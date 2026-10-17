import 'package:flutter/material.dart';
import 'package:quantumquiz/models/canonical_solution_builder.dart';
import 'package:quantumquiz/models/mastery_2_presentation.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/circuit_preview.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/web_learning_text.dart';
import 'package:quantumquiz/widgets/activity_instruction_presentation.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

class MasteryEvidenceView extends StatelessWidget {
  const MasteryEvidenceView({
    super.key,
    required this.presentation,
    this.includeQuestion = false,
    this.includeInstruction = true,
    this.compactSpacing = false,
    this.webLearning = false,
  });

  final MasteryChallengePresentation presentation;

  /// Web semantic roles; default preserves native presentation.
  final bool webLearning;

  /// Composer instructions share the evidence flow. Choice presenters retain
  /// their existing, separately styled question and interaction.
  final bool includeQuestion;

  /// Web instruction wrappers own this role; standalone consumers still render it.
  final bool includeInstruction;

  /// Keeps sentence-like Composer briefs together without resizing their math
  /// or changing the spacing of existing evidence/choice presentations.
  final bool compactSpacing;

  /// Shared visual scale for ordinary mathematical evidence. Evidence should
  /// support the question rather than compete with its heading.
  static const double normalMathDisplayHeight = 20;
  // A fraction has numerator, rule and denominator: its total viewport must
  // be taller than a single line to keep its glyphs comparable to body text.
  static const double stackedMathDisplayHeight = 44;
  static const double normalMathInlineHeight = 16;

  @override
  Widget build(BuildContext context) {
    final proseGap = !webLearning && compactSpacing
        ? QubitQuestSpacing.micro
        : QubitQuestSpacing.regular;
    final blockGap = !webLearning && compactSpacing
        ? QubitQuestSpacing.micro
        : QubitQuestSpacing.compact;
    return Column(
      key: const ValueKey('mastery-evidence-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeInstruction && presentation.instruction.isNotEmpty)
          ActivityInstructionPresentation(
              task: presentation.instruction, webLearning: webLearning),
        if (presentation.intro case final intro?) ...[
          _authoredText(
            intro,
            key: const ValueKey('mastery-evidence-intro'),
            webRole: webLearning ? WebLearningTextRole.introduction : null,
            style: QubitQuestTypography.body,
          ),
          SizedBox(height: proseGap),
        ],
        for (final (index, block) in presentation.evidence.indexed) ...[
          _MasteryEvidenceBlockView(
              block: block, index: index, webLearning: webLearning),
          if (index + 1 < presentation.evidence.length)
            SizedBox(height: blockGap),
        ],
        if (presentation.helperText case final helper?) ...[
          SizedBox(height: proseGap),
          if (webLearning)
            WebLearningText(helper,
                key: const ValueKey('mastery-evidence-helper'),
                role: WebLearningTextRole.supporting)
          else
            LatexText(
              key: const ValueKey('mastery-evidence-helper'),
              math: _withInlineKetConvention(helper),
              textStyle: QubitQuestTypography.supporting,
              inlineMathColor: QubitQuestColors.textMuted,
              inlineMathHeight: normalMathInlineHeight,
            ),
        ],
        if (includeInstruction &&
            presentation.instructionAfterEvidence.isNotEmpty) ...[
          SizedBox(height: proseGap),
          ActivityInstructionPresentation(
              task: presentation.instructionAfterEvidence,
              webLearning: webLearning),
        ],
        if (includeQuestion && presentation.question.isNotEmpty) ...[
          SizedBox(height: proseGap),
          if (webLearning)
            ActivityInstructionPresentation(
                question: presentation.question,
                webLearning: true,
                questionKey: const ValueKey('mastery-task-instruction'))
          else
            LatexText(
              key: const ValueKey('mastery-task-instruction'),
              math: presentation.question,
              textStyle: QubitQuestTypography.body,
              inlineMathHeight: normalMathInlineHeight,
            ),
        ],
      ],
    );
  }

