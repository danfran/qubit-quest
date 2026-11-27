import 'dart:math' as math;

import 'package:advance_math/advance_math.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/bloch_explorer_model.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/quantum_state_formatter.dart';
import 'package:quantumquiz/widgets/bloch_sphere_panel.dart';
import 'package:quantumquiz/widgets/latex_text.dart';

enum QuantumInspectorView { state, bloch, measure }

/// Presentation state owned by the workbench, independently of Inspector elements.
class QuantumInspectorSelection {
  QuantumInspectorView selected = QuantumInspectorView.state;

  /// The learner's Bloch camera (rotation and zoom). Kept here, beside the
  /// selected view, so a responsive relayout that rebuilds the inspector
  /// never resets an orbit the learner made (v2.6 M6a).
  BlochCamera camera = defaultCamera;

  static const BlochCamera defaultCamera = BlochCamera(zoom: 1.15);

  void reconcile({required bool supportsBloch, required bool supportsMeasure}) {
    if ((selected == QuantumInspectorView.bloch && !supportsBloch) ||
        (selected == QuantumInspectorView.measure && !supportsMeasure)) {
      selected = QuantumInspectorView.state;
    }
  }
}

class QuantumInspectorViews extends StatefulWidget {
  const QuantumInspectorViews({
    super.key,
    required this.stateView,
    required this.currentStateVector,
    required this.numQubits,
    this.allowBloch = true,
    this.blochCaption,
    this.blochNote,
    this.blochUnavailableMessage,
    this.blochHeader,
    this.keepBlochTabSelectable = false,
    required this.contentDriven,
    this.targetStateExpression,
    this.measureView,
    this.selection,
    this.compactTabs = false,
    this.fitTabsToWidth = false,
    this.showViewSelector = true,
  });

  /// False shows only the selected view, without the State / Bloch /
  /// Measure selector: the laboratory Composer (v2.6 M11C) places the Bloch
  /// sphere as a panel of its own beside the state.
  final bool showViewSelector;

  /// Scales the tab selector down (never up) when it is wider than the
  /// panel, for example at large text sizes in a narrow results column.
  final bool fitTabsToWidth;

  /// Omits the tab icons so the three labels fit narrow panels.
  final bool compactTabs;

  final QuantumInspectorSelection? selection;
  final Widget stateView;
  final Widget? measureView;
  final List<Complex> currentStateVector;
  final int numQubits;
  final bool allowBloch;

  /// Optional heading and explanation shown above the sphere, e.g. when the
  /// vector is the state immediately before a terminal measurement.
  final String? blochCaption;
  final String? blochNote;

  /// Explains why Bloch is unavailable; shown inside the Bloch tab when
  /// [keepBlochTabSelectable] is true.
  final String? blochUnavailableMessage;

  /// Optional control above the Bloch sphere (the desktop Composer's
  /// Before measurement / After single run selector). Null: unchanged.
  final Widget? blochHeader;

  /// Keeps the Bloch tab selectable even when the Bloch view is unsupported,
  /// so navigation never changes; the tab then explains why instead.
  final bool keepBlochTabSelectable;
  final bool contentDriven;
  final String? targetStateExpression;

  bool get supportsBloch =>
      allowBloch && numQubits == 1 && currentStateVector.length >= 2;

  @override
  State<QuantumInspectorViews> createState() => _QuantumInspectorViewsState();
}

class _QuantumInspectorViewsState extends State<QuantumInspectorViews> {
  final _localSelection = QuantumInspectorSelection();
  QuantumInspectorSelection get _selection =>
      widget.selection ?? _localSelection;
  QuantumInspectorView get _view => _selection.selected;
  BlochCamera _localCamera = QuantumInspectorSelection.defaultCamera;

  BlochCamera get _camera => widget.selection?.camera ?? _localCamera;
  set _camera(BlochCamera camera) {
    _localCamera = camera;
    widget.selection?.camera = camera;
  }

  @override
  void initState() {
    super.initState();
    _reconcileSelection();
  }

  void _reconcileSelection() => _selection.reconcile(
        supportsBloch: widget.supportsBloch || widget.keepBlochTabSelectable,
        supportsMeasure: widget.measureView != null,
      );

