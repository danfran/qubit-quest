import 'package:quantumquiz/widgets/progress_save_feedback.dart';
// home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';
import 'package:quantumquiz/screens/bloch_explorer_screen.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/progression_rules.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/tutorial_flags_store.dart';
import 'package:quantumquiz/screens/learning_flow_widgets.dart';
import 'package:quantumquiz/screens/webview_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/widgets/responsive_dashboard_grid.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

import '../models/qq_level.dart';
import '../models/qq_levels.dart';
import '../models/qq_levels_category.dart';

class HomePage extends StatefulWidget {
  HomePage({
    super.key,
    CampaignProgressController? progressController,
    this.sandboxPersistenceStore = const SandboxPersistenceStore(),
    this.tutorialFlagsStore = const TutorialFlagsStore(),
  }) : progressController =
            progressController ?? CampaignProgressController.instance;

  final CampaignProgressController progressController;
  final SandboxPersistenceStore sandboxPersistenceStore;
  final TutorialFlagsStore tutorialFlagsStore;

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _HomeLoadState { loading, ready, error }

class _HomePageState extends State<HomePage> {
  // Compatibility aliases. QubitQuestColors is the canonical authority.
  static const Color qqBlack = QubitQuestColors.background;
  static const Color qqCard = QubitQuestColors.surface;
  static const Color qqCard2 = QubitQuestColors.surfaceRaised;
  static const Color qqBorder = QubitQuestColors.border;
  static const Color qqCyan = QubitQuestColors.accentInteractive;
  static const Set<String> _chapter1DiscoveryTitles = {
    'Information',
    'Reversibility',
    'Equivalent Results',
    'State Transformations',
    'The Quantum Bit',
  };
  static const Set<String> _chapter2DiscoveryTitles = {
    'Hidden Change',
    'Invisible Difference',
    'Relative Phase',
    'Phase Information',
    'Phase',
  };
  static const Set<String> _chapter3DiscoveryTitles = {
    'The Third State',
    'Two Possibilities',
    'Precise Superposition',
    'Prepared Possibilities',
    'Superposition',
  };
  static const Set<String> _chapter4DiscoveryTitles = {
    'Phase Is Hidden',
    'Phase Becomes Bit',
    'Bit Becomes Phase',
    'Destructive Interference',
    'Interference',
  };
  static const Set<String> _chapter5DiscoveryTitles = {
    'Two Qubits',
    'Correlation',
    'Bell State',
    'One Quantum System',
    'Entanglement',
  };
  static const Set<String> _chapter6DiscoveryTitles = {
    'Control',
    'Conditional Action',
    'Information Transfer',
    'Swap',
    'Information Flow',
  };
  static const Set<String> _chapter7DiscoveryTitles = {
    'Three Qubits',
    'Shared Information',
    'All Together',
    'GHZ State',
    'One System, Three Qubits',
  };
  static const Set<String> _chapter8DiscoveryTitles = {
    'Hidden Information',
    'Phase Carrier',
    'Phase Kickback',
    'Hidden Communication',
    'The Language of Quantum Algorithms',
  };
  static const Set<String> _chapter9DiscoveryTitles = {
    'A Special State',
    'Hidden Mark',
    'Oracle',
    'Invisible Mark',
    'Phase Marking',
  };
  static const Set<String> _chapter10DiscoveryTitles = {
    'Marked But Hidden',
    'Mark Becomes Probability',
    'Amplitude Amplification',
    'Bias Becomes Amplification',
    'Amplification as Computational Advantage',
  };
  static const Set<String> _chapter11DiscoveryTitles = {
    'Why One Step Is Not Enough',
    'Iteration Improves Likelihood',
    'Convergence Toward Solution',
    'Classical vs Quantum Iteration',
    'Cognitive Transfer of Iteration Thinking',
  };
  static const Set<String> _chapter12DiscoveryTitles = {
    'Quantum Algorithm Structure',
    'Role Separation in Quantum Algorithms',
    'Why Composition Creates Advantage',
    'Classical vs Quantum Structural Difference',
    'Unified Quantum Algorithm Model',
  };
  static const int _guidedDiscoveryLevelCount =
      ProgressionRules.guidedDiscoveryLevelCount;

  CampaignProgressController get _progressController =>
      widget.progressController;
  CampaignProgressState _progressState = CampaignProgressState.fresh();
  int _maxUnlockedLevel = 1;
  _HomeLoadState _loadState = _HomeLoadState.loading;
  bool _progressLoadPending = false;
  bool _showMasteryCompleteDialogAfterReturn = false;

  PackageInfo? _packageInfo;
  List<MapEntry<String, String>>? _aboutData; // Data for the about dialog

  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    _populateAboutData();
    _progressController.addListener(_syncConfirmedProgress);
    _loadMaxUnlockedLevel();
    _initPackageInfo();
  }

