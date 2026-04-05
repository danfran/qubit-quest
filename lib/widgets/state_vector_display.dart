import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/utils/complex_formatter.dart';


class StateVectorDisplay extends StatefulWidget {
  final List<Complex> stateVector;
  /// Optional target/solution state vector for side-by-side comparison.
  /// When null the widget behaves exactly as before.
  final List<Complex>? targetStateVector;
  final int numQubits;

  const StateVectorDisplay({
    super.key,
    required this.stateVector,
    required this.numQubits,
    this.targetStateVector,
  });

  @override
  State<StateVectorDisplay> createState() => _StateVectorDisplayState();
}

class _StateVectorDisplayState extends State<StateVectorDisplay> {
  bool _showAllValues = false;
  static const double _emptyThreshold = 1e-9;
  static const double _matchTolerance = 1e-6;

  late ScrollController _stateVectorVerticalScrollController;

  @override
  void initState() {
    super.initState();
    _stateVectorVerticalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _stateVectorVerticalScrollController.dispose();
    super.dispose();
  }

  String _toBinaryKet(int index, int numQubits) {
    String binary = index.toRadixString(2);
    return '|${binary.padLeft(numQubits, '0')}⟩';
  }

  bool _complexClose(Complex a, Complex b) {
    return (a.real - b.real).abs() < _matchTolerance &&
        (a.imaginary - b.imaginary).abs() < _matchTolerance;
  }

  @override
  Widget build(BuildContext context) {
    final int vectorSize = 1 << widget.numQubits;
    final bool hasTarget = widget.targetStateVector != null &&
        widget.targetStateVector!.length == vectorSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hasTarget ? 'State  (now → target)' : 'State Vector:',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('All',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _showAllValues,
                    onChanged: (v) => setState(() => _showAllValues = v),
                    activeColor: Colors.blueAccent,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Scrollable list ───────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Scrollbar(
                controller: _stateVectorVerticalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _stateVectorVerticalScrollController,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(vectorSize, (index) {
                        final Complex current = widget.stateVector[index];
                        final Complex? target = hasTarget
                            ? widget.targetStateVector![index]
                            : null;

                        final bool currentNonZero =
                            current.magnitude > _emptyThreshold;
                        final bool targetNonZero = target != null &&
                            target.magnitude > _emptyThreshold;

                        // Hide when all values zero (unless Show All)
                        if (!_showAllValues &&
                            !currentNonZero &&
                            !targetNonZero) {
                          return const SizedBox.shrink();
                        }

                        final String ket =
                            _toBinaryKet(index, widget.numQubits);

                        if (!hasTarget) {
                          // ── Simple single-column display (no target) ────────
                          if (!_showAllValues &&
                              current.magnitude < _emptyThreshold) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 1.0),
                            child: Text(
                              '$ket: ${formatComplex(current)}',
                              style: TextStyle(
                                color: currentNonZero
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        // ── Two-line comparison display ─────────────────────
                        // Line 1: |ket⟩: current_amplitude
                        // Line 2: (indented) → target_amplitude [✓]
                        final bool matched = _complexClose(current, target!);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Line 1 — current state
                              Text(
                                '$ket: ${formatComplex(current)}',
                                style: TextStyle(
                                  color: currentNonZero
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              // Line 2 — target state
                              Row(
                                children: [
                                  const SizedBox(width: 12),
                                  Text(
                                    '→ ${formatComplex(target)}',
                                    style: TextStyle(
                                      color: targetNonZero
                                          ? const Color(0xFF64B5F6)
                                          : Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (matched) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF66BB6A), size: 12),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}