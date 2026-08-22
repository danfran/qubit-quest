import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/quantum_circuit.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/widgets/circuit_geometry.dart';
import 'package:quantumquiz/widgets/quantum_circuit_painter.dart';

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
  });

  final QuantumCircuit circuit;
  final GateId? selectedGateId;
  final ValueChanged<PlacedGateRef?> onGateTap;
  final Future<void> Function(ComposerCircuitDropIntent intent) onDropRequested;
  final ValueChanged<PlacedGateRef> onPlacedGateDragStarted;
  final ValueChanged<PlacedGateRef> onDeletePlacedGateRequested;
  final ValueChanged<bool>? onDragActiveChanged;

  @override
  State<ComposerCircuitCanvas> createState() => _ComposerCircuitCanvasState();
}

class _ComposerCircuitCanvasState extends State<ComposerCircuitCanvas> {
  static const Color _innerColor = Color(0xFF101A2D);
  static const Color _cardColor = Color(0xFF18233A);
  static const Color _cyan = Color(0xFF56CCF2);
  static const Color _borderSoft = Color(0x3D344A73);

  final GlobalKey _gestureDetectorKey = GlobalKey();
  late final ScrollController _scrollController;

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

  int get _numQubits => widget.circuit.currentLevel.numQubits;

  bool get _isDraggingGate =>
      _draggingOffset != null &&
      _draggingGate.type != SelectedGateType.none &&
      _draggingGate.type != SelectedGateType.delete;

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

  void _onDragEnter(Offset globalPosition, CircuitDragData data) {
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
    if (movePlan != null && !_isValidMovePlan(movePlan)) destination = null;
    setState(() {
      _latestCircuitDragGlobalPosition = globalPosition;
      _draggingOffset = contentPosition;
      _draggingDestination = destination;
      _draggingMovePlan = movePlan;
      _draggingGate = data.gate;
    });
    _reportDragActive(_isDraggingGate);
  }

  void _refreshCircuitDragDestinationAfterScroll() {
    final pointer = _latestCircuitDragGlobalPosition;
    if (!mounted || pointer == null || !_isDraggingGate) return;
    final contentPosition = _gatePositionToContent(pointer);
    if (contentPosition == null) return;
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
    widget.onGateTap(CircuitGeometry.hitTestGate(
      widget.circuit,
      contentPosition,
    ));
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
    final destination = _draggingDestination;
    if (destination == null) return null;
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxPosition = widget.circuit.isCircuitEmpty()
              ? -1
              : widget.circuit.placedGates
                  .map((row) => row.length)
                  .reduce(math.max);
          final width = math.max(
            CircuitGeometry.contentWidth(widget.circuit),
            constraints.maxWidth,
          );
          final drawingHeight =
              QuantumCircuitPainter.requiredDrawingHeightFor(_numQubits);
          final viewportHeight = math.max(drawingHeight, constraints.maxHeight);
          return DragTarget<CircuitDragData>(
            onAcceptWithDetails: (details) async {
              final intent = _dropIntent(details);
              if (intent != null) await widget.onDropRequested(intent);
              if (mounted) setState(_clearDragState);
            },
            onLeave: (_) => setState(_clearDragState),
            onMove: (details) => _onDragEnter(details.offset, details.data),
            onWillAcceptWithDetails: (details) {
              _onDragEnter(details.offset, details.data);
              return details.data.gate.type != SelectedGateType.delete;
            },
            builder: (context, candidateData, rejectedData) => KeyedSubtree(
              key: const ValueKey('circuit-interaction-surface'),
              child: GestureDetector(
                key: _gestureDetectorKey,
                onTapDown: _handleTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SingleChildScrollView(
                      key: const ValueKey('circuit-horizontal-scroll'),
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: width,
                        height: viewportHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _CircuitGuidePainter(
                                numQubits: _numQubits,
                                columns: math.max(4, maxPosition + 4),
                                isDragging: _isDraggingGate,
                                destination: _draggingDestination,
                              ),
                            ),
                            CustomPaint(
                              painter: QuantumCircuitPainter(
                                widget.circuit,
                                previewGates:
                                    _isDraggingGate ? _dragPreview() : null,
                                selectedGateId: widget.selectedGateId,
                                ghostedGateId: _activeDragData?.isPlaced == true
                                    ? _activeDragData!.sourceId
                                    : null,
                                highlightedQubit:
                                    _draggingDestination?.location.qubit,
                              ),
                            ),
                            if (widget.circuit.isCircuitEmpty())
                              Align(
                                alignment: const Alignment(0, -0.42),
                                child: _EmptyCircuitPrompt(
                                  isDragging: _isDraggingGate,
                                ),
                              ),
                            ..._placedGateDragOverlays(),
                          ],
                        ),
                      ),
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
      ),
    );
  }

  List<Widget> _placedGateDragOverlays() => [
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
              Text(
                isDragging ? 'Release on a slot' : 'Drag a gate here',
                style: const TextStyle(
                  color: Color(0xFFD6E3F8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
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
  });

  final int numQubits;
  final int columns;
  final bool isDragging;
  final CircuitDropDestination? destination;

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
        if (isDragging && activeQubit == qubit && activeColumn == column) {
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
      oldDelegate.destination != destination;
}