  static String _withInlineKetConvention(String helper) {
    return helper.replaceAllMapped(
      RegExp(r'\|q([0-9](?: q[0-9])*)⟩'),
      (match) {
        final qubits = match
            .group(1)!
            .split(' q')
            .map((index) => 'q_{$index}')
            .join(r'\,');
        return r'\(\lvert ' + qubits + r'\rangle\)';
      },
    );
  }
}

class _MasteryEvidenceBlockView extends StatelessWidget {
  const _MasteryEvidenceBlockView(
      {required this.block, required this.index, required this.webLearning});

  final MasteryEvidenceBlock block;
  final int index;
  final bool webLearning;

  @override
  Widget build(BuildContext context) {
    final child = switch (block) {
      MasteryMathEvidence math =>
        _MathEvidence(expression: math.expression, webLearning: webLearning),
      MasteryTextEvidence text => _authoredText(
          text.text,
          webRole: webLearning
              ? (text.isInstruction
                  ? WebLearningTextRole.task
                  : WebLearningTextRole.evidence)
              : null,
          style: QubitQuestTypography.body.copyWith(
            color: QubitQuestColors.textPrimary,
          ),
        ),
      MasteryCircuitEvidence circuit => QubitQuestStaticCircuit(
          key: ValueKey('mastery-static-circuit-$index'),
          evidence: circuit,
        ),
      MasteryPipelineEvidence pipeline =>
        _PipelineEvidence(stages: pipeline.stages, webLearning: webLearning),
    };

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (block.label case final label?) ...[
          _authoredText(
            label,
            webRole: webLearning ? WebLearningTextRole.evidenceLabel : null,
            style: QubitQuestTypography.label.copyWith(
              color: QubitQuestColors.accentInteractive,
            ),
          ),
          const SizedBox(height: QubitQuestSpacing.compact),
        ],
        child,
      ],
    );

    // A circuit benefits from a bounded diagram surface. Short equations,
    // labels and case evidence are grouped by rhythm and typography alone.
    if (block is MasteryCircuitEvidence) {
      return QubitQuestPanel(
        key: ValueKey('mastery-evidence-block-$index'),
        level: QubitQuestSurfaceLevel.inset,
        padding: const EdgeInsets.symmetric(
          horizontal: QubitQuestSpacing.regular,
          vertical: QubitQuestSpacing.compact,
        ),
        child: content,
      );
    }

    return KeyedSubtree(
      key: ValueKey('mastery-evidence-block-$index'),
      child: content,
    );
  }
}

/// Only explicitly delimited mathematical spans opt prose/labels into TeX.
Widget _authoredText(String text,
    {required TextStyle style, Key? key, WebLearningTextRole? webRole}) {
  if (webRole != null) return WebLearningText(text, key: key, role: webRole);
  if (text.contains(r'\(') || text.contains(r'\[') || text.contains(r'$')) {
    return LatexText(
      key: key,
      math: text,
      textStyle: style,
      inlineMathHeight: MasteryEvidenceView.normalMathInlineHeight,
    );
  }
  return Text(text, key: key, style: style);
}

class _MathEvidence extends StatelessWidget {
  const _MathEvidence({required this.expression, required this.webLearning});

  final String expression;
  final bool webLearning;

  @override
  Widget build(BuildContext context) {
    final hasStackedFraction = expression.contains(r'\tfrac') ||
        expression.contains(r'\frac') ||
        expression.contains(r'\dfrac');
    // Authored evidence historically uses \tfrac to keep source concise. In a
    // display-evidence role, a full fraction plus a modestly taller viewport
    // keeps numerator/denominator glyphs comparable to ordinary ket evidence.
    final renderedExpression = expression.replaceAll(r'\tfrac', r'\frac');
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const ValueKey('mastery-math-evidence'),
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          key: const ValueKey('mastery-math-centering-region'),
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Align(
            key: const ValueKey('mastery-math-centered-group'),
            alignment: Alignment.center,
            child: LatexText(
              math: renderedExpression,
              minimumDisplayMathScale: webLearning ? 1 : 0,
              mathFontSize: webLearning
                  ? QubitQuestTypography.mathDisplay.fontSize
                  : null,
              textStyle: webLearning
                  ? QubitQuestTypography.mathDisplay
                  : QubitQuestTypography.body.copyWith(
                      color: QubitQuestColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              inlineMathHeight:
                  webLearning ? 18 : MasteryEvidenceView.normalMathInlineHeight,
              displayMathHeight: webLearning
                  ? 18
                  : hasStackedFraction
                      ? MasteryEvidenceView.stackedMathDisplayHeight
                      : MasteryEvidenceView.normalMathDisplayHeight,
            ),
          ),
        ),
      ),
    );
  }
}

