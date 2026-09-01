import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/level_ui_router.dart';

void main() {
  const landscapeSize = Size(1000, 700);
  const cutoutPadding = EdgeInsets.only(left: 90, right: 34);

  Future<void> pumpLevel(
    WidgetTester tester,
    int levelId, {
    EdgeInsets padding = cutoutPadding,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = landscapeSize;
    addTearDown(tester.view.reset);

    final QQLevel level = getQQLevelById(levelId)!;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: MediaQuery(
          data: const MediaQueryData(size: landscapeSize).copyWith(
            padding: padding,
            viewPadding: padding,
          ),
          child: LevelUIRouter.buildLevelUI(
            level: level,
            levelId: levelId,
            onLevelUnlocked: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> revealFirstAnswer(WidgetTester tester) async {
    final verticalScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('circuit-reading-option-0')),
      180,
      scrollable: verticalScrollable.first,
    );
    await tester.pump();
  }

  testWidgets('M1 body, circuit, and answers stay inside landscape cutouts',
      (tester) async {
    await pumpLevel(tester, 61);

    final safeContent = tester.getRect(
      find.byKey(const ValueKey('lesson-content-safe-content')),
    );
    final circuit = tester.getRect(
      find.byKey(const ValueKey('circuit-reading-circuit')),
    );
    await revealFirstAnswer(tester);
    final firstAnswer = tester.getRect(
      find.byKey(const ValueKey('circuit-reading-option-0')),
    );

    expect(safeContent.left, greaterThanOrEqualTo(cutoutPadding.left));
    expect(safeContent.right,
        lessThanOrEqualTo(landscapeSize.width - cutoutPadding.right));
    expect(circuit.left, greaterThan(cutoutPadding.left));
    expect(circuit.right, lessThan(landscapeSize.width - cutoutPadding.right));
    expect(firstAnswer.left, closeTo(circuit.left, 0.01));
    expect(firstAnswer.right, closeTo(circuit.right, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('asymmetric right cutout also constrains Circuit Reading',
      (tester) async {
    const rightCutout = EdgeInsets.only(left: 18, right: 112);
    await pumpLevel(tester, 66, padding: rightCutout);

    final circuit = tester.getRect(
      find.byKey(const ValueKey('circuit-reading-circuit')),
    );
    await revealFirstAnswer(tester);
    final firstAnswer = tester.getRect(
      find.byKey(const ValueKey('circuit-reading-option-0')),
    );
    expect(circuit.left, greaterThan(rightCutout.left));
    expect(circuit.right, lessThan(landscapeSize.width - rightCutout.right));
    expect(firstAnswer.left, closeTo(circuit.left, 0.01));
    expect(firstAnswer.right, closeTo(circuit.right, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all mobile activity presenters share the safe body boundary',
      (tester) async {
    final representativeIds = <int>[
      62, // MCQ
      64, // Fill the Gate
      65, // Composer
      69, // Measurement Lab
      71, // Circuit Reading
    ];

    for (final levelId in representativeIds) {
      await pumpLevel(tester, levelId);
      final safeContent = tester.getRect(
        find.byKey(const ValueKey('lesson-content-safe-content')),
      );
      expect(safeContent.left, greaterThanOrEqualTo(cutoutPadding.left),
          reason: 'Left cutout not respected by level $levelId');
      expect(
        safeContent.right,
        lessThanOrEqualTo(landscapeSize.width - cutoutPadding.right),
        reason: 'Right cutout not respected by level $levelId',
      );
      expect(tester.takeException(), isNull,
          reason: 'Unexpected layout exception for level $levelId');
    }
  });

  testWidgets('portrait without horizontal insets keeps full usable width',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(430, 900)),
          child: LevelUIRouter.buildLevelUI(
            level: getQQLevelById(61)!,
            levelId: 61,
            onLevelUnlocked: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final safeContent = tester.getRect(
      find.byKey(const ValueKey('lesson-content-safe-content')),
    );
    expect(safeContent.left, 0);
    expect(safeContent.right, 430);
    expect(tester.takeException(), isNull);
  });
}
