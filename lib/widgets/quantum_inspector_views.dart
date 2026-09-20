import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

enum QuantumInspectorView { state, bloch }

class QuantumInspectorViews extends StatefulWidget {
  const QuantumInspectorViews({
    super.key,
    required this.stateView,
    required this.currentStateVector,
    required this.numQubits,
    required this.contentDriven,
    this.targetStateExpression,
  });

  final Widget stateView;
  final List<Complex> currentStateVector;
  final int numQubits;
  final bool contentDriven;
  final String? targetStateExpression;

  bool get supportsBloch => numQubits == 1 && currentStateVector.length >= 2;

  @override
  State<QuantumInspectorViews> createState() => _QuantumInspectorViewsState();
}

class _QuantumInspectorViewsState extends State<QuantumInspectorViews> {
  QuantumInspectorView _view = QuantumInspectorView.state;

  @override
  void didUpdateWidget(covariant QuantumInspectorViews oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.supportsBloch && _view == QuantumInspectorView.bloch) {
      _view = QuantumInspectorView.state;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _view == QuantumInspectorView.bloch && widget.supportsBloch
        ? _blochView()
        : widget.stateView;
    return Column(
      key: const ValueKey('quantum-inspector-views'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: widget.contentDriven ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<QuantumInspectorView>(
            key: const ValueKey('quantum-inspector-view-selector'),
            segments: [
              const ButtonSegment(
                value: QuantumInspectorView.state,
                label: Text('State'),
                icon: Icon(Icons.data_array_outlined, size: 15),
              ),
              ButtonSegment(
                value: QuantumInspectorView.bloch,
                label: const Text('Bloch'),
                icon: const Icon(Icons.language_outlined, size: 15),
                enabled: widget.supportsBloch,
              ),
            ],
            selected: {_view},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity(horizontal: -2, vertical: -3),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelectionChanged: (selection) {
              setState(() => _view = selection.single);
            },
          ),
        ),
        if (!widget.supportsBloch) ...[
          const SizedBox(height: 6),
          const Text(
            'Bloch view is available for single-qubit states.',
            key: ValueKey('quantum-inspector-bloch-unavailable'),
            style: TextStyle(
              color: QubitQuestColors.textMuted,
              fontSize: 10.5,
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (widget.contentDriven) content else Expanded(child: content),
      ],
    );
  }

  Widget _blochView() {
    final state = BlochState.fromAmplitudes(
      widget.currentStateVector[0],
      widget.currentStateVector[1],
    );
    final rawTarget = widget.targetStateExpression?.trim();
    final target = rawTarget?.isNotEmpty == true
        ? targetStateMathExpression(rawTarget!)
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? math.max(0.0,
                constraints.maxHeight - (target?.isNotEmpty == true ? 48 : 0))
            : 280.0;
        final regionWidth = math.min(360.0, constraints.maxWidth);
        final regionHeight = math.min(280.0, availableHeight);
        return Column(
          key: const ValueKey('quantum-inspector-bloch-view'),
          mainAxisSize:
              widget.contentDriven ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Center(
              child: SizedBox(
                key: const ValueKey('quantum-inspector-bloch-sphere-region'),
                width: regionWidth,
                height: regionHeight,
                child: BlochSpherePanel(
                  state: state,
                  camera: const BlochCamera(zoom: 1.15),
                  interactive: false,
                  reserveOverlaySafeRegions: true,
                  showHelper: false,
                  compactAnnotations: true,
                  overlaySphereFraction: .95,
                  overlaySphereAlignment: const Alignment(0, -.05),
                  onCameraChanged: (_) {},
                  onStatePreview: (_) {},
                  onStateCommitted: (_) {},
                  onGestureStarted: () {},
                  onStateGestureStarted: () => state,
                ),
              ),
            ),
            if (target?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Target',
                    style: TextStyle(
                      color: QubitQuestColors.accentStrong,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: LatexText(
                      key: const ValueKey(
                        'quantum-inspector-bloch-target-reference',
                      ),
                      math: '\$${quantumStateNotationToLatex(target!)}\$',
                      textStyle: const TextStyle(fontSize: 11),
                      inlineMathHeight: 16,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
