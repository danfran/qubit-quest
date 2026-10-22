import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/validation/chapter_release_gate.dart';

void main() {
  final chapters = groupedLevels.where((chapter) => !chapter.isMasteryPhase);
  test('release catalogue contains thirteen Journey chapters', () {
    expect(chapters, hasLength(13));
  });
  for (final chapter in chapters) {
    test('release gate: ${chapter.groupName}', () {
      final result = ChapterReleaseGate.validateChapter(chapter);
      expect(result.passed, isTrue, reason: result.toReport());
    });
  }
}
