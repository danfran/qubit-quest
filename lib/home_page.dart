// home_page.dart

import 'package:flutter/material.dart';
import 'package:quantumquiz/quantum_composer.dart';

import 'models/qq_levels.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Placeholder for the maximum unlocked level.
  // In a real app, this would be loaded from user data (e.g., preferences, database).
  int _maxUnlockedLevel = 1; // Example: Levels 1 to 5 are unlocked initially

  // Total number of levels (placeholder)
  final int _totalLevels = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Consistent dark background
      appBar: AppBar(
        title: Text(
          "⟨𝜑ubit|𝜑uest⟩", // App name
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black, // Dark app bar
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
                        int selectedLevel = _getLevel();

                        // Navigate to the last unlocked level or first unlocked level
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuantumComposer(
                              levelId: selectedLevel, // Pass the level ID
                              level: getQQLevelById(selectedLevel)!, // Pass the entire Level object
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
                        itemCount: _totalLevels,
                        itemBuilder: (context, index) {
                          final int levelNumber = index + 1;
                          final bool isUnlocked = levelNumber <= _maxUnlockedLevel;

                          return ElevatedButton(
                            onPressed: isUnlocked
                                ? () {
                              // Navigate to the QuantumComposer for the selected level
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuantumComposer(
                                    levelId: levelNumber,
                                    level: getQQLevelById(levelNumber)!, // Pass the entire Level object
                                  ), // Pass level data if needed later
                                ),
                              );
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

  int _getLevel() {
    int targetLevelId = 1; // Default to level 1

    // Example: Load the last unlocked level. This data would usually come
    // from shared preferences, a database, or user authentication.
    // For demonstration, let's assume last unlocked is Level 3.
    int lastUnlockedLevelId = 1; // Placeholder for actual user progress
    bool userWantsToContinue = true; // Placeholder for user choice or game state

    if (userWantsToContinue && lastUnlockedLevelId > 0) {
      targetLevelId = lastUnlockedLevelId;
    } else {
      targetLevelId = 1; // Start a new game or re-start level 1
    }

    return targetLevelId;
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
