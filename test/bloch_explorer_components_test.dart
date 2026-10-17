import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/canonical_qubit_state.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/bloch_explorer_panels.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';

void main() {
  testWidgets('public sphere renders the supplied state independently',
      (tester) async {
    final state = CanonicalQubitState.one.blochState;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 320,
          child: BlochSpherePanel(
            state: state,
            camera: const BlochCamera(),
            onCameraChanged: (_) {},
            onStatePreview: (_) {},
            onStateCommitted: (_) {},
            onGestureStarted: () {},
            onStateGestureStarted: () => state,
          ),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('bloch-sphere-canvas')),
    );
    expect((paint.painter! as BlochSpherePainter).state, state);
    expect(find.byKey(const ValueKey('bloch-live-probabilities')), findsOne);
    final angleText = tester.widget<Text>(find.text('θ = 3.142'));
    final probabilityStyle = tester.widget<DefaultTextStyle>(
      find
          .descendant(
            of: find.byKey(const ValueKey('bloch-live-probabilities')),
            matching: find.byType(DefaultTextStyle),
          )
          .last,
    );
    expect(angleText.style, blochTelemetryTextStyle);
    expect(probabilityStyle.style.fontSize, blochTelemetryTextStyle.fontSize);
  });

  testWidgets('gate and playback panels forward semantic intents',
      (tester) async {
    SelectedGateType? applied;
    var undid = false;
    bool? instant;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(children: [
            BlochGatePanel(
              initialState: CanonicalQubitState.zero.blochState,
              rotationAngle: 1.5707963267948966,
              enabled: true,
              onSelectPreset: (_) {},
              onApplyGate: (gate) => applied = gate,
              onInspectGate: (_) {},
              onAngleChanged: (_) {},
            ),
            BlochPlaybackControls(
              canUndo: true,
              canRedo: false,
              canReplay: false,
              replayRunning: false,
              instant: false,
              onUndo: () => undid = true,
              onRedo: () {},
              onReplay: () {},
              onReset: () {},
              onInstantChanged: (value) => instant = value,
            ),
          ]),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('bloch-gate-x')));
    await tester.tap(find.byKey(const ValueKey('bloch-undo')));
    await tester.tap(find.byKey(const ValueKey('bloch-instant-mode')));
    await tester.pump();

    expect(applied, SelectedGateType.x);
    expect(undid, isTrue);
    expect(instant, isTrue);
  });

  testWidgets('math panel renders supplied state details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlochStateMathPanel(
            state: BlochState.zero,
            globalPhase: 0.25,
          ),
        ),
      ),
    );

    expect(find.text('P(|0⟩) = 100.0%'), findsOne);
    expect(find.text('P(|1⟩) = 0.0%'), findsOne);
    expect(find.text('Global phase γ: 0.25 rad'), findsOne);
  });
}
