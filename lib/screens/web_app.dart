import '../widgets/sandbox_load_recovery.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:quantumquiz/widgets/progress_save_feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quantumquiz/models/bloch_lab.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/qq_levels.dart' show journeyChapters;
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/screens/web_bloch_workspace.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';

const _surface = QubitQuestColors.surface;
const _cyan = QubitQuestColors.accentInteractive;
const _purple = QubitQuestColors.accentStrong;

enum WebDestination { journey, notebook, mastery, composer, bloch }

/// Parses a web address fragment such as `/journey/chapter-3` (v2.6 M5,
/// D8). Returns null for an empty or unknown destination. A chapter is
/// returned (zero-based) only for an existing Journey chapter; it selects
/// the chapter for reading and never unlocks its lessons.
({WebDestination destination, int? chapterIndex, String? articleId})?
    parseWebRoute(String fragment) {
  final segments =
      fragment.split('/').where((segment) => segment.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  final destination =
      WebDestination.values.where((d) => d.name == segments.first).firstOrNull;
  if (destination == null) return null;
  int? chapter;
  if (destination == WebDestination.journey && segments.length > 1) {
    final match = RegExp(r'^chapter-(\d+)$').firstMatch(segments[1]);
    final number = match == null ? null : int.tryParse(match.group(1)!);
    if (number != null && number >= 1 && number <= journeyChapters.length) {
      chapter = number - 1;
    }
  }
  // v2.6 M6b: `#/notebook/<article-id>` (an entry ID or `gate-<type>`).
  String? article;
  if (destination == WebDestination.notebook && segments.length > 1) {
    final id = segments[1];
    if (RegExp(r'^[a-z0-9_-]+$').hasMatch(id)) article = id;
  }
  return (destination: destination, chapterIndex: chapter, articleId: article);
}

class QubitQuestWebApp extends StatelessWidget {
  QubitQuestWebApp({
    super.key,
    this.storage = const SharedPreferencesAppStorage(),
    String? startupRoute,
  })  : progressController = CampaignProgressController(
          store: SharedPreferencesCampaignProgressStore(storage: storage),
        ),
        sandboxPersistenceStore = SandboxPersistenceStore(storage: storage),
        layoutController = WorkspaceLayoutController(storage: storage),
        // Pass the route captured in main() before any Navigator exists: the
        // startup splash's Navigator reports `/` and replaces the address.
        startupRoute =
            startupRoute ?? ui.PlatformDispatcher.instance.defaultRouteName {
    CampaignProgressController.configureSharedInstance(progressController);
  }

  /// The address the app was opened with (e.g. `/journey/chapter-3`).
  final String startupRoute;

  final AppStorage storage;
  final CampaignProgressController progressController;
  final SandboxPersistenceStore sandboxPersistenceStore;

  /// Presentation-only preferences (navigation rail, Composer panels).
  final WorkspaceLayoutController layoutController;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Qubit Quest',
        debugShowCheckedModeBanner: false,
        theme: QubitQuestTheme.web(),
        // Destinations are shell state, not Navigator routes: the shell reads
        // the address itself (parseWebRoute), so the Navigator always starts
        // at its single home route.
        initialRoute: '/',
        home: QubitQuestWebShell(
          startupRoute: startupRoute,
          progressController: progressController,
          sandboxPersistenceStore: sandboxPersistenceStore,
          layoutController: layoutController,
        ),
      );
}

/// Test seam (v2.6 M11C): true hosts the Sandbox in the classic
/// three-column Composer layout, which Journey lessons, Mastery challenges
/// and Notebook examples still use until M11D. Existing layout tests set it
/// so they keep covering that layout; production never changes it.
@visibleForTesting
bool debugClassicSandboxLayout = false;

class QubitQuestWebShell extends StatefulWidget {
  const QubitQuestWebShell({
    super.key,
    required this.progressController,
    required this.sandboxPersistenceStore,
    this.layoutController,
    this.startupRoute = '/',
  });

  /// Address fragment the app was opened with; see [parseWebRoute].
  final String startupRoute;

  final CampaignProgressController progressController;
  final SandboxPersistenceStore sandboxPersistenceStore;

  /// Shared with the Composer workspace; an in-memory controller is used
  /// when none is supplied.
  final WorkspaceLayoutController? layoutController;

