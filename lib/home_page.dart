// home_page.dart

import 'package:flutter/material.dart';
import 'package:quantumquiz/quantum_composer.dart';
import 'package:quantumquiz/utils/level_completion_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMaxUnlockedLevel();
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('About this app coming soon!')),
                        );
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
