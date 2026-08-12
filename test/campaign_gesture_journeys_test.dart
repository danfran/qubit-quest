import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

import 'support/campaign_integration_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final levels = allQQLevels.indexed
      .where((entry) => entry.$2 is ComposerLevel)
      .map((entry) => (id: entry.$1 + 1, level: entry.$2 as ComposerLevel))
      .toList(growable: false);

  testWidgets('UI journey: early lesson palette drag to real Check Result',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final entry = levels.first;
    final harness = CampaignIntegrationHarness(tester);
    await harness.loadLevel(entry.id, entry.level);
    await harness
        .insertStepWithGesture(entry.level.canonicalSolution!.steps.single);
    await harness.checkResultAndComplete();
  });

  testWidgets('UI journey: two-qubit controlled insertion completes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final entry = levels.firstWhere((entry) {
      final steps = entry.level.canonicalSolution!.steps;
      return entry.level.numQubits == 2 &&
          steps.length == 1 &&
          steps.single.gateType == SelectedGateType.cnot &&
          entry.level.availableGates.first.type == SelectedGateType.cnot;
    });
    final harness = CampaignIntegrationHarness(tester);
    await harness.loadLevel(entry.id, entry.level);
    await harness
        .insertStepWithGesture(entry.level.canonicalSolution!.steps.single);
    await harness.checkResultAndComplete();
  });
}
