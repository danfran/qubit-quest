import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for orientation control
import 'package:flutter_tex/flutter_tex.dart';
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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: QuantumComposer(),
      debugShowCheckedModeBanner: false,
    );
  }
}
