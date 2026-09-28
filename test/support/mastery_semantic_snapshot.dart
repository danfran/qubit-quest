import 'package:advance_math/advance_math.dart';
import 'package:quantumquiz/models/mastery_challenge_catalogue.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';

/// Only formatting equivalences used by this pass; keeps symbols, signs,
/// numbers, words and their order. This is not a quantum expression evaluator.
String normalizeMasteryNotation(String text) {
  var value = text
      .replaceAllMapped(
        RegExp(r'\\frac\{([^{}]*)\}\{\\sqrt\{2\}\}'),
        (m) => '(${m[1]})/√2',
      )
      .replaceAllMapped(
        RegExp(r'\\frac\{([^{}]*)\}\{([^{}]*)\}'),
        (m) => '${m[1]}/${m[2]}',
      );
  for (final delimiter in [r'\(', r'\)', r'\[', r'\]', r'\bigl', r'\bigr']) {
    value = value.replaceAll(delimiter, '');
  }
  return value
      .replaceAll(r'\rangle', '⟩')
      .replaceAll(r'\Phi', 'Φ')
      .replaceAll('−', '-')
      .replaceAll(RegExp(r'[\s^{}]'), '');
}

List<Map<String, Object?>> masterySemanticSnapshot(
    MasteryChallengeCatalogue catalogue) {
  List<num> complex(Complex c) => [c.real, c.imaginary];
  Object? matrix(List<List<Complex>>? value) =>
      value?.map((row) => row.map(complex).toList()).toList();
  return [
    for (final d in catalogue.orderedDefinitions)
      (() {
        final level = d.levelDefinition;
        final result = <String, Object?>{
          'semanticId': d.semanticId,
          'displayOrder': d.displayOrder,
          'title': d.title,
          'contentVersion': d.contentVersion,
          'difficulty': d.difficulty.name,
          'conceptTags': d.conceptTags.map((t) => t.name).toList()..sort(),
          'interactionType': d.interactionType.name,
          'runtimeType': level.runtimeType.toString(),
          'targetStateExpression': level.targetStateExpression,
          'targetStateLabel': level.targetStateLabel,
          'hints': level.hints,
          'solutionExplanation': level.solutionExplanation,
        };
        if (level is McqLevel) {
          result['options'] =
              level.options.map(normalizeMasteryNotation).toList();
          result['correctOptionIndex'] = level.correctOptionIndex;
        }
        if (level is ComposerLevel) {
          final circuit = QuantumCircuit(currentLevel: level);
          result.addAll({
            'numQubits': level.numQubits,
            'initialState': level.initialQubitsState.map(complex).toList(),
            'initialLabel': level.initialQubitsStateStr,
            'allowedGates': level.availableGates
                .map((g) => [g.type.name, g.angle])
                .toList(),
            'targetVector': matrix(level.solutionFinalVector),
            'targetUnitary': matrix(level.targetUnitary),
            'alternateTargets':
                level.alternateTargetUnitaries.map(matrix).toList(),
            'validationMode': level.validationMode.name,
            'canonicalSolution': level.canonicalSolution?.steps
                .map((s) => [
                      s.gateType.name,
                      s.targetQubit,
                      s.controlQubit,
                      s.secondControlQubit,
                      s.angle
                    ])
                .toList(),
            'fixedGates': circuit.logicalGates
                .map((g) => [
                      g.type.name,
                      g.column,
                      g.anchor.qubit,
                      g.controlQubit,
                      g.targetQubit,
                      g.secondControlQubit,
                      g.isDeletable
                    ])
                .toList(),
            'preparedState':
                circuit.currentState.stateVector.map(complex).toList(),
          });
          circuit.dispose();
        }
        return result;
      })()
  ];
}
