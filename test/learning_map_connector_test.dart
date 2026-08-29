import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/campaign_progress.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/screens/learning_map_screen.dart';

void main() {
  group('Learning Map connector geometry', () {
    const size = Size(800, 18);

    test('routes left-to-right and points toward the next chapter', () {
      final geometry = LearningMapConnectorGeometry.between(
        size: size,
        compact: false,
        sourceChapter: 1,
      );

      expect(geometry.start.dx, lessThan(geometry.destination.dx));
      expect(geometry.start.dy, 0);
      expect(geometry.destination.dy, size.height);
      expect(
        geometry.arrowHead.skip(1).every(
              (point) => point.dy < geometry.destination.dy,
            ),
        isTrue,
      );
    });

    test('routes right-to-left without a diagonal fallback', () {
      final geometry = LearningMapConnectorGeometry.between(
        size: size,
        compact: false,
        sourceChapter: 2,
      );

      expect(geometry.start.dx, greaterThan(geometry.destination.dx));
      for (var index = 1; index < geometry.routePoints.length; index++) {
        final previous = geometry.routePoints[index - 1];
        final current = geometry.routePoints[index];
        expect(
          previous.dx == current.dx || previous.dy == current.dy,
          isTrue,
          reason: 'Every connector segment must be orthogonal.',
        );
      }
    });

    test('compact routing remains vertical and outside card interiors', () {
      final geometry = LearningMapConnectorGeometry.between(
        size: const Size(358, 16),
        compact: true,
        sourceChapter: 1,
      );
      const sourceCard = Rect.fromLTWH(0, 0, 358, 150);
      const destinationCard = Rect.fromLTWH(0, 166, 358, 150);
      const unrelatedCard = Rect.fromLTWH(0, 332, 358, 150);

      for (final point in geometry.routePoints) {
        final globalPoint = point + const Offset(0, 150);
        expect(sourceCard.deflate(0.1).contains(globalPoint), isFalse);
        expect(destinationCard.deflate(0.1).contains(globalPoint), isFalse);
        expect(unrelatedCard.deflate(0.1).contains(globalPoint), isFalse);
      }
      expect(
          geometry.routePoints.map((point) => point.dx).toSet(), hasLength(1));
    });
  });

  group('Learning Map connector integration', () {
    Future<void> pumpMap(
      WidgetTester tester, {
      CampaignProgressState? state,
      Future<void> Function(int)? onStartChapter,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 760);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: LearningMapScreen(
            progressState: state ?? CampaignProgressState.fresh(),
            onStartChapter: onStartChapter ?? (_) async {},
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders one arrow connector for every consecutive pair',
        (tester) async {
      await pumpMap(tester);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.painter is LearningMapConnectorPainter,
        ),
        findsNWidgets(groupedLevels.length - 1),
      );
      final firstPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('learning-map-connector-1-2')),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(firstPaint.painter, isA<LearningMapConnectorPainter>());
    });

    testWidgets('chapter navigation and locking behavior remain unchanged',
        (tester) async {
      int? openedLevel;
      await pumpMap(
        tester,
        state: CampaignProgressState.fresh(),
        onStartChapter: (level) async => openedLevel = level,
      );

      final firstChapter = find.byKey(const ValueKey('learning-map-chapter-1'));
      final secondChapter =
          find.byKey(const ValueKey('learning-map-chapter-2'));
      expect(tester.widget<InkWell>(firstChapter).onTap, isNotNull);
      expect(tester.widget<InkWell>(secondChapter).onTap, isNull);

      await tester.tap(firstChapter);
      await tester.pump();
      expect(openedLevel, 1);
    });

    testWidgets('completed progression retains accent connector state',
        (tester) async {
      await pumpMap(
        tester,
        state: CampaignProgressState(
          maxUnlockedLevel: 6,
          completedLessonIds: {1, 2, 3, 4, 5},
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('learning-map-connector-1-2')),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter as LearningMapConnectorPainter;
      expect(painter.completed, isTrue);
      expect(
          tester
              .widget<InkWell>(
                find.byKey(const ValueKey('learning-map-chapter-2')),
              )
              .onTap,
          isNotNull);
    });
  });
}