  void _syncConfirmedProgress() {
    if (!mounted ||
        !_progressController.isLoaded ||
        identical(_progressState, _progressController.state)) {
      return;
    }
    setState(() {
      _progressState = _progressController.state;
      _maxUnlockedLevel = _progressState.maxUnlockedLevel;
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressController != widget.progressController) {
      oldWidget.progressController.removeListener(_syncConfirmedProgress);
      _progressController.addListener(_syncConfirmedProgress);
    }
  }

  @override
  void dispose() {
    _progressController.removeListener(_syncConfirmedProgress);
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _packageInfo = info;
        _populateAboutData();
      });
    } catch (error) {
      // The static About details remain usable without platform metadata.
      if (!mounted) return;
      debugPrint('Unable to load app information: $error');
    }
  }

  void _populateAboutData() {
    // This method creates the list of data to display in the grid
    _aboutData = [
      MapEntry('App name', _packageInfo?.appName ?? 'Qubit Quest'),
      MapEntry('Author', 'Eigenplay'),
      MapEntry('Package name', _packageInfo?.packageName ?? 'com.qubitquest'),
      MapEntry('App version', _packageInfo?.version ?? 'Unavailable'),
      MapEntry('Build number', _packageInfo?.buildNumber ?? 'Unavailable'),
      MapEntry(
          'Build signature', _packageInfo?.buildSignature ?? 'Unavailable'),
      MapEntry(
          'Installer store', _packageInfo?.installerStore ?? 'not available'),
      MapEntry('Contact', 'qubitquestapp@gmail.com'),
    ];
  }

  // Load campaign progression through the central controller.
  Future<void> _loadMaxUnlockedLevel() async {
    if (!mounted || _progressLoadPending) return;
    _progressLoadPending = true;
    setState(() => _loadState = _HomeLoadState.loading);
    try {
      final progressState = await _progressController.load();
      if (!mounted) return;
      setState(() {
        _progressState = progressState;
        _maxUnlockedLevel = progressState.maxUnlockedLevel;
        _loadState = _HomeLoadState.ready;
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Unable to load campaign progress: $error');
      setState(() => _loadState = _HomeLoadState.error);
    } finally {
      _progressLoadPending = false;
    }
  }

  // Preserve the existing completion callback contract while centralizing writes.
  Future<void> _updateMaxUnlockedLevel(
      int completedLevelNumber, NumericActivityDomain domain) async {
    final completedLevel = completedLevelNumber - 1;
    if (domain == NumericActivityDomain.historicalMastery) {
      final wasAlreadyCompleted =
          _progressState.completedChallengeIds.contains(completedLevel);
      if (!await saveProgressWithFeedback(context,
          () => _progressController.completeChallenge(completedLevel))) {
        return;
      }
      if (!mounted) return;
      final updatedProgressState = _progressController.state;
      final updatedCompletedMasteryLevels =
          updatedProgressState.completedChallengeIds;
      final masteryChallengeCount = _masteryChallengeCount;
      final shouldShowMasteryComplete = masteryChallengeCount > 0 &&
          !wasAlreadyCompleted &&
          updatedCompletedMasteryLevels.length >= masteryChallengeCount;
      if (shouldShowMasteryComplete &&
          !updatedProgressState.masteryCompleteDialogShown) {
        if (!await saveProgressWithFeedback(context,
            () => _progressController.markMasteryCompleteDialogShown())) {
          return;
        }
        _showMasteryCompleteDialogAfterReturn = true;
      }
      if (mounted) {
        final progressState = _progressController.state;
        setState(() {
          _progressState = progressState;
          _maxUnlockedLevel = progressState.maxUnlockedLevel;
        });
      }
      return;
    }

    if (!await saveProgressWithFeedback(
        context, () => _progressController.completeLesson(completedLevel))) {
      return;
    }
    if (mounted) {
      final progressState = _progressController.state;
      setState(() {
        _progressState = progressState;
        _maxUnlockedLevel = progressState.maxUnlockedLevel;
      });
      debugPrint('Updated and saved max unlocked level: $_maxUnlockedLevel');
    }
  }

  // Show a dialog if all levels are completed
  void _showGameCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return QubitQuestDialog(
          title: 'Learning Journey Complete',
          maxWidth: 520,
          actions: [
            QubitQuestDialogButton.primary(
              label: 'Close',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          child: const _JourneyCompleteBody(),
        );
      },
    );
  }

  void _showAboutDialog() {
    // Ensure data is ready before showing the dialog
    if (!mounted) return;
    if (_aboutData == null) {
      debugPrint('About data not yet loaded.');
      _showUtilityFallbackMessage('About information is still loading.');
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return QubitQuestDialog(
          title: 'About Qubit Quest',
          maxWidth: 560,
          actions: [
            QubitQuestDialogButton.secondary(
              label: 'Close',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final dataEntry in _aboutData!) ...[
                _AboutInfoRow(label: dataEntry.key, value: dataEntry.value),
                if (dataEntry != _aboutData!.last) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  // NEW: Method to handle rating the app
  Future<void> _rateApp() async {
    final String packageName = _packageInfo?.packageName ?? 'com.qubitquest';

    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        return;
      }

      try {
        await _inAppReview.openStoreListing(
          appStoreId: null,
          microsoftStoreId: null,
        );
        return;
      } catch (error) {
        debugPrint('In-app review store listing failed: $error');
      }

      final bool openedStore = await _openPlayStoreListing(packageName);
      if (!openedStore) {
        _showUtilityFallbackMessage(
          'Rating will be available after Qubit Quest is listed in the store.',
        );
      }
    } catch (error) {
      debugPrint('Rate Us failed: $error');
      _showUtilityFallbackMessage(
        'Rating will be available after Qubit Quest is listed in the store.',
      );
    }
  }

  Future<bool> _openPlayStoreListing(String packageName) async {
    final Uri marketUri = Uri.parse('market://details?id=$packageName');
    if (await canLaunchUrl(marketUri) &&
        await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    final Uri webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );
    if (await canLaunchUrl(webUri) &&
        await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    return false;
  }

  void _showQubitSelectionDialog() {
    showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return QubitQuestDialog(
          title: 'Choose Number of Qubits',
          maxWidth: 460,
          actions: [
            QubitQuestDialogButton.secondary(
              label: 'Cancel',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Open the sandbox with a circuit size.',
                style: TextStyle(
                  color: QubitQuestDialog.mutedText,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (int numQubits = 1; numQubits <= 5; numQubits++)
                    _buildQubitChoiceButton(
                      dialogContext,
                      numQubits,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((selectedNumQubits) async {
      if (!mounted) return;
      if (selectedNumQubits != null) {
        final snapshot = await widget.sandboxPersistenceStore
            .loadSnapshot(selectedNumQubits);
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => QuantumComposer(
              levelId: -1,
              level: createSandboxComposerLevel(
                selectedNumQubits,
                initialBinaryState: snapshot?.initialBinaryState,
              ),
              onLevelUnlocked: null,
              sessionOwnership: ComposerSessionOwnership.sandbox,
              initialSandboxSnapshot: snapshot,
              sandboxPersistenceStore: widget.sandboxPersistenceStore,
            ),
          ),
        );
      }
    });
  }

  void _openSandbox() {
    _showQubitSelectionDialog();
  }

  Widget _buildQubitChoiceButton(BuildContext dialogContext, int numQubits) {
    return InkWell(
      onTap: () => Navigator.of(dialogContext).pop(numQubits),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4A8DFF),
              Color(0xFF2F6FEA),
              Color(0xFF1F4FC7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0x80344A73)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$numQubits',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openYoutubePlaylist(String playlistTextLink) async {
    final uri = Uri.parse(
      playlistTextLink,
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showUtilityFallbackMessage('Could not open solution videos.');
    }
  }

  void _showUtilityFallbackMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: qqCard2,
      ),
    );
  }

  void _selectUtilityMenuAction(String action) {
    switch (action) {
      case 'videos':
        _openYoutubePlaylist(
          'https://www.youtube.com/playlist?list=PL1UkEjMAb8Lq1Nivn894qBWTU938HKPM7',
        );
        break;
      case 'discoveries':
        final chapter1LevelNumber = _firstChapter1InformationLevelNumber();
        final chapter2LevelNumber = _firstChapter2HiddenChangeLevelNumber();
        final chapter3LevelNumber = _firstChapter3SuperpositionLevelNumber();
        final chapter4LevelNumber = _firstChapter4InterferenceLevelNumber();
        final chapter5LevelNumber = _firstChapter5EntanglementLevelNumber();
        final chapter6LevelNumber = _firstChapter6InformationFlowLevelNumber();
        final chapter7LevelNumber = _firstChapter7GhzStatesLevelNumber();
        final chapter8LevelNumber = _firstChapter8PhaseKickbackLevelNumber();
        final chapter9LevelNumber = _firstChapter9OracleThinkingLevelNumber();
        final chapter10LevelNumber =
            _firstChapter10AmplitudeAmplificationLevelNumber();
        final chapter11LevelNumber =
            _firstChapter11GroverLoopIntuitionLevelNumber();
        final chapter12LevelNumber =
            _firstChapter12QuantumAlgorithmStructureLevelNumber();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiscoveriesScreen(
              prototypeChapters: [
                if (chapter1LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 1',
                    subtitle: 'Start Information',
                    levelNumber: chapter1LevelNumber,
                  ),
                if (chapter2LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 2',
                    subtitle: 'Start Hidden Change',
                    levelNumber: chapter2LevelNumber,
                  ),
                if (chapter3LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 3',
                    subtitle: 'Start Superposition',
                    levelNumber: chapter3LevelNumber,
                  ),
                if (chapter4LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 4',
                    subtitle: 'Start Interference',
                    levelNumber: chapter4LevelNumber,
                  ),
                if (chapter5LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 5',
                    subtitle: 'Start Entanglement',
                    levelNumber: chapter5LevelNumber,
                  ),
                if (chapter6LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 6',
                    subtitle: 'Start Information Flow',
                    levelNumber: chapter6LevelNumber,
                  ),
                if (chapter7LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 7',
                    subtitle: 'Start GHZ States',
                    levelNumber: chapter7LevelNumber,
                  ),
                if (chapter8LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 8',
                    subtitle: 'Start Phase Kickback',
                    levelNumber: chapter8LevelNumber,
                  ),
                if (chapter9LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 9',
                    subtitle: 'Start Oracle Thinking',
                    levelNumber: chapter9LevelNumber,
                  ),
                if (chapter10LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 10',
                    subtitle: 'Start Amplitude Amplification',
                    levelNumber: chapter10LevelNumber,
                  ),
                if (chapter11LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 11',
                    subtitle: 'Start Grover Loop Intuition',
                    levelNumber: chapter11LevelNumber,
                  ),
                if (chapter12LevelNumber != null)
                  DiscoveryPrototypeChapter(
                    title: 'Chapter 12',
                    subtitle: 'Start Quantum Algorithm Structure',
                    levelNumber: chapter12LevelNumber,
                  ),
              ],
              onStartPrototypeLevel: (levelNumber) =>
                  _playLevelSequence(levelNumber, this.context),
            ),
          ),
        );
        break;
      case 'rate':
        _rateApp();
        break;
      case 'privacy':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WebViewPage(
              title: 'Privacy Policy',
              url: 'https://danfran.github.io/qubit-quest/privacy-policy.html',
            ),
          ),
        );
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  bool _isChapter4InterferenceLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 16, 20) &&
        discoveryTitle != null &&
        _chapter4DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter1InformationLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 1, 5) &&
        discoveryTitle != null &&
        _chapter1DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter2HiddenChangeLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 6, 10) &&
        discoveryTitle != null &&
        _chapter2DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter3SuperpositionLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 11, 15) &&
        discoveryTitle != null &&
        _chapter3DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter5EntanglementLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 21, 25) &&
        discoveryTitle != null &&
        _chapter5DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter6InformationFlowLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 26, 30) &&
        discoveryTitle != null &&
        _chapter6DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter7GhzStatesLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 31, 35) &&
        discoveryTitle != null &&
        _chapter7DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter8PhaseKickbackLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 36, 40) &&
        discoveryTitle != null &&
        _chapter8DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter9OracleThinkingLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 41, 45) &&
        discoveryTitle != null &&
        _chapter9DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter10AmplitudeAmplificationLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 46, 50) &&
        discoveryTitle != null &&
        _chapter10DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter11GroverLoopIntuitionLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 51, 55) &&
        discoveryTitle != null &&
        _chapter11DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isChapter12QuantumAlgorithmStructureLevel(QQLevel level) {
    final discoveryTitle = level.discoveryTitle?.trim();
    return _isLevelNumberInRange(level, 56, 60) &&
        discoveryTitle != null &&
        _chapter12DiscoveryTitles.contains(discoveryTitle);
  }

  bool _isLevelNumberInRange(QQLevel level, int firstLevel, int lastLevel) {
    final index = journeyLessons.indexOf(level);
    final levelNumber = index + 1;
    return index >= 0 && levelNumber >= firstLevel && levelNumber <= lastLevel;
  }

  bool _isLegacyChallengeLevel(QQLevel level) {
    return historicalMasteryActivities.contains(level);
  }

  bool _isMasteryChallengeLevel(QQLevel level) {
    return _isLegacyChallengeLevel(level);
  }

  int get _masteryChallengeCount {
    return mastery2Catalogue.length;
  }

  bool _isMasteryCompleted(int levelNumber) {
    return CampaignProgressPolicy.isChallengeCompleted(
      _progressState,
      levelNumber,
    );
  }

  bool _isSemanticMasteryCompleted(String semanticId) {
    return CampaignProgressPolicy.isMasteryChallengeCompleted(
      _progressState,
      semanticId,
    );
  }

  bool _isMasteryCategoryName(String groupName) {
    return groupName == 'Mastery Challenges';
  }

  int? _firstChapter1InformationLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter1InformationLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter2HiddenChangeLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter2HiddenChangeLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter3SuperpositionLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter3SuperpositionLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter4InterferenceLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter4InterferenceLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter5EntanglementLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter5EntanglementLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter6InformationFlowLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter6InformationFlowLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter7GhzStatesLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter7GhzStatesLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter8PhaseKickbackLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter8PhaseKickbackLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter9OracleThinkingLevelNumber() {
    final index = journeyLessons.indexWhere(_isChapter9OracleThinkingLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter10AmplitudeAmplificationLevelNumber() {
    final index =
        journeyLessons.indexWhere(_isChapter10AmplitudeAmplificationLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter11GroverLoopIntuitionLevelNumber() {
    final index =
        journeyLessons.indexWhere(_isChapter11GroverLoopIntuitionLevel);
    return index < 0 ? null : index + 1;
  }

  int? _firstChapter12QuantumAlgorithmStructureLevelNumber() {
    final index =
        journeyLessons.indexWhere(_isChapter12QuantumAlgorithmStructureLevel);
    return index < 0 ? null : index + 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadState == _HomeLoadState.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadState == _HomeLoadState.error) {
      return Scaffold(
        backgroundColor: qqBlack,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Unable to load your progress',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'Please try again. Your saved progress has not been reset. '
                      'If this continues, contact support before changing app data.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadMaxUnlockedLevel,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: qqBlack,
      bottomNavigationBar:
          ProgressSaveStatusView(controller: _progressController),
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        title: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 34,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        backgroundColor: qqBlack,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            color: qqCard,
            surfaceTintColor: Colors.transparent,
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onSelected: _selectUtilityMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'videos',
                child: _UtilityMenuRow(
                  icon: Icons.video_library_outlined,
                  label: 'Solution Videos',
                ),
              ),
              PopupMenuItem(
                value: 'rate',
                child: _UtilityMenuRow(
                  icon: Icons.star_outline,
                  label: 'Rate Us',
                ),
              ),
              PopupMenuItem(
                value: 'privacy',
                child: _UtilityMenuRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: _UtilityMenuRow(
                  icon: Icons.info_outline,
                  label: 'About',
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxWidth < 720;
            final double horizontalPadding = compact ? 12 : 28;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 10 : 18,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPrimaryActionSection(compact: compact),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrimaryActionSection({required bool compact}) {
    final continueDestination =
        CampaignProgressPolicy.continueJourneyDestination(_progressState);
    final Widget journeyCard = _buildActionCard(
      title: continueDestination.isJourneyComplete
          ? 'Learning Journey'
          : 'Continue Journey',
      subtitle: continueDestination.isJourneyComplete
          ? 'Review your completed learning journey'
          : 'Next: Lesson ${continueDestination.levelNumber}',
      icon: Icons.play_arrow_rounded,
      primary: true,
      compact: compact,
      onTap: _openLearningJourney,
    );
    final Widget masteryCard = _buildActionCard(
      title: 'Mastery Challenges',
      subtitle: 'Test and combine what you know • '
          '${_progressState.completedMasterySemanticIds.length} / $_masteryChallengeCount completed',
      icon: Icons.workspace_premium_outlined,
      primary: true,
      mastery: true,
      compact: compact,
      onTap: _openMasteryChallenges,
    );
    final Widget composerCard = _buildActionCard(
      title: 'Sandbox Composer',
      subtitle: 'Build and test your own quantum circuits',
      icon: Icons.tune_rounded,
      primary: false,
      compact: compact,
      onTap: _openSandbox,
    );
    final Widget notebookCard = _buildActionCard(
      title: 'Quantum Notebook',
      subtitle: 'Review concepts and go deeper',
      icon: Icons.auto_stories_outlined,
      primary: false,
      compact: compact,
      onTap: () => _selectUtilityMenuAction('discoveries'),
    );
    final Widget learningMapCard = _buildActionCard(
      title: 'Learning Map',
      subtitle: 'See the concept graph behind your journey',
      icon: Icons.account_tree_rounded,
      primary: false,
      compact: compact,
      onTap: _openLearningMap,
    );
    final Widget blochExplorerCard = _buildActionCard(
      title: 'Bloch Explorer',
      subtitle: 'Move states and see the mathematics change',
      icon: Icons.public_rounded,
      primary: false,
      compact: compact,
      onTap: _openBlochExplorer,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveDashboardGrid(
          key: const ValueKey('home-destination-grid'),
          minimumTileWidth: 250,
          maxColumns: 2,
          mainAxisExtent: compact ? 88 : 100,
          spacing: compact ? 10 : 14,
          children: [journeyCard, masteryCard],
        ),
        SizedBox(height: compact ? 10 : 14),
        ResponsiveDashboardGrid(
          key: const ValueKey('home-action-grid'),
          minimumTileWidth: 250,
          maxColumns: 4,
          mainAxisExtent: compact ? 82 : 94,
          spacing: compact ? 10 : 14,
          children: [
            notebookCard,
            learningMapCard,
            blochExplorerCard,
            composerCard,
          ],
        ),
      ],
    );
  }

  void _openLearningJourney() {
    _openCatalogueDestination(mastery: false);
  }

  void _openMasteryChallenges() {
    _openCatalogueDestination(mastery: true);
  }

  void _openCatalogueDestination({required bool mastery}) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => AnimatedBuilder(
          animation: _progressController,
          builder: (context, _) => _buildCataloguePage(
            mastery: mastery,
            progressState: _progressController.state,
          ),
        ),
      ),
    );
  }

  Widget _buildCataloguePage({
    required bool mastery,
    required CampaignProgressState progressState,
  }) {
    final categories = groupedLevels.where(
      (category) => category.isMasteryPhase == mastery,
    );
    return Scaffold(
      key: ValueKey(
        mastery ? 'mastery-challenges-page' : 'learning-journey-page',
      ),
      backgroundColor: qqBlack,
      appBar: AppBar(
        backgroundColor: qqBlack,
        surfaceTintColor: Colors.transparent,
        title: Text(mastery ? 'Mastery Challenges' : 'Learning Journey'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final horizontalPadding = compact ? 12.0 : 28.0;
            return SingleChildScrollView(
              key: ValueKey(
                mastery
                    ? 'mastery-challenges-scroll'
                    : 'learning-journey-scroll',
              ),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 10 : 18,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (mastery)
                        _buildMastery2Section(
                          compact: compact,
                          progressState: progressState,
                        )
                      else
                        for (final category in categories)
                          _buildTopicSection(
                            category.groupName,
                            category.from,
                            category.to,
                            compact: compact,
                            progressState: progressState,
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMastery2Section({
    required bool compact,
    required CampaignProgressState progressState,
  }) {
    final definitions = mastery2Catalogue.orderedDefinitions;
    final completed = progressState.completedMasterySemanticIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: compact ? 12 : 16,
            bottom: compact ? 8 : 10,
          ),
          child: Text(
            'Mastery Challenges\nConcept Integration • Completed: $completed / ${definitions.length}',
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = compact ? 8.0 : 10.0;
            final columns = DashboardGridPolicy.columnsFor(
              availableWidth: constraints.maxWidth,
              minimumTileWidth: compact ? 108 : 160,
              maxColumns: 10,
              spacing: spacing,
            );
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: compact ? 1.02 : 1.18,
              ),
              itemCount: definitions.length,
              itemBuilder: (context, index) {
                final definition = definitions[index];
                final isCompleted = progressState.completedMasterySemanticIds
                    .contains(definition.semanticId);
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F766E),
                        Color(0xFF115E59),
                        Color(0xFF134E4A),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(color: const Color(0x80344A73)),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ElevatedButton(
                          key: ValueKey(
                            'mastery-challenge-${definition.semanticId}',
                          ),
                          onPressed: () => _playMasteryChallenge(definition),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(6),
                          ),
                          child: Text(
                            'Challenge ${definition.displayOrder}\n${definition.title}',
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 11 : 13,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Positioned(
                          key: ValueKey(
                            'mastery-completed-${definition.semanticId}',
                          ),
                          top: 7,
                          right: 7,
                          child: const _MasteryCompletedCheckmark(),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _completeSemanticMasteryChallenge(
    MasteryChallengeDefinition definition,
  ) async {
    if (!await saveProgressWithFeedback(
        context,
        () => _progressController
            .completeMasteryChallenge(definition.semanticId))) {
      return;
    }
    if (!mounted) return;
    setState(() => _progressState = _progressController.state);
  }

  Future<void> _playMasteryChallenge(
    MasteryChallengeDefinition definition,
  ) async {
    final shouldStart = await _showSemanticMasteryChallengeBrief(definition);
    if (!shouldStart || !mounted) return;
    await Navigator.of(context).push<LevelCompletionAction>(
      MaterialPageRoute(
        builder: (context) => LevelUIRouter.buildLevelUI(
          level: definition.levelDefinition,
          levelId: definition.displayOrder,
          masteryChallenge: definition,
          isCompleted: _isSemanticMasteryCompleted(definition.semanticId),
          onLevelUnlocked: (_) => _completeSemanticMasteryChallenge(definition),
        ),
      ),
    );
  }

  Future<bool> _showSemanticMasteryChallengeBrief(
    MasteryChallengeDefinition definition,
  ) async {
    final level = definition.levelDefinition;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QubitQuestDialog(
        title: 'Mastery Challenge ${definition.displayOrder}',
        maxWidth: 560,
        actions: [
          QubitQuestDialogButton.secondary(
            label: 'Not now',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          QubitQuestDialogButton.primary(
            label: 'Start Challenge',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
        child: _MasteryChallengeBriefBody(
          level: level,
          relatedEntries: const [],
          onReviewDiscovery: (_) {},
        ),
      ),
    );
    return result ?? false;
  }

  void _openBlochExplorer() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => const BlochExplorerScreen()),
    );
  }

  void _openLearningMap() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => LearningMapScreen(
          progressState: _progressState,
          onOpenMastery: () {
            Navigator.of(context).pop();
            _playLevelSequence(
                ProgressionRules.legacyMasteryFirstId, this.context,
                domain: NumericActivityDomain.historicalMastery);
          },
          onStartChapter: (levelNumber) async {
            Navigator.of(context).pop();
            await _playLevelSequence(levelNumber, this.context);
          },
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool primary,
    bool mastery = false,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: ValueKey('home-action-$title'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 13 : 16,
        ),
        decoration: BoxDecoration(
          color: primary ? null : qqCard,
          gradient: primary
              ? LinearGradient(
                  colors: mastery
                      ? const [
                          Color(0xFF0F766E),
                          Color(0xFF115E59),
                          Color(0xFF134E4A),
                        ]
                      : const [
                          Color(0xFFA855F7),
                          Color(0xFF8B4BE8),
                          Color(0xFF5B21B6),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary
                ? mastery
                    ? const Color(0xFF0B4F4A)
                    : const Color(0xFF3B1B75)
                : qqBorder,
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool narrow = constraints.maxWidth < 250;
            final double iconSize = narrow
                ? 32
                : compact
                    ? 36
                    : 42;

            return Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.16)
                        : qqCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: primary
                          ? Colors.white.withValues(alpha: 0.20)
                          : qqBorder,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: primary ? Colors.white : qqCyan,
                    size: narrow
                        ? 20
                        : compact
                            ? 22
                            : 24,
                  ),
                ),
                SizedBox(width: narrow ? 9 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: narrow ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: narrow
                              ? 14
                              : compact
                                  ? 16
                                  : 19,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: narrow ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white
                              .withValues(alpha: primary ? 0.82 : 0.68),
                          fontSize: narrow
                              ? 10.5
                              : compact
                                  ? 11
                                  : 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!narrow) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color:
                        Colors.white.withValues(alpha: primary ? 0.92 : 0.60),
                    size: compact ? 24 : 28,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopicSection(
    String topic,
    int indexStart,
    int indexStop, {
    required bool compact,
    CampaignProgressState? progressState,
  }) {
    final displayedProgress = progressState ?? _progressState;
    final category = groupedLevels.firstWhere(
      (category) => category.groupName == topic,
    );
    final isMasterySection = _isMasteryCategoryName(topic);
    final masteryCompletionSummary =
        'Completed: ${displayedProgress.completedChallengeIds.length} / $_masteryChallengeCount';

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 14 : 18),
      child: LayoutBuilder(builder: (context, constraints) {
        final spacing = compact ? 8.0 : 10.0;
        final columns = DashboardGridPolicy.columnsFor(
          availableWidth: constraints.maxWidth,
          minimumTileWidth: compact
              ? 108
              : isMasterySection
                  ? 160
                  : 120,
          maxColumns: 10,
          spacing: spacing,
        );
        return CustomScrollView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: compact ? 12 : 16,
                  bottom: compact ? 8 : 10,
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: topic,
                        style: TextStyle(
                          fontSize: compact ? 18 : 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.12,
                        ),
                      ),
                      TextSpan(
                        text: isMasterySection
                            ? '\nConcept Integration • $masteryCompletionSummary'
                            : '\n${category.phaseTitle} • ${category.phasePurpose}',
                        style: TextStyle(
                          fontSize: compact ? 11 : 12.5,
                          fontWeight: FontWeight.w800,
                          color: isMasterySection
                              ? const Color(0xFF7CFFB2)
                              : qqCyan.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: isMasterySection
                    ? compact
                        ? 1.02
                        : 1.18
                    : compact
                        ? 1.02
                        : 1.18,
              ),
              itemCount: indexStop - indexStart + 1,
              itemBuilder: (context, index) {
                final int currentIndex = indexStart + index;
                final int levelNumber = currentIndex + 1;
                final domain = category.isMasteryPhase
                    ? NumericActivityDomain.historicalMastery
                    : NumericActivityDomain.journey;
                final QQLevel level =
                    numericActivityCatalogue.lookup(levelNumber, domain)!;
                final bool isUnlocked = category.isMasteryPhase ||
                    ProgressionRules.isJourneyLessonUnlocked(
                        lessonId: levelNumber,
                        maxUnlockedLevel: displayedProgress.maxUnlockedLevel);
                final bool isCompleted = isMasterySection &&
                    CampaignProgressPolicy.isChallengeCompleted(
                      displayedProgress,
                      levelNumber,
                    );

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isUnlocked ? 0.28 : 0.16),
                        spreadRadius: isUnlocked ? 1 : 0.5,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    gradient: isUnlocked
                        ? LinearGradient(
                            colors: isMasterySection
                                ? const [
                                    Color(0xFF0F766E),
                                    Color(0xFF115E59),
                                    Color(0xFF134E4A),
                                  ]
                                : const [
                                    Color(0xFF4A8DFF),
                                    Color(0xFF2F6FEA),
                                    Color(0xFF1F4FC7),
                                  ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: isUnlocked ? null : qqCard2,
                    border: Border.all(
                      color: isUnlocked ? const Color(0x80344A73) : qqBorder,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ElevatedButton(
                          key: ValueKey(
                            isMasterySection
                                ? 'mastery-challenge-${ProgressionRules.masteryChallengeNumber(levelNumber)}'
                                : 'journey-lesson-$levelNumber',
                          ),
                          onPressed: isUnlocked
                              ? () async {
                                  await _playLevelSequence(levelNumber, context,
                                      domain: domain);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                          ),
                          child: isUnlocked
                              ? Center(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: isMasterySection
                                              ? 'Challenge ${ProgressionRules.masteryChallengeNumber(levelNumber)}'
                                              : 'Lesson $levelNumber',
                                          style: TextStyle(
                                            fontSize: isMasterySection
                                                ? compact
                                                    ? 12.5
                                                    : 13.5
                                                : compact
                                                    ? 14
                                                    : 16,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            height: 1.04,
                                          ),
                                        ),
                                        if (level.title != null)
                                          TextSpan(
                                            text: '\n${level.title!}',
                                            style: TextStyle(
                                              fontSize: compact ? 9 : 10,
                                              color: Colors.white
                                                  .withValues(alpha: 0.78),
                                              fontWeight: FontWeight.w700,
                                              height: 1.08,
                                            ),
                                          ),
                                        if (isMasterySection &&
                                            level.conceptsUsed.isNotEmpty)
                                          TextSpan(
                                            text:
                                                '\n${level.conceptsUsed.take(2).join(' + ')}',
                                            style: TextStyle(
                                              fontSize: compact ? 8 : 9,
                                              color: Colors.white
                                                  .withValues(alpha: 0.72),
                                              fontWeight: FontWeight.w800,
                                              height: 1.08,
                                            ),
                                          ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: isMasterySection ? 5 : 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : Icon(
                                  Icons.lock,
                                  color: Colors.white.withValues(alpha: 0.24),
                                  size: 26,
                                ),
                        ),
                      ),
                      if (isCompleted)
                        Positioned(
                          key: ValueKey('mastery-completed-$levelNumber'),
                          top: 7,
                          right: 7,
                          child: const _MasteryCompletedCheckmark(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }

  // Route to the correct screen based on level type
  Widget _screenForLevel(
      QQLevel level, int levelId, NumericActivityDomain domain) {
    return LevelUIRouter.buildLevelUI(
      level: level,
      levelId: levelId,
      onLevelUnlocked: (next) => _updateMaxUnlockedLevel(next, domain),
      activityDomain: domain,
      isCompleted: domain == NumericActivityDomain.historicalMastery &&
          _isMasteryCompleted(levelId),
    );
  }

  Future<void> _showMasteryCompleteDialog() async {
    if (!mounted) return;
    _showMasteryCompleteDialogAfterReturn = false;

    final action = await showDialog<_MasteryCompleteAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return QubitQuestDialog(
          title: '🏆 Mastery Complete',
          maxWidth: 560,
          actions: [
            QubitQuestDialogButton.secondary(
              label: 'Review Notebook',
              onPressed: () => Navigator.of(context).pop(
                _MasteryCompleteAction.reviewNotebook,
              ),
            ),
            QubitQuestDialogButton.primary(
              label: 'Continue Exploring',
              onPressed: () => Navigator.of(context).pop(
                _MasteryCompleteAction.continueExploring,
              ),
            ),
          ],
          child: _MasteryCompleteBody(
            completedCount: _masteryChallengeCount,
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == _MasteryCompleteAction.reviewNotebook) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => const DiscoveriesScreen(),
        ),
      );
    }
  }

  Future<bool> _showMasteryChallengeBrief(
    QQLevel level,
    int levelNumber,
  ) async {
    if (!mounted) return false;

    final relatedEntries = [
      for (final title in level.relatedDiscoveryTitles)
        if (notebookEntriesByDiscoveryTitle[title] != null)
          notebookEntriesByDiscoveryTitle[title]!,
    ];

    while (mounted) {
      final result = await showDialog<Object>(
        context: context,
        builder: (context) {
          return QubitQuestDialog(
            title:
                'Mastery Challenge ${levelNumber - _guidedDiscoveryLevelCount}',
            maxWidth: 560,
            actions: [
              QubitQuestDialogButton.secondary(
                label: 'Not now',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              QubitQuestDialogButton.primary(
                label: 'Start Challenge',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
            child: _MasteryChallengeBriefBody(
              level: level,
              relatedEntries: relatedEntries,
              onReviewDiscovery: (entry) => Navigator.of(context).pop(entry),
            ),
          );
        },
      );

      if (!mounted) return false;
      if (result == true) return true;
      if (result is NotebookEntry) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (context) => NotebookEntryScreen(entry: result),
          ),
        );
        continue;
      }
      return false;
    }
    return false;
  }

  Future<void> _showLearningIntroIfNeeded(QQLevel level) async {
    if (!mounted) return;

    if (_isChapter1InformationLevel(level)) {
      const seenKey = 'chapter_intro_seen_chapter_1_information_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 1 - Information',
              text:
                  'Begin with the first mystery: what is a qubit? Investigate how quantum circuits store, change, and restore information.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter2HiddenChangeLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_2_hidden_change_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 2 - Hidden Change',
              text:
                  'Not every quantum change shows up in measurement right away. In this chapter, investigate changes that feel invisible until a later operation reveals them.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter3SuperpositionLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_3_superposition_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 3 - Superposition',
              text:
                  'A qubit does not have to be only 0 or only 1. In this chapter, investigate states that hold multiple possibilities at once.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter4InterferenceLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_4_interference_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 4 - Interference',
              text:
                  'Some quantum changes hide in phase until a circuit makes them interfere. In this chapter, experiment with how amplitudes can reinforce or cancel each other.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter5EntanglementLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_5_entanglement_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 5 - Entanglement',
              text:
                  'Two qubits are not always just two independent qubits. In this chapter, investigate when a pair becomes one shared quantum system.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter6InformationFlowLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_6_information_flow_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 6 - Information Flow',
              text:
                  'Qubits do not always act alone. In this chapter, investigate how controlled interactions move and route information through a quantum system.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter7GhzStatesLevel(level)) {
      const seenKey = 'chapter_intro_seen_chapter_7_ghz_states_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 7 - GHZ States',
              text:
                  'Entanglement is not limited to a pair. In this chapter, widen your view from connected qubits to a shared three-qubit quantum system.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter8PhaseKickbackLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_8_phase_kickback_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 8 - Phase Kickback',
              text:
                  'Information does not always travel as a visible bit flip. In this chapter, look for how controlled operations can write information into phase, then reveal it through interference.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter9OracleThinkingLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_9_oracle_thinking_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 9 - Oracle Thinking',
              text:
                  'A quantum oracle is a black-box function. In this chapter, treat a circuit as a hidden rule that classifies inputs as valid or invalid without directly revealing the answer.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter10AmplitudeAmplificationLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_10_amplitude_amplification_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 10 - Amplitude Amplification',
              text:
                  'The oracle gives structured access to a hidden rule. In this chapter, learn how a later algorithm can make a valid classification more likely to appear.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter11GroverLoopIntuitionLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_11_grover_loop_intuition_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 11 - Grover Loop Intuition',
              text:
                  'Grover is an iterative computational pattern. In this chapter, repeat the oracle and amplification abstractions in your reasoning to see how success probability grows.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    } else if (_isChapter12QuantumAlgorithmStructureLevel(level)) {
      const seenKey =
          'chapter_intro_seen_chapter_12_quantum_algorithm_structure_vertical_slice';
      if (await widget.tutorialFlagsStore.markSeenIfNeeded(seenKey)) {
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const ChapterIntroScreen(
              title: 'Chapter 12 - Quantum Algorithm Structure',
              text:
                  'This chapter is a meta-level synthesis. Unify oracle, amplification, and iteration into one abstract algorithm model: define, bias, iterate.',
              buttonLabel: 'Begin Discovery',
            ),
          ),
        );
      }
    }

    if (!mounted || !level.hasMystery) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MysteryPanel(level: level),
      ),
    );
  }

  Future<void> _showDiscoveryFlowIfNeeded(QQLevel level) async {
    if (!mounted || !level.hasDiscovery) return;

    final String? discoveryTitle = level.discoveryTitle?.trim();
    if (discoveryTitle != null && discoveryTitle.isNotEmpty) {
      if (!await saveProgressWithFeedback(
          context, () => _progressController.unlockDiscovery(discoveryTitle))) {
        return;
      }
      if (mounted) {
        final progressState = _progressController.state;
        setState(() {
          _progressState = progressState;
          _maxUnlockedLevel = progressState.maxUnlockedLevel;
        });
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DiscoveryDialog(level: level),
    );
  }

  bool _isCompletedLevelResult(LevelCompletionAction? result) {
    return result == LevelCompletionAction.nextLevel ||
        result == LevelCompletionAction.levelSelect ||
        result == LevelCompletionAction.reviewSolution;
  }

  QQLevelsCategory? _chapterCategoryForLevel(int levelNumber) {
    return journeyChapterForLesson(levelNumber);
  }

  bool _isFinalChapterLevel(int levelNumber) {
    final category = _chapterCategoryForLevel(levelNumber);
    return category != null && levelNumber - 1 == category.to;
  }

  String _chapterDisplayTitle(QQLevelsCategory category) =>
      category.groupName.replaceFirst(' - ', ' — ');

  String _chapterIdentityFor(QQLevelsCategory category) {
    for (final entry in notebookEntries) {
      if (entry.chapterTitle == category.groupName) {
        return entry.chapterIdentity;
      }
    }
    return '';
  }

  Future<void> _showChapterCompleteIfNeeded(int levelNumber) async {
    if (!_isFinalChapterLevel(levelNumber)) return;
    if (levelNumber == _guidedDiscoveryLevelCount) return;

    final category = _chapterCategoryForLevel(levelNumber);
    if (category == null || !mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ChapterCompleteScreen(
          chapterTitle: _chapterDisplayTitle(category),
          chapterIdentity: _chapterIdentityFor(category),
        ),
      ),
    );
  }

  Future<void> _playLevelSequence(int levelNumber, BuildContext context,
      {NumericActivityDomain domain = NumericActivityDomain.journey}) async {
    int currentLevelToPlay = levelNumber;
    bool continueLevelChain = true;

    while (continueLevelChain) {
      final levelData =
          numericActivityCatalogue.lookup(currentLevelToPlay, domain);

      if (levelData == null) {
        debugPrint(
            'HomePage: Error: Level $currentLevelToPlay data not found. Exiting chain.');
        _showGameCompleteDialog();
        continueLevelChain = false;
        break;
      }

      if (_isMasteryChallengeLevel(levelData)) {
        final shouldStart =
            await _showMasteryChallengeBrief(levelData, currentLevelToPlay);
        if (!shouldStart || !context.mounted) break;
      }

      await _showLearningIntroIfNeeded(levelData);
      if (!context.mounted) break;

      debugPrint(
          'HomePage: Pushing screen for Level $currentLevelToPlay (${levelData.runtimeType})...');
      final result = await Navigator.push<LevelCompletionAction>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              _screenForLevel(levelData, currentLevelToPlay, domain),
        ),
      );

      debugPrint(
          'HomePage: Returned from Level $currentLevelToPlay with result: $result');

      if (_isCompletedLevelResult(result)) {
        await _showDiscoveryFlowIfNeeded(levelData);
        if (!context.mounted) break;
        if (_showMasteryCompleteDialogAfterReturn) {
          await _showMasteryCompleteDialog();
          continueLevelChain = false;
          break;
        }
      }

      if (result == LevelCompletionAction.nextLevel) {
        if (domain == NumericActivityDomain.journey) {
          await _showChapterCompleteIfNeeded(currentLevelToPlay);
        }
        if (!context.mounted) break;

        if (domain == NumericActivityDomain.journey &&
            currentLevelToPlay == _guidedDiscoveryLevelCount) {
          continueLevelChain = false;
        } else if (domain == NumericActivityDomain.historicalMastery &&
            currentLevelToPlay == ProgressionRules.legacyMasteryLastId) {
          continueLevelChain = false;
        } else {
          currentLevelToPlay++;
        }
      } else if (result == LevelCompletionAction.levelSelect) {
        continueLevelChain = false;
      } else if (result == LevelCompletionAction.reviewSolution) {
        continueLevelChain = false;
      } else {
        continueLevelChain = false;
      }
    }
  }
}

class _UtilityMenuRow extends StatelessWidget {
  const _UtilityMenuRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 40,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MasteryCompleteAction {
  continueExploring,
  reviewNotebook,
}

class _MasteryCompletedCheckmark extends StatelessWidget {
  const _MasteryCompletedCheckmark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF7CFFB2).withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF7CFFB2).withValues(alpha: 0.46),
        ),
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: Icon(
          Icons.check_rounded,
          color: Color(0xFF7CFFB2),
          size: 16,
        ),
      ),
    );
  }
}

class _JourneyCompleteBody extends StatelessWidget {
  const _JourneyCompleteBody();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.cyan.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: QubitQuestDialog.cyan.withValues(alpha: 0.32),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: QubitQuestDialog.cyan,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You completed the Learning Journey. Every lesson remains available for review, and Mastery Challenges remain an independent practice destination.',
                style: TextStyle(
                  color: Color(0xFFD6E3F8),
                  fontSize: 14,
                  height: 1.38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryCompleteBody extends StatelessWidget {
  const _MasteryCompleteBody({
    required this.completedCount,
  });

  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: QubitQuestDialog.cyan.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: QubitQuestDialog.cyan.withValues(alpha: 0.32),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Congratulations!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'You have completed every Mastery Challenge in Qubit Quest.',
                  style: TextStyle(
                    color: Color(0xFFD6E3F8),
                    fontSize: 14.5,
                    height: 1.42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: QubitQuestDialog.innerColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: QubitQuestDialog.borderSoftColor),
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MasteryFlowRow(
                  icon: Icons.auto_stories_outlined,
                  title: 'Guided Discovery',
                  text: 'The lessons taught the concepts.',
                ),
                SizedBox(height: 12),
                _MasteryFlowRow(
                  icon: Icons.hub_outlined,
                  title: 'Mastery Challenges',
                  text: 'The challenges showed that you can apply them.',
                ),
                SizedBox(height: 12),
                _MasteryFlowRow(
                  icon: Icons.flag_outlined,
                  title: 'Current Learning Journey',
                  text: 'You have completed the current learning journey.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _MasteryCompleteCount(completedCount: completedCount),
      ],
    );
  }
}

class _MasteryCompleteCount extends StatelessWidget {
  const _MasteryCompleteCount({
    required this.completedCount,
  });

  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B2D2A).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7CFFB2).withValues(alpha: 0.30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF7CFFB2),
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mastery Challenges Completed',
                style: TextStyle(
                  color: Color(0xFFD6E3F8),
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$completedCount / $completedCount',
              style: const TextStyle(
                color: Color(0xFF7CFFB2),
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryChallengeBriefBody extends StatelessWidget {
  const _MasteryChallengeBriefBody({
    required this.level,
    required this.relatedEntries,
    required this.onReviewDiscovery,
  });

  final QQLevel level;
  final List<NotebookEntry> relatedEntries;
  final ValueChanged<NotebookEntry> onReviewDiscovery;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MasteryIconHeader(
          icon: Icons.hub_outlined,
          label: level.difficulty == null
              ? 'Apply what you learned'
              : '${level.difficulty} Advanced Challenge',
        ),
        const SizedBox(height: 14),
        const Text(
          'This challenge combines discoveries from the guided curriculum. Use the concepts together; the puzzle mechanics are unchanged.',
          style: TextStyle(
            color: Color(0xFFD6E3F8),
            fontSize: 14,
            height: 1.42,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (level.conceptsUsed.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _MasterySectionLabel('Concepts Used'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final concept in level.conceptsUsed)
                _MasteryTag(label: concept),
            ],
          ),
        ],
        if (relatedEntries.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _MasterySectionLabel('Related Discoveries'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in relatedEntries)
                _MasteryDiscoveryButton(
                  label: entry.discoveryTitle,
                  onPressed: () => onReviewDiscovery(entry),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MasteryIconHeader extends StatelessWidget {
  const _MasteryIconHeader({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.cyan.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: QubitQuestDialog.cyan.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: QubitQuestDialog.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: QubitQuestDialog.borderColor),
              ),
              child: Icon(icon, color: QubitQuestDialog.cyan, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryFlowRow extends StatelessWidget {
  const _MasteryFlowRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: QubitQuestDialog.cyan, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: QubitQuestDialog.mutedText,
                  fontSize: 13,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MasterySectionLabel extends StatelessWidget {
  const _MasterySectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MasteryTag extends StatelessWidget {
  const _MasteryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF134E4A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF7CFFB2).withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MasteryDiscoveryButton extends StatelessWidget {
  const _MasteryDiscoveryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFD6E3F8),
        backgroundColor: QubitQuestDialog.cardColor,
        side: BorderSide(
          color: QubitQuestDialog.cyan.withValues(alpha: 0.32),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  const _AboutInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: QubitQuestDialog.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
