import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Import for orientation control
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/sandbox_circuit_persistence.dart';
import 'package:quantumquiz/models/tutorial_flags_store.dart';
import 'package:quantumquiz/screens/home_page.dart';
import 'package:quantumquiz/screens/web_app.dart';
import 'package:quantumquiz/storage/app_storage.dart';
import 'package:quantumquiz/storage/shared_preferences_app_storage.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TeXRenderingServer.start();

  if (kIsWeb) {
    runApp(QubitQuestWebApp());
    return;
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  MyApp({super.key, this.storage = const SharedPreferencesAppStorage()})
      : progressController = CampaignProgressController(
          store: SharedPreferencesCampaignProgressStore(storage: storage),
        ),
        sandboxPersistenceStore = SandboxPersistenceStore(storage: storage),
        tutorialFlagsStore = TutorialFlagsStore(storage: storage) {
    CampaignProgressController.configureSharedInstance(progressController);
  }

  final AppStorage storage;
  final CampaignProgressController progressController;
  final SandboxPersistenceStore sandboxPersistenceStore;
  final TutorialFlagsStore tutorialFlagsStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quantum Composer',
      theme: QubitQuestTheme.mobile(),
      home: SafeArea(
        child: HomePage(
          progressController: progressController,
          sandboxPersistenceStore: sandboxPersistenceStore,
          tutorialFlagsStore: tutorialFlagsStore,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