class _PipelineEvidence extends StatelessWidget {
  const _PipelineEvidence({required this.stages, required this.webLearning});

  final List<String> stages;
  final bool webLearning;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 460;
        final widgets = <Widget>[];
        for (final (index, stage) in stages.indexed) {
          widgets.add(
            DecoratedBox(
              key: ValueKey('mastery-pipeline-stage-$index'),
              decoration: BoxDecoration(
                color: QubitQuestColors.surfaceRaised,
                borderRadius: QubitQuestRadii.control,
                border: const Border.fromBorderSide(QubitQuestBorders.standard),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QubitQuestSpacing.regular,
                  vertical: QubitQuestSpacing.compact,
                ),
                child: webLearning
                    ? WebLearningText(stage, role: WebLearningTextRole.evidence)
                    : Text(
                        stage,
                        textAlign: TextAlign.center,
                        style: QubitQuestTypography.body.copyWith(
                          color: QubitQuestColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          );
          if (index + 1 < stages.length) {
            widgets.add(
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: vertical ? 0 : QubitQuestSpacing.micro,
                  vertical: vertical ? QubitQuestSpacing.micro : 0,
                ),
                child: Icon(
                  vertical
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_forward_rounded,
                  color: QubitQuestColors.textMuted,
                  size: 18,
                ),
              ),
            );
          }
        }
        return vertical
            ? Column(children: widgets)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widgets,
              );
      },
    );
  }
}

class QubitQuestStaticCircuit extends StatefulWidget {
  const QubitQuestStaticCircuit({
    super.key,
    required this.evidence,
  });

  final MasteryCircuitEvidence evidence;

  @override
  State<QubitQuestStaticCircuit> createState() =>
      _QubitQuestStaticCircuitState();
}

class _QubitQuestStaticCircuitState extends State<QubitQuestStaticCircuit> {
  late QuantumCircuit _circuit;

  @override
  void initState() {
    super.initState();
    _circuit = _buildCircuit();
  }

  @override
  void didUpdateWidget(covariant QubitQuestStaticCircuit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evidence != widget.evidence) {
      _circuit.dispose();
      _circuit = _buildCircuit();
    }
  }

  QuantumCircuit _buildCircuit() {
    final evidence = widget.evidence;
    final gateTypes = evidence.operations.map((step) => step.gateType).toSet();
    final level = ComposerLevel.fromBinaryString(
      taskDescription: evidence.semanticDescription,
      initialQubitsStateString: evidence.initialBasis,
      availableGates: [for (final type in gateTypes) Gate.fromIdentifier(type)],
      solutionFinalVector: const [],
    );
    final circuit = QuantumCircuit(currentLevel: level);
    applyCanonicalCircuitSteps(circuit, evidence.operations);
    return circuit;
  }

  @override
  void dispose() {
    _circuit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      image: true,
      label: widget.evidence.semanticDescription,
      child: ExcludeSemantics(
        child: QubitQuestCircuitPreview(
          circuit: _circuit,
          missingGateColumn: widget.evidence.missingGateColumn,
          missingGateQubit: widget.evidence.missingGateQubit,
          minimumWidth: 220,
          showInitialStateValues: widget.evidence.showInitialValues,
          centerWhenFitted: true,
        ),
      ),
    );
  }
}
