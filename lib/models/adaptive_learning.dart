import 'package:quantumquiz/models/notebook_entry.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

enum AdaptiveConfusionType {
  repeatedIncorrectGateSequence,
  repeatedMcqConceptMiss,
  oscillatingIncorrectStates,
  repeatedGateOveruse,
  notebookPerformanceMisalignment,
}

enum AdaptiveMisconceptionCategory {
  mechanismMisunderstanding,
  conceptualInterpretation,
  transformationLogic,
  missingConceptualShift,
  notebookIntegrationGap,
}

enum AdaptiveVisualEmphasis {
  none,
  controlRole,
  targetRole,
  phaseLocation,
  transformationDirection,
}

class AdaptiveLearningInsight {
  const AdaptiveLearningInsight({
    required this.confusionType,
    required this.misconceptionCategory,
    required this.notebookReinforcement,
    required this.minimalHint,
    required this.keyInsight,
    this.visualEmphasis = AdaptiveVisualEmphasis.none,
  });

  final AdaptiveConfusionType confusionType;
  final AdaptiveMisconceptionCategory misconceptionCategory;
  final String notebookReinforcement;
  final String minimalHint;
  final String keyInsight;
  final AdaptiveVisualEmphasis visualEmphasis;

  String get confusionLabel {
    return switch (confusionType) {
      AdaptiveConfusionType.repeatedIncorrectGateSequence =>
        'Repeated incorrect gate sequence',
      AdaptiveConfusionType.repeatedMcqConceptMiss =>
        'Repeated concept-check miss',
      AdaptiveConfusionType.oscillatingIncorrectStates =>
        'Oscillation between similar incorrect states',
      AdaptiveConfusionType.repeatedGateOveruse =>
        'Overuse of the same gate without progression',
      AdaptiveConfusionType.notebookPerformanceMisalignment =>
        'Notebook reading and level performance are misaligned',
    };
  }

  String get misconceptionLabel {
    return switch (misconceptionCategory) {
      AdaptiveMisconceptionCategory.mechanismMisunderstanding =>
        'Mechanism misunderstanding',
      AdaptiveMisconceptionCategory.conceptualInterpretation =>
        'Conceptual interpretation',
      AdaptiveMisconceptionCategory.transformationLogic =>
        'Transformation logic',
      AdaptiveMisconceptionCategory.missingConceptualShift =>
        'Missing conceptual shift',
      AdaptiveMisconceptionCategory.notebookIntegrationGap =>
        'Notebook integration gap',
    };
  }
}

class AdaptiveComposerAttempt {
  const AdaptiveComposerAttempt({
    required this.signature,
    required this.gateCounts,
    required this.correct,
  });

  final String signature;
  final Map<SelectedGateType, int> gateCounts;
  final bool correct;
}

class AdaptiveLearningSession {
  AdaptiveLearningSession({
    required this.level,
    this.notebookEntry,
  });

  static const int _repeatedSequenceThreshold = 3;
  static const int _gateOveruseThreshold = 4;
  static const int _notebookMisalignmentThreshold = 3;

  final QQLevel level;
  final NotebookEntry? notebookEntry;

  final List<AdaptiveComposerAttempt> _composerAttempts = [];
  final List<int> _mcqSelections = [];
  bool _notebookOpened = false;

  void recordNotebookOpened() {
    _notebookOpened = true;
  }

  AdaptiveLearningInsight? recordComposerAttempt({
    required String signature,
    required Map<SelectedGateType, int> gateCounts,
    required bool correct,
  }) {
    _composerAttempts.add(
      AdaptiveComposerAttempt(
        signature: signature,
        gateCounts: gateCounts,
        correct: correct,
      ),
    );

    if (correct) return null;

    final repeatedCount = _composerAttempts
        .where((attempt) => !attempt.correct && attempt.signature == signature)
        .length;
    if (repeatedCount >= _repeatedSequenceThreshold) {
      return _insightFor(
        confusionType: AdaptiveConfusionType.repeatedIncorrectGateSequence,
        misconceptionCategory:
            AdaptiveMisconceptionCategory.mechanismMisunderstanding,
        fallbackHint:
            'You are repeating the same circuit shape. Change the mechanism, not just the timing.',
        visualEmphasis: _visualEmphasisForLevel(),
      );
    }

    final maxGateCount = gateCounts.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );
    if (maxGateCount >= _gateOveruseThreshold) {
      return _insightFor(
        confusionType: AdaptiveConfusionType.repeatedGateOveruse,
        misconceptionCategory:
            AdaptiveMisconceptionCategory.missingConceptualShift,
        fallbackHint:
            'Using more of the same gate is not creating a new idea. Look for the gate role the level is testing.',
        visualEmphasis: _visualEmphasisForLevel(),
      );
    }

