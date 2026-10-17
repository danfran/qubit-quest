import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/mastery_2_catalogue.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';

void main() {
  test('all 96 authored presentation sources remain unchanged', () {
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < 60; i++) {
      final l = getQQLevelById(i + 1)!;
      rows.add({
        'id': 'J${i + 1}',
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
    for (final c in mastery2Catalogue.orderedDefinitions) {
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
    expect(
        rows,
        jsonDecode(File('test/fixtures/web_learning_catalogue_content.json')
            .readAsStringSync()));
    expect(rows.length, 96);
  });
}
