import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';

void main() {
  List<Map<String, dynamic>> currentRows(
      {List<Map<String, dynamic>>? original}) {
    final rows = <Map<String, dynamic>>[];
    final journeyIds = original == null
        ? [for (var id = 1; id <= 66; id++) id]
        : original
            .where((row) => row['semanticId'] == null)
            .map((row) => int.parse((row['id'] as String).substring(1)))
            .toList();
    for (final id in journeyIds) {
      final l = getJourneyLessonById(id)!;
      rows.add({
        'id': 'J$id',
        'type': l.runtimeType.toString(),
        'title': l.title,
        'task': l.taskDescription,
        'question': l.mysteryTitle,
        'concept': l.conceptIntro,
        'support': l.mysteryText,
        'hints': l.hints,
        'targetLabel': l.targetStateLabel,
        'targetExpression': l.targetStateExpression
      });
    }
    final challenges = original == null
        ? mastery2Catalogue.orderedDefinitions
        : original
            .where((row) => row['semanticId'] != null)
            .map((row) => mastery2Catalogue
                .requireBySemanticId(row['semanticId'] as String))
            .toList();
    for (final c in challenges) {
      final p = requireMasteryPresentation(c.semanticId);
      final l = c.levelDefinition;
      rows.add({
        'id': 'M${c.displayOrder}',
        'semanticId': c.semanticId,
        'type': l.runtimeType.toString(),
        'title': c.title,
        'task': p.instruction,
        'continuation': p.instructionAfterEvidence,
        'question': p.question,
        'intro': p.intro,
        'concept': l.conceptIntro,
        'support': l.mysteryText,
        'helper': p.helperText,
        'hints': l.hints,
        'legacyTask': l.taskDescription,
        'evidence': [
          for (final e in p.evidence)
            {
              'type': e.runtimeType.toString(),
              'label': e.label,
              'content': switch (e) {
                MasteryMathEvidence m => m.expression,
                MasteryTextEvidence t => t.text,
                MasteryCircuitEvidence c => c.semanticDescription,
                MasteryPipelineEvidence p => p.stages
              }
            }
        ]
      });
    }
    return rows;
  }

  String identity(Map<String, dynamic> row) => row['semanticId'] == null
      ? row['id'] as String
      : 'Mastery:${row['semanticId']}';

  test(
      'every frozen original presentation matches by stable identity and order',
      () {
    final expected = (jsonDecode(
            File('test/fixtures/web_learning_catalogue_content.json')
                .readAsStringSync()) as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    expect(expected, hasLength(96));
    expect(expected.where((r) => r['semanticId'] == null), hasLength(60));
    expect(expected.where((r) => r['semanticId'] != null), hasLength(36));
    final live = currentRows(original: expected);
    expect(
        live.where((row) => row['semanticId'] != null).map((row) => row['id']),
        expected
            .where((row) => row['semanticId'] != null)
            .map((row) => row['id']));
    final byIdentity = {for (final row in live) identity(row): row};
    expect(byIdentity.length, live.length,
        reason: 'Duplicate live identities must fail');
    final originalIds = expected.map(identity).toList();
    expect(originalIds.toSet(), hasLength(96));
    for (final original in expected) {
      expect(byIdentity, contains(identity(original)));
      expect(byIdentity[identity(original)], original,
          reason: identity(original));
    }
    expect(
        live.where((row) => originalIds.contains(identity(row))).map(identity),
        originalIds);
  });

  test(
      'current 66 Journey and 42 Mastery presentations are exhaustively represented',
      () {
    expect(journeyLessons, hasLength(66));
    final rows = currentRows();
    expect(mastery2Catalogue.length, 42);
    expect(rows, hasLength(108));
    expect(rows.where((r) => r['semanticId'] == null).map((r) => r['id']),
        [for (var id = 1; id <= 66; id++) 'J$id']);
    expect(
        rows
            .where((r) => r['semanticId'] != null)
            .map((r) => r['semanticId'])
            .toSet(),
        mastery2Presentations.keys.toSet());
    expect(rows.map(identity).toSet(), hasLength(108));
    for (final row in rows) {
      expect(row['title'], isNotEmpty, reason: identity(row));
    }
  });
}
