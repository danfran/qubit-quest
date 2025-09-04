// home_page.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:quantumquiz/screens/quantum_composer.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/screens/webview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/qq_levels.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Placeholder for the maximum unlocked level.
  // In a real app, this would be loaded from user data (e.g., preferences, database).
  int _maxUnlockedLevel = 1; // Example: Levels 1 to 5 are unlocked initially
  bool _isLoadingLevels = true; // To show loading state

  late PackageInfo _packageInfo;
  late List<MapEntry<String, String>> _aboutData; // Data for the about dialog

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
      MapEntry('Installer store', _packageInfo.installerStore ?? 'not available'),
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
          backgroundColor: const Color(0xFF2D2E40), // Dark background for the dialog
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
              child: const Text('Close', style: TextStyle(color: Colors.blueAccent)),
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
          backgroundColor: const Color(0xFF2D2E40), // Dark background for the dialog
          title: const Text('About', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite, // Allows dialog to expand horizontally
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Keep column compact vertically
                children: <Widget>[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                      childAspectRatio: 4.0,
                    ),
                    itemCount: _aboutData.length,
                    itemBuilder: (context, index) {
                      final dataEntry = _aboutData[index];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B3C50), // Updated to match new theme
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
              child: const Text('Close', style: TextStyle(color: Colors.blueAccent)),
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
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2E40), // Updated to match new theme
          title: const Text(
            'Choose Number of Qubits',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox( // Use SizedBox to give GridView a bounded size
            width: 390.0, // Calculated width: (5 buttons * 70 width/button) + (4 spaces * 10 spacing/space)
            height: 60.0, // Height for one row of buttons (buttons are 46.67px tall, so 60px provides comfortable padding)
            child: GridView.builder( // Changed to GridView.builder for horizontal layout
              scrollDirection: Axis.horizontal, // Scroll horizontally
              shrinkWrap: true, // Make GridView take only as much space as its children
              physics: const NeverScrollableScrollPhysics(), // No scrolling needed if all fit
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1, // One row
                mainAxisSpacing: 10.0, // Horizontal spacing between buttons
                mainAxisExtent: 70.0, // Explicitly set the width of each item to match level buttons
                childAspectRatio: 1.5, // Matches the level buttons' width/height ratio (70/46.67)
              ),
              itemCount: 5,
              itemBuilder: (context, index) {
                final numQubits = index + 1;
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(numQubits); // Pop dialog with selected number
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D5FE6), // Updated to a vibrant blue
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 5, // Add elevation for a lifted effect
                    padding: EdgeInsets.zero, // Remove default padding for better text centering
                    // minimumSize is not needed here as mainAxisExtent and childAspectRatio define size
                  ),
                  child: Text(
                    '$numQubits',
                    style: const TextStyle(
                      fontSize: 24, // Consistent font size with levels
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((selectedNumQubits) {
      if (selectedNumQubits != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuantumComposer(
              levelId: -1,
              level: getComposerAsLevel(selectedNumQubits), // No specific level provided
              onLevelUnlocked: null,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLevels) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // Consistent dark background
      appBar: AppBar(
        scrolledUnderElevation: 0.0, // Prevent elevation change on scroll
        surfaceTintColor: Colors.transparent, // Prevent color tinting on scroll
        title: SvgPicture.asset(
          'assets/images/logo.svg', // Path to your white SVG
          height: 36, // Adjust height as needed
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ), // Ensure it's white if not already in SVG, or to override
        ),
        backgroundColor: const Color(0xFF1E1E2C), // Dark app bar
        centerTitle: true,
      ),
      body: Container(
        // Use a gradient for the background to add visual depth
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2C),
        ),
        child: SafeArea( // Ensures content avoids notches/cutouts
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Row( // Changed from Column to Row for two-column layout
              children: [
                // Left side: Options list (30% width)
                Expanded(
                  flex: 3, // 30% of the available width
                  child: Align(
                    alignment: Alignment.topCenter, // This aligns the content to the top
                    child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2E40),
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      // Removed SingleChildScrollView to prevent scrolling
                      child: Column(
                        // Center main content vertically
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildOptionButton(context, "Start/Continue", Icons.play_arrow, () {
                            if (_maxUnlockedLevel > numberOfLevels) {
                              _showGameCompleteDialog();
                              return;
                            }
                            _playLevelSequence(_maxUnlockedLevel, context);
                          }),
                          const SizedBox(height: 2), // Adjusted spacing
                          _buildOptionButton(context, "App Documentation", Icons.book, () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const WebViewPage(
                                  title: 'App Documentation',
                                  url: 'https://danfran.github.io/qubit-quest/app-documentation.html',
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 2), // Adjusted spacing
                          _buildOptionButton(context, "Rate Us", Icons.star, () {
                            _rateApp();
                          }),
                          const SizedBox(height: 2), // Adjusted spacing
                          _buildOptionButton(context, "Privacy Policy", Icons.security, () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const WebViewPage(
                                  title: 'Privacy Policy',
                                  url: 'https://danfran.github.io/qubit-quest/privacy-policy.html',
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 2), // Adjusted spacing
                          _buildOptionButton(context, "About", Icons.info, () {
                            _showAboutDialog();
                          }),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
                const SizedBox(width: 24.0), // Increased space between the two columns

                // Right side: Levels grid (70% width)
                Expanded(
                  flex: 7,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left:20.0, right:20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The Hero Card
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.0),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5D5FE6), Color(0xFF8843F2)], // Vibrant gradient
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5D5FE6).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0, // No elevation on the card itself
                            color: Colors.transparent, // Make card transparent to show the container's gradient
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 20, // Increased font size for hero section
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(2, 2),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  children: <TextSpan>[
                                    const TextSpan(text: 'Select a Level or use the '),
                                    TextSpan(
                                      text: 'Composer',
                                      style: const TextStyle(
                                        color: Color(0xFFF2F272), // A bright yellow
                                        decoration: TextDecoration.none, // Explicitly remove underline
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _showQubitSelectionDialog();
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // Spacing between the card and the grid
                        for (var topic in groupedLevels)
                          _buildTopicSection(topic.groupName, topic.from, topic.to),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build a topic section with a header and a grid of levels
  Widget _buildTopicSection(String topic, int indexStart, int indexStop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            topic,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true, // Important to allow the grid to be in a scrollable view
          physics: const NeverScrollableScrollPhysics(), // Prevents nested scrolling
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 70.0,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 1.5,
          ),
          itemCount: indexStop - indexStart + 1,
          itemBuilder: (context, index) {
            int currentIndex = indexStart + index;
            int levelNumber = currentIndex + 1;
            final bool isUnlocked = levelNumber <= _maxUnlockedLevel;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isUnlocked ? 0.3 : 0.2),
                    spreadRadius: isUnlocked ? 1 : 0.5,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                gradient: isUnlocked
                    ? const LinearGradient(
                  colors: [Color(0xFF5D5FE6), Color(0xFF8843F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null, // No gradient for locked levels
                color: isUnlocked ? null : const Color(0xFF3B3C50),
              ),
              child: ElevatedButton(
                onPressed: isUnlocked
                    ? () async {
                  await _playLevelSequence(levelNumber, context);
                }
                    : null, // Disable button if level is locked
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Make button background transparent
                  shadowColor: Colors.transparent, // No button shadow
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 0, // No elevation
                  padding: EdgeInsets.zero,
                ),
                child: isUnlocked
                    ? Text(
                  '$levelNumber',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : Icon(
                  Icons.lock,
                  color: Colors.grey[600],
                  size: 28,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20), // Spacing between topics
      ],
    );
  }

  Future<void> _playLevelSequence(int levelNumber, BuildContext context) async {
    int currentLevelToPlay = levelNumber; // Start with the level that was tapped
    bool continueLevelChain = true;

    while (continueLevelChain) {
      final levelData = getQQLevelById(currentLevelToPlay);

      if (levelData == null) {
        debugPrint('HomePage: Error: Level $currentLevelToPlay data not found. Exiting chain.');
        _showGameCompleteDialog(); // Or an error message
        continueLevelChain = false; // Stop the loop
        break; // Exit the loop
      }

      debugPrint('HomePage: Pushing QuantumComposerScreen for Level $currentLevelToPlay...');
      // Push the QuantumComposerScreen and AWAIT its result
      final result = await Navigator.push<LevelCompletionAction>(
        context,
        MaterialPageRoute(
          builder: (context) => QuantumComposer(
            levelId: currentLevelToPlay,
            level: levelData,
            onLevelUnlocked: _updateMaxUnlockedLevel, // Pass the entire Level object
          ),
        ),
      );

      debugPrint('HomePage: Returned from Composer (Level $currentLevelToPlay) with result: $result');

      if (result == LevelCompletionAction.nextLevel) {
        currentLevelToPlay++; // Increment to load the next level in the loop
        debugPrint('HomePage: Preparing to load next level: $currentLevelToPlay');
      } else if (result == LevelCompletionAction.levelSelect) {
        debugPrint('HomePage: User chose Level Select. Exiting chain.');
        continueLevelChain = false;
      } else if (result == LevelCompletionAction.reviewSolution) {
        debugPrint('HomePage: User chose Review Solution. Exiting chain.');
        continueLevelChain = false;
      } else { // result is LevelCompletionAction.none, or null (back button)
        debugPrint('HomePage: User chose Back/None. Exiting chain.');
        continueLevelChain = false;
      }
    }
  }

  // Helper method for building consistent option buttons
  Widget _buildOptionButton(BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, // Make button fill available width
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B3C50), // A darker button color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6), // Adjusted padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 5,
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