  @override
  void didUpdateWidget(covariant QuantumInspectorViews oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reconcileSelection();
  }

  @override
  Widget build(BuildContext context) {
    final content =
        _view == QuantumInspectorView.measure && widget.measureView != null
            ? widget.measureView!
            : _view == QuantumInspectorView.bloch && widget.supportsBloch
                ? _blochView()
                : _view == QuantumInspectorView.bloch &&
                        widget.keepBlochTabSelectable
                    ? _blochUnavailable()
                    : widget.stateView;
    return Column(
      key: const ValueKey('quantum-inspector-views'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: widget.contentDriven ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (!widget.showViewSelector)
          const SizedBox.shrink()
        else
          Align(
            alignment: Alignment.centerLeft,
            child: _fitTabs(
              SegmentedButton<QuantumInspectorView>(
                key: const ValueKey('quantum-inspector-view-selector'),
                segments: [
                  ButtonSegment(
                    value: QuantumInspectorView.state,
                    label: const Text('State'),
                    icon: widget.compactTabs
                        ? null
                        : const Icon(Icons.data_array_outlined, size: 15),
                  ),
                  ButtonSegment(
                    value: QuantumInspectorView.bloch,
                    label: const Text('Bloch'),
                    icon: widget.compactTabs
                        ? null
                        : const Icon(Icons.language_outlined, size: 15),
                    enabled:
                        widget.supportsBloch || widget.keepBlochTabSelectable,
                  ),
                  if (widget.measureView != null)
                    const ButtonSegment(
                      value: QuantumInspectorView.measure,
                      label: Text('Measure'),
                    ),
                ],
                selected: {_view},
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity(horizontal: -2, vertical: -3),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onSelectionChanged: (selection) {
                  setState(() => _selection.selected = selection.single);
                },
              ),
            ),
          ),
        if (widget.showViewSelector &&
            widget.allowBloch &&
            !widget.supportsBloch &&
            !widget.keepBlochTabSelectable &&
            _view != QuantumInspectorView.measure) ...[
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
        if (widget.showViewSelector) const SizedBox(height: 10),
        if (widget.contentDriven) content else Expanded(child: content),
      ],
    );
  }

  Widget _fitTabs(Widget tabs) => widget.fitTabsToWidth
      ? FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: tabs,
        )
      : tabs;

  Widget _blochUnavailable() => Padding(
        key: const ValueKey('quantum-inspector-bloch-unavailable-panel'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                size: 16, color: QubitQuestColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.blochUnavailableMessage ??
                    'The Bloch sphere shows a single qubit. This circuit has '
                        '${widget.numQubits} qubits; use State to inspect it. '
                        'A qubit entangled with others has no state vector of '
                        'its own: its reduced state would lie inside the '
                        'sphere (at the centre for a Bell pair), so no single '
                        'vector is drawn.',
                key: const ValueKey(
                    'quantum-inspector-bloch-unavailable-reason'),
                style: QubitQuestTypography.supporting,
              ),
            ),
          ],
        ),
      );

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
            if (widget.blochHeader case final header?) ...[
              header,
              const SizedBox(height: 8),
            ],
            if (widget.blochCaption case final caption?) ...[
              Text(
                caption,
                key: const ValueKey('quantum-inspector-bloch-caption'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: QubitQuestColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.blochNote case final note?)
                Text(
                  note,
                  key: const ValueKey('quantum-inspector-bloch-note'),
                  textAlign: TextAlign.center,
                  style: QubitQuestTypography.supporting,
                ),
              const SizedBox(height: 6),
            ],
            Center(
              child: SizedBox(
                key: const ValueKey('quantum-inspector-bloch-sphere-region'),
                width: regionWidth,
                height: regionHeight,
                child: BlochSpherePanel(
                  state: state,
                  camera: _camera,
                  allowStateEditing: false,
                  reserveOverlaySafeRegions: true,
                  showHelper: false,
                  compactAnnotations: true,
                  overlaySphereFraction: .95,
                  overlaySphereAlignment: const Alignment(0, -.05),
                  onCameraChanged: (camera) => setState(() => _camera = camera),
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
