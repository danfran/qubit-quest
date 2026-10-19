import 'package:quantumquiz/models/progression_rules.dart';
import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/lesson_content_safe_area.dart';
import 'package:quantumquiz/widgets/level_header_router.dart';
import 'package:quantumquiz/widgets/qubit_quest_primitives.dart';
import 'package:quantumquiz/widgets/qubit_quest_activity_shell.dart';

class MeasurementLabScreen extends StatefulWidget {
  final NumericActivityDomain activityDomain;
  final int levelId;
  final MeasurementLabLevel level;
  final Function(int)? onLevelUnlocked;
  final bool isCompleted;

  const MeasurementLabScreen({
    super.key,
    required this.levelId,
    this.activityDomain = NumericActivityDomain.journey,
    required this.level,
    required this.onLevelUnlocked,
    this.isCompleted = false,
  });

  @override
  State<MeasurementLabScreen> createState() => _MeasurementLabScreenState();
}

class _MeasurementLabScreenState extends State<MeasurementLabScreen> {
  final Map<String, int> _counts = {};
  int _total = 0;
  final Random _rng = Random();
  late QuantumCircuit _circuit;
  bool _unlocked = false;
  late bool _isCompleted;

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

  /// Performs one probabilistic measurement of the current state vector.
  String _measure() {
    final List<Complex> state = _circuit.currentState.stateVector;
    final double r = _rng.nextDouble();
    double cumulative = 0.0;
    for (int i = 0; i < state.length; i++) {
      cumulative += pow(state[i].magnitude, 2).toDouble();
      if (r <= cumulative) {
        return '|${i.toRadixString(2).padLeft(widget.level.numQubits, '0')}⟩';
      }
    }
    // Fallback (floating point rounding)
    return '|${'0' * widget.level.numQubits}⟩';
  }

  void _onMeasure() {
    final outcome = _measure();
    setState(() {
      _counts[outcome] = (_counts[outcome] ?? 0) + 1;
      _total++;
      if (_total >= widget.level.requiredMeasurements && !_unlocked) {
        _unlocked = true;
        if ((widget.activityDomain ==
            NumericActivityDomain.historicalMastery)) {
          _isCompleted = true;
        }
        widget.onLevelUnlocked?.call(widget.levelId + 1);
      }
    });
  }

  bool get _usesCanonicalVisualGrammar =>
      widget.activityDomain == NumericActivityDomain.historicalMastery &&
      widget.levelId == 69;

