import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for orientation control
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/home_page.dart';
import 'package:quantumquiz/quantum_composer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TeXRenderingServer.start();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quantum Composer',
      theme: ThemeData(
        brightness: Brightness.dark, // Use dark theme for better contrast with white text
        primarySwatch: Colors.blue,
        // Set default text color for various text styles to white
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
        // Ensure text selection handles also use white (or a contrasting color)
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Colors.blue.withOpacity(0.5), // Example selection color
          selectionHandleColor: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black, // Ensure app bar is dark
          foregroundColor: Colors.white, // Default icon/text color in app bar
        ),
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
