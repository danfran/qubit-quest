import 'dart:math' as math;
import 'package:quantumquiz/models/circuit_program.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/circuit_layout_metrics.dart';
import 'package:quantumquiz/widgets/measurement_glyph.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';

@immutable
class ComposerCircuitDropIntent {
  const ComposerCircuitDropIntent({
    required this.data,
    required this.destination,
    this.movePlan,
  });

  final CircuitDragData data;
  final CircuitDropDestination destination;
  final LogicalMovePlan? movePlan;
}

enum ComposerCircuitSurfaceTreatment {
  inset,
  workbench,
}

class ComposerCircuitCanvas extends StatefulWidget {
  const ComposerCircuitCanvas({
    super.key,
    required this.circuit,
    required this.selectedGateId,
    required this.onGateTap,
    required this.onDropRequested,
    required this.onPlacedGateDragStarted,
    required this.onDeletePlacedGateRequested,
    this.onDragActiveChanged,
    this.measurementPlacement = false,
    this.onMeasurementPlaced,
    this.onMeasurementDropped,
    this.onMeasurementMoved,
    this.onMeasurementSelected,
    this.onDropRejected,
    this.enableDesktopHorizontalScrolling = false,
    this.surfaceTreatment = ComposerCircuitSurfaceTreatment.inset,
    this.scale = 1.0,
    this.pinnedQubitLabels = false,
    this.wireColor,
    this.markFixedGates = false,
    this.onFixedGateDragAttempted,
  });

  /// Display scale of the whole circuit (1.0 = the shared 100% geometry).
  ///
  /// The canvas lays out, paints and hit-tests in *logical* 100%
  /// coordinates ([CircuitLayoutMetrics]) inside a single scale transform,
  /// so geometry, hit-testing, scroll extents and drop positions remain one
  /// coordinate space: `globalToLocal` maps pointers through the transform.
  /// Only feedback drawn in the drag overlay is scaled explicitly.
  final double scale;

  /// Draws the qubit identifiers and initial states in a pinned gutter
  /// beside the scrolling circuit, instead of inside the 20 px padding.
  final bool pinnedQubitLabels;

  /// Wire colour passed to [QuantumCircuitPainter]; null keeps its default.
  final Color? wireColor;

  /// Lock badges on activity-fixed gates (see [QuantumCircuitPainter]).
  final bool markFixedGates;

  /// Called when the learner tries to drag a fixed gate (which never
  /// moves), so the host can explain why. Taps still select the gate.
  final ValueChanged<PlacedGateRef>? onFixedGateDragAttempted;

  /// Logical width of the pinned label gutter.
  static const double qubitLabelGutterWidth = 44;

  final bool measurementPlacement;
  final VoidCallback? onMeasurementPlaced;

  /// Host-owned measurement placement from a [CircuitDragData.measurement]
  /// drag. The location may be occupied; the host validates and reports it.
  /// When null, measurement drags are refused.
  final ValueChanged<CircuitLocation>? onMeasurementDropped;

  /// Host-owned horizontal move of an existing measurement to a column.
  /// When null, placed measurements are not draggable.
  final void Function(GateId id, int column)? onMeasurementMoved;

  /// Receives the reason when a drop targets a destination the circuit
  /// rejects (shown in red while hovering). Opting in also enables exact
  /// previews and rejection for gate drags in measured circuits.
  final ValueChanged<String>? onDropRejected;

  /// Host-owned measurement selection: the canvas highlights the measurement
  /// whose ID equals [selectedGateId] and shows no canvas-local delete icon.
  /// When null, the legacy canvas-local selection is used.
  final ValueChanged<GateId>? onMeasurementSelected;
  final QuantumCircuit circuit;
  final GateId? selectedGateId;
  final ValueChanged<PlacedGateRef?> onGateTap;
  final Future<void> Function(ComposerCircuitDropIntent intent) onDropRequested;
  final ValueChanged<PlacedGateRef> onPlacedGateDragStarted;
  final ValueChanged<PlacedGateRef> onDeletePlacedGateRequested;
  final ValueChanged<bool>? onDragActiveChanged;
  final bool enableDesktopHorizontalScrolling;
  final ComposerCircuitSurfaceTreatment surfaceTreatment;

  @override
  State<ComposerCircuitCanvas> createState() => _ComposerCircuitCanvasState();
}

class _ComposerCircuitCanvasState extends State<ComposerCircuitCanvas> {
  static const Color _innerColor = QubitQuestColors.surfaceInsetRaised;
  static const Color _cardColor = QubitQuestColors.surfaceRaised;
  static const Color _cyan = QubitQuestColors.accentInteractive;
  static const Color _borderSoft = QubitQuestColors.borderSoft;

  final GlobalKey _gestureDetectorKey = GlobalKey();
  late final ScrollController _scrollController;

  GateId? _selectedMeasurement;
  Offset? _draggingOffset;
  CircuitDropDestination? _draggingDestination;
  LogicalMovePlan? _draggingMovePlan;
  Offset? _latestCircuitDragGlobalPosition;
  Gate _draggingGate = Gate.fromIdentifier(SelectedGateType.none);
  CircuitDragData? _activeDragData;
  Offset? _latestPlacedDragPointerPosition;
  int _placedDragAnchorRowOffset = 0;
  bool _placedDragOutsideCircuit = false;
  bool _placedDragWasCancelled = false;
  Rect? _circuitViewportBounds;
  bool _reportedDragActive = false;
  bool _draggingMeasurement = false;
  CircuitDragData? _measurementDragData;