  @override
  State<QubitQuestWebShell> createState() => _QubitQuestWebShellState();
}

class _QubitQuestWebShellState extends State<QubitQuestWebShell> {
  static const double _wideNavigationBreakpoint = 900;
  static const double _sidebarWidth = 238;
  static const double _railWidth = 64;
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  WebDestination _destination = WebDestination.journey;

  /// Chapter shown in the Journey overview, mirrored as
  /// `#/journey/chapter-N`; null when none was chosen yet.
  int? _journeyChapter;

  /// A chapter requested by the address at startup (zero-based).
  int? _initialJourneyChapter;
  String? _reportedRoute;
  String? _requestedNotebookDiscoveryTitle;
  String? _requestedNotebookArticleId;

  /// Article shown in the Notebook, mirrored as `#/notebook/<id>`.
  String? _notebookArticle;

  /// Cross-destination requests (v2.6 M6b). The serial makes a repeated
  /// request for the same target act again.
  int _requestSerial = 0;
  int _notebookRequestSerial = 0;
  ({int lessonId, int serial})? _journeyLessonRequest;
  ({String id, int serial})? _masteryChallengeRequest;

  /// The learner's own Bloch laboratory (kept across destinations) and an
  /// optional isolated exploration (v2.6 M8). Explorations never modify the
  /// standalone lab, the Sandbox or any progress.
  final BlochLabSession _blochLab = BlochLabSession.standalone();
  BlochLabSession? _blochExploration;
  VoidCallback? _blochReturn;
  late final WorkspaceLayoutController _layout =
      widget.layoutController ?? WorkspaceLayoutController();

  /// Startup address → destination (v2.6 M5, D8). Hash routes, one per
  /// primary destination plus Journey chapters: `#/journey`,
  /// `#/journey/chapter-3`, `#/notebook`, `#/mastery`, `#/composer`,
  /// `#/bloch`. A chapter link only *selects* the chapter: its lessons still
  /// follow the progression rules. Unknown routes open the Journey.
  void _readStartupRoute() {
    // On the web (hash strategy) the platform's default route is the
    // address fragment, e.g. `/journey/chapter-3`; elsewhere it is `/`.
    // (Uri.base is the document base, which has no fragment.)
    final route = parseWebRoute(widget.startupRoute);
    if (route == null) return;
    _destination = route.destination;
    _initialJourneyChapter = route.chapterIndex;
    _journeyChapter = route.chapterIndex;
    if (route.articleId case final id?) {
      _requestedNotebookArticleId = id;
      _notebookRequestSerial = ++_requestSerial;
    }
  }

  String get _route => switch (_destination) {
        WebDestination.journey when _journeyChapter != null =>
          '/journey/chapter-${_journeyChapter! + 1}',
        WebDestination.notebook when _notebookArticle != null =>
          '/notebook/$_notebookArticle',
        _ => '/${_destination.name}',
      };

  /// Mirrors the current destination in the address bar, replacing the
  /// history entry (Back and Forward are not intercepted; see the M5
  /// report). Never touches sessions: destinations stay mounted.
  void _reportRoute() {
    if (!kIsWeb) return;
    final route = _route;
    if (route == _reportedRoute) return;
    _reportedRoute = route;
    SystemNavigator.routeInformationUpdated(
        uri: Uri(path: route), replace: true);
  }

  @override
  void initState() {
    super.initState();
    _readStartupRoute();
    unawaited(widget.progressController.load());
    unawaited(_layout.load());
    _layout.addListener(_layoutChanged);
  }

  bool _navigationCollapsed =
      WorkspaceLayoutPreferences.defaults.navigationCollapsed;

  void _layoutChanged() {
    final collapsed = _layout.preferences.navigationCollapsed;
    if (collapsed != _navigationCollapsed && mounted) {
      setState(() => _navigationCollapsed = collapsed);
    }
  }

  void _toggleNavigation() => _layout.commit(
      _layout.preferences.copyWith(navigationCollapsed: !_navigationCollapsed));

  @override
  void dispose() {
    _layout.removeListener(_layoutChanged);
    if (widget.layoutController == null) _layout.dispose();
    super.dispose();
  }

  void _select(WebDestination destination) {
    setState(() => _destination = destination);
  }

