import 'package:flutter/material.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/lesson_content_safe_area.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';

class CircuitReadingScreen extends StatefulWidget {
  final int levelId;
  final CircuitReadingLevel level;
  final Function(int)? onLevelUnlocked;
  final bool isCompleted;

  const CircuitReadingScreen({
    super.key,
    required this.levelId,
    required this.level,
    required this.onLevelUnlocked,
    this.isCompleted = false,
  });

  @override
  State<CircuitReadingScreen> createState() => _CircuitReadingScreenState();
}

class _CircuitReadingScreenState extends State<CircuitReadingScreen> {
  int? _selected;
  bool _answered = false;
  late bool _isCompleted;
  late QuantumCircuit _circuit;

  bool get _isCorrect => _selected == widget.level.correctOptionIndex;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
    _circuit = QuantumCircuit(currentLevel: widget.level.toComposerLevel());
  }

  @override
  void dispose() {
    _circuit.dispose();
    super.dispose();
  }

  bool get _usesCanonicalVisualGrammar =>
      const {61, 63, 66, 71}.contains(widget.levelId);

  String _canonicalKey(String role) => widget.levelId == 61
      ? switch (role) {
          'support' => 'm1-supporting-callout',
          'question' => 'm1-activity-question',
          'feedback' => 'm1-answer-feedback',
          'action' => 'm1-primary-action',
          _ => 'm1-$role',
        }
      : 'mastery-circuit-reading-$role-${widget.levelId}';

  void _finish() {
    if (_isCorrect) {
      setState(() {
        _isCompleted = LevelHeaderRouter.isMasteryLevel(widget.levelId)
            ? true
            : _isCompleted;
      });
      widget.onLevelUnlocked?.call(widget.levelId + 1);
    }
    Navigator.of(context).pop(
      _isCorrect
          ? LevelCompletionAction.nextLevel
          : LevelCompletionAction.levelSelect,
    );
  }

  Widget _canonicalCircuit() => QubitQuestPanel(
        key: const ValueKey('circuit-reading-circuit'),
        level: QubitQuestSurfaceLevel.inset,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: widget.level.numQubits * QuantumCircuitPainter.qubitSpacing +
              QuantumCircuitPainter.padding * 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double minW = (_circuit.isCircuitEmpty()
                          ? 2
                          : _circuit.maxCircuitDepth() + 2) *
                      QuantumCircuitPainter.gateSpacing +
                  QuantumCircuitPainter.padding * 2;
              final double w =
                  minW.clamp(constraints.maxWidth, double.infinity);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: w,
                  child: CustomPaint(
                    painter: QuantumCircuitPainter(_circuit),
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _buildCanonicalMastery(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    final horizontalPadding =
        compact ? QubitQuestSpacing.component : QubitQuestSpacing.section;

    return Scaffold(
      backgroundColor: QubitQuestColors.background,
      appBar: LevelHeaderRouter.headerFor(
        level: widget.level,
        levelId: widget.levelId,
        compact: false,
        isCompleted: _isCompleted,
      ),
      body: LessonContentSafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    horizontalPadding,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (widget.level.conceptIntro case final intro?) ...[
                        QubitQuestCallout(
                          key: ValueKey(_canonicalKey('support')),
                          message: intro,
                        ),
                        const SizedBox(height: QubitQuestSpacing.component),
                      ],
                      QubitQuestActivityQuestion(
                        key: ValueKey(_canonicalKey('question')),
                        activityLabel: 'CIRCUIT READING',
                        question: LatexText(
                          math: widget.level.taskDescription,
                          textStyle: QubitQuestTypography.question,
                          inlineMathHeight: 21,
                        ),
                      ),
                      const SizedBox(height: QubitQuestSpacing.component),
                      _canonicalCircuit(),
                      const SizedBox(height: QubitQuestSpacing.section),
                      for (final (idx, option) in widget.level.options.indexed)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: idx + 1 < widget.level.options.length
                                ? QubitQuestSpacing.compact
                                : 0,
                          ),
                          child: QubitQuestChoiceCard(
                            key: ValueKey('circuit-reading-option-$idx'),
                            indexLabel: String.fromCharCode(65 + idx),
                            state: QubitQuestChoiceState.forAnswer(
                              answered: _answered,
                              isSelected: _selected == idx,
                              isCorrect: idx == widget.level.correctOptionIndex,
                            ),
                            onPressed: _answered
                                ? null
                                : () => setState(() => _selected = idx),
                            child: LatexText(
                              math: option,
                              textStyle: QubitQuestTypography.body.copyWith(
                                color: QubitQuestColors.textPrimary,
                                fontSize: 15,
                              ),
                              inlineMathHeight: 16,
                            ),
                          ),
                        ),
                      if (_answered &&
                          widget.level.solutionExplanation != null) ...[
                        const SizedBox(height: QubitQuestSpacing.component),
                        QubitQuestCallout(
                          key: ValueKey(_canonicalKey('feedback')),
                          variant: _isCorrect
                              ? QubitQuestCalloutVariant.success
                              : QubitQuestCalloutVariant.info,
                          message: widget.level.solutionExplanation!,
                        ),
                      ],
                    ]),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          QubitQuestSpacing.component,
                          horizontalPadding,
                          QubitQuestSpacing.component,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: QubitQuestActionButton(
                            key: ValueKey(_canonicalKey('action')),
                            label: _answered
                                ? (_isCorrect ? 'Continue' : 'Back')
                                : 'Confirm',
                            onPressed: _answered
                                ? _finish
                                : _selected == null
                                    ? null
                                    : () => setState(() => _answered = true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usesCanonicalVisualGrammar) {
      return _buildCanonicalMastery(context);
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: LevelHeaderRouter.headerFor(
        level: widget.level,
        levelId: widget.levelId,
        compact: false,
        isCompleted: _isCompleted,
      ),
      body: LessonContentSafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Scrollable content ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Concept intro
                  if (widget.level.conceptIntro != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2E40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF5D5FE6)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF5D5FE6), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.level.conceptIntro!,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text('Read the Circuit',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  LatexText(
                    math: widget.level.taskDescription,
                    textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                    inlineMathHeight: 20,
                  ),
                  const SizedBox(height: 20),

                  // Circuit display (fixed height)
                  Container(
                    key: const ValueKey('circuit-reading-circuit'),
                    height: widget.level.numQubits *
                            QuantumCircuitPainter.qubitSpacing +
                        QuantumCircuitPainter.padding * 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4D4D5C)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double minW = (_circuit.isCircuitEmpty()
                                    ? 2
                                    : _circuit.maxCircuitDepth() + 2) *
                                QuantumCircuitPainter.gateSpacing +
                            QuantumCircuitPainter.padding * 2;
                        final double w =
                            minW.clamp(constraints.maxWidth, double.infinity);
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: w,
                            child: CustomPaint(
                              painter: QuantumCircuitPainter(_circuit),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text('What is the output state?',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),

                  // Options
                  ...List.generate(widget.level.options.length, (idx) {
                    final bool isCorrect =
                        idx == widget.level.correctOptionIndex;
                    final bool isSelected = _selected == idx;

                    Color borderColor = Colors.transparent;
                    Color bgColor = const Color(0xFF2D2E40);
                    Widget? trailing;

                    if (_answered) {
                      if (isCorrect) {
                        borderColor = Colors.green;
                        bgColor = Colors.green.withValues(alpha: 0.15);
                        trailing =
                            const Icon(Icons.check_circle, color: Colors.green);
                      } else if (isSelected) {
                        borderColor = Colors.red;
                        bgColor = Colors.red.withValues(alpha: 0.15);
                        trailing = const Icon(Icons.cancel, color: Colors.red);
                      }
                    } else if (isSelected) {
                      borderColor = const Color(0xFF5D5FE6);
                      bgColor = const Color(0xFF5D5FE6).withValues(alpha: 0.15);
                    }

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom:
                              idx < widget.level.options.length - 1 ? 10 : 0),
                      child: GestureDetector(
                        key: ValueKey('circuit-reading-option-$idx'),
                        onTap: _answered
                            ? null
                            : () => setState(() => _selected = idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${String.fromCharCode(65 + idx)}.  ',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              Expanded(
                                child: LatexText(
                                  math: widget.level.options[idx],
                                  textStyle: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                  inlineMathHeight: 16,
                                ),
                              ),
                              if (trailing != null) trailing,
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Solution explanation
                  if (_answered && widget.level.solutionExplanation != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2E40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        widget.level.solutionExplanation!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14, height: 1.5),
                      ),
                    ),
                ]),
              ),
            ),

            // ── Sticky footer: action button ────────────────────────────────
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _answered
                            ? () {
                                if (_isCorrect) {
                                  setState(() {
                                    _isCompleted =
                                        LevelHeaderRouter.isMasteryLevel(
                                      widget.levelId,
                                    )
                                            ? true
                                            : _isCompleted;
                                  });
                                  widget.onLevelUnlocked
                                      ?.call(widget.levelId + 1);
                                }
                                Navigator.of(context).pop(
                                  _isCorrect
                                      ? LevelCompletionAction.nextLevel
                                      : LevelCompletionAction.levelSelect,
                                );
                              }
                            : _selected == null
                                ? null
                                : () => setState(() => _answered = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _answered
                              ? (_isCorrect ? Colors.green : Colors.orange)
                              : const Color(0xFF5D5FE6),
                          disabledBackgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _answered
                              ? (_isCorrect
                                  ? 'Continue Journey'
                                  : 'Back to Journey')
                              : 'Confirm',
                          style: const TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
