import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/notebook_entries.dart';
import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

enum ContentAuditSeverity { info, warning, error }

enum ContentAuditStatus { pass, warning, review }

class ComposerContentFinding {
  final String category;
  final ContentAuditSeverity severity;
  final double confidence;
  final String relevantText;
  final String expectedBehaviour;
  final String suggestedReview;

  const ComposerContentFinding({
    required this.category,
    required this.severity,
    required this.confidence,
    required this.relevantText,
    required this.expectedBehaviour,
    required this.suggestedReview,
  });
}

class ComposerLevelAudit {
  final int id;
  final String title;
  final List<ComposerContentFinding> findings;

  ComposerLevelAudit({
    required this.id,
    required this.title,
    required Iterable<ComposerContentFinding> findings,
  }) : findings = List.unmodifiable(findings);

  ContentAuditStatus get status {
    if (findings
        .any((finding) => finding.severity == ContentAuditSeverity.error)) {
      return ContentAuditStatus.review;
    }
    if (findings.isNotEmpty) return ContentAuditStatus.warning;
    return ContentAuditStatus.pass;
  }
}

class ComposerContentAuditReport {
  final List<ComposerLevelAudit> levels;
  final List<ComposerContentFinding> corpusFindings;

  ComposerContentAuditReport({
    required Iterable<ComposerLevelAudit> levels,
    Iterable<ComposerContentFinding> corpusFindings = const [],
  })  : levels = List.unmodifiable(levels),
        corpusFindings = List.unmodifiable(corpusFindings);

  int get passCount =>
      levels.where((level) => level.status == ContentAuditStatus.pass).length;
  int get warningCount => levels
      .where((level) => level.status == ContentAuditStatus.warning)
      .length;
  int get reviewCount =>
      levels.where((level) => level.status == ContentAuditStatus.review).length;
}

String formatComposerContentAuditReport(ComposerContentAuditReport report) {
  final buffer = StringBuffer()
    ..writeln('Composer Content Audit')
    ..writeln('Composer levels: ${report.levels.length}')
    ..writeln('PASS: ${report.passCount}')
    ..writeln('WARNING: ${report.warningCount}')
    ..writeln('REVIEW: ${report.reviewCount}');

  for (final level in report.levels.where(
    (level) => level.status != ContentAuditStatus.pass,
  )) {
    buffer.writeln(
        '\n${level.id} | ${level.title} | ${level.status.name.toUpperCase()}');
    for (final finding in level.findings) {
      buffer
        ..writeln(
          '- ${finding.severity.name.toUpperCase()} '
          '${finding.category} (${(finding.confidence * 100).round()}%)',
        )
        ..writeln('  Text: ${finding.relevantText}')
        ..writeln('  Expected: ${finding.expectedBehaviour}')
        ..writeln('  Review: ${finding.suggestedReview}');
    }
  }

  if (report.corpusFindings.isNotEmpty) {
    buffer.writeln('\nNotebook / discovery corpus findings:');
    for (final finding in report.corpusFindings) {
      buffer.writeln(
        '- ${finding.severity.name.toUpperCase()} ${finding.category}: '
        '${finding.relevantText}',
      );
    }
  }
  return buffer.toString().trimRight();
}

class ComposerContentAuditor {
  static final _assignmentPattern = RegExp(
    r'\|([01]+)⟩(?:(?!\|[01]+⟩)[^.!?\n]){0,180}?Q(?:ubit\s*)?(\d)\s*=\s*([01])',
    caseSensitive: false,
  );
  static final _cnotTransitionPattern = RegExp(
    r'CNOT\s*\(\s*Q(\d)\s*→\s*Q(\d)\s*\)\s*(?:on\s*)?:?\s*\|([01]+)⟩[^.!?\n]{0,100}?(?:→|=|giving|produces?)\s*\|([01]+)⟩',
    caseSensitive: false,
  );
  static final _xTransitionPattern = RegExp(
    r'X(?:\s+on)?\s+Q(\d)[^.!?\n]{0,60}?\|([01]+)⟩\s*→\s*\|([01]+)⟩',
    caseSensitive: false,
  );
  static final _ccxTopologyPattern = RegExp(
    r'CCX\s*\((?:ctrl:)?\s*Q(\d)\s*[,，]\s*Q(\d)\s*(?:→|;\s*target:)\s*Q(\d)\s*\)',
    caseSensitive: false,
  );