  Widget _buildCanonicalMastery(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    final horizontalPadding =
        compact ? QubitQuestSpacing.component : QubitQuestSpacing.section;
    final required = widget.level.requiredMeasurements;
    final progress = (_total / required).clamp(0.0, 1.0);
    final explanation = widget.level.solutionExplanation;

    return QubitQuestActivityShell(
      header: LevelHeaderRouter.headerFor(
        level: widget.level,
        levelId: widget.levelId,
        activityDomain: widget.activityDomain,
        compact: false,
        isCompleted: _isCompleted,
      ),
      bottomAction: Row(
        children: [
          Expanded(
            child: QubitQuestActionButton(
              key: const ValueKey('mastery-measure-action'),
              label: 'Measure',
              icon: Icons.science_outlined,
              role: _unlocked
                  ? QubitQuestActionRole.secondary
                  : QubitQuestActionRole.primary,
              onPressed: _onMeasure,
            ),
          ),
          if (_unlocked) ...[
            const SizedBox(width: QubitQuestSpacing.regular),
            Expanded(
              child: QubitQuestActionButton(
                key: const ValueKey('mastery-measure-continue'),
                label: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: () =>
                    Navigator.of(context).pop(LevelCompletionAction.nextLevel),
              ),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (widget.level.conceptIntro case final intro?) ...[
            QubitQuestCallout(
              key: const ValueKey('mastery-measure-support'),
              variant: QubitQuestCalloutVariant.insight,
              message: intro,
            ),
            const SizedBox(height: QubitQuestSpacing.component),
          ],
          QubitQuestActivityQuestion(
            key: const ValueKey('mastery-measure-question'),
            activityLabel: 'MEASUREMENT',
            question: LatexText(
              math: widget.level.taskDescription,
              textStyle: QubitQuestTypography.question,
              inlineMathHeight: 21,
            ),
          ),
          const SizedBox(height: QubitQuestSpacing.section),
          Row(
            key: const ValueKey('mastery-measure-progress'),
            children: [
              Text(
                'Measurements: $_total / $required',
                style: QubitQuestTypography.supporting,
              ),
              const SizedBox(width: QubitQuestSpacing.regular),
              Expanded(
                child: ClipRRect(
                  borderRadius: QubitQuestRadii.pill,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: QubitQuestColors.surfaceInset,
                    color: _unlocked
                        ? QubitQuestColors.success
                        : QubitQuestColors.accentInteractive,
                  ),
                ),
              ),
              if (_unlocked) ...[
                const SizedBox(width: QubitQuestSpacing.compact),
                const Icon(
                  Icons.check_circle,
                  color: QubitQuestColors.success,
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: QubitQuestSpacing.component),
          QubitQuestPanel(
            key: const ValueKey('mastery-measure-histogram'),
            level: QubitQuestSurfaceLevel.inset,
            child: _counts.isEmpty
                ? SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'Press Measure to start',
                        style: QubitQuestTypography.supporting,
                      ),
                    ),
                  )
                : _buildHistogram(),
          ),
          if (_unlocked && explanation != null) ...[
            const SizedBox(height: QubitQuestSpacing.component),
            QubitQuestCallout(
              key: const ValueKey('mastery-measure-feedback'),
              variant: QubitQuestCalloutVariant.info,
              message: explanation,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usesCanonicalVisualGrammar) return _buildCanonicalMastery(context);
    final int required = widget.level.requiredMeasurements;
    final double progress = (_total / required).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: LevelHeaderRouter.headerFor(
        level: widget.level,
        levelId: widget.levelId,
        activityDomain: widget.activityDomain,
        compact: false,
        isCompleted: _isCompleted,
      ),

      // ── Fixed footer: action buttons ─────────────────────────────────────
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _onMeasure,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Measure', style: TextStyle(fontSize: 17)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D5FE6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_unlocked) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop(LevelCompletionAction.nextLevel),
                    icon: const Icon(Icons.arrow_forward),
                    label:
                        const Text('Continue', style: TextStyle(fontSize: 17)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: LessonContentSafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable header: concept intro + task + progress bar
              // ConstrainedBox gives it a bounded maxHeight so SingleChildScrollView
              // actually scrolls instead of expanding to full content height.
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: constraints.maxHeight * 0.42),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      LatexText(
                        math: widget.level.taskDescription,
                        textStyle: const TextStyle(
                            color: Colors.white, fontSize: 16, height: 1.5),
                        inlineMathHeight: 18,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            'Measurements: $_total / $required',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white12,
                                color: _unlocked
                                    ? Colors.green
                                    : const Color(0xFF5D5FE6),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          if (_unlocked)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ), // ConstrainedBox

              // Histogram + solution explanation — scrollable so explanation
              // never pushes content off-screen after unlock
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _counts.isEmpty
                            ? SizedBox(
                                height: 120,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app,
                                          size: 48, color: Colors.white24),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Press Measure to start',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _buildHistogram(),
                        if (_unlocked &&
                            widget.level.solutionExplanation != null)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2E40),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              widget.level.solutionExplanation!,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ), // Expanded
            ],
          ), // Column
        ), // LayoutBuilder
      ),
    );
  }

  Widget _buildHistogram() {
    // Sort by outcome name for consistent display
    final entries = _counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final int maxCount = entries.map((e) => e.value).fold(0, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final double barFraction = maxCount > 0 ? entry.value / maxCount : 0;
        final double pct = _total > 0 ? entry.value / _total * 100 : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  entry.key,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: barFraction,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D5FE6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
