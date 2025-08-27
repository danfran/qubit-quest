// home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:quantumquiz/models/qq_level.dart';
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
          title: const Text('All Levels Completed!'),
          content: const Text('Congratulations! You\'ve mastered all the quantum puzzles.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
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
          title: const Text('About'),
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
                      crossAxisCount: 4, // <--- CORRECTED: Now 4 columns, as requested!
                      crossAxisSpacing: 4.0, // Reduced horizontal gap between boxes
                      mainAxisSpacing: 4.0,  // Reduced vertical gap between rows
                      childAspectRatio: 4.0, // <--- ADJUSTED: Increased for narrower columns (width/height)
                      // You might need to fine-tune this value further (e.g., 4.5, 5.0)
                    ),
                    itemCount: _aboutData.length, // Still one item per data pair
                    itemBuilder: (context, index) {
                      final dataEntry = _aboutData[index];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0), // Reduced internal padding
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade800,
                          borderRadius: BorderRadius.circular(4.0), // Slightly smaller radius
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${dataEntry.key}: ',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11, // <--- ADJUSTED: Slightly smaller font for tighter space
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: dataEntry.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13, // <--- ADJUSTED: Slightly smaller font for tighter space
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2, // Allow wrapping to 2 lines
                          overflow: TextOverflow.ellipsis, // Add ellipsis if it overflows
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
              child: const Text('Close'),
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
      // If in-app review is available (iOS 10.3+, Android 5.0+),
      // it will show the native rating prompt.
      await _inAppReview.requestReview();
    } else {
      // If in-app review is not available (e.g., on older OS versions, or
      // if the user has already been prompted too many times),
      // it will open the store listing page.
      // You should replace 'com.your.app.id' with your actual app ID
      // from Google Play Console or Apple App Store Connect.
      try {
        await _inAppReview.openStoreListing(
          appStoreId: '1234567890', // Your Apple App Store ID (for iOS)
          microsoftStoreId: null,   // Your Microsoft Store ID (for Windows)
        );
      } catch (e) {
        debugPrint('Error opening store listing: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open store page.')),
        );
      }
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
      backgroundColor: Color(0xFF1E1E2C), // Consistent dark background
      appBar: AppBar(
        scrolledUnderElevation: 0.0, // Prevent elevation change on scroll
        surfaceTintColor: Colors.transparent, // Prevent color tinting on scroll
        title: SvgPicture.asset(
          'assets/images/logo.svg', // Path to your white SVG
          height: 36, // Adjust height as needed
          colorFilter: ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ), // Ensure it's white if not already in SVG, or to override
        ),
        backgroundColor: Color(0xFF1E1E2C), // Dark app bar
        centerTitle: true,
      ),
      body: SafeArea( // Ensures content avoids notches/cutouts
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: Row( // Changed from Column to Row for two-column layout
            children: [
              // Left side: Options list (30% width)
              Expanded(
                flex: 3, // 30% of the available width
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900], // Slightly lighter background for the options panel
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center options vertically
                    children: [
                      _buildOptionButton(context, "Start/Continue", () {
                        // Check if all levels are already completed
                        if (_maxUnlockedLevel > numberOfLevels) {
                          _showGameCompleteDialog(); // Game already completed, just show dialog
                          return;
                        }
                        // Start the level sequence from the last unlocked level
                        _playLevelSequence(_maxUnlockedLevel, context);
                      }),
                      SizedBox(height: 6),
                      _buildOptionButton(context, "App Documentation", () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WebViewPage(
                              title: 'App Documentation',
                              url: 'https://danfran.github.io/qubit-quest/app-documentation.html',
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 6),
                      _buildOptionButton(context, "Rate Us", () {
                        _rateApp();
                      }),
                      SizedBox(height: 6),
                      _buildOptionButton(context, "Privacy Policy", () {
                        Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const WebViewPage(
                                title: 'Privacy Policy',
                                url: 'https://danfran.github.io/qubit-quest/privacy-policy.html',
                              ),
                            ),
                        );
                      }),
                      SizedBox(height: 6),
                      _buildOptionButton(context, "About", () {
                        _showAboutDialog();
                      }),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.0), // Space between the two columns

              // Right side: Levels grid (70% width)
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left:20.0, right:20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            // This creates a multi-color gradient for a vibrant fire effect.
                            return const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF8A2BE2), // Blue Violet
                                Color(0xFFBA55D3), // Medium Orchid
                                Color(0xFF00BFFF), // Deep Sky Blue
                              ],
                              stops: [0.0, 0.5, 1.0], // Controls the spread of the colors
                              tileMode: TileMode.clamp,
                            ).createShader(bounds);
                          },
                          child: Text(
                            "Select a Level",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // The color is now a fallback for the gradient
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5 * 255), // A semi-transparent black shadow
                                  offset: const Offset(3, 3), // Moves the shadow 3 pixels right and down
                                  blurRadius: 5, // Blurs the shadow for a softer effect
                                ),
                              ],
                            ),
                          ),
                        )
                      ),
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

            return ElevatedButton(
              onPressed: isUnlocked
                  ? () async {
                await _playLevelSequence(levelNumber, context);
              }
                  : null, // Disable button if level is locked
              style: ElevatedButton.styleFrom(
                backgroundColor: isUnlocked ? Colors.blueAccent : Colors.grey[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 5,
                padding: EdgeInsets.zero,
              ),
              child: Text(
                '$levelNumber',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.white : Colors.grey[600],
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
        // User completed the level and wants the next one
        currentLevelToPlay++; // Increment to load the next level in the loop
        debugPrint('HomePage: Preparing to load next level: $currentLevelToPlay');
        // The loop will reiterate, pushing the next level
      } else if (result == LevelCompletionAction.levelSelect) {
        // User chose to go back to level select (HomePage)
        debugPrint('HomePage: User chose Level Select. Exiting chain.');
        continueLevelChain = false; // Stop the loop
        // The QuantumComposerScreen has already popped itself back to HomePage.
      } else if (result == LevelCompletionAction.reviewSolution) {
        // User chose to go back to level select (HomePage)
        debugPrint('HomePage: User chose Review Solution. Exiting chain.');
        continueLevelChain = false; // Stop the loop
        // The QuantumComposerScreen has already popped itself back to HomePage.
      } else { // result is LevelCompletionAction.none, or null (back button)
        // User chose to review, or pressed back, or dialog dismissed without specific action.
        debugPrint('HomePage: User chose Back/None. Exiting chain.');
        continueLevelChain = false; // Stop the loop
        // The QuantumComposerScreen has already popped itself back to HomePage.
      }
    }
  }

  // Helper method for building consistent option buttons
  Widget _buildOptionButton(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, // Make button fill available width
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey[700], // Darker button color
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
          ),
          elevation: 3,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
