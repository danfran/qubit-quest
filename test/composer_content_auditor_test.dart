import 'package:flutter_test/flutter_test.dart';
import 'package:quantumquiz/models/composer_content_auditor.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/qq_levels.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

void main() {
  late ComposerContentAuditReport report;
  late Map<int, ComposerLevelAudit> byId;

  setUpAll(() {
    report = ComposerContentAuditor().audit(allQQLevels);
    final historicalReport = ComposerContentAuditor().audit([
      ...journeyLessons.take(60),
      ...historicalMasteryActivities,
    ]);
    byId = {for (final level in historicalReport.levels) level.id: level};
  });

  group('Composer Content Auditor historical regressions', () {
    test('emits the permanent structured authoring report', () {
      final formatted = formatComposerContentAuditReport(report);
      // This focused Flutter test is the authoring-tool entry point used by CI.
      // ignore: avoid_print
      print(formatted);
      expect(formatted, contains('Composer levels: ${report.levels.length}'));

      const strict = bool.fromEnvironment('CONTENT_AUDIT_STRICT');
      if (strict) {
        expect(
          report.reviewCount,
          0,
          reason: 'Strict content audit requires every ERROR to be reviewed.',
        );
      }
    });

    test('audits every active Composer level without a maintained ID list', () {
      expect(
        report.levels.length,
        allQQLevels.whereType<ComposerLevel>().length,
      );
      expect(report.levels, everyElement(isA<ComposerLevelAudit>()));
    });

    test('corrected ID 74 remains clear of historical findings', () {
      expect(byId[74]!.title, 'CNOT Gate');
      expect(byId[74]!.status, ContentAuditStatus.pass);
    });

    for (final id in [22, 75, 76, 77, 79, 80, 81, 90, 93]) {
      test('corrected historical level $id remains PASS', () {
        expect(byId[id]!.status, ContentAuditStatus.pass);
        expect(byId[id]!.findings, isEmpty);
      });
    }

    test('the corrected corpus has no remaining deterministic findings', () {
      expect(report.passCount, report.levels.length);
      expect(report.warningCount, 0);
      expect(report.reviewCount, 0);
      expect(report.corpusFindings, isEmpty);
    });

    test('canonical levels build and validate through production paths', () {
      for (final level in report.levels.where(
        (result) =>
            (allQQLevels[result.id - 1] as ComposerLevel).canonicalSolution !=
            null,
      )) {
        expect(
          level.findings.where((finding) =>
              finding.category == 'canonical-build' ||
              finding.category == 'canonical-validation'),
          isEmpty,
          reason: '${level.id} ${level.title}',
        );
      }
    });
  });

  group('deterministic text rules', () {
    ComposerLevel fixture({
      required String hint,
      String initial = '00',
    }) =>
        ComposerLevel.fromBinaryString(
          title: 'Audit fixture',
          taskDescription: 'Audit explicit statements.',
          hints: [hint],
          initialQubitsStateString: initial,
          availableGates: [Gate.fromIdentifier(SelectedGateType.cnot)],
          solutionFinalVector: ComposerLevel.getZeroStateVector(initial.length)
              .map((value) => [value])
              .toList(),
        );

    test('flags an explicit wrong ket-to-qubit assignment', () {
      final result = ComposerContentAuditor().auditLevel(
        1,
        fixture(hint: 'In |10⟩, Q0=1 and Q1=0.'),
      );
      expect(result.status, ContentAuditStatus.review);
      expect(result.findings.first.category, 'qubit-order');
    });

    test('accepts an explicit correct ket-to-qubit assignment', () {
      final result = ComposerContentAuditor().auditLevel(
        1,
        fixture(hint: 'In |10⟩, Q1=1 and Q0=0.'),
      );
      expect(result.status, ContentAuditStatus.pass);
    });

    test('flags a demonstrably wrong CNOT intermediate state', () {
      final result = ComposerContentAuditor().auditLevel(
        1,
        fixture(hint: 'CNOT(Q0→Q1) on |11⟩ produces |10⟩.'),
      );
      expect(
        result.findings.map((finding) => finding.category),
        contains('controlled-transition'),
      );
    });

    test('flags a demonstrably wrong X intermediate state', () {
      final result = ComposerContentAuditor().auditLevel(
        1,
        fixture(initial: '010', hint: 'X on Q0: |010⟩ → |110⟩.'),
      );
      expect(
        result.findings.map((finding) => finding.category),
        contains('single-gate-transition'),
      );
    });

    test('does not guess when prose lacks an explicit checkable claim', () {
      final result = ComposerContentAuditor().auditLevel(
        1,
        fixture(hint: 'Think carefully about the control and target.'),
      );
      expect(result.status, ContentAuditStatus.pass);
    });
  });
}
