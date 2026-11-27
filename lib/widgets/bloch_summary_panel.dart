import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/models/bloch_lab.dart' show blochAngle, blochNumber;
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/qq_scientific_primitives.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';

/// The embedded Bloch sphere of the Composer analysis (v2.6 M11C.1): a
/// geometric summary of the current one-qubit state, not the Bloch
/// Explorer laboratory.
///
/// The sphere is drawn without floating numeric overlays; its coordinates
/// sit in a structured readout below it. Probabilities are not repeated
/// (the Probabilities component owns them). The camera can be orbited and
/// is kept by the host across rebuilds. The state is read-only here.
class QqBlochSummaryPanel extends StatelessWidget {
  const QqBlochSummaryPanel({
    super.key,
    required this.alpha,
    required this.beta,
    required this.camera,
    required this.onCameraChanged,
    this.caption,
    this.note,
    this.selector,
    this.onOpenExplorer,
  });

  final Complex alpha;
  final Complex beta;
  final BlochCamera camera;
  final ValueChanged<BlochCamera> onCameraChanged;

  /// Which state is drawn when it is not simply the current one
  /// ("Before measurement", "After the single run (outcome 1)").
  final String? caption;
  final String? note;

  /// Optional control choosing the drawn state (before / after a run).
  final Widget? selector;

  /// Opens this circuit in the Bloch Explorer; null hides the action.
  final VoidCallback? onOpenExplorer;

  @override
  Widget build(BuildContext context) {
    final state = BlochState.fromAmplitudes(alpha, beta);
    final open = onOpenExplorer == null
        ? null
        : TextButton.icon(
            key: const ValueKey('composer-explore-in-bloch'),
            onPressed: onOpenExplorer,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open in Bloch Explorer'),
            style: TextButton.styleFrom(
              textStyle: QqType.control.copyWith(fontSize: 13.5),
              visualDensity: VisualDensity.compact,
            ),
          );
    return QqWorkspacePanel(
      label: 'Bloch sphere',
      child: Column(
        key: const ValueKey('quantum-inspector-bloch-view'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selector case final s?) ...[
            Align(alignment: Alignment.centerLeft, child: s),
            const SizedBox(height: 8),
          ],
          if (caption case final c?) ...[
            Text(c,
                key: const ValueKey('quantum-inspector-bloch-caption'),
                style: QqType.subheading),
            if (note case final text?)
              QqMeta(text, key: const ValueKey('quantum-inspector-bloch-note')),
            const SizedBox(height: 8),
          ],
          LayoutBuilder(builder: (context, constraints) {
            final side = constraints.maxWidth.clamp(160.0, 280.0);
            return Center(
              child: SizedBox(
                key: const ValueKey('quantum-inspector-bloch-sphere-region'),
                width: side,
                height: side,
                child: BlochSpherePanel(
                  state: state,
                  camera: camera,
                  showAnnotations: false,
                  showStateLabels: true,
                  allowStateEditing: false,
                  onCameraChanged: onCameraChanged,
                  onStatePreview: (_) {},
                  onStateCommitted: (_) {},
                  onGestureStarted: () {},
                  onStateGestureStarted: () => state,
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Divider(height: 1, color: QubitQuestSurfaces.rule),
          const SizedBox(height: 12),
          Semantics(
            label:
                'Bloch coordinates: polar angle θ ${blochAngle(state.theta)}, '
                'azimuth φ ${_atPole(state) ? 'undefined' : blochAngle(state.phi)}, vector x '
                '${blochNumber(state.x, digits: 3)}, y '
                '${blochNumber(state.y, digits: 3)}, z '
                '${blochNumber(state.z, digits: 3)}',
            excludeSemantics: true,
            child: QqFactList(
              key: const ValueKey('composer-bloch-readout'),
              labelWidth: 92,
              facts: [
                ('Polar θ', Text(blochAngle(state.theta))),
                (
                  'Azimuth φ',
                  // At a pole every φ names the same point.
                  Text(_atPole(state)
                      ? 'undefined at the pole'
                      : blochAngle(state.phi)),
                ),
                (
                  '(x, y, z)',
                  Text('(${blochNumber(state.x, digits: 3)}, '
                      '${blochNumber(state.y, digits: 3)}, '
                      '${blochNumber(state.z, digits: 3)})'),
                ),
              ],
            ),
          ),
          if (open != null) ...[
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: open),
          ],
        ],
      ),
    );
  }
}

bool _atPole(BlochState state) =>
    state.theta.abs() < 1e-9 || (state.theta - 3.141592653589793).abs() < 1e-9;
