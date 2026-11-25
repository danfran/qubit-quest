import '../widgets/sandbox_load_recovery.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:quantumquiz/widgets/progress_save_feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/qq_levels.dart' show journeyChapters;
import 'package:quantumquiz/models/composer_policy.dart';
import 'package:quantumquiz/models/composer_session.dart';
import 'package:quantumquiz/models/executable_notebook_example.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/screens/gate_inspector_dialog.dart';
import 'package:quantumquiz/screens/web_learning_workspace.dart';
import 'package:quantumquiz/screens/web_notebook_workspace.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_session_workspace.dart';
import 'package:quantumquiz/widgets/composer_workspace/workspace_layout_state.dart';

const _background = QubitQuestColors.background;
const _surface = QubitQuestColors.surface;
const _cyan = QubitQuestColors.accentInteractive;
const _purple = QubitQuestColors.accentStrong;

enum WebDestination { journey, notebook, mastery, composer, bloch }

/// Parses a web address fragment such as `/journey/chapter-3` (v2.6 M5,
/// D8). Returns null for an empty or unknown destination. A chapter is
/// returned (zero-based) only for an existing Journey chapter; it selects
/// the chapter for reading and never unlocks its lessons.
({WebDestination destination, int? chapterIndex})? parseWebRoute(
    String fragment) {
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
  return (destination: destination, chapterIndex: chapter);
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
  ExecutableNotebookExample? _requestedComposerExample;
  BlochState? _requestedBlochState;
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
  }

  String get _route => switch (_destination) {
        WebDestination.journey when _journeyChapter != null =>
          '/journey/chapter-${_journeyChapter! + 1}',
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
    setState(() {
      if (destination == WebDestination.composer) {
        _requestedComposerExample = null;
      }
      _destination = destination;
    });
  }

  void _openNotebook([String? discoveryTitle]) {
    setState(() {
      _requestedNotebookDiscoveryTitle = discoveryTitle;
      _destination = WebDestination.notebook;
    });
  }

  void _openMastery() {
    _select(WebDestination.mastery);
  }

  void _openNotebookExampleInComposer(ExecutableNotebookExample example) {
    setState(() {
      _requestedComposerExample = example;
      _destination = WebDestination.composer;
    });
  }

  void _openNotebookExampleInBloch(
    ExecutableNotebookExample example,
    ExecutableNotebookResult result,
  ) {
    if (example.qubitCount != 1 || result.state.length != 2) return;
    setState(() {
      _requestedBlochState = BlochState.fromAmplitudes(
        result.state[0],
        result.state[1],
      );
      _destination = WebDestination.bloch;
    });
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
          ),
          WebNotebookWorkspace(
            key: const ValueKey('web-workspace-notebook'),
            progressController: widget.progressController,
            requestedDiscoveryTitle: _requestedNotebookDiscoveryTitle,
            onOpenJourney: () => _select(WebDestination.journey),
            onOpenExampleInComposer: _openNotebookExampleInComposer,
            onOpenExampleInBlochExplorer: _openNotebookExampleInBloch,
          ),
          WebMasteryWorkspace(
            key: const ValueKey('web-workspace-mastery'),
            progressController: widget.progressController,
            onBackToJourney: () => _select(WebDestination.journey),
            onOpenNotebook: _openNotebook,
            onOpenNotebookEntry: _openNotebook,
            layout: _layout,
            isActive: _destination == WebDestination.mastery,
          ),
          _ComposerWorkspace(
            key: const ValueKey('web-workspace-composer'),
            persistence: widget.sandboxPersistenceStore,
            example: _requestedComposerExample,
            isActive: _destination == WebDestination.composer,
            layout: _layout,
            onOpenNotebookEntry: _openNotebook,
          ),
          _BlochWorkspace(
            key: const ValueKey('web-workspace-bloch'),
            requestedInitialState: _requestedBlochState,
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
          return Scaffold(
            key: const ValueKey('web-shell'),
            bottomNavigationBar:
                ProgressSaveStatusView(controller: widget.progressController),
            backgroundColor: _background,
            appBar: AppBar(
              toolbarHeight: 52,
              leading: wide
                  ? null
                  : Builder(
                      builder: (context) => IconButton(
                        key: const ValueKey('web-navigation-menu'),
                        tooltip: 'Open navigation',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu),
                      ),
                    ),
              automaticallyImplyLeading: !wide,
              title: const _QubitQuestWordmark(),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: QubitQuestColors.shellDivider),
              ),
            ),
            drawer: wide
                ? null
                : Drawer(
                    key: const ValueKey('web-navigation-drawer'),
                    backgroundColor: _surface,
                    child: SafeArea(child: navigation),
                  ),
            body: Row(
              children: [
                if (wide) ...[
                  SizedBox(
                    key: const ValueKey('web-navigation-sidebar'),
                    width: rail ? _railWidth : _sidebarWidth,
                    child: navigation,
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

  Widget _rail() => Column(
        key: const ValueKey('web-navigation-rail'),
        children: [
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
    this.example,
    this.onOpenNotebookEntry,
  });

  /// Opens a Notebook discovery (related concepts in the Learn section).
  /// The Composer stays mounted, so its session survives the visit.
  final ValueChanged<String>? onOpenNotebookEntry;
  final SandboxPersistenceStore persistence;
  final bool isActive;
  final ExecutableNotebookExample? example;

  /// Presentation-only layout preferences, shared with the shell.
  final WorkspaceLayoutController layout;

  @override
  State<_ComposerWorkspace> createState() => _ComposerWorkspaceState();
}

/// Web host for the Sandbox and for Notebook examples. It owns the two
/// sessions and the qubit chooser; the workspace itself is the shared
/// [ComposerSessionWorkspace] (also used by Journey lessons and Mastery
/// challenges, v2.6 M6a).
///
/// The Sandbox and the active Notebook example are independent sessions:
/// opening an example never replaces, edits or saves the Sandbox circuit,
/// and returning to the Sandbox shows it exactly as it was left.
///
/// Measurement results belong to each session (v2.6 M6a): leaving the
/// Composer for another destination keeps them, because the session is
/// retained. Only a change to the circuit invalidates them.
class _ComposerWorkspaceState extends State<_ComposerWorkspace> {
  static const String _chooseStatus =
      'Choose a circuit size to open the Sandbox.';

  ComposerWorkspaceSlot? _sandbox;
  ComposerWorkspaceSlot? _example;
  bool _opening = false;
  String? _openError;
  String _chooserStatus = _chooseStatus;

  bool get _isExample => widget.example != null;
  ComposerWorkspaceSlot? get _slot => _isExample ? _example : _sandbox;

  @override
  void initState() {
    super.initState();
    if (widget.example != null) _example = _newExampleSlot(widget.example!);
  }

  ComposerWorkspaceSlot _newExampleSlot(ExecutableNotebookExample example) {
    final level = example.createEditableComposerLevel();
    final session = ComposerSession(
      circuit: QuantumCircuit(currentLevel: level),
      policy: ComposerPolicy.forMode(ComposerMode.notebookExample, level),
      beforeRun: _endOfFrame,
    );
    return ComposerWorkspaceSlot(session,
        status: 'Notebook example: ${example.title}');
  }

  static Future<void> _endOfFrame() => WidgetsBinding.instance.endOfFrame;

  void _disposeSlot(ComposerWorkspaceSlot? slot) => slot?.session.dispose();

  @override
  void didUpdateWidget(covariant _ComposerWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.example, widget.example)) {
      // Only the example session changes; the Sandbox session is untouched.
      final old = _example;
      _example =
          widget.example == null ? null : _newExampleSlot(widget.example!);
      // Disposed after this frame, once its workspace has unmounted.
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _disposeSlot(old));
      }
    }
  }

  @override
  void dispose() {
    _disposeSlot(_sandbox);
    _disposeSlot(_example);
    super.dispose();
  }

  Future<void> _openSandbox(int qubitCount) async {
    if (_opening) return;
    _opening = true;
    if (_openError != null) setState(() => _openError = null);
    QuantumCircuit? nextCircuit;
    var installed = false;
    try {
      final programs = widget.persistence.programs;
      final loaded =
          await loadSandboxWithRecovery(context, programs, qubitCount);
      if (!mounted || !loaded.opened || widget.example != null) return;
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
    final slot = _slot;
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
      // One workspace state per session: Sandbox and example never share
      // inspector tabs, result scroll or status.
      key: ObjectKey(slot.session),
      slot: slot,
      layout: widget.layout,
      shortcutsEnabled: widget.isActive,
      contextLabel: _isExample
          ? 'Notebook example · ${widget.example!.title}'
          : 'Sandbox',
      onSelectQubits: _isExample ? null : _openSandbox,
      clearLabel: _isExample ? 'Reset example' : null,
      clearedStatus:
          _isExample ? 'Cleared Notebook example.' : 'Circuit cleared.',
      onOpenNotebookEntry: widget.onOpenNotebookEntry,
      showLegacyMeasurementNote: !_isExample,
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

class _BlochWorkspace extends StatefulWidget {
  const _BlochWorkspace({
    super.key,
    this.requestedInitialState,
    this.onOpenNotebookEntry,
  });

  final BlochState? requestedInitialState;
  final ValueChanged<String>? onOpenNotebookEntry;

  @override
  State<_BlochWorkspace> createState() => _BlochWorkspaceState();
}

class _BlochWorkspaceState extends State<_BlochWorkspace>
    with SingleTickerProviderStateMixin {
  static const _gateDuration = Duration(milliseconds: 650);
  static const _replayDuration = Duration(milliseconds: 420);
  static const _replayGap = Duration(milliseconds: 90);

  late final BlochExplorerHistory _history;
  late final AnimationController _animation;
  final ScrollController _historyScrollController = ScrollController();
  late BlochState _displayState;
  BlochState? _animationStart;
  BlochState? _animationEnd;
  BlochCamera _camera = const BlochCamera();
  double _angle = math.pi / 2;
  bool _instant = false;
  bool _replaying = false;
  int _replayGeneration = 0;
  int? _selectedHistoryIndex;
  BlochHistoryEntry? _selectedHistoryEntry;
  int? _activeHistoryIndex;
  bool _historyExpanded = false;
  String _interaction = 'Ready.';

  @override
  void initState() {
    super.initState();
    _displayState = widget.requestedInitialState ?? BlochState.zero;
    _history = BlochExplorerHistory(initial: _displayState)
      ..addListener(_syncHistory);
    _animation = AnimationController(vsync: this, duration: _gateDuration)
      ..addListener(_tickAnimation);
  }

  @override
  void didUpdateWidget(covariant _BlochWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
        oldWidget.requestedInitialState, widget.requestedInitialState)) {
      final requested = widget.requestedInitialState;
      if (requested != null) {
        _cancelMotion(restoreCurrent: false);
        _history.reset(initial: requested);
        setState(() {
          _displayState = requested;
          _selectedHistoryIndex = null;
          _selectedHistoryEntry = null;
          _interaction = 'Opened Notebook example result.';
        });
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _history
      ..removeListener(_syncHistory)
      ..dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _syncHistory() {
    if (!mounted) return;
    setState(() {
      final selected = _selectedHistoryIndex;
      if (selected != null &&
          (selected > _history.index ||
              selected >= _history.entries.length ||
              !identical(_history.entries[selected], _selectedHistoryEntry))) {
        _selectedHistoryIndex = null;
        _selectedHistoryEntry = null;
      }
      _displayState = _history.state;
    });
  }

  void _tickAnimation() {
    final start = _animationStart;
    final end = _animationEnd;
    if (!mounted || start == null || end == null) return;
    final progress = Curves.easeInOut.transform(_animation.value);
    setState(
        () => _displayState = BlochState.interpolate(start, end, progress));
  }

  void _cancelMotion({bool restoreCurrent = true}) {
    _replayGeneration++;
    _animation.stop();
    if (mounted) {
      setState(() {
        _replaying = false;
        _activeHistoryIndex = null;
        if (restoreCurrent) _displayState = _history.state;
      });
    }
  }

  void _animate(BlochState from, BlochState to, Duration duration) {
    _animation
      ..stop()
      ..duration = duration;
    _animationStart = from;
    _animationEnd = to;
    setState(() => _displayState = from);
    unawaited(_animation.forward(from: 0));
  }

  void _applyGate(SelectedGateType type) {
    _cancelMotion();
    _clearHistoryPreview();
    final rotation = type == SelectedGateType.rx ||
        type == SelectedGateType.ry ||
        type == SelectedGateType.rz;
    final gate = Gate.fromIdentifier(type, angle: rotation ? _angle : null);
    final source = _history.state;
    final destination = source.applyGate(type, angle: _angle);
    _history.commit(
      gate.label.replaceAll('\n', ' '),
      destination,
      gate: gate,
    );
    setState(() {
      _interaction = 'Applied ${gate.label.replaceAll('\n', ' ')}.';
    });
    if (!_instant) _animate(source, destination, _gateDuration);
  }

  Future<void> _replay() async {
    if (_replaying) return;
    _cancelMotion();
    final startIndex = _selectedHistoryIndex ?? 0;
    final sequence = _history.replaySequenceFrom(startIndex);
    if (sequence.isEmpty) return;
    final generation = _replayGeneration;
    setState(() => _replaying = true);
    for (final (offset, transition) in sequence.indexed) {
      if (!mounted || generation != _replayGeneration) return;
      setState(() {
        _activeHistoryIndex = startIndex + offset + 1;
        _displayState = _instant ? transition.destination : transition.source;
      });
      _scrollActiveHistoryEntry();
      if (_instant) {
        await Future<void>.delayed(_replayGap);
      } else {
        _animationStart = transition.source;
        _animationEnd = transition.destination;
        _animation.duration = _replayDuration;
        try {
          await _animation.forward(from: 0).orCancel;
        } on TickerCanceled {
          return;
        }
      }
      if (!_instant && offset + 1 < sequence.length) {
        await Future<void>.delayed(_replayGap);
      }
    }
    if (mounted && generation == _replayGeneration) {
      setState(() {
        _replaying = false;
        _activeHistoryIndex = null;
        _displayState = _history.state;
      });
    }
  }

  void _clearHistoryPreview() {
    if (_selectedHistoryIndex == null) return;
    setState(() {
      _selectedHistoryIndex = null;
      _selectedHistoryEntry = null;
      _displayState = _history.state;
    });
  }

  void _selectHistory(int index) {
    if (_replaying || index < 0 || index > _history.index) return;
    setState(() {
      if (_selectedHistoryIndex == index) {
        _selectedHistoryIndex = null;
        _selectedHistoryEntry = null;
        _displayState = _history.state;
      } else {
        final entry = _history.entries[index];
        _selectedHistoryIndex = index;
        _selectedHistoryEntry = entry;
        _displayState = entry.state;
      }
      _interaction = _selectedHistoryIndex == null
          ? 'History preview cleared.'
          : 'History step $index selected.';
    });
  }

  Future<void> _inspectHistoryGate(int index) async {
    if (_replaying || index <= 0 || index > _history.index) return;
    final gate = _history.entries[index].gate;
    if (gate == null) return;
    final preceding = [
      for (var step = 1; step < index; step++) _history.entries[step].label,
    ];
    final concise = preceding.length <= 4
        ? preceding
        : ['…', ...preceding.sublist(preceding.length - 4)];
    await _inspect(
      gate,
      inspectionContext: GateInspectorContext(
        title: 'History step $index of ${_history.index}',
        description:
            'Applied after: ${concise.isEmpty ? 'Start' : concise.join(' → ')}',
      ),
    );
  }

  Future<void> _inspect(
    Gate gate, {
    GateInspectorContext? inspectionContext,
  }) async {
    final info = GateEducationalCatalog.forType(gate.type);
    final notebookTitle = info?.notebookDiscoveryTitle;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => GateInspectorDialog.forGate(
        gate: gate,
        info: info,
        inspectionContext: inspectionContext,
        onOpenNotebook:
            notebookTitle == null || widget.onOpenNotebookEntry == null
                ? null
                : () {
                    Navigator.of(dialogContext).pop();
                    widget.onOpenNotebookEntry!(notebookTitle);
                  },
        onOpenRelatedConcept: widget.onOpenNotebookEntry == null
            ? null
            : (title) {
                Navigator.of(dialogContext).pop();
                widget.onOpenNotebookEntry!(title);
              },
      ),
    );
  }

  void _scrollActiveHistoryEntry() {
    if (!_historyExpanded || _activeHistoryIndex == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_historyScrollController.hasClients) return;
      final target = (_activeHistoryIndex! * 82.0).clamp(
        0.0,
        _historyScrollController.position.maxScrollExtent,
      );
      _historyScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
        key: const ValueKey('web-bloch-workspace-scroll'),
        padding: const EdgeInsets.all(24),
        children: [
          const _WorkspaceHeading(
            title: 'Bloch Explorer',
            subtitle: 'See how gates transform a single qubit.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              final sphereHeight = wide
                  ? (constraints.maxWidth * .48).clamp(470.0, 610.0)
                  : (constraints.maxWidth * .72).clamp(350.0, 540.0);
              final sphere = _WorkspaceCard(
                child: MouseRegion(
                  key: const ValueKey('web-bloch-sphere-pointer-area'),
                  cursor: _replaying
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.grab,
                  child: SizedBox(
                    key: const ValueKey('web-bloch-sphere'),
                    height: sphereHeight,
                    child: IgnorePointer(
                      ignoring: _replaying,
                      child: BlochSpherePanel(
                        reserveOverlaySafeRegions: wide,
                        state: _displayState,
                        camera: _camera,
                        onCameraChanged: (camera) => setState(() {
                          _camera = camera;
                          _interaction = 'Camera updated.';
                        }),
                        onStatePreview: (state) => setState(() {
                          _displayState = state;
                          _interaction = 'Vector preview updated.';
                        }),
                        onStateCommitted: (state) {
                          _history.commit('Direct state', state);
                          setState(
                              () => _interaction = 'Vector state committed.');
                        },
                        onGestureStarted: _cancelMotion,
                        onStateGestureStarted: () {
                          _cancelMotion();
                          _clearHistoryPreview();
                          return _history.state;
                        },
                      ),
                    ),
                  ),
                ),
              );
              final controls = Column(
                key: const ValueKey('web-bloch-tools'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WorkspaceCard(
                    child: BlochGatePanel(
                      initialState: _history.initialState,
                      rotationAngle: _angle,
                      enabled: !_replaying,
                      onSelectPreset: (preset) {
                        _cancelMotion(restoreCurrent: false);
                        _history.reset(initial: preset.blochState);
                        setState(() {
                          _selectedHistoryIndex = null;
                          _selectedHistoryEntry = null;
                          _displayState = preset.blochState;
                          _interaction = 'Preset ${preset.label} selected.';
                        });
                      },
                      onApplyGate: _applyGate,
                      onInspectGate: _inspect,
                      onAngleChanged: (angle) => setState(() => _angle = angle),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WorkspaceCard(
                    child: BlochPlaybackControls(
                      canUndo: _history.canUndo,
                      canRedo: _history.canRedo,
                      canReplay: (_selectedHistoryIndex ?? 0) < _history.index,
                      replayRunning: _replaying,
                      instant: _instant,
                      onUndo: () {
                        _cancelMotion();
                        _clearHistoryPreview();
                        _history.undo();
                      },
                      onRedo: () {
                        _cancelMotion();
                        _clearHistoryPreview();
                        _history.redo();
                      },
                      onReplay: _replay,
                      onReset: () {
                        _cancelMotion(restoreCurrent: false);
                        _selectedHistoryIndex = null;
                        _selectedHistoryEntry = null;
                        _history.reset();
                      },
                      onInstantChanged: (value) =>
                          setState(() => _instant = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WorkspaceCard(
                    child: BlochHistoryPanel(
                      entries: _history.entries,
                      currentIndex: _history.index,
                      selectedIndex: _selectedHistoryIndex,
                      activeReplayIndex: _activeHistoryIndex,
                      replayRunning: _replaying,
                      scrollController: _historyScrollController,
                      onExpansionChanged: (expanded) {
                        _historyExpanded = expanded;
                        if (expanded) _scrollActiveHistoryEntry();
                      },
                      onSelected: _selectHistory,
                      onInspect: _inspectHistoryGate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_interaction, key: const ValueKey('web-bloch-status')),
                ],
              );
              if (!wide) {
                return Column(
                  key: const ValueKey('web-bloch-stacked-layout'),
                  children: [sphere, const SizedBox(height: 12), controls],
                );
              }
              return Row(
                key: const ValueKey('web-bloch-wide-layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 13, child: sphere),
                  const SizedBox(width: 18),
                  Expanded(flex: 10, child: controls),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _WorkspaceCard(
            child: BlochStateMathPanel(
              state: _displayState,
              globalPhase: _displayState.globalPhase,
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
