import 'package:flutter/material.dart';
import 'package:quantumquiz/models/level_completion_action.dart';
import 'package:quantumquiz/models/qq_level.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

class FillTheGateScreen extends StatefulWidget {
  final int levelId;
  final FillTheGateLevel level;
  final Function(int)? onLevelUnlocked;

  const FillTheGateScreen({
    super.key,
    required this.levelId,
    required this.level,
    required this.onLevelUnlocked,
  });

  @override
  State<FillTheGateScreen> createState() => _FillTheGateScreenState();
}

class _FillTheGateScreenState extends State<FillTheGateScreen> {
  int? _selectedIndex;
  bool _answered = false;
  bool _correct = false;

  /// Simulate the circuit with the chosen gate and compare to the solution.
  bool _checkAnswer(Gate gate) {
    final composerLevel = widget.level.toComposerLevelWith(gate);
    final circuit = QuantumCircuit(currentLevel: composerLevel);
    final bool match =
        circuit.currentState.state.almostEqualTo(QuantumMatrix(widget.level.solutionFinalVector));
    circuit.dispose();
    return match;
  }

  void _onOptionSelected(int idx, Gate gate) {
    if (_answered) return;
    final bool correct = _checkAnswer(gate);
    setState(() {
      _selectedIndex = idx;
      _answered = true;
      _correct = correct;
    });
    if (correct) {
      widget.onLevelUnlocked?.call(widget.levelId + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.extension_outlined, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'Level ${widget.levelId}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      const Icon(Icons.info_outline, color: Color(0xFF5D5FE6), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.level.conceptIntro!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text('Fill the Gate',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 13, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(
                widget.level.taskDescription,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 28),

              // Circuit visual (text-based schematic)
              _buildCircuitSchematic(),
              const SizedBox(height: 28),

              const Text(
                'Choose the missing gate:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),

              // Gate options grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.level.options.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final Gate gate = entry.value;
                  final bool isSelected = _selectedIndex == idx;
                  final bool isCorrectGate =
                      gate.type == widget.level.correctGate.type;

                  Color borderColor = Colors.transparent;
                  Color bgColor = gate.color.withOpacity(0.85);

                  if (_answered) {
                    if (isCorrectGate) {
                      borderColor = Colors.green;
                      bgColor = Colors.green.withOpacity(0.3);
                    } else if (isSelected) {
                      borderColor = Colors.red;
                      bgColor = Colors.red.withOpacity(0.2);
                    } else {
                      bgColor = gate.color.withOpacity(0.3);
                    }
                  } else if (isSelected) {
                    borderColor = Colors.white;
                  }

                  return GestureDetector(
                    onTap: _answered ? null : () => _onOptionSelected(idx, gate),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          gate.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // Feedback
              if (_answered) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _correct
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _correct ? Colors.green : Colors.red,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _correct ? Icons.check_circle : Icons.cancel,
                        color: _correct ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _correct
                              ? 'Correct! ${widget.level.solutionExplanation ?? ''}'
                              : 'Not quite — the correct gate is ${widget.level.correctGate.label}. '
                                  '${widget.level.solutionExplanation ?? ''}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _correct
                            ? LevelCompletionAction.nextLevel
                            : LevelCompletionAction.levelSelect,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _correct ? Colors.green : Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _correct ? 'Next Level →' : 'Back to Level Select',
                      style: const TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a simple text schematic of the circuit showing the blank slot.
  Widget _buildCircuitSchematic() {
    // Build a temporary circuit to inspect what pre-built gates look like
    final tempLevel = ComposerLevel.fromBinaryString(
      taskDescription: widget.level.taskDescription,
      initialQubitsStateString: widget.level.initialQubitsStateString,
      availableGates: const [],
      solutionFinalVector: const [],
      preInsertedGates: widget.level.preBuiltGates,
    );
    final circuit = QuantumCircuit(currentLevel: tempLevel);

    final List<String> qubitRows = [];
    for (int q = 0; q < widget.level.numQubits; q++) {
      final StringBuffer row = StringBuffer();
      row.write('|${widget.level.initialQubitsStateString[q]}⟩ ─── ');

      final int depth = circuit.isCircuitEmpty()
          ? 0
          : circuit.placedGates[q].length;
      for (int pos = 0; pos < depth; pos++) {
        final gate = circuit.placedGates[q][pos];
        if (gate.gate.type == SelectedGateType.none) {
          row.write('─── ');
        } else {
          row.write('[${gate.gate.label}] ─── ');
        }
      }
      row.write('[?] ───');
      qubitRows.add(row.toString());
    }

    circuit.dispose();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D4D5C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: qubitRows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  row,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}



