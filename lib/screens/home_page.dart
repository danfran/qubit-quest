// home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:quantumquiz/screens/circuit_reading_screen.dart';
import 'package:quantumquiz/screens/fill_the_gate_screen.dart';
import 'package:quantumquiz/screens/mcq_screen.dart';
import 'package:quantumquiz/screens/measurement_lab_screen.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/screens/webview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/qq_level.dart';
import '../models/qq_levels.dart';
import '../models/qq_levels_category.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color qqBlack = Color(0xFF00030A);
  static const Color qqCard = Color(0xFF111827);
  static const Color qqCard2 = Color(0xFF18233A);
  static const Color qqBorder = Color(0x66344A73);
  static const Color qqCyan = Color(0xFF56CCF2);

  // Placeholder for the maximum unlocked level.
  // In a real app, this would be loaded from user data (e.g., preferences, database).
  int _maxUnlockedLevel = 1; // Example: Levels 1 to 5 are unlocked initially
  bool _isLoadingLevels = true; // To show loading state

  late PackageInfo _packageInfo;
  List<MapEntry<String, String>>? _aboutData; // Data for the about dialog

  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    _loadMaxUnlockedLevel();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
      _populateAboutData(); // Populate the data once package info is loaded
    });
  }

  void _populateAboutData() {
    // This method creates the list of data to display in the grid
    _aboutData = [
      MapEntry('App name', _packageInfo.appName),
      MapEntry('Author', 'aion'),
      MapEntry('Package name', _packageInfo.packageName),
      MapEntry('App version', _packageInfo.version),
      MapEntry('Build number', _packageInfo.buildNumber),
      MapEntry('Build signature', _packageInfo.buildSignature),
      MapEntry(
          'Installer store', _packageInfo.installerStore ?? 'not available'),
      MapEntry('Contact', 'dfrancesconi12@gmail.com'),
    ];
  }

  // Load the max unlocked level from SharedPreferences
  Future<void> _loadMaxUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxUnlockedLevel = prefs.getInt('maxUnlockedLevel') ?? 1;
      _isLoadingLevels = false; // Loading complete
    });
    debugPrint('Loaded max unlocked level: $_maxUnlockedLevel');
  }

  // Update and save the max unlocked level
  Future<void> _updateMaxUnlockedLevel(int completedLevelNumber) async {
    if (completedLevelNumber >= _maxUnlockedLevel) {
      final newMaxLevel = completedLevelNumber;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('maxUnlockedLevel', newMaxLevel);
      setState(() {
        _maxUnlockedLevel = newMaxLevel;
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
        return AlertDialog(
          backgroundColor:
              const Color(0xFF2D2E40), // Dark background for the dialog
          title: const Text(
            'All Levels Completed!',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Congratulations! You\'ve mastered all the quantum puzzles.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close',
                  style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    // Ensure data is ready before showing the dialog
    if (!mounted || _aboutData == null) {
      // You might want to show a loading indicator or handle this case
      debugPrint('About data not yet loaded.');
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF2D2E40), // Dark background for the dialog
          title: const Text('About', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite, // Allows dialog to expand horizontally
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Keep column compact vertically
                children: <Widget>[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                      childAspectRatio: 4.0,
                    ),
                    itemCount: _aboutData!.length,
                    itemBuilder: (context, index) {
                      final dataEntry = _aboutData![index];

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 4.0),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: const Color(
                              0xFF3B3C50), // Updated to match new theme
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${dataEntry.key}: ',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: dataEntry.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close',
                  style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // NEW: Method to handle rating the app
  Future<void> _rateApp() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      try {
        await _inAppReview.openStoreListing(
          appStoreId: 'com.qubitquest',
          microsoftStoreId: null,
        );
      } catch (e) {
        debugPrint('Error opening store listing: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open store page.')),
        );
      }
    }
  }

  void _showQubitSelectionDialog() {
    showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth.clamp(0, 460);

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: qqCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: qqBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.34),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Choose Number of Qubits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open the sandbox with a circuit size.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.66),
                          fontSize: 12,
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
                ),
              );
            },
          ),
        );
      },
    ).then((selectedNumQubits) {
      if (!mounted) return;
      if (selectedNumQubits != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuantumComposer(
              levelId: -1,
              level: getComposerAsLevel(
                  selectedNumQubits), // No specific level provided
              onLevelUnlocked: null,
            ),
          ),
        );
      }
    });
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

  void _openYoutubePlaylist(String playlistTextLink) async {
    final uri = Uri.parse(
      playlistTextLink,
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch YouTube';
    }
  }

  void _selectUtilityMenuAction(String action) {
    switch (action) {
      case 'docs':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WebViewPage(
              title: 'App Documentation',
              url:
                  'https://danfran.github.io/qubit-quest/app-documentation.html',
            ),
          ),
        );
        break;
      case 'videos':
        _openYoutubePlaylist(
          'https://www.youtube.com/playlist?list=PL1UkEjMAb8Lq1Nivn894qBWTU938HKPM7',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLevels) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: qqBlack,
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
                value: 'docs',
                child: ListTile(
                  leading: Icon(Icons.book_outlined, color: Colors.white),
                  title: Text('Documentation',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              PopupMenuItem(
                value: 'videos',
                child: ListTile(
                  leading:
                      Icon(Icons.video_library_outlined, color: Colors.white),
                  title: Text('Solution Videos',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              PopupMenuItem(
                value: 'rate',
                child: ListTile(
                  leading: Icon(Icons.star_outline, color: Colors.white),
                  title: Text('Rate Us', style: TextStyle(color: Colors.white)),
                ),
              ),
              PopupMenuItem(
                value: 'privacy',
                child: ListTile(
                  leading:
                      Icon(Icons.privacy_tip_outlined, color: Colors.white),
                  title: Text('Privacy Policy',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.white),
                  title: Text('About', style: TextStyle(color: Colors.white)),
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
                      SizedBox(height: compact ? 18 : 24),
                      for (var topic in groupedLevels)
                        _buildTopicSection(
                          topic.groupName,
                          topic.from,
                          topic.to,
                          compact: compact,
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

  Widget _buildPrimaryActionSection({required bool compact}) {
    final Widget continueCard = _buildActionCard(
      title: 'Continue Journey',
      subtitle: _maxUnlockedLevel > numberOfLevels
          ? 'Review your completed quantum path'
          : 'Next: Level $_maxUnlockedLevel',
      icon: Icons.play_arrow_rounded,
      primary: true,
      compact: compact,
      onTap: () {
        if (_maxUnlockedLevel > numberOfLevels) {
          _showGameCompleteDialog();
          return;
        }
        _playLevelSequence(_maxUnlockedLevel, context);
      },
    );
    final Widget composerCard = _buildActionCard(
      title: 'Sandbox Composer',
      subtitle: 'Build and test your own quantum circuits',
      icon: Icons.tune_rounded,
      primary: false,
      compact: compact,
      onTap: _showQubitSelectionDialog,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          continueCard,
          const SizedBox(height: 10),
          composerCard,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 6, child: continueCard),
        const SizedBox(width: 14),
        Expanded(flex: 5, child: composerCard),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool primary,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return InkWell(
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
              ? const LinearGradient(
                  colors: [
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
            color: primary ? const Color(0xFF3B1B75) : qqBorder,
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
        child: Row(
          children: [
            Container(
              width: compact ? 36 : 42,
              height: compact ? 36 : 42,
              decoration: BoxDecoration(
                color: primary
                    ? Colors.white.withValues(alpha: 0.16)
                    : qqCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      primary ? Colors.white.withValues(alpha: 0.20) : qqBorder,
                ),
              ),
              child: Icon(
                icon,
                color: primary ? Colors.white : qqCyan,
                size: compact ? 22 : 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 16 : 19,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          Colors.white.withValues(alpha: primary ? 0.82 : 0.68),
                      fontSize: compact ? 11 : 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: primary ? 0.92 : 0.60),
              size: compact ? 24 : 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSection(
    String topic,
    int indexStart,
    int indexStop, {
    required bool compact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: compact ? 12 : 16,
            bottom: compact ? 8 : 10,
          ),
          child: Text(
            topic,
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.12,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: compact ? 116.0 : 132.0,
            crossAxisSpacing: compact ? 8.0 : 10.0,
            mainAxisSpacing: compact ? 8.0 : 10.0,
            childAspectRatio: compact ? 1.18 : 1.32,
          ),
          itemCount: indexStop - indexStart + 1,
          itemBuilder: (context, index) {
            final int currentIndex = indexStart + index;
            final int levelNumber = currentIndex + 1;
            final bool isUnlocked = levelNumber <= _maxUnlockedLevel;

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
                    ? const LinearGradient(
                        colors: [
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
              child: ElevatedButton(
                onPressed: isUnlocked
                    ? () async {
                        await _playLevelSequence(levelNumber, context);
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                ),
                child: isUnlocked
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$levelNumber',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: compact ? 21 : 23,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          if (allQQLevels[currentIndex].title != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              allQQLevels[currentIndex].title!,
                              style: TextStyle(
                                fontSize: compact ? 9.5 : 10.5,
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w700,
                                height: 1.08,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      )
                    : Icon(
                        Icons.lock,
                        color: Colors.white.withValues(alpha: 0.24),
                        size: 26,
                      ),
              ),
            );
          },
        ),
        SizedBox(height: compact ? 14 : 18),
      ],
    );
  }

  // Route to the correct screen based on level type
  Widget _screenForLevel(QQLevel level, int levelId) {
    return switch (level) {
      ComposerLevel l => QuantumComposer(
          levelId: levelId,
          level: l,
          onLevelUnlocked: _updateMaxUnlockedLevel,
        ),
      FillTheGateLevel l => FillTheGateScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: _updateMaxUnlockedLevel,
        ),
      CircuitReadingLevel l => CircuitReadingScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: _updateMaxUnlockedLevel,
        ),
      McqLevel l => McqScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: _updateMaxUnlockedLevel,
        ),
      MeasurementLabLevel l => MeasurementLabScreen(
          levelId: levelId,
          level: l,
          onLevelUnlocked: _updateMaxUnlockedLevel,
        ),
    };
  }

  // Show category intro dialog once per category (tracked in SharedPreferences)
  Future<void> _showCategoryIntroIfNeeded(int levelNumber) async {
    final category = groupedLevels.cast<QQLevelsCategory?>().firstWhere(
          (c) =>
              c != null &&
              (c.from + 1) == levelNumber &&
              c.categoryIntro != null,
          orElse: () => null,
        );
    if (category == null) return;

    final prefs = await SharedPreferences.getInstance();
    final seenKey = 'intro_seen_${category.groupName}';
    if (prefs.getBool(seenKey) == true) return;
    await prefs.setBool(seenKey, true);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2E40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          category.groupName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          category.categoryIntro!,
          style:
              const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D5FE6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Let's go →",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _playLevelSequence(int levelNumber, BuildContext context) async {
    int currentLevelToPlay = levelNumber;
    bool continueLevelChain = true;

    while (continueLevelChain) {
      final levelData = getQQLevelById(currentLevelToPlay);

      if (levelData == null) {
        debugPrint(
            'HomePage: Error: Level $currentLevelToPlay data not found. Exiting chain.');
        _showGameCompleteDialog();
        continueLevelChain = false;
        break;
      }

      // Show category intro once if this is the first level of a category
      await _showCategoryIntroIfNeeded(currentLevelToPlay);
      if (!context.mounted) break;

      debugPrint(
          'HomePage: Pushing screen for Level $currentLevelToPlay (${levelData.runtimeType})...');
      final result = await Navigator.push<LevelCompletionAction>(
        context,
        MaterialPageRoute(
          builder: (context) => _screenForLevel(levelData, currentLevelToPlay),
        ),
      );

      debugPrint(
          'HomePage: Returned from Level $currentLevelToPlay with result: $result');

      if (result == LevelCompletionAction.nextLevel) {
        currentLevelToPlay++;
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