  ComposerContentAuditReport audit(Iterable<QQLevel> activeLevels) {
    final results = <ComposerLevelAudit>[];
    for (final (index, level) in activeLevels.indexed) {
      if (level is! ComposerLevel) continue;
      results.add(auditLevel(index + 1, level));
    }
    final notebookFindings = <ComposerContentFinding>[];
    for (final entry in notebookEntries) {
      for (final text in _notebookSources(entry)) {
        notebookFindings.addAll(_auditAssignments(text));
        notebookFindings.addAll(_auditDirectionalClaims(text));
      }
    }
    return ComposerContentAuditReport(
      levels: results,
      corpusFindings: _deduplicate(notebookFindings),
    );
  }

  ComposerLevelAudit auditLevel(int id, ComposerLevel level) {
    final findings = <ComposerContentFinding>[];
    final sources = _authoredSources(level);
    for (final source in sources) {
      findings.addAll(_auditAssignments(source));
      findings.addAll(_auditDirectionalClaims(source));
      findings.addAll(_auditCnotTransitions(source));
      findings.addAll(_auditXTransitions(source));
    }
    findings.addAll(_auditPreInsertedTopology(level, sources));
    findings.addAll(_auditCanonicalSolution(level));
    return ComposerLevelAudit(
      id: id,
      title: level.title ?? 'Untitled Composer level',
      findings: _deduplicate(findings),
    );
  }

  List<String> _authoredSources(ComposerLevel level) => [
        level.taskDescription,
        if (level.conceptIntro != null) level.conceptIntro!,
        ...?level.hints,
        if (level.solutionExplanation != null) level.solutionExplanation!,
        if (level.discoveryText != null) level.discoveryText!,
        if (level.keyInsight != null) level.keyInsight!,
        if (level.whyItMatters != null) level.whyItMatters!,
        if (level.nextMystery != null) level.nextMystery!,
      ];

  List<String> _notebookSources(NotebookEntry entry) => [
        entry.summary,
        ..._sectionSources(entry.intuition),
        ..._sectionSources(entry.whatChanged),
        ..._sectionSources(entry.quantumView),
        ..._sectionSources(entry.advancedNotes),
      ];

  List<String> _sectionSources(NotebookSection? section) => [
        if (section != null) section.body,
        if (section != null)
          for (final example in section.examples) ...[
            example.notation,
            if (example.explanation != null) example.explanation!,
          ],
      ];

  Iterable<ComposerContentFinding> _auditDirectionalClaims(String text) sync* {
    final claims = <({int qubit, String direction, String text})>[];
    for (final match in RegExp(
      r'Q(\d)[^.!?\n]{0,60}?\b(leftmost|rightmost|least significant|most significant)\b',
      caseSensitive: false,
    ).allMatches(text)) {
      claims.add((
        qubit: int.parse(match.group(1)!),
        direction: match.group(2)!.toLowerCase(),
        text: match.group(0)!,
      ));
    }
    for (final claim in claims) {
      final mustBeQ0 = claim.direction == 'rightmost' ||
          claim.direction == 'least significant';
      final contradicts = mustBeQ0 ? claim.qubit != 0 : claim.qubit == 0;
      if (contradicts) {
        yield ComposerContentFinding(
          category: 'directional-qubit-order',
          severity: ContentAuditSeverity.error,
          confidence: 0.98,
          relevantText: claim.text,
          expectedBehaviour:
              'Q0 is the rightmost/least-significant ket bit; the leftmost bit is the highest-numbered qubit.',
          suggestedReview:
              'Correct the directional claim using docs/qubit_ordering.md.',
        );
      }
    }
  }

  Iterable<ComposerContentFinding> _auditAssignments(String text) sync* {
    for (final match in _assignmentPattern.allMatches(text)) {
      final afterKet = text.substring(match.start + match.group(1)!.length + 2,
          text.indexOf('Q', match.start));
      // A ket embedded in a superposition can be followed by prose about the
      // whole expression. Only treat it as a named assignment when the ket is
      // followed by explicit assignment punctuation/wording, not algebra.
      if (afterKet.trimLeft().startsWith(')')) continue;
      final ket = match.group(1)!;
      final qubit = int.parse(match.group(2)!);
      final claimed = int.parse(match.group(3)!);
      if (qubit >= ket.length) continue;
      final expected = int.parse(ket[ket.length - 1 - qubit]);
      if (claimed != expected) {
        yield ComposerContentFinding(
          category: 'qubit-order',
          severity: ContentAuditSeverity.error,
          confidence: 1,
          relevantText: match.group(0)!,
          expectedBehaviour:
              '|$ket⟩ is |Q${ket.length - 1}...Q0⟩, so Q$qubit=$expected.',
          suggestedReview:
              'Correct the named qubit value using docs/qubit_ordering.md.',
        );
      }
    }
  }