    if (_isOscillatingBetweenIncorrectAttempts()) {
      return _insightFor(
        confusionType: AdaptiveConfusionType.oscillatingIncorrectStates,
        misconceptionCategory:
            AdaptiveMisconceptionCategory.transformationLogic,
        fallbackHint:
            'Your attempts are switching between two nearby wrong patterns. Track what each gate changes before adding another.',
        visualEmphasis: AdaptiveVisualEmphasis.transformationDirection,
      );
    }

    final incorrectAttempts =
        _composerAttempts.where((attempt) => !attempt.correct).length;
    if (!_notebookOpened &&
        notebookEntry != null &&
        incorrectAttempts >= _notebookMisalignmentThreshold) {
      return _insightFor(
        confusionType: AdaptiveConfusionType.notebookPerformanceMisalignment,
        misconceptionCategory:
            AdaptiveMisconceptionCategory.notebookIntegrationGap,
        fallbackHint:
            'The notebook entry for this discovery is likely relevant now. Review the key idea, then try a different circuit plan.',
        visualEmphasis: _visualEmphasisForLevel(),
      );
    }

    return null;
  }

  AdaptiveLearningInsight? recordMcqAnswer({
    required int selectedIndex,
    required int correctIndex,
  }) {
    _mcqSelections.add(selectedIndex);
    if (selectedIndex == correctIndex) return null;

    final selectedCount =
        _mcqSelections.where((selection) => selection == selectedIndex).length;
    return _insightFor(
      confusionType: selectedCount >= 2
          ? AdaptiveConfusionType.repeatedMcqConceptMiss
          : notebookEntry != null
              ? AdaptiveConfusionType.notebookPerformanceMisalignment
              : AdaptiveConfusionType.repeatedMcqConceptMiss,
      misconceptionCategory:
          AdaptiveMisconceptionCategory.conceptualInterpretation,
      fallbackHint: notebookEntry != null
          ? 'This is a concept check, not a circuit trick. Compare the answer with the notebook idea for this discovery.'
          : 'Return to the supplied evidence and test each claim against what it actually establishes.',
      visualEmphasis: _visualEmphasisForLevel(),
    );
  }

  bool _isOscillatingBetweenIncorrectAttempts() {
    final incorrect = _composerAttempts
        .where((attempt) => !attempt.correct)
        .map((attempt) => attempt.signature)
        .toList(growable: false);
    if (incorrect.length < 4) return false;

    final recent = incorrect.sublist(incorrect.length - 4);
    return recent[0] == recent[2] &&
        recent[1] == recent[3] &&
        recent[0] != recent[1];
  }

  AdaptiveLearningInsight _insightFor({
    required AdaptiveConfusionType confusionType,
    required AdaptiveMisconceptionCategory misconceptionCategory,
    required String fallbackHint,
    required AdaptiveVisualEmphasis visualEmphasis,
  }) {
    final reinforcement = _reinforcementForLevel();
    return AdaptiveLearningInsight(
      confusionType: confusionType,
      misconceptionCategory: misconceptionCategory,
      notebookReinforcement: reinforcement,
      minimalHint: fallbackHint,
      keyInsight: 'Key Insight Revisited',
      visualEmphasis: visualEmphasis,
    );
  }

  String _reinforcementForLevel() {
    final text = [
      level.discoveryTitle,
      level.title,
      notebookEntry?.title,
      notebookEntry?.summary,
    ].whereType<String>().join(' ').toLowerCase();

    if (text.contains('kickback') ||
        text.contains('phase carrier') ||
        text.contains('hidden communication')) {
      return 'Phase Kickback: phase is written by a controlled operation, then revealed later.';
    }
    if (text.contains('ghz') || text.contains('three qubits')) {
      return 'GHZ: reason about the full register, not separate pairs.';
    }
    if (text.contains('interference')) {
      return 'Interference: phase becomes visible only when paths are recombined.';
    }
    if (text.contains('entanglement') || text.contains('bell')) {
      return 'Entanglement: the system cannot be explained as independent qubits.';
    }
    if (notebookEntry != null) {
      return '${notebookEntry!.title}: ${notebookEntry!.summary}';
    }
    return 'Revisit the discovery idea before trying the same pattern again.';
  }

  AdaptiveVisualEmphasis _visualEmphasisForLevel() {
    final text = [
      level.discoveryTitle,
      level.title,
      notebookEntry?.title,
      notebookEntry?.summary,
    ].whereType<String>().join(' ').toLowerCase();

    if (text.contains('kickback') ||
        text.contains('control') ||
        text.contains('phase carrier')) {
      return AdaptiveVisualEmphasis.phaseLocation;
    }
    if (text.contains('transfer') || text.contains('flow')) {
      return AdaptiveVisualEmphasis.transformationDirection;
    }
    return AdaptiveVisualEmphasis.none;
  }
}