  /// Exact proposed grid from a dry run or move plan, drawn while hovering.
  List<List<PlacedQuantumGate>>? _editPreviewRows;

  /// The operation being inserted or moved within [_editPreviewRows].
  GateId? _previewId;

  /// Reason the hovered destination is rejected, if it is.
  String? _dropRejection;
  CircuitDropDestination? _rejectedDestination;

  bool get _hostOwnsMeasurements => widget.onMeasurementSelected != null;

  int get _numQubits => widget.circuit.currentLevel.numQubits;

  bool get _isDraggingGate =>
      _draggingOffset != null &&
      (_draggingMeasurement ||
          (_draggingGate.type != SelectedGateType.none &&
              _draggingGate.type != SelectedGateType.delete));

  @override
  void initState() {
    super.initState();
    widget.circuit.addListener(_circuitChanged);
    _scrollController = ScrollController()
      ..addListener(_refreshCircuitDragDestinationAfterScroll);
  }

  @override
  void didUpdateWidget(covariant ComposerCircuitCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.circuit, widget.circuit)) {
      oldWidget.circuit.removeListener(_circuitChanged);
      widget.circuit.addListener(_circuitChanged);
      _clearDragState();
    }
  }

  @override
  void dispose() {
    widget.circuit.removeListener(_circuitChanged);
    _scrollController
      ..removeListener(_refreshCircuitDragDestinationAfterScroll)
      ..dispose();
    super.dispose();
  }

  void _circuitChanged() {
    if (mounted) setState(() {});
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!widget.enableDesktopHorizontalScrolling ||
        event is! PointerScrollEvent ||
        !_scrollController.hasClients) {
      return;
    }
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;
    // Wheel deltas are in screen pixels; the scroll offset is logical.
    final position = (_scrollController.offset + delta / widget.scale).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(position);
  }

  Widget _horizontalCircuitSurface({
    required double width,
    required double height,
    required int maxPosition,
  }) {
    final scrollView = SingleChildScrollView(
      key: const ValueKey('circuit-horizontal-scroll'),
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _CircuitGuidePainter(
                numQubits: _numQubits,
                columns: math.max(4, maxPosition + 4),
                isDragging: _isDraggingGate,
                destination: _draggingDestination,
                rejectedDestination: _rejectedDestination,
              ),
            ),
            CustomPaint(
              painter: QuantumCircuitPainter(
                widget.circuit,
                previewGates: _isDraggingGate ? _dragPreview() : null,
                selectedGateId: widget.selectedGateId,
                ghostedGateId: _activeDragData?.isPlaced == true
                    ? _activeDragData!.sourceId
                    : null,
                highlightedQubit: _draggingDestination?.location.qubit,
                showQubitLabels: !widget.pinnedQubitLabels,
                wireColor: widget.wireColor,
                markFixedGates: widget.markFixedGates,
              ),
            ),
            if (widget.circuit.isCircuitEmpty())
              Align(
                alignment: const Alignment(0, -0.42),
                child: _EmptyCircuitPrompt(isDragging: _isDraggingGate),
              ),
            ..._placedGateDragOverlays(),
            ..._measurementOverlays(),
          ],
        ),
      ),
    );
    if (!widget.enableDesktopHorizontalScrolling) return scrollView;
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: scrollView,
      ),
    );
  }

  void _reportDragActive(bool active) {
    if (_reportedDragActive == active) return;
    _reportedDragActive = active;
    widget.onDragActiveChanged?.call(active);
  }

  Offset? _gatePositionToViewport(Offset globalPosition) {
    final renderBox =
        _gestureDetectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.attached) {
      return renderBox.globalToLocal(globalPosition);
    }
    final cachedBounds = _circuitViewportBounds;
    if (cachedBounds != null) return globalPosition - cachedBounds.topLeft;
    return null;
  }

  Offset? _gatePositionToContent(Offset globalPosition) {
    final viewportPosition = _gatePositionToViewport(globalPosition);
    if (viewportPosition == null) return null;
    return CircuitCoordinateMapper.viewportToContent(
      viewportPosition,
      horizontalScrollOffset:
          _scrollController.hasClients ? _scrollController.offset : 0,
    );
  }

  CircuitDropDestination _logicalMoveDestination(
    CircuitDropDestination destination,
    CircuitDragData data,
  ) {
    if (!data.isPlaced) return destination;
    return CircuitDropDestination(
      contentPoint: destination.contentPoint,
      location: CircuitLocation(
        qubit: destination.location.qubit + _placedDragAnchorRowOffset,
        column: destination.location.column,
      ),
    );
  }

  bool _isValidMovePlan(LogicalMovePlan plan) =>
      plan.status == CircuitEditStatus.changed ||
      plan.status == CircuitEditStatus.same;

  void _updateMeasurementDrag(
    Offset contentPosition,
    CircuitDragData data, {
    Offset? pointer,
  }) {
    final destination = CircuitGeometry.dropDestinationForPoint(
      circuit: widget.circuit,
      contentPoint: contentPosition,
    );
    List<List<PlacedQuantumGate>>? rows;
    GateId? previewId;
    String? rejection;
    if (destination != null) {
      final location = destination.location;
      if (data.isMeasurementMove) {
        final plan =
            widget.circuit.planMeasurementMove(data.sourceId!, location.column);
        if (plan.changed) {
          rows = plan.proposedRows;
          previewId = data.sourceId;
        } else if (plan.status != CircuitEditStatus.same) {
          rejection = plan.reason ?? 'The measurement cannot move there.';
        }
      } else {
        final preview = widget.circuit.previewMeasurementInsertion(
          qubit: location.qubit,
          column: location.column,
        );
        if (preview.outcome.changed) {
          rows = preview.rows;
          previewId = preview.outcome.affectedGateId;
        } else {
          rejection =
              preview.outcome.detail ?? 'A measurement cannot be placed there.';
        }
      }
    }
    setState(() {
      if (pointer != null) _latestCircuitDragGlobalPosition = pointer;
      _draggingMeasurement = true;
      _measurementDragData = data;
      _draggingOffset = contentPosition;
      _draggingDestination = destination;
      _draggingMovePlan = null;
      _editPreviewRows = rows;
      _previewId = previewId;
      _dropRejection = rejection;
      _rejectedDestination = rejection == null ? null : destination;
    });
    _reportDragActive(true);
  }

  /// Exact preview and rejection for gate drags in measured circuits, where
  /// the terminal-measurement policy can reject a destination.
  void _updateGateDropCheck(
    CircuitDragData data,
    CircuitDropDestination? destination,
    LogicalMovePlan? movePlan,
  ) {
    _editPreviewRows = null;
    _previewId = null;
    _dropRejection = null;
    _rejectedDestination = null;
    if (widget.onDropRejected == null ||
        !widget.circuit.hasMeasurements ||
        destination == null) {
      return;
    }
    if (data.isPlaced) {
      if (movePlan != null && movePlan.status == CircuitEditStatus.invalid) {
        _dropRejection = movePlan.reason ?? 'The gate cannot move there.';
        _rejectedDestination = destination;
      }
      return;
    }
    // Ordering depends only on the occupied wire, so a plain X stands in for
    // the dragged gate (rotation angles and controls are chosen on drop).
    final preview = widget.circuit.previewSingleGateInsertion(
      Gate.fromIdentifier(SelectedGateType.x),
      destination.location,
    );
    if (preview.outcome.status == CircuitEditStatus.invalid) {
      _dropRejection =
          preview.outcome.detail ?? 'A gate cannot be placed there.';
      _rejectedDestination = destination;
    } else if (preview.outcome.changed && _isSingleQubitType(data.gate.type)) {
      final id = preview.outcome.affectedGateId;
      _editPreviewRows = [
        for (final row in preview.rows)
          [
            for (final cell in row)
              cell.id != null && cell.id == id
                  ? PlacedQuantumGate(
                      gate: Gate.fromIdentifier(SelectedGateType.draggedGate))
                  : cell,
          ],
      ];
    }
  }

  static bool _isSingleQubitType(SelectedGateType type) =>
      type != SelectedGateType.cnot &&
      type != SelectedGateType.cz &&
      type != SelectedGateType.ccnot;

  void _onDragEnter(Offset globalPosition, CircuitDragData data) {
    if (data.isMeasurement) {
      if (!_acceptsMeasurementDrag(data)) return;
      final contentPosition = _gatePositionToContent(globalPosition);
      if (contentPosition != null) {
        _updateMeasurementDrag(contentPosition, data, pointer: globalPosition);
      }
      return;
    }
    if (data.isPlaced) {
      final source = widget.circuit.logicalGateById(data.sourceId!);
      if (source == null || !source.isMovable) {
        setState(_clearDragState);
        return;
      }
    }
    final contentPosition = _gatePositionToContent(globalPosition);
    if (contentPosition == null) return;
    final rawDestination = CircuitGeometry.dropDestinationForPoint(
      circuit: widget.circuit,
      contentPoint: contentPosition,
    );
    var destination = rawDestination == null
        ? null
        : _logicalMoveDestination(rawDestination, data);
    final movePlan = data.isPlaced && destination != null
        ? widget.circuit.planLogicalGateMove(
            data.sourceId!,
            destination.location,
          )
        : null;
    final candidate = destination;
    if (movePlan != null && !_isValidMovePlan(movePlan)) destination = null;
    setState(() {
      _latestCircuitDragGlobalPosition = globalPosition;
      _draggingOffset = contentPosition;
      _draggingDestination = destination;
      _draggingMovePlan = movePlan;
      _draggingGate = data.gate;
      _updateGateDropCheck(data, candidate, movePlan);
    });
    _reportDragActive(_isDraggingGate);
  }

  void _refreshCircuitDragDestinationAfterScroll() {
    final pointer = _latestCircuitDragGlobalPosition;
    if (!mounted || pointer == null || !_isDraggingGate) return;
    final contentPosition = _gatePositionToContent(pointer);
    if (contentPosition == null) return;
    if (_draggingMeasurement && _measurementDragData != null) {
      _updateMeasurementDrag(contentPosition, _measurementDragData!);
      return;
    }
    final rawDestination = CircuitGeometry.dropDestinationForPoint(
      circuit: widget.circuit,
      contentPoint: contentPosition,
    );
    final data = _activeDragData;
    var destination = data == null
        ? rawDestination
        : rawDestination == null
            ? null
            : _logicalMoveDestination(rawDestination, data);
    final movePlan = data?.isPlaced == true && destination != null
        ? widget.circuit.planLogicalGateMove(
            data!.sourceId!,
            destination.location,
          )
        : null;
    if (movePlan != null && !_isValidMovePlan(movePlan)) destination = null;
    setState(() {
      _draggingOffset = contentPosition;
      _draggingDestination = destination;
      _draggingMovePlan = movePlan;
    });
  }

  void _clearDragState() {
    _draggingOffset = null;
    _draggingDestination = null;
    _draggingMovePlan = null;
    _latestCircuitDragGlobalPosition = null;
    _draggingGate = Gate.fromIdentifier(SelectedGateType.none);
    _draggingMeasurement = false;
    _measurementDragData = null;
    _editPreviewRows = null;
    _previewId = null;
    _dropRejection = null;
    _rejectedDestination = null;
    _reportDragActive(false);
  }

  ComposerCircuitDropIntent? _dropIntent(
    DragTargetDetails<CircuitDragData> details,
  ) {
    final contentPosition = _gatePositionToContent(details.offset);
    final fallback = contentPosition == null
        ? null
        : CircuitGeometry.dropDestinationForPoint(
            circuit: widget.circuit,
            contentPoint: contentPosition,
          );
    final destination = _draggingDestination ??
        (fallback == null
            ? null
            : _logicalMoveDestination(fallback, details.data));
    if (destination == null) return null;
    final movePlan = details.data.isPlaced
        ? (_draggingMovePlan ??
            widget.circuit.planLogicalGateMove(
              details.data.sourceId!,
              destination.location,
            ))
        : null;
    return ComposerCircuitDropIntent(
      data: details.data,
      destination: destination,
      movePlan: movePlan,
    );
  }

  void _handleTap(TapDownDetails details) {
    final contentPosition = CircuitCoordinateMapper.viewportToContent(
      details.localPosition,
      horizontalScrollOffset:
          _scrollController.hasClients ? _scrollController.offset : 0,
    );
    final measurement = _measurementAt(contentPosition);
    if (_hostOwnsMeasurements && measurement != null) {
      widget.onMeasurementSelected!(measurement.id);
      return;
    }
    if (widget.measurementPlacement) {
      final qubit = CircuitGeometry.qubitForPoint(contentPosition, _numQubits);
      if (qubit != null)
        _placeMeasurement(
            qubit, CircuitGeometry.insertionColumnForPoint(contentPosition));
      return;
    }
    setState(() => _selectedMeasurement = null);
    widget.onGateTap(CircuitGeometry.hitTestGate(
      widget.circuit,
      contentPosition,
    ));
  }

  Future<void> _placeMeasurement(int qubit, int column) async {
    final circuit = widget.circuit;
    var destination = qubit;
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
                title: Text('Measure q$qubit in Z basis'),
                content: DropdownButton<int>(
                  value: destination,
                  items: List.generate(
                      math.max(_numQubits, circuit.classicalBitCount),
                      (i) => DropdownMenuItem(value: i, child: Text('c$i'))),
                  onChanged: (value) {
                    if (value != null) update(() => destination = value);
                  },
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, destination),
                      child: const Text('Place measurement')),
                ],
              )),
    );
    if (!mounted || chosen == null || !identical(circuit, widget.circuit)) {
      return;
    }
    // Same ordering rules as the Web host (terminal measurement per qubit).
    final outcome = circuit.insertMeasurementWithOutcome(
        qubit: qubit, column: column, classicalBit: chosen);
    if (outcome.changed) {
      setState(() => _selectedMeasurement = outcome.affectedGateId);
      widget.onGateTap(null);
      widget.onMeasurementPlaced?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Cannot place measurement: '
              '${outcome.detail ?? 'choose another slot.'}')));
    }
  }

  MeasureZOperation? _measurementAt(Offset contentPosition) {
    for (final m in widget.circuit.measurements) {
      final bounds = CircuitGeometry.singleGateBounds(
          CircuitLocation(qubit: m.qubit, column: m.column));
      if (bounds.inflate(5).contains(contentPosition)) return m;
    }
    return null;
  }

  bool _acceptsMeasurementDrag(CircuitDragData data) => data.isMeasurementMove
      ? widget.onMeasurementMoved != null
      : widget.onMeasurementDropped != null;

  Widget _measurementGlyph(MeasureZOperation m, {bool selected = false}) =>
      MeasurementGlyph(
        size: CircuitLayoutMetrics.gateSize,
        radius: 6,
        classicalBit: m.classicalBit,
        selected: selected,
      );

  Rect _measurementRect(MeasureZOperation m) =>
      CircuitGeometry.singleGateBounds(
          CircuitLocation(qubit: m.qubit, column: m.column));

  List<Widget> _measurementOverlays() =>
      _hostOwnsMeasurements ? _hostMeasurementLayers() : _legacyMeasurements();

  /// Web host: a visual layer drawn from the current grid, or from the exact
  /// proposed grid while hovering, plus transparent drag handles for moving.
  List<Widget> _hostMeasurementLayers() {
    final previewRows = _editPreviewRows;
    final shown = QuantumCircuit.measurementsInRows(
        previewRows ?? widget.circuit.placedGates);
    final rejected = _draggingMeasurement ? _rejectedDestination : null;
    final movingId = _measurementDragData?.sourceId;
    return [
      for (final m in shown)
        Positioned.fromRect(
          rect: _measurementRect(m),
          child: IgnorePointer(
            child: previewRows != null && m.id == _previewId
                ? Opacity(
                    key: const ValueKey('measurement-drop-preview'),
                    opacity: .8,
                    child: _measurementGlyph(m),
                  )
                : Semantics(
                    key: ValueKey('measurement-${m.id.value}'),
                    selected: widget.selectedGateId == m.id,
                    label: 'Measure Z q${m.qubit} to c${m.classicalBit}',
                    child: Opacity(
                      opacity: previewRows == null &&
                              rejected != null &&
                              m.id == movingId
                          ? .45
                          : 1,
                      child: _measurementGlyph(
                        m,
                        selected: widget.selectedGateId == m.id,
                      ),
                    ),
                  ),
          ),
        ),
      if (rejected != null)
        Positioned.fromRect(
          rect: CircuitGeometry.singleGateBounds(rejected.location),
          child: IgnorePointer(
            child: Opacity(
              opacity: .85,
              child: MeasurementGlyph(
                key: const ValueKey('measurement-drop-preview-rejected'),
                size: CircuitLayoutMetrics.gateSize,
                radius: 6,
                classicalBit: movingId == null
                    ? rejected.location.qubit
                    : widget.circuit.measurementById(movingId)?.classicalBit,
                rejected: true,
              ),
            ),
          ),
        ),
      if (widget.onMeasurementMoved != null)
        for (final m in widget.circuit.measurements)
          Positioned.fromRect(
            rect: _measurementRect(m).inflate(3),
            child: Draggable<CircuitDragData>(
              key: ValueKey('measurement-drag-${m.id.value}'),
              data: CircuitDragData.measurement(sourceId: m.id),
              dragAnchorStrategy: pointerDragAnchorStrategy,
              // Overlay feedback is outside the canvas transform, so it is
              // drawn at the displayed (scaled) size, centred on the pointer.
              feedback: Transform.translate(
                offset: Offset(
                  -CircuitLayoutMetrics.gateSize * widget.scale / 2,
                  -CircuitLayoutMetrics.gateSize * widget.scale / 2,
                ),
                child: Opacity(
                  opacity: .85,
                  child: MeasurementGlyph(
                    key: const ValueKey('measurement-drag-feedback'),
                    size: CircuitLayoutMetrics.gateSize * widget.scale,
                    radius: 6 * widget.scale,
                    classicalBit: m.classicalBit,
                  ),
                ),
              ),
              // Taps fall through to the canvas gesture detector (selection);
              // only a drag beyond touch slop starts a move.
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
    ];
  }

  /// Native host: canvas-local selection with the legacy delete affordance.
  List<Widget> _legacyMeasurements() {
    final preview = _draggingMeasurement ? _draggingDestination : null;
    return [
      for (final measurement in widget.circuit.measurements)
        Positioned.fromRect(
          rect: _measurementRect(measurement),
          child: Semantics(
            button: true,
            selected: _selectedMeasurement == measurement.id,
            label: 'Measure Z q${measurement.qubit} to '
                'c${measurement.classicalBit}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('measurement-${measurement.id.value}'),
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  widget.onGateTap(null);
                  setState(() => _selectedMeasurement = measurement.id);
                },
                child: _measurementGlyph(
                  measurement,
                  selected: _selectedMeasurement == measurement.id,
                ),
              ),
            ),
          ),
        ),
      if (preview != null)
        Positioned.fromRect(
          rect: CircuitGeometry.singleGateBounds(preview.location),
          child: IgnorePointer(
            child: Opacity(
              opacity: .8,
              child: MeasurementGlyph(
                key: const ValueKey('measurement-drop-preview'),
                size: CircuitLayoutMetrics.gateSize,
                radius: 6,
                classicalBit: preview.location.qubit,
              ),
            ),
          ),
        ),
      if (_selectedMeasurement != null &&
          widget.circuit.measurements.any((m) => m.id == _selectedMeasurement))
        Positioned(
            right: 8,
            top: 0,
            child: IconButton(
              tooltip: 'Remove measurement',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                widget.circuit.removeMeasurement(_selectedMeasurement!);
                setState(() => _selectedMeasurement = null);
              },
            )),
    ];
  }

  void _capturePlacedDragOrigin(
    PointerDownEvent event,
    LogicalGateFootprint footprint,
  ) {
    _latestPlacedDragPointerPosition = event.position;
    final contentPosition = _gatePositionToContent(event.position);
    final grabbedRow = contentPosition == null
        ? null
        : CircuitGeometry.qubitForPoint(contentPosition, _numQubits);
    _placedDragAnchorRowOffset =
        grabbedRow == null ? 0 : footprint.anchor.qubit - grabbedRow;
  }

  bool _isClearlyOutsideCircuitForDeletion(Offset pointerPosition) {
    final renderBox =
        _gestureDetectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return false;
    return CircuitGeometry.isClearlyOutsideCircuitForDeletion(
      circuitBounds: renderBox.localToGlobal(Offset.zero) & renderBox.size,
      pointerPosition: pointerPosition,
    );
  }

  void _startPlacedDrag(PlacedGateRef source) {
    final pointerPosition = _latestPlacedDragPointerPosition;
    setState(() {
      _placedDragWasCancelled = false;
      _activeDragData = CircuitDragData.placed(
        sourceId: source.id,
        gate: source.gate,
      );
      _placedDragOutsideCircuit = pointerPosition != null &&
          _isClearlyOutsideCircuitForDeletion(pointerPosition);
    });
    widget.onPlacedGateDragStarted(source);
  }

  void _updatePlacedDragPosition(Offset pointerPosition) {
    _latestPlacedDragPointerPosition = pointerPosition;
    if (!mounted || !(_activeDragData?.isPlaced ?? false)) return;
    final outside = _isClearlyOutsideCircuitForDeletion(pointerPosition);
    if (_placedDragOutsideCircuit == outside) return;
    setState(() => _placedDragOutsideCircuit = outside);
  }

  void _finishPlacedDrag() {
    if (!mounted) return;
    setState(() {
      _activeDragData = null;
      _latestPlacedDragPointerPosition = null;
      _placedDragAnchorRowOffset = 0;
      _placedDragOutsideCircuit = false;
      _placedDragWasCancelled = false;
      _clearDragState();
    });
  }

  void _handlePlacedDragCancelled(PlacedGateRef source) {
    final pointerPosition = _latestPlacedDragPointerPosition;
    if (mounted &&
        !_placedDragWasCancelled &&
        pointerPosition != null &&
        _isClearlyOutsideCircuitForDeletion(pointerPosition)) {
      widget.onDeletePlacedGateRequested(source);
    }
    _finishPlacedDrag();
  }

  List<List<PlacedQuantumGate>>? _dragPreview() {
    if (_editPreviewRows != null) return _editPreviewRows;
    final destination = _draggingDestination;
    if (destination == null || _draggingMeasurement) return null;
    if (_activeDragData?.isPlaced ?? false) {
      return _draggingMovePlan?.proposedRows;
    }
    return CircuitGeometry.insertionPreview(
      circuit: widget.circuit,
      destination: destination,
      gate: _draggingGate,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox =
          _gestureDetectorKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.attached) {
        _circuitViewportBounds =
            renderBox.localToGlobal(Offset.zero) & renderBox.size;
      }
    });
    final integratedWorkbench =
        widget.surfaceTreatment == ComposerCircuitSurfaceTreatment.workbench;
    return AnimatedContainer(
      key: ValueKey(
        integratedWorkbench
            ? 'circuit-workbench-surface'
            : 'circuit-inset-surface',
      ),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: integratedWorkbench
          ? const BoxDecoration()
          : BoxDecoration(
              color: const Color(0xFF020713),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
      clipBehavior: Clip.antiAlias,
      child: _ScaledCircuitViewport(
        scale: widget.scale,
        child: _withLabelGutter(LayoutBuilder(
          builder: (context, constraints) {
            // Includes measurement barrier columns, not only gate rows.
            final maxPosition = widget.circuit.isCircuitEmpty()
                ? -1
                : widget.circuit.maxCircuitDepth();
            final width = math.max(
              math.max(
                  CircuitGeometry.contentWidth(widget.circuit),
                  (widget.circuit.measurements.fold<int>(
                              0, (v, m) => math.max(v, m.column + 3))) *
                          QuantumCircuitPainter.gateSpacing +
                      QuantumCircuitPainter.padding * 2),
              constraints.maxWidth,
            );
            final drawingHeight =
                QuantumCircuitPainter.requiredDrawingHeightFor(_numQubits);
            final viewportHeight =
                math.max(drawingHeight, constraints.maxHeight);
            return DragTarget<CircuitDragData>(
              onAcceptWithDetails: (details) async {
                final data = details.data;
                final rejection = _dropRejection;
                if (data.isMeasurement) {
                  final contentPosition =
                      _gatePositionToContent(details.offset);
                  final destination = _draggingDestination ??
                      (contentPosition == null
                          ? null
                          : CircuitGeometry.dropDestinationForPoint(
                              circuit: widget.circuit,
                              contentPoint: contentPosition,
                            ));
                  if (mounted) setState(_clearDragState);
                  if (destination == null) return;
                  if (rejection != null) {
                    widget.onDropRejected?.call(rejection);
                  } else if (data.isMeasurementMove) {
                    widget.onMeasurementMoved
                        ?.call(data.sourceId!, destination.location.column);
                  } else {
                    widget.onMeasurementDropped?.call(destination.location);
                  }
                  return;
                }
                if (rejection != null) {
                  if (mounted) setState(_clearDragState);
                  widget.onDropRejected?.call(rejection);
                  return;
                }
                final intent = _dropIntent(details);
                if (intent != null) await widget.onDropRequested(intent);
                if (mounted) setState(_clearDragState);
              },
              onLeave: (_) => setState(_clearDragState),
              onMove: (details) => _onDragEnter(details.offset, details.data),
              onWillAcceptWithDetails: (details) {
                if (details.data.isMeasurement &&
                    !_acceptsMeasurementDrag(details.data)) {
                  return false;
                }
                _onDragEnter(details.offset, details.data);
                return details.data.isMeasurement ||
                    details.data.gate.type != SelectedGateType.delete;
              },
              builder: (context, candidateData, rejectedData) => KeyedSubtree(
                key: const ValueKey('circuit-interaction-surface'),
                child: GestureDetector(
                  key: _gestureDetectorKey,
                  onTapDown: _handleTap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _horizontalCircuitSurface(
                        width: width,
                        height: viewportHeight,
                        maxPosition: maxPosition,
                      ),
                      if (_placedDragOutsideCircuit &&
                          (_activeDragData?.isPlaced ?? false))
                        const Positioned(
                          right: 12,
                          top: 10,
                          child: _ReleaseToRemovePill(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        )),
      ),
    );
  }

  /// Pinned qubit labels (identifier above the initial state), aligned with
  /// each wire's centre in the same logical coordinates as the painter.
  Widget _withLabelGutter(Widget circuit) {
    if (!widget.pinnedQubitLabels) return circuit;
    final states = QuantumCircuitPainter.initialQubitStateLabelsFor(
      initialQubitsStateStr: widget.circuit.currentLevel.initialQubitsStateStr,
      numQubits: _numQubits,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const ValueKey('circuit-qubit-label-gutter'),
          width: ComposerCircuitCanvas.qubitLabelGutterWidth,
          child: Stack(
            children: [
              for (var q = 0; q < _numQubits; q++)
                Positioned(
                  left: 0,
                  right: 2,
                  top: QuantumCircuitPainter.qubitCenterYFor(q) -
                      QuantumCircuitPainter.hitTolerance,
                  height: QuantumCircuitPainter.hitTolerance * 2,
                  child: _QubitLabel(
                    key: ValueKey('circuit-qubit-label-$q'),
                    qubit: q,
                    state: states[q],
                    shaded: q.isEven,
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: circuit),
      ],
    );
  }

  List<Widget> _placedGateDragOverlays() => [
        if (widget.onFixedGateDragAttempted != null)
          for (final footprint
              in widget.circuit.logicalGates.where((gate) => !gate.isDeletable))
            if (CircuitGeometry.logicalGateBounds(
              widget.circuit,
              footprint.id,
            )
                case final bounds?)
              Positioned.fromRect(
                rect: bounds.inflate(5),
                child: Semantics(
                  label: 'Fixed gate ${footprint.gate.label}',
                  hint: 'Part of the activity. It can be inspected but not '
                      'moved or removed.',
                  child: GestureDetector(
                    key: ValueKey('fixed-gate-${footprint.id.value}'),
                    behavior: HitTestBehavior.translucent,
                    onTap: () => widget.onGateTap(footprint.toPlacedGateRef()),
                    onPanStart: (_) => widget.onFixedGateDragAttempted!(
                        footprint.toPlacedGateRef()),
                  ),
                ),
              ),
        for (final footprint
            in widget.circuit.logicalGates.where((gate) => gate.isDeletable))
          if (CircuitGeometry.logicalGateBounds(
            widget.circuit,
            footprint.id,
          )
              case final bounds?)
            Positioned.fromRect(
              rect: bounds.inflate(5),
              child: Listener(
                onPointerDown: (event) =>
                    _capturePlacedDragOrigin(event, footprint),
                onPointerMove: (event) =>
                    _updatePlacedDragPosition(event.position),
                onPointerCancel: (_) => _placedDragWasCancelled = true,
                child: _placedGateDraggable(footprint.toPlacedGateRef()),
              ),
            ),
      ];

  Widget _placedGateDraggable(PlacedGateRef placed) {
    final selected = placed.id == widget.selectedGateId;
    return Semantics(
      label: selected
          ? 'Selected gate ${placed.gate.label}'
          : 'Gate ${placed.gate.label}',
      hint: 'Drag to move. Drag outside circuit to remove.',
      child: Draggable<CircuitDragData>(
        key: ValueKey('placed-gate-drag-${placed.id.value}'),
        data: CircuitDragData.placed(sourceId: placed.id, gate: placed.gate),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => _startPlacedDrag(placed),
        onDragUpdate: (details) =>
            _updatePlacedDragPosition(details.globalPosition),
        onDragCompleted: _finishPlacedDrag,
        onDraggableCanceled: (_, __) => _handlePlacedDragCancelled(placed),
        feedback: const SizedBox(
          key: ValueKey('placed-drag-transparent-feedback'),
          width: 1,
          height: 1,
        ),
        childWhenDragging: const SizedBox.expand(),
        child: Tooltip(
          message:
              selected ? 'Selected gate • Drag to move' : 'Drag gate to move',
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ReleaseToRemovePill extends StatelessWidget {
  const _ReleaseToRemovePill();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        key: const ValueKey('release-to-remove'),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFEF5350).withValues(alpha: 0.72),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Color(0xFFFFB4B1), size: 14),
              SizedBox(width: 5),
              Text(
                'Release to remove',
                style: TextStyle(
                  color: Color(0xFFFFDAD8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptyCircuitPrompt extends StatelessWidget {
  const _EmptyCircuitPrompt({required this.isDragging});

  final bool isDragging;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isDragging
                ? _ComposerCircuitCanvasState._cyan.withValues(alpha: 0.10)
                : _ComposerCircuitCanvasState._cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDragging
                  ? _ComposerCircuitCanvasState._cyan.withValues(alpha: 0.46)
                  : _ComposerCircuitCanvasState._borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDragging
                    ? Icons.add_circle_outline
                    : Icons.touch_app_outlined,
                color: _ComposerCircuitCanvasState._cyan,
                size: 15,
              ),
              const SizedBox(width: 6),
              // Flexible: a scaled canvas has a narrower logical width.
              Flexible(
                child: Text(
                  isDragging ? 'Release on a slot' : 'Drag a gate here',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD6E3F8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _CircuitGuidePainter extends CustomPainter {
  const _CircuitGuidePainter({
    required this.numQubits,
    required this.columns,
    required this.isDragging,
    required this.destination,
    this.rejectedDestination,
  });

  final int numQubits;
  final int columns;
  final bool isDragging;
  final CircuitDropDestination? destination;

  /// Hovered destination the circuit rejects; drawn in red.
  final CircuitDropDestination? rejectedDestination;

  @override
  void paint(Canvas canvas, Size size) {
    final lanePaint = Paint()
      ..color = _ComposerCircuitCanvasState._innerColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final depthGuidePaint = Paint()
      ..color = _ComposerCircuitCanvasState._cyan.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final activeSlotPaint = Paint()
      ..color = _ComposerCircuitCanvasState._cyan.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final activeSlotFillPaint = Paint()
      ..color = _ComposerCircuitCanvasState._cyan.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final activeLanePaint = Paint()
      ..color = _ComposerCircuitCanvasState._cyan.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final rejectedSlotPaint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rejectedSlotFillPaint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final rejected = rejectedDestination?.location;
    final activeQubit = destination?.location.qubit;
    final activeColumn = destination?.location.column;

    if (isDragging) {
      for (var column = 0; column < columns; column++) {
        final centerX = QuantumCircuitPainter.padding +
            column * QuantumCircuitPainter.gateSpacing +
            QuantumCircuitPainter.gateSpacing / 2;
        canvas.drawLine(
          Offset(centerX, 0),
          Offset(centerX, size.height),
          depthGuidePaint,
        );
      }
    }
    for (var qubit = 0; qubit < numQubits; qubit++) {
      final centerY = QuantumCircuitPainter.qubitCenterYFor(qubit);
      final laneRect = Rect.fromLTRB(
        0,
        centerY - QuantumCircuitPainter.hitTolerance,
        size.width,
        centerY + QuantumCircuitPainter.hitTolerance,
      );
      if (qubit.isEven) canvas.drawRect(laneRect, lanePaint);
      if (isDragging && activeQubit == qubit) {
        canvas.drawRect(laneRect, activeLanePaint);
      }
      for (var column = 0; column < columns; column++) {
        final centerX = QuantumCircuitPainter.padding +
            column * QuantumCircuitPainter.gateSpacing +
            QuantumCircuitPainter.gateSpacing / 2;
        final slot = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: QuantumCircuitPainter.gateSize + 4,
            height: QuantumCircuitPainter.gateSize + 4,
          ),
          const Radius.circular(7),
        );
        if (isDragging &&
            rejected != null &&
            rejected.qubit == qubit &&
            rejected.column == column) {
          canvas.drawRRect(slot, rejectedSlotFillPaint);
          canvas.drawRRect(slot, rejectedSlotPaint);
        } else if (isDragging &&
            activeQubit == qubit &&
            activeColumn == column) {
          canvas.drawRRect(slot, activeSlotFillPaint);
          canvas.drawRRect(slot, activeSlotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitGuidePainter oldDelegate) =>
      oldDelegate.numQubits != numQubits ||
      oldDelegate.columns != columns ||
      oldDelegate.isDragging != isDragging ||
      oldDelegate.destination != destination ||
      oldDelegate.rejectedDestination != rejectedDestination;
}

/// Lays its child out at `constraints / scale` and paints it scaled, so the
/// child works entirely in logical circuit coordinates. Hit-testing passes
/// through the same transform, keeping pointer mapping exact.
class _ScaledCircuitViewport extends StatelessWidget {
  const _ScaledCircuitViewport({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (scale == 1.0) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / scale;
        final height = constraints.maxHeight / scale;
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: width,
              maxWidth: width,
              minHeight: height,
              maxHeight: height,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// One wire's label: muted identifier over the initial-state ket.
class _QubitLabel extends StatelessWidget {
  const _QubitLabel({
    super.key,
    required this.qubit,
    required this.state,
    required this.shaded,
  });

  final int qubit;
  final String state;
  final bool shaded;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Qubit $qubit, initial state $state',
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: shaded
                  ? _ComposerCircuitCanvasState._innerColor
                      .withValues(alpha: 0.28)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              // Identifier above its initial state (the painter's own
              // convention), never wider than the gutter.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'q$qubit',
                      style: const TextStyle(
                        color: QubitQuestColors.textMuted,
                        fontSize: 10.5,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      state,
                      style: const TextStyle(
                        color: QubitQuestColors.textPrimary,
                        fontSize: 14,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