  Iterable<ComposerContentFinding> _auditCnotTransitions(String text) sync* {
    for (final match in _cnotTransitionPattern.allMatches(text)) {
      final control = int.parse(match.group(1)!);
      final target = int.parse(match.group(2)!);
      final input = match.group(3)!;
      final claimed = match.group(4)!;
      if (control >= input.length ||
          target >= input.length ||
          control == target) {
        continue;
      }
      final expected = _applyControlledX(input, [control], target);
      if (claimed != expected) {
        yield ComposerContentFinding(
          category: 'controlled-transition',
          severity: ContentAuditSeverity.error,
          confidence: 1,
          relevantText: match.group(0)!,
          expectedBehaviour:
              'CNOT(Q$control→Q$target)|$input⟩ produces |$expected⟩, not |$claimed⟩.',
          suggestedReview:
              'Review the named control, target and intermediate ket.',
        );
      }
    }
  }

  Iterable<ComposerContentFinding> _auditXTransitions(String text) sync* {
    for (final match in _xTransitionPattern.allMatches(text)) {
      final qubit = int.parse(match.group(1)!);
      final input = match.group(2)!;
      final claimed = match.group(3)!;
      if (qubit >= input.length) continue;
      final expected = _flipBit(input, qubit);
      if (claimed != expected) {
        yield ComposerContentFinding(
          category: 'single-gate-transition',
          severity: ContentAuditSeverity.error,
          confidence: 1,
          relevantText: match.group(0)!,
          expectedBehaviour:
              'X(Q$qubit)|$input⟩ produces |$expected⟩, not |$claimed⟩.',
          suggestedReview: 'Review the named qubit and intermediate ket.',
        );
      }
    }
  }

  Iterable<ComposerContentFinding> _auditPreInsertedTopology(
    ComposerLevel level,
    List<String> sources,
  ) sync* {
    if (level.preInsertedGates == null) return;
    final circuit = QuantumCircuit(currentLevel: level);
    final fixedControlled = circuit.logicalGates
        .where((gate) => !gate.isDeletable && !gate.isSingleQubit)
        .toList();
    if (fixedControlled.isEmpty) return;

    for (final source in sources) {
      for (final match in _ccxTopologyPattern.allMatches(source)) {
        final describedControls = {
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
        };
        final describedTarget = int.parse(match.group(3)!);
        final agrees = fixedControlled.any((gate) =>
            gate.type == SelectedGateType.ccnot &&
            {gate.controlQubit, gate.secondControlQubit}
                .whereType<int>()
                .toSet()
                .containsAll(describedControls) &&
            gate.targetQubit == describedTarget);
        if (!agrees) {
          final actual = fixedControlled.first;
          yield ComposerContentFinding(
            category: 'pre-inserted-topology',
            severity: ContentAuditSeverity.error,
            confidence: 0.98,
            relevantText: match.group(0)!,
            expectedBehaviour:
                'The fixed runtime ${actual.type.name} has controls '
                'Q${actual.controlQubit},Q${actual.secondControlQubit} and '
                'target Q${actual.targetQubit}.',
            suggestedReview:
                'Reconcile the authored topology with the fixed circuit callback.',
          );
        }
      }
    }
  }

  Iterable<ComposerContentFinding> _auditCanonicalSolution(
      ComposerLevel level) sync* {
    if (level.canonicalSolution == null) return;
    try {
      final circuit = buildCanonicalSolutionCircuit(level);
      if (!level.validateCircuit(circuit)) {
        yield const ComposerContentFinding(
          category: 'canonical-validation',
          severity: ContentAuditSeverity.error,
          confidence: 1,
          relevantText: 'Canonical solution metadata',
          expectedBehaviour:
              'The canonical circuit must pass production validation.',
          suggestedReview:
              'Review canonical steps against authored intent and target metadata.',
        );
      }
    } on Object catch (error) {
      yield ComposerContentFinding(
        category: 'canonical-build',
        severity: ContentAuditSeverity.error,
        confidence: 1,
        relevantText: 'Canonical solution metadata',
        expectedBehaviour: 'Canonical construction must succeed: $error',
        suggestedReview:
            'Correct invalid canonical metadata; do not weaken validation.',
      );
    }
  }

  String _applyControlledX(String ket, List<int> controls, int target) {
    final fires = controls.every((qubit) => ket[ket.length - 1 - qubit] == '1');
    return fires ? _flipBit(ket, target) : ket;
  }

  String _flipBit(String ket, int qubit) {
    final bits = ket.split('');
    final position = ket.length - 1 - qubit;
    bits[position] = bits[position] == '0' ? '1' : '0';
    return bits.join();
  }

  List<ComposerContentFinding> _deduplicate(
      List<ComposerContentFinding> findings) {
    final seen = <String>{};
    return findings
        .where((finding) => seen.add(
            '${finding.category}|${finding.relevantText}|${finding.expectedBehaviour}'))
        .toList(growable: false);
  }
}
