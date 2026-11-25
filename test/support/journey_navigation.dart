import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// v2.6 M5 Journey navigation for tests: select chapter [chapter] (1-based)
/// in the curriculum, then use its primary action (Start / Continue /
/// Review), which opens the lesson the progression rules allow.
Future<void> openJourneyChapter(WidgetTester tester, int chapter) async {
  final row = find.byKey(ValueKey('journey-chapter-$chapter'));
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
  final action = find.byKey(const ValueKey('journey-primary-action'));
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}
