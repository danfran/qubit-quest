// home_page.dart

import 'package:flutter/material.dart';
import 'package:quantumquiz/quantum_composer.dart';
import 'package:quantumquiz/utils/level_completion_action.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/qq_levels.dart';

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
    print('Loaded max unlocked level: $_maxUnlockedLevel');
  }

  // Update and save the max unlocked level
  Future<void> _updateMaxUnlockedLevel(int completedLevelNumber) async {
    if (completedLevelNumber >= _maxUnlockedLevel) {
      final newMaxLevel = completedLevelNumber + 1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('maxUnlockedLevel', newMaxLevel);
      setState(() {
        _maxUnlockedLevel = newMaxLevel;
      });
      print('Updated and saved max unlocked level: $_maxUnlockedLevel');
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

  // Show aabout if all
  Widget _infoTile(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle.isEmpty ? 'Not set' : subtitle),
    );
  }

  void _showAboutDialog() {
    // Ensure data is ready before showing the dialog
    if (!mounted || _aboutData == null) {
      // You might want to show a loading indicator or handle this case
      print('About data not yet loaded.');
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
        title: Text(
          "⟨𝜑ubit|𝜑uest⟩", // App name
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1E1E2C), // Dark app bar
        centerTitle: true,
      ),
      body: SafeArea( // Ensures content avoids notches/cutouts
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row( // Changed from Column to Row for two-column layout
            children: [
              // Left side: Options list (30% width)
              Expanded(
                flex: 3, // 30% of the available width
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900], // Slightly lighter background for the options panel
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center options vertically
                    children: [
                      _buildOptionButton(context, "Start/Continue", () {
                        int selectedLevel = _maxUnlockedLevel;

                        // Navigate to the last unlocked level or first unlocked level
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuantumComposer(
                              levelId: selectedLevel, // Pass the level ID
                              level: getQQLevelById(selectedLevel)!,
                            ), // Placeholder, pass level data later
                          ),
                        );
                      }),
                      SizedBox(height: 20),
                      _buildOptionButton(context, "Documentation", () {
                        // TODO: Implement navigation to documentation page
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Documentation coming soon!')),
                        );
                      }),
                      SizedBox(height: 20),
                      _buildOptionButton(context, "About", () {
                        // TODO: Implement navigation to about page
                        _showAboutDialog();
                      }),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.0), // Space between the two columns

              // Right side: Levels grid (70% width)
              Expanded(
                flex: 7, // 70% of the available width
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        "Select a Level",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 70.0, // Adjusted max width for 10 items in 70% width
                          crossAxisSpacing: 10.0,   // Horizontal space between items
                          mainAxisSpacing: 10.0,    // Vertical space between items
                          childAspectRatio: 1.5,    // Make items square
                        ),
                        itemCount: numberOfLevels,
                        itemBuilder: (context, index) {
                          final int levelNumber = index + 1;
                          final bool isUnlocked = levelNumber <= _maxUnlockedLevel;

                          return ElevatedButton(
                            onPressed: isUnlocked
                                ? () async {
                              int currentLevelToPlay = levelNumber; // Start with the level that was tapped
                              bool continueLevelChain = true;

                              while (continueLevelChain) {
                                final levelData = getQQLevelById(currentLevelToPlay);

                                if (levelData == null) {
                                  print('HomePage: Error: Level $currentLevelToPlay data not found. Exiting chain.');
                                  _showGameCompleteDialog(); // Or an error message
                                  continueLevelChain = false; // Stop the loop
                                  break; // Exit the loop
                                }

                                print('HomePage: Pushing QuantumComposerScreen for Level $currentLevelToPlay...');
                                // Push the QuantumComposerScreen and AWAIT its result
                                final result = await Navigator.push<LevelCompletionAction>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuantumComposer(
                                      levelId: currentLevelToPlay,
                                      level: levelData, // Pass the entire Level object
                                    ),
                                  ),
                                );

                                print('HomePage: Returned from Composer (Level $currentLevelToPlay) with result: $result');

                                if (result == LevelCompletionAction.nextLevel) {
                                  // User completed the level and wants the next one
                                  await _updateMaxUnlockedLevel(currentLevelToPlay); // Unlock the *next* level
                                  currentLevelToPlay++; // Increment to load the next level in the loop
                                  print('HomePage: Preparing to load next level: $currentLevelToPlay');
                                  // The loop will reiterate, pushing the next level
                                } else if (result == LevelCompletionAction.levelSelect) {
                                  // User chose to go back to level select (HomePage)
                                  print('HomePage: User chose Level Select. Exiting chain.');
                                  continueLevelChain = false; // Stop the loop
                                  // The QuantumComposerScreen has already popped itself back to HomePage.
                                } else { // result is LevelCompletionAction.reviewSolution, LevelCompletionAction.none, or null (back button)
                                  // User chose to review, or pressed back, or dialog dismissed without specific action.
                                  print('HomePage: User chose Review/Back/None. Exiting chain.');
                                  continueLevelChain = false; // Stop the loop
                                  // The QuantumComposerScreen has already popped itself back to HomePage.
                                }
                              }
                              // If result is LevelCompletionAction.reviewSolution or null,
                              // the ComposerScreen was simply popped, and we are back on HomePage.
                              // No special action needed here.
                            }
                                : null, // Disable button if level is locked
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUnlocked ? Colors.blueAccent : Colors.grey[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0), // Rounded corners for buttons
                              ),
                              elevation: 5,
                              padding: EdgeInsets.zero, // Remove default padding for better text centering
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
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