  void _openNotebook([String? discoveryTitle]) {
    setState(() {
      _requestedNotebookDiscoveryTitle = discoveryTitle;
      _requestedNotebookArticleId = null;
      _notebookRequestSerial = ++_requestSerial;
      _destination = WebDestination.notebook;
    });
  }

  /// Opens a Notebook article by its stable ID (e.g. `gate-cnot`).
  void _openNotebookArticle(String id) {
    setState(() {
      _requestedNotebookDiscoveryTitle = null;
      _requestedNotebookArticleId = id;
      _notebookRequestSerial = ++_requestSerial;
      _destination = WebDestination.notebook;
    });
  }

  /// Opens a Journey lesson; the Journey enforces its locks.
  void _openJourneyLesson(int lessonId) {
    setState(() {
      _journeyLessonRequest = (lessonId: lessonId, serial: ++_requestSerial);
      _destination = WebDestination.journey;
    });
  }

  /// Opens a Mastery challenge (always accessible).
  void _openMasteryChallenge(String semanticId) {
    setState(() {
      _masteryChallengeRequest = (id: semanticId, serial: ++_requestSerial);
      _destination = WebDestination.mastery;
    });
  }

  void _openMastery() {
    _select(WebDestination.mastery);
  }

  /// Opens [seed] as an isolated exploration; [onReturn] goes back to where
  /// it came from. A new exploration replaces only the previous exploration.
  void _openBlochExploration(BlochLabSeed seed, {VoidCallback? onReturn}) {
    final previous = _blochExploration;
    setState(() {
      _blochExploration = BlochLabSession(seed);
      _blochReturn = onReturn;
      _destination = WebDestination.bloch;
    });
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _closeBlochExploration() {
    final previous = _blochExploration;
    if (previous == null) return;
    setState(() {
      _blochExploration = null;
      _blochReturn = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  void _openNotebookExampleInBloch(
    ExecutableNotebookExample example,
    ExecutableNotebookResult result,
  ) {
    final seed = blochSeedForNotebookExample(example);
    if (seed == null) return;
    // The Notebook stays mounted, so its article and scroll are intact.
    _openBlochExploration(seed,
        onReturn: () => _select(WebDestination.notebook));
  }

  void _exploreCircuitInBloch(QuantumCircuit circuit) {
    final seed = blochSeedForCircuit(circuit);
    if (seed == null) return;
    // The Composer session (circuit and results) is retained.
    _openBlochExploration(seed,
        onReturn: () => _select(WebDestination.composer));
  }

  Widget _workspace() => IndexedStack(
        index: _destination.index,
        children: [
          WebJourneyWorkspace(
            initialChapterIndex: _initialJourneyChapter,
            onChapterShown: (index) {
              _journeyChapter = index;
              _reportRoute();
            },
            progressController: widget.progressController,
            onOpenNotebook: _openNotebook,
            onOpenNotebookEntry: _openNotebook,
            onOpenMastery: _openMastery,
            layout: _layout,
            isActive: _destination == WebDestination.journey,
            requestedLessonId: _journeyLessonRequest?.lessonId,
            lessonRequestSerial: _journeyLessonRequest?.serial ?? 0,
          ),
          WebNotebookWorkspace(
            key: const ValueKey('web-workspace-notebook'),
            progressController: widget.progressController,
            requestedDiscoveryTitle: _requestedNotebookDiscoveryTitle,
            requestedArticleId: _requestedNotebookArticleId,
            requestSerial: _notebookRequestSerial,
            onOpenJourney: () => _select(WebDestination.journey),
            onOpenExampleInBlochExplorer: _openNotebookExampleInBloch,
            onOpenJourneyLesson: _openJourneyLesson,
            onOpenMasteryChallenge: _openMasteryChallenge,
            layout: _layout,
            isActive: _destination == WebDestination.notebook,
            onArticleShown: (id) {
              _notebookArticle = id;
              _reportRoute();
            },
          ),
          WebMasteryWorkspace(
            key: const ValueKey('web-workspace-mastery'),
            progressController: widget.progressController,
            onBackToJourney: () => _select(WebDestination.journey),
            onOpenNotebook: _openNotebook,
            onOpenNotebookEntry: _openNotebook,
            onOpenNotebookArticle: _openNotebookArticle,
            layout: _layout,
            isActive: _destination == WebDestination.mastery,
            requestedChallengeId: _masteryChallengeRequest?.id,
            challengeRequestSerial: _masteryChallengeRequest?.serial ?? 0,
          ),
          _ComposerWorkspace(
            key: const ValueKey('web-workspace-composer'),
            persistence: widget.sandboxPersistenceStore,
            isActive: _destination == WebDestination.composer,
            layout: _layout,
            onOpenNotebookEntry: _openNotebook,
            onExploreInBloch: _exploreCircuitInBloch,
          ),
          WebBlochWorkspace(
            key: const ValueKey('web-workspace-bloch'),
            standalone: _blochLab,
            exploration: _blochExploration,
            onReturnFromExploration: _blochReturn,
            onCloseExploration: _closeBlochExploration,
            onStartComparison: (seed) => _openBlochExploration(seed),
            onOpenNotebookEntry: _openNotebook,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _reportRoute());
          final wide = constraints.maxWidth >= _wideNavigationBreakpoint;
          final rail = wide && _navigationCollapsed;
          final navigation = AnimatedBuilder(
            animation: widget.progressController,
            builder: (context, _) => _WebNavigation(
              selected: _destination,
              packageInfo: _packageInfo,
              collapsed: rail,
              onToggleCollapsed: wide ? _toggleNavigation : null,
              onSelected: (destination) {
                if (!wide) Navigator.of(context).pop();
                if (destination == WebDestination.mastery) {
                  if (wide) {
                    _openMastery();
                  } else {
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _openMastery());
                  }
                } else {
                  _select(destination);
                }
              },
            ),
          );
          // Shell v2 (v2.6 M11C): on wide layouts the brand sits at the top
          // of the global navigation, so the workspace starts at the top of
          // the window and its own header is the page header. Narrow
          // layouts keep the top bar with the menu button.
          return Scaffold(
            key: const ValueKey('web-shell'),
            bottomNavigationBar:
                ProgressSaveStatusView(controller: widget.progressController),
            backgroundColor: QubitQuestSurfaces.app,
            appBar: wide
                ? null
                : AppBar(
                    toolbarHeight: 52,
                    backgroundColor: QubitQuestSurfaces.nav,
                    leading: Builder(
                      builder: (context) => IconButton(
                        key: const ValueKey('web-navigation-menu'),
                        tooltip: 'Open navigation',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu),
                      ),
                    ),
                    title: const _QubitQuestWordmark(),
                    bottom: const PreferredSize(
                      preferredSize: Size.fromHeight(1),
                      child: Divider(
                          height: 1, color: QubitQuestColors.shellDivider),
                    ),
                  ),
            drawer: wide
                ? null
                : Drawer(
                    key: const ValueKey('web-navigation-drawer'),
                    backgroundColor: QubitQuestSurfaces.nav,
                    child: SafeArea(child: navigation),
                  ),
            body: Row(
              children: [
                if (wide) ...[
                  Container(
                    key: const ValueKey('web-navigation-sidebar'),
                    width: rail ? _railWidth : _sidebarWidth,
                    color: QubitQuestSurfaces.nav,
                    child: SafeArea(right: false, child: navigation),
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: QubitQuestColors.shellDivider,
                  ),
                ],
                Expanded(
                  key: const ValueKey('web-workspace-host'),
                  child: _workspace(),
                ),
              ],
            ),
          );
        },
      );
}

class _QubitQuestWordmark extends StatelessWidget {
  const _QubitQuestWordmark();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Qubit Quest',
        image: true,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          key: const ValueKey('web-qubit-quest-wordmark'),
          height: 26,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
      );
}

/// Compact brand for the navigation rail: the wordmark's ϕ, with the full
/// name for assistive technology and in a tooltip.
class _QubitQuestMark extends StatelessWidget {
  const _QubitQuestMark();

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Qubit Quest',
        child: Semantics(
          label: 'Qubit Quest',
          image: true,
          child: Container(
            key: const ValueKey('web-qubit-quest-wordmark'),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: QubitQuestRadii.card,
              border: Border.all(color: QubitQuestColors.border),
            ),
            child: const ExcludeSemantics(
              child: Text(
                '⟨ϕ|',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
}

class _WebNavigation extends StatelessWidget {
  const _WebNavigation({
    required this.selected,
    required this.packageInfo,
    required this.onSelected,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  final WebDestination selected;
  final Future<PackageInfo> packageInfo;
  final ValueChanged<WebDestination> onSelected;

  /// Icon rail with tooltips instead of labelled rows.
  final bool collapsed;

  /// Collapses or expands the sidebar; null in the narrow-screen drawer.
  final VoidCallback? onToggleCollapsed;

  static const _destinations = [
    (WebDestination.journey, Icons.route_outlined, 'Journey'),
    (WebDestination.notebook, Icons.menu_book_outlined, 'Notebook'),
    (
      WebDestination.mastery,
      Icons.workspace_premium_outlined,
      'Mastery Challenges'
    ),
    (WebDestination.composer, Icons.account_tree_outlined, 'Composer'),
    (WebDestination.bloch, Icons.blur_circular, 'Bloch Explorer'),
  ];

  Widget _toggle() => Tooltip(
        message: collapsed ? 'Expand navigation' : 'Collapse navigation',
        child: IconButton(
          key: const ValueKey('web-navigation-collapse'),
          onPressed: onToggleCollapsed,
          icon: Icon(
            collapsed
                ? Icons.keyboard_double_arrow_right_rounded
                : Icons.keyboard_double_arrow_left_rounded,
            size: 20,
          ),
          color: QubitQuestColors.textMuted,
        ),
      );

  @override
  Widget build(BuildContext context) => collapsed ? _rail() : _expanded();

  /// The brand heads the navigation on wide layouts (the drawer's top bar
  /// already shows it on narrow ones).
  bool get _showsBrand => onToggleCollapsed != null;

  Widget _rail() => Column(
        key: const ValueKey('web-navigation-rail'),
        children: [
          if (_showsBrand)
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 16, 8, 10),
              child: _QubitQuestMark(),
            ),
          const SizedBox(height: 14),
          for (final (destination, icon, label) in _destinations) ...[
            if (destination == WebDestination.composer)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Divider(height: 1, color: QubitQuestColors.borderSoft),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Tooltip(
                message: label,
                preferBelow: false,
                child: Semantics(
                  selected: selected == destination,
                  label: label,
                  button: true,
                  child: IconButton(
                    key: ValueKey('web-nav-${destination.name}'),
                    isSelected: selected == destination,
                    onPressed: () => onSelected(destination),
                    icon: Icon(icon),
                    color: QubitQuestColors.textMuted,
                    selectedIcon: Icon(icon, color: _cyan),
                    style: IconButton.styleFrom(
                      backgroundColor: selected == destination
                          ? QubitQuestColors.navigationSelected
                          : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onToggleCollapsed != null) _toggle(),
          const SizedBox(height: 12),
        ],
      );

  Widget _expanded() => Column(children: [
        if (_showsBrand)
          const Padding(
            padding: EdgeInsets.fromLTRB(26, 22, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _QubitQuestWordmark(),
            ),
          ),
        Expanded(
            child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
          children: [
            const _NavigationHeading('LEARN'),
            _item(WebDestination.journey, Icons.route_outlined, 'Journey'),
            _item(
                WebDestination.notebook, Icons.menu_book_outlined, 'Notebook'),
            _item(WebDestination.mastery, Icons.workspace_premium_outlined,
                'Mastery Challenges'),
            const SizedBox(height: 22),
            const _NavigationHeading('EXPLORE'),
            _item(WebDestination.composer, Icons.account_tree_outlined,
                'Composer'),
            _item(WebDestination.bloch, Icons.blur_circular, 'Bloch Explorer'),
          ],
        )),
        FutureBuilder<PackageInfo>(
          future: packageInfo,
          builder: (context, snapshot) {
            final info = snapshot.data;
            if (info == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Divider(color: QubitQuestColors.borderSoft),
                const SizedBox(height: 8),
                Text(
                  'Web v${info.version} · Build ${info.buildNumber}',
                  key: const ValueKey('web-navigation-version'),
                  textAlign: TextAlign.center,
                  style: QubitQuestTypography.supporting
                      .copyWith(color: QubitQuestColors.textMuted),
                ),
              ]),
            );
          },
        ),
        if (onToggleCollapsed != null)
          Align(alignment: Alignment.centerRight, child: _toggle()),
        const SizedBox(height: 10),
      ]);

  Widget _item(WebDestination destination, IconData icon, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          key: ValueKey('web-nav-${destination.name}'),
          selected: selected == destination,
          selectedColor: _cyan,
          selectedTileColor: QubitQuestColors.navigationSelected,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          onTap: () => onSelected(destination),
        ),
      );
}

class _NavigationHeading extends StatelessWidget {
  const _NavigationHeading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Text(
          label,
          style: const TextStyle(
            color: _purple,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      );
}

class _ComposerWorkspace extends StatefulWidget {
  const _ComposerWorkspace({
    super.key,
    required this.persistence,
    required this.isActive,
    required this.layout,
    this.onOpenNotebookEntry,
    this.onExploreInBloch,
  });

  /// Opens a one-qubit Sandbox circuit in the Bloch Explorer (v2.6 M8).
  final ValueChanged<QuantumCircuit>? onExploreInBloch;

  /// Opens a Notebook discovery (related concepts in the Learn section).
  /// The Composer stays mounted, so its session survives the visit.
  final ValueChanged<String>? onOpenNotebookEntry;
  final SandboxPersistenceStore persistence;
  final bool isActive;

  /// Presentation-only layout preferences, shared with the shell.
  final WorkspaceLayoutController layout;

  @override
  State<_ComposerWorkspace> createState() => _ComposerWorkspaceState();
}

/// Web host for the Sandbox. It owns the Sandbox session and the qubit
/// chooser; the workspace itself is the shared [ComposerSessionWorkspace]
/// (also used by Journey lessons, Mastery challenges and Notebook
/// experiments). Notebook experiments run inside the Notebook in sessions of
/// their own (v2.6 M6b), so nothing here ever replaces the Sandbox.
///
/// Measurement results belong to each session (v2.6 M6a): leaving the
/// Composer for another destination keeps them, because the session is
/// retained. Only a change to the circuit invalidates them.
class _ComposerWorkspaceState extends State<_ComposerWorkspace> {
  static const String _chooseStatus =
      'Choose a circuit size to open the Sandbox.';

  ComposerWorkspaceSlot? _sandbox;
  bool _opening = false;
  String? _openError;
  String _chooserStatus = _chooseStatus;

  static Future<void> _endOfFrame() => WidgetsBinding.instance.endOfFrame;

  void _disposeSlot(ComposerWorkspaceSlot? slot) => slot?.session.dispose();

  /// Register size opened on entry (v2.6 M11C): the size used last in this
  /// visit, else one qubit. The header's qubit selector changes it.
  int _entryQubits = ComposerPolicy.sandboxQubitCounts.first;

  /// The automatic open happens once per visit; after a cancelled or failed
  /// open the size choices are shown instead of retrying.
  bool _entryHandled = false;
  bool _autoOpenPending = false;

  @override
  void initState() {
    super.initState();
    _openOnEntry();
  }

  @override
  void didUpdateWidget(covariant _ComposerWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _openOnEntry();
  }

  /// The Composer opens straight into the Sandbox (M11B F14) the first
  /// time it becomes visible; storage is not read before that. A failed
  /// open is not retried automatically: the error and the size choices
  /// stay on screen instead.
  void _openOnEntry() {
    if (!widget.isActive || _entryHandled || _sandbox != null || _opening) {
      return;
    }
    _entryHandled = true;
    _autoOpenPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && widget.isActive && _sandbox == null) {
        await _openSandbox(_entryQubits);
      }
      if (mounted) setState(() => _autoOpenPending = false);
    });
  }

  @override
  void dispose() {
    _disposeSlot(_sandbox);
    super.dispose();
  }

  Future<void> _openSandbox(int qubitCount) async {
    if (_opening) return;
    _opening = true;
    _entryQubits = qubitCount;
    if (_openError != null) setState(() => _openError = null);
    QuantumCircuit? nextCircuit;
    var installed = false;
    try {
      final programs = widget.persistence.programs;
      final loaded =
          await loadSandboxWithRecovery(context, programs, qubitCount);
      if (!mounted || !loaded.opened) return;
      final snapshot = loaded.snapshot;
      nextCircuit = snapshot?.restoreCircuit() ??
          QuantumCircuit(currentLevel: createSandboxComposerLevel(qubitCount));
      if (!nextCircuit.hasMeasurements) nextCircuit.runSimulation();
      final session = ComposerSession(
        circuit: nextCircuit,
        policy: ComposerPolicy.forMode(
          ComposerMode.sandbox,
          nextCircuit.currentLevel,
        ),
        saveQueue: programs.queue(qubitCount),
        beforeRun: _endOfFrame,
      );
      installed = true;
      final old = _sandbox;
      setState(() {
        // The restore/ready note is informational: it fades (M5).
        _sandbox = ComposerWorkspaceSlot(
          session,
          status: snapshot == null
              ? 'Ready — changes save in this browser.'
              : 'Restored ${snapshot.program.operations.length} saved '
                  'operation(s).',
          statusFades: true,
        );
      });
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _disposeSlot(old));
      }
    } catch (error, stackTrace) {
      // Unexpected initialization/restoration failures (recoverable storage
      // errors are handled by loadSandboxWithRecovery). Never substitute an
      // empty circuit: saved records stay untouched for the next attempt.
      debugPrint('Unable to open $qubitCount-qubit Sandbox: $error\n'
          '$stackTrace');
      if (!installed) nextCircuit?.dispose();
      if (!mounted) return;
      final message = 'Could not open the $qubitCount-qubit Sandbox. '
          'Saved circuits were kept. Please try again.';
      setState(() {
        _openError = message;
        _chooserStatus = message;
      });
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _opening = false;
    }
  }

  Widget _buildQubitChooser() => _WorkspaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ComposerSectionHeading(
              title: 'Choose Number of Qubits',
              icon: Icons.memory_outlined,
            ),
            const SizedBox(height: 8),
            const Text(
              'Open the sandbox with a circuit size.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final qubits in ComposerPolicy.sandboxQubitCounts)
                  FilledButton(
                    key: ValueKey('web-composer-qubits-$qubits'),
                    onPressed: () => _openSandbox(qubits),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 58),
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text('$qubits'),
                  ),
              ],
            ),
            if (_openError != null) ...[
              const SizedBox(height: 12),
              Text(
                _openError!,
                key: const ValueKey('web-composer-open-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ] else if (_chooserStatus != _chooseStatus) ...[
              const SizedBox(height: 12),
              Text(_chooserStatus, style: QubitQuestTypography.supporting),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final slot = _sandbox;
    if (slot == null && _autoOpenPending) {
      // Opening on entry: a quiet placeholder for the moment storage is
      // read (the size choices appear only if opening fails).
      return const Center(
        key: ValueKey('web-composer-opening'),
        child: Text('Opening the Sandbox…',
            style: QubitQuestTypography.supporting),
      );
    }
    if (slot == null) {
      return LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final horizontalPadding = compact ? 14.0 : 24.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            compact ? 16 : 24,
            horizontalPadding,
            24,
          ),
          children: [
            const _WorkspaceHeading(
              title: 'Composer',
              subtitle: 'Build, move, and inspect quantum gates.',
            ),
            SizedBox(height: compact ? 14 : 18),
            _buildQubitChooser(),
          ],
        );
      });
    }
    return ComposerSessionWorkspace(
      // One workspace state per session.
      key: ObjectKey(slot.session),
      slot: slot,
      layout: widget.layout,
      shortcutsEnabled: widget.isActive,
      contextLabel: 'Sandbox',
      laboratory: !debugClassicSandboxLayout,
      onSelectQubits: _openSandbox,
      clearedStatus: 'Circuit cleared.',
      onOpenNotebookEntry: widget.onOpenNotebookEntry,
      showLegacyMeasurementNote: true,
      onExploreInBloch: widget.onExploreInBloch == null
          ? null
          : () => widget.onExploreInBloch!(slot.session.circuit),
    );
  }
}

class _ComposerSectionHeading extends StatelessWidget {
  const _ComposerSectionHeading({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _cyan),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: QubitQuestColors.textPrimary,
              ),
            ),
          ),
        ],
      );
}

class _WorkspaceHeading extends StatelessWidget {
  const _WorkspaceHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      );
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x66344A73)),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}
