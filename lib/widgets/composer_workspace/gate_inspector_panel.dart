import 'dart:math' as math;

import 'package:advance_math/advance_math.dart' show Complex;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantumquiz/models/circuit_editing.dart';
import 'package:quantumquiz/models/circuit_program.dart';
import 'package:quantumquiz/models/composer_gate_capabilities.dart';
import 'package:quantumquiz/models/gate_educational_info.dart';
import 'package:quantumquiz/models/gate_id.dart';
import 'package:quantumquiz/models/logical_gate_footprint.dart';
import 'package:quantumquiz/models/placed_quantum_gate.dart';
import 'package:quantumquiz/models/quantum_matrix.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';
import 'package:quantumquiz/theme/qubit_quest_visuals.dart';
import 'package:quantumquiz/utils/angle_expression.dart';
import 'package:quantumquiz/widgets/composer_workspace/composer_gate_palette_panel.dart';
import 'package:quantumquiz/widgets/gate_educational_sections.dart';
import 'package:quantumquiz/widgets/gate_educational_visual.dart';
import 'package:quantumquiz/widgets/latex_text.dart';
import 'package:quantumquiz/widgets/measurement_glyph.dart';
import 'package:quantumquiz/widgets/qubit_quest_gate_tile.dart';
import 'package:quantumquiz/widgets/qubit_quest_workspace_primitives.dart';

/// Circuit facts for the inspector's empty state.
@immutable
class ComposerCircuitSummary {
  const ComposerCircuitSummary({
    required this.qubits,
    required this.depth,
    required this.gates,
    required this.measurements,
  });
  final int qubits;
  final int depth;
  final int gates;
  final int measurements;
}

/// Host callbacks for inspector actions. Every edit is a `ComposerSession`
/// command issued by the host; the inspector never touches the circuit.
@immutable
class GateInspectorActions {
  const GateInspectorActions({
    required this.onReplace,
    required this.onDuplicate,
    required this.onDelete,
    required this.onAngleCommitted,
    required this.onClassicalBitChanged,
  });

  /// Replaces the selected gate with a type chosen in the inspector's
  /// anchored menu (one of [GateInspectorPanel.replacementTypes]).
  final ValueChanged<SelectedGateType> onReplace;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final void Function(GateId id, double angle) onAngleCommitted;
  final ValueChanged<int?> onClassicalBitChanged;
}

/// Inspector content sections. Purely presentational: switching never
/// changes the circuit, its history or its results.
enum GateInspectorTab {
  overview('Overview'),
  mathematics('Mathematics'),
  learn('Learn');

  const GateInspectorTab(this.label);
  final String label;
}

/// Persistent, non-modal inspector below the circuit — the desktop
/// Composer's single place for understanding and configuring a gate.
///
/// Shows exactly one of: nothing selected (circuit facts), a palette
/// preview (a gate *type*, never in the circuit), a placed gate, or a
/// placed measurement. Gates with educational content get Overview /
/// Mathematics / Learn sections built from the same shared widgets as
/// `GateInspectorDialog` (`gate_educational_sections.dart`).
class GateInspectorPanel extends StatelessWidget {
  const GateInspectorPanel({
    super.key,
    required this.summary,
    required this.actions,
    this.selectedGate,
    this.selectedMeasurement,
    this.capabilities = ComposerSelectedGateCapabilities.none,
    this.previewType,
    this.classicalBitWidth = 0,
    this.usedClassicalBits = const {},
    this.replacementTypes = const [],
    this.collapsed = false,
    this.onToggleCollapsed,
    this.expanded = false,
    this.onToggleExpanded,
    this.tab = GateInspectorTab.overview,
    this.onTabChanged,
    this.onOpenRelatedConcept,
    this.legacyNote,
    this.contextual = false,
    this.onClose,
    this.openSections = const {},
    this.onSectionChanged,
  });

  /// Contextual presentation (v2.6 M11C): shown only while something is
  /// selected or previewed, closed with one control at the top right
  /// ([onClose], which deselects and never edits the circuit), and laid out
  /// as stacked sections: identity and actions, *What it does*, *Rule*, then
  /// *Mathematics* and *Learn more* as disclosures. No tabs, no collapse
  /// and no expanded mode.
  final bool contextual;
  final VoidCallback? onClose;

  /// Disclosure sections the learner opened (`mathematics`, `learn`); kept
  /// by the host in memory so they stay open across selections.
  final Set<String> openSections;
  final void Function(String section, bool open)? onSectionChanged;

  /// Opens a related concept's Notebook discovery; null leaves the related
  /// concepts as read-only chips.
  final ValueChanged<String>? onOpenRelatedConcept;

  final ComposerCircuitSummary summary;
  final GateInspectorActions actions;
  final LogicalGateFootprint? selectedGate;
  final MeasureZOperation? selectedMeasurement;
  final ComposerSelectedGateCapabilities capabilities;
  final SelectedGateType? previewType;

  /// Classical bits offered for a selected measurement (c0 … c(width−1)).
  final int classicalBitWidth;

  /// Classical bit → measured qubit, for bits written by *other*
  /// measurements.
  final Map<int, int> usedClassicalBits;

  /// Valid replacements for the selected gate, offered in an anchored menu.
  final List<SelectedGateType> replacementTypes;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  /// Expanded mode: the workspace gives the inspector most of the centre
  /// column while keeping the circuit visible.
  final bool expanded;
  final VoidCallback? onToggleExpanded;
  final GateInspectorTab tab;
  final ValueChanged<GateInspectorTab>? onTabChanged;
  final String? legacyNote;

  String get _heading {
    if (selectedMeasurement != null) return 'Measurement';
    if (selectedGate != null) return 'Selected gate';
    if (previewType != null) return 'Palette preview';
    return 'Inspector';
  }

  /// Educational content for the current subject, when it has any.
  GateEducationalInfo? get _info {
    if (selectedMeasurement != null) return null;
    final type = selectedGate?.type ?? previewType;
    return type == null ? null : GateEducationalCatalog.forType(type);
  }

  @override
  Widget build(BuildContext context) {
    if (contextual) return _buildContextual(context);
    final info = _info;
    final tabbed = info != null && !collapsed && onTabChanged != null;
    final iconButtons = [
      if (onToggleExpanded != null && !collapsed)
        IconButton(
          key: const ValueKey('composer-inspector-expand-mode'),
          tooltip: expanded
              ? 'Return the inspector to its normal size'
              : 'Give the inspector more room',
          onPressed: onToggleExpanded,
          isSelected: expanded,
          icon: Icon(
            expanded
                ? Icons.close_fullscreen_rounded
                : Icons.open_in_full_rounded,
            size: 16,
          ),
          color: expanded
              ? QubitQuestColors.accentInteractive
              : QubitQuestColors.textMuted,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
        ),
      if (onToggleCollapsed != null)
        IconButton(
          key: const ValueKey('composer-inspector-toggle'),
          tooltip: collapsed ? 'Expand inspector' : 'Collapse inspector',
          onPressed: onToggleCollapsed,
          icon: Icon(
            collapsed
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
          ),
          color: QubitQuestColors.textMuted,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
        ),
    ];
    final title = Text('GATE INSPECTOR', style: workspacePanelTitle);
    final heading = Text(
      collapsed ? _collapsedSummary() : _heading,
      key: const ValueKey('composer-inspector-heading'),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: QubitQuestTypography.supporting.copyWith(fontSize: 12),
    );
    final header = LayoutBuilder(builder: (context, constraints) {
      final tabs = tabbed
          ? _InspectorTabs(selected: tab, onChanged: onTabChanged!)
          : null;
      // Tabs share the header row when there is room, else get their own.
      final inline = tabs != null && constraints.maxWidth >= 820;
      final row = Row(
        children: [
          title,
          const SizedBox(width: 10),
          Expanded(child: heading),
          if (inline) ...[
            Flexible(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: tabs,
              ),
            ),
            const SizedBox(width: 8),
          ],
          ...iconButtons,
        ],
      );
      const padding = EdgeInsets.fromLTRB(16, 6, 6, 2);
      // A lone row (collapsed, or tabs inline) keeps M3's single-row header
      // so the 44 px collapsed strip never overflows.
      if (tabs == null || inline) {
        return Padding(padding: padding, child: row);
      }
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row,
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2, right: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(fit: BoxFit.scaleDown, child: tabs),
              ),
            ),
          ],
        ),
      );
    });
    if (collapsed) {
      return KeyedSubtree(
        key: const ValueKey('composer-gate-inspector'),
        child: header,
      );
    }
    return Column(
      key: const ValueKey('composer-gate-inspector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('composer-inspector-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child:
                _body(context, info, tabbed ? tab : GateInspectorTab.overview),
          ),
        ),
      ],
    );
  }

  Widget _buildContextual(BuildContext context) {
    final info = _info;
    final gate = selectedGate;
    final type = gate?.type ?? previewType;
    final measurement = selectedMeasurement;
    final subject = measurement != null
        ? 'measurement-${measurement.id.value}'
        : gate != null
            ? 'gate-${gate.id.value}'
            : type != null
                ? 'preview-${type.name}'
                : 'none';
    final Widget body;
    if (measurement != null) {
      body = _MeasurementDetails(
        measurement: measurement,
        width: classicalBitWidth,
        usedBits: usedClassicalBits,
        onBitChanged: actions.onClassicalBitChanged,
        onDelete: actions.onDelete,
      );
    } else if (type == null) {
      body = _EmptyState(summary: summary);
    } else {
      final footprint = gate ?? _syntheticFootprint(_previewGate(type));
      final rotation = footprint.gate.requiresAngle;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (gate != null)
            _PlacedGateDetails(
              gate: gate,
              capabilities: capabilities,
              actions: actions,
              replacementTypes: replacementTypes,
              legacyNote: legacyNote,
              showTheory: false,
            )
          else
            _PreviewDetails(type: type, showTheory: false),
          if (info != null)
            _ContextualTheory(
              info: info,
              footprint: footprint,
              // A placed rotation's editor already states what it does.
              describe: !(rotation && gate != null),
              openSections: openSections,
              onSectionChanged: onSectionChanged,
              onOpenRelatedConcept: onOpenRelatedConcept,
            )
          else if (type == SelectedGateType.measureZ) ...[
            const SizedBox(height: 4),
            const Text(
              'Reads one qubit in the Z basis and stores the outcome (0 or 1) '
              'in a classical bit. Run the circuit from the Measure tab.',
              style: QubitQuestTypography.body,
            ),
          ],
        ],
      );
    }
    return Semantics(
      container: true,
      label: 'Gate inspector',
      child: Column(
        key: const ValueKey('composer-gate-inspector'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(
              children: [
                const Expanded(child: QqPanelLabel('Gate inspector')),
                Text(
                  _heading,
                  key: const ValueKey('composer-inspector-heading'),
                  style: QqType.meta,
                ),
                const SizedBox(width: 4),
                if (onClose != null)
                  IconButton(
                    key: const ValueKey('composer-inspector-close'),
                    tooltip: 'Close the inspector (the circuit is unchanged)',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: QubitQuestColors.textMuted,
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('composer-inspector-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: KeyedSubtree(
                // Nothing from a previous subject (an angle draft, a scroll
                // position) leaks into the next one.
                key: ValueKey('composer-inspector-subject-$subject'),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _collapsedSummary() {
    final gate = selectedGate;
    if (gate != null) {
      return '${_gateName(gate.type)} · ${_qubitList(gate)}';
    }
    final m = selectedMeasurement;
    if (m != null) return 'Measurement · q${m.qubit} → c${m.classicalBit}';
    return _heading;
  }

  Widget _body(
    BuildContext context,
    GateEducationalInfo? info,
    GateInspectorTab tab,
  ) {
    if (selectedMeasurement case final measurement?) {
      return _MeasurementDetails(
        measurement: measurement,
        width: classicalBitWidth,
        usedBits: usedClassicalBits,
        onBitChanged: actions.onClassicalBitChanged,
        onDelete: actions.onDelete,
      );
    }
    final gate = selectedGate;
    final type = gate?.type ?? previewType;
    if (type == null) return _EmptyState(summary: summary);
    // Keyed by subject and tab, so nothing from a previous selection (an
    // expansion, a scroll position, a draft) can leak into the new one.
    final subject =
        gate == null ? 'preview-${type.name}' : 'gate-${gate.id.value}';
    if (info != null && tab != GateInspectorTab.overview) {
      final footprint = gate ?? _syntheticFootprint(_previewGate(type));
      return Column(
        key: ValueKey('composer-inspector-${tab.name}-$subject'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The gate stays identified on every section (M4).
          _CompactIdentity(gate: footprint.gate, preview: gate == null),
          const SizedBox(height: 12),
          tab == GateInspectorTab.mathematics
              ? _GateMathematics(info: info, gate: footprint.gate)
              : _GateLearn(
                  info: info,
                  footprint: footprint,
                  onOpenRelatedConcept: onOpenRelatedConcept,
                ),
        ],
      );
    }
    if (gate != null) {
      return _PlacedGateDetails(
        key: ValueKey('composer-inspector-overview-$subject'),
        gate: gate,
        capabilities: capabilities,
        actions: actions,
        replacementTypes: replacementTypes,
        legacyNote: legacyNote,
      );
    }
    return _PreviewDetails(
      key: ValueKey('composer-inspector-overview-$subject'),
      type: type,
    );
  }
}

/// The footprint the inspector's Learn visual uses for a gate *type* that
/// is not in a circuit. Shared with the Notebook's gate articles (M6b), so
/// both show the same educational visual.
LogicalGateFootprint gateEducationalPreviewFootprint(SelectedGateType type) =>
    _syntheticFootprint(_previewGate(type));

/// Default-angle gate used to show a palette preview.
Gate _previewGate(SelectedGateType type) => Gate.fromIdentifier(type,
    angle: Gate.fromIdentifier(type).requiresAngle ? math.pi / 2 : null);

/// A one-fragment footprint for educational visuals of a gate that is not
/// in the circuit (the same shape `GateInspectorDialog.forGate` uses).
LogicalGateFootprint _syntheticFootprint(Gate gate) {
  const id = GateId(-1);
  const location = CircuitLocation(qubit: 0, column: 0);
  return LogicalGateFootprint(
    id: id,
    gate: gate,
    fragments: [
      LogicalGateFragment(
        location: location,
        placedGate: PlacedQuantumGate(id: id, gate: gate),
      ),
    ],
    anchor: location,
    controlQubit: null,
    secondControlQubit: null,
    targetQubit: null,
    isDeletable: true,
  );
}

class _InspectorTabs extends StatelessWidget {
  const _InspectorTabs({required this.selected, required this.onChanged});

  final GateInspectorTab selected;
  final ValueChanged<GateInspectorTab> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<GateInspectorTab>(
        key: const ValueKey('composer-inspector-tabs'),
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        segments: [
          for (final tab in GateInspectorTab.values)
            ButtonSegment(
              value: tab,
              label: Text(tab.label,
                  key: ValueKey('composer-inspector-tab-${tab.name}')),
            ),
        ],
        selected: {selected},
        onSelectionChanged: (value) => onChanged(value.single),
      );
}

String _gateName(SelectedGateType type) => type == SelectedGateType.measureZ
    ? 'Measurement (Z basis)'
    : GateEducationalCatalog.forType(type)?.name ?? gatePaletteLabel(type);

/// Operand qubits only (controls and target); wires a controlled gate's
/// link merely crosses are not operands.
String _qubitList(LogicalGateFootprint gate) {
  final controls = controlQubitsOf(gate);
  final qubits = controls.isEmpty
      ? (gate.occupiedLocations.map((l) => l.qubit).toSet().toList()..sort())
      : ([...controls, gate.targetQubit!]..sort());
  return qubits.map((q) => 'q$q').join(', ');
}

/// Control qubits of [gate] in role order; every control of a
/// multi-controlled X (v2.6 M7).
List<int> controlQubitsOf(LogicalGateFootprint gate) => gate.controlQubits;

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.summary});
  final ComposerCircuitSummary summary;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('web-composer-no-selected-gate'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a gate to inspect it, or drag a gate onto the circuit.',
            key: ValueKey('web-composer-selection-empty'),
            style: QubitQuestTypography.body,
          ),
          const SizedBox(height: 10),
          Wrap(
            key: const ValueKey('composer-inspector-circuit-summary'),
            spacing: 18,
            runSpacing: 6,
            children: [
              _Fact('Qubits', summary.qubits),
              _Fact('Depth', summary.depth),
              _Fact('Gates', summary.gates),
              _Fact('Measurements', summary.measurements),
            ],
          ),
        ],
      );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label ', style: QubitQuestTypography.supporting),
          TextSpan(
            text: '$value',
            style: const TextStyle(
              color: QubitQuestColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ]),
      );
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.tile,
    required this.title,
    required this.subtitle,
    this.titleKey,
    this.tileKey,
    this.subtitleKey,
  });

  final Widget tile;
  final String title;
  final String subtitle;
  final Key? titleKey;
  final Key? tileKey;
  final Key? subtitleKey;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          KeyedSubtree(key: tileKey, child: tile),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, key: titleKey, style: QqType.subjectTitle),
                const SizedBox(height: 2),
                Text(subtitle, key: subtitleKey, style: QqType.meta),
              ],
            ),
          ),
        ],
      );
}

/// Two related regions: explanation/configuration on the left and the
/// mathematics directly beside it (stacked when narrow). The left column has
/// a reading width, so the maths sits next to the text it belongs to instead
/// of drifting to the far edge of a wide inspector.
class _SideBySide extends StatelessWidget {
  const _SideBySide({required this.start, required this.end});
  final Widget start;
  final Widget end;

  static const double breakpoint = 560;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < breakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [start, const SizedBox(height: 14), end],
            );
          }
          final startWidth = math.min(460.0, constraints.maxWidth * .56);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: startWidth, child: start),
              const SizedBox(width: 28),
              Expanded(
                child: Align(alignment: Alignment.topLeft, child: end),
              ),
            ],
          );
        },
      );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: QubitQuestTypography.supporting.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
          ),
        ),
      );
}

/// Overview body shared by previews and placed gates: intuition, basis
/// transformations and the matrix from [GateEducationalCatalog].
class _GateTheory extends StatelessWidget {
  const _GateTheory({required this.info});
  final GateEducationalInfo info;

  @override
  Widget build(BuildContext context) => _SideBySide(
        start: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plainGateText(info.intuition),
                key: const ValueKey('composer-inspector-intuition'),
                style: QubitQuestTypography.body),
            if (info.transformations.isNotEmpty) ...[
              const SizedBox(height: 10),
              const _Caption('BASIS STATES'),
              Wrap(
                key: const ValueKey('composer-inspector-transformations'),
                spacing: 18,
                runSpacing: 6,
                children: [
                  for (final t in info.transformations) _InlineMath(t),
                ],
              ),
            ],
          ],
        ),
        end: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Caption(mathDefinitionHeading(info.matrix)),
            GateEducationalMatrix(
              latexKey: const ValueKey('composer-inspector-matrix'),
              matrix: info.matrix,
              mathFontSize: 19,
              // The Overview column is narrow: wide definitions (CCX's
              // mapping) shrink slightly, then scroll; never below 80%.
              minimumScale: .8,
            ),
          ],
        ),
      );
}

/// Mathematics section: definition, state action, properties, identities.
/// Large matrices (CCX is 8×8) scroll inside their own region at full size.
class _GateMathematics extends StatelessWidget {
  const _GateMathematics({required this.info, required this.gate});
  final GateEducationalInfo info;
  final Gate gate;

  @override
  Widget build(BuildContext context) {
    final rotation = gate.requiresAngle && gate.angle != null;
    return Column(
      key: const ValueKey('composer-inspector-mathematics'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SideBySide(
          start: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Caption(mathDefinitionHeading(info.matrix)),
              GateEducationalMatrix(
                latexKey: const ValueKey('composer-math-matrix'),
                matrix: info.matrix,
                mathFontSize: 21,
              ),
              if (rotation) ...[
                const SizedBox(height: 12),
                _Caption('AT θ = ${formatAngleAsPi(gate.angle!)}'),
                _NumericMatrix(
                  key: const ValueKey('composer-math-numeric-matrix'),
                  title: '${gatePaletteLabel(gate.type)}'
                      '(${formatAngleAsPi(gate.angle!)})',
                  entries: _rotationMatrix(gate.type, gate.angle!),
                ),
              ],
            ],
          ),
          end: info.transformations.isEmpty
              ? const SizedBox.shrink()
              : GateEducationalMathList(
                  title: 'State action',
                  values: info.transformations,
                  level: GateEducationalMathLevel.secondary,
                  keyPrefix: 'composer-math-state',
                  decorated: false,
                  large: true,
                ),
        ),
        const SizedBox(height: 14),
        _SideBySide(
          start: info.properties.isEmpty
              ? const SizedBox.shrink()
              : GateEducationalListSection(
                  title: 'Properties', values: info.properties),
          end: info.identities.isEmpty
              ? const SizedBox.shrink()
              : GateEducationalMathList(
                  title: 'Important identities',
                  values: info.identities,
                  // The persistent inspector has room for readable
                  // identities (the dialog keeps its compact tertiary role).
                  level: GateEducationalMathLevel.secondary,
                  keyPrefix: 'composer-math-identity',
                  decorated: false,
                  large: true,
                ),
        ),
      ],
    );
  }
}

/// Learn section: illustration, conceptual explanation, related concepts.
class _GateLearn extends StatelessWidget {
  const _GateLearn({
    required this.info,
    required this.footprint,
    this.onOpenRelatedConcept,
  });
  final GateEducationalInfo info;
  final LogicalGateFootprint footprint;
  final ValueChanged<String>? onOpenRelatedConcept;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('composer-inspector-learn'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SideBySide(
            start: GateEducationalSummary(info: info, decorated: false),
            // Bounded responsive size (the dialog keeps its 92 px).
            end: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth.clamp(0.0, 380.0);
                return SizedBox(
                  width: width,
                  child: GateEducationalVisualView(
                    key: const ValueKey('composer-learn-visual'),
                    visual: info.visual,
                    footprint: footprint,
                    height: (width * .5).clamp(120.0, 180.0),
                  ),
                );
              },
            ),
          ),
          if (isControlledEducationalVisual(info.visual.kind))
            const GateEducationalTextSection(
              title: 'Why one Bloch sphere is not enough',
              body: controlledGateBlochNote,
            ),
          if (info.relatedConcepts.isNotEmpty)
            GateRelatedConceptsSection(
              concepts: info.relatedConcepts,
              onOpen: onOpenRelatedConcept,
              decorated: false,
            ),
        ],
      );
}

class _PreviewDetails extends StatelessWidget {
  const _PreviewDetails(
      {super.key, required this.type, this.showTheory = true});
  final SelectedGateType type;
  final bool showTheory;

  @override
  Widget build(BuildContext context) {
    final info = GateEducationalCatalog.forType(type);
    final category = gatePaletteCategoryFor(type).label;
    return Column(
      key: const ValueKey('composer-inspector-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Identity(
          tile: type == SelectedGateType.measureZ
              ? const MeasurementGlyph(size: 40)
              : QubitQuestGateTile(
                  gate: _previewGate(type),
                  size: 40,
                  fontSize: isWideGateLabel(type) ? 12 : 16,
                  onPressed: null,
                ),
          title: _gateName(type),
          subtitle: '$category · preview — drag it onto a qubit wire to place',
        ),
        const SizedBox(height: 12),
        if (!showTheory)
          const SizedBox.shrink()
        else if (info != null)
          _GateTheory(info: info)
        else if (type == SelectedGateType.measureZ)
          const Text(
            'Reads one qubit in the Z basis and stores the outcome (0 or 1) '
            'in a classical bit. Run it from the Measure tab.',
            style: QubitQuestTypography.body,
          ),
      ],
    );
  }
}

class _PlacedGateDetails extends StatelessWidget {
  const _PlacedGateDetails({
    super.key,
    required this.gate,
    required this.capabilities,
    required this.actions,
    required this.replacementTypes,
    this.legacyNote,
    this.showTheory = true,
  });

  /// False in the contextual inspector, which shows the theory as its own
  /// stacked sections below the actions.
  final bool showTheory;
  final LogicalGateFootprint gate;
  final ComposerSelectedGateCapabilities capabilities;
  final GateInspectorActions actions;
  final List<SelectedGateType> replacementTypes;
  final String? legacyNote;

  bool _can(ComposerSelectedGateAction a) => capabilities.supports(a);

  @override
  Widget build(BuildContext context) {
    final info = GateEducationalCatalog.forType(gate.type);
    final controls = controlQubitsOf(gate);
    // The qubits are named once: in the relationship line. The subtitle
    // carries only the position.
    final role = controls.isEmpty
        ? 'Single-qubit gate on q${gate.anchor.qubit}'
        : '${controls.length == 1 ? 'Control' : 'Controls'} '
            '${controls.map((c) => 'q$c').join(', ')} → '
            'target q${gate.targetQubit}';
    final readOnly = !gate.isDeletable;
    final rotation = gate.gate.requiresAngle && gate.gate.angle != null;
    final angleEditable =
        rotation && _can(ComposerSelectedGateAction.editAngle);
    final actionButtons = <Widget>[
      if (_can(ComposerSelectedGateAction.replace) &&
          replacementTypes.isNotEmpty)
        _ReplaceMenu(types: replacementTypes, onSelected: actions.onReplace),
      if (_can(ComposerSelectedGateAction.duplicate))
        _ActionButton(
          key: const ValueKey('web-composer-duplicate-selected-gate'),
          icon: Icons.copy_rounded,
          label: 'Duplicate',
          onPressed: actions.onDuplicate,
        ),
      if (_can(ComposerSelectedGateAction.delete))
        _ActionButton(
          key: const ValueKey('web-composer-delete-selected-gate'),
          icon: Icons.delete_outline,
          label: 'Delete',
          destructive: true,
          onPressed: actions.onDelete,
        ),
    ];
    return Column(
      key: const ValueKey('composer-inspector-placed-gate'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Identity(
                tile: Semantics(
                  label: 'Selected component ${gatePaletteLabel(gate.type)}',
                  child: ExcludeSemantics(
                    child: QubitQuestGateTile(
                      gate: gate.gate,
                      size: 40,
                      fontSize: isWideGateLabel(gate.type)
                          ? 12
                          : rotation
                              ? 9.5
                              : 16,
                      onPressed: null,
                    ),
                  ),
                ),
                title: _gateName(gate.type),
                titleKey: const ValueKey('web-composer-selected-gate'),
                tileKey: const ValueKey('web-composer-selection-tile'),
                subtitleKey: const ValueKey('web-composer-selection-position'),
                subtitle: role,
              ),
              // The contextual inspector's subtitle already names every
              // control and the target; the classic panel repeats them.
              if (controls.length >= 3 && showTheory) ...[
                const SizedBox(height: 6),
                Text(
                  '${controls.length} controls: '
                  '${controls.map((c) => 'q$c').join(', ')}  ·  '
                  'Target: q${gate.targetQubit}',
                  key: const ValueKey('composer-inspector-topology'),
                  style: QubitQuestTypography.supporting,
                ),
              ],
              if (readOnly) ...[
                const SizedBox(height: 6),
                const Text(
                  'Part of this activity’s setup. It can be inspected but not '
                  'changed.',
                  key: ValueKey('composer-inspector-read-only'),
                  style: QubitQuestTypography.supporting,
                ),
              ],
              if (legacyNote != null) ...[
                const SizedBox(height: 6),
                Text(legacyNote!, style: QubitQuestTypography.supporting),
              ],
            ],
          );
          final position = Text(
            'Column ${gate.column + 1}',
            key: const ValueKey('web-composer-selected-gate-detail'),
            style: QubitQuestTypography.supporting,
          );
          final buttons = Wrap(
            key: const ValueKey('web-composer-selection-actions'),
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [position, const SizedBox(width: 4), ...actionButtons],
          );
          if (constraints.maxWidth >= 560) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: buttons,
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              // Narrow (contextual inspector, stacked layouts): location
              // belongs to the identity; the actions form their own row,
              // left-aligned under it.
              Padding(
                padding: const EdgeInsets.only(left: 52, top: 2),
                child:
                    DefaultTextStyle.merge(style: QqType.meta, child: position),
              ),
              if (actionButtons.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  key: const ValueKey('web-composer-selection-actions'),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: actionButtons,
                ),
              ],
            ],
          );
        }),
        const SizedBox(height: 14),
        if (rotation)
          RotationAngleEditor(
            key: ValueKey('composer-angle-editor-${gate.id.value}'),
            type: gate.type,
            committedAngle: gate.gate.angle!,
            editable: angleEditable,
            onCommit: (angle) => actions.onAngleCommitted(gate.id, angle),
            info: info,
          )
        else if (info != null && showTheory)
          _GateTheory(info: info),
      ],
    );
  }
}

/// Stacked theory sections of the contextual inspector: a plain sentence,
/// the basis-state rule, then the mathematics and the learning material as
/// closed disclosures (M11B information tiers T3/T4). Every statement comes
/// from [GateEducationalCatalog]; nothing is generated from the circuit.
class _ContextualTheory extends StatelessWidget {
  const _ContextualTheory({
    required this.info,
    required this.footprint,
    required this.describe,
    required this.openSections,
    this.onSectionChanged,
    this.onOpenRelatedConcept,
  });

  final GateEducationalInfo info;
  final LogicalGateFootprint footprint;
  final bool describe;
  final Set<String> openSections;
  final void Function(String section, bool open)? onSectionChanged;
  final ValueChanged<String>? onOpenRelatedConcept;

  @override
  Widget build(BuildContext context) {
    final related = info.relatedConcepts;
    return Column(
      key: const ValueKey('composer-inspector-sections'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (describe) ...[
          const SizedBox(height: 4),
          const Text('What it does', style: QqType.subheading),
          const SizedBox(height: 4),
          Text(plainGateText(info.intuition),
              key: const ValueKey('composer-inspector-intuition'),
              style: QqType.body.copyWith(fontSize: 14.5)),
        ],
        if (info.transformations.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Rule on basis states', style: QqType.subheading),
          const SizedBox(height: 8),
          QqMathWell(
            child: Wrap(
              key: const ValueKey('composer-inspector-transformations'),
              spacing: 18,
              runSpacing: 6,
              children: [for (final t in info.transformations) _InlineMath(t)],
            ),
          ),
        ],
        const SizedBox(height: 20),
        QqDisclosure(
          key: const ValueKey('composer-inspector-section-mathematics'),
          toggleKey:
              const ValueKey('composer-inspector-section-mathematics-toggle'),
          title: 'Mathematics',
          summary: [
            mathDefinitionHeading(info.matrix).toLowerCase(),
            if (info.properties.isNotEmpty) 'properties',
            if (info.identities.isNotEmpty) 'identities',
          ].join(' · '),
          initiallyExpanded: openSections.contains('mathematics'),
          onChanged: (open) => onSectionChanged?.call('mathematics', open),
          child: _GateMathematics(info: info, gate: footprint.gate),
        ),
        QqDisclosure(
          key: const ValueKey('composer-inspector-section-learn'),
          toggleKey: const ValueKey('composer-inspector-section-learn-toggle'),
          title: 'Learn more',
          // Counted, not listed: a truncated list of names said little.
          summary: related.isEmpty
              ? 'picture and explanation'
              : 'picture, explanation · ${related.length} related '
                  'concept${related.length == 1 ? '' : 's'}',
          initiallyExpanded: openSections.contains('learn'),
          onChanged: (open) => onSectionChanged?.call('learn', open),
          child: _GateLearn(
            info: info,
            footprint: footprint,
            onOpenRelatedConcept: onOpenRelatedConcept,
          ),
        ),
      ],
    );
  }
}

/// Inline replacement: an anchored menu of the valid replacement types.
/// Dismissing the menu cancels; choosing issues one host command.
class _ReplaceMenu extends StatelessWidget {
  const _ReplaceMenu({required this.types, required this.onSelected});
  final List<SelectedGateType> types;
  final ValueChanged<SelectedGateType> onSelected;

  @override
  Widget build(BuildContext context) => MenuAnchor(
        style: const MenuStyle(
          backgroundColor:
              WidgetStatePropertyAll(QubitQuestColors.surfaceRaised),
        ),
        menuChildren: [
          for (final type in types)
            MenuItemButton(
              key: ValueKey('composer-replace-with-${type.name}'),
              leadingIcon: SizedBox(
                width: 26,
                height: 26,
                child: QubitQuestGateTile(
                  gate: _previewGate(type),
                  size: 26,
                  fontSize: 11,
                  onPressed: null,
                ),
              ),
              onPressed: () => onSelected(type),
              child: Text(_gateName(type)),
            ),
        ],
        builder: (context, controller, _) => _ActionButton(
          key: const ValueKey('web-composer-replace-selected-gate'),
          icon: Icons.swap_horiz_rounded,
          label: 'Replace',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? QubitQuestColors.error : QubitQuestColors.textBody;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: destructive
              ? QubitQuestColors.error.withValues(alpha: .45)
              : QubitQuestColors.border,
        ),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.compact,
        textStyle: QqType.control.copyWith(fontSize: 13.5),
      ),
    );
  }
}

class _MeasurementDetails extends StatelessWidget {
  const _MeasurementDetails({
    required this.measurement,
    required this.width,
    required this.usedBits,
    required this.onBitChanged,
    required this.onDelete,
  });

  final MeasureZOperation measurement;
  final int width;
  final Map<int, int> usedBits;
  final ValueChanged<int?> onBitChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('composer-inspector-measurement'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Identity(
            tile: MeasurementGlyph(
              size: 40,
              classicalBit: measurement.classicalBit,
            ),
            title: 'Measurement Z',
            titleKey: const ValueKey('web-composer-selected-measurement'),
            tileKey: const ValueKey('web-composer-selection-tile'),
            subtitleKey: const ValueKey('web-composer-selection-position'),
            subtitle: 'q${measurement.qubit} → c${measurement.classicalBit} '
                '· column ${measurement.column + 1}',
          ),
          const SizedBox(height: 8),
          Text(
            'Reads q${measurement.qubit} in the Z basis. Run it from the '
            'Measure tab in Results.',
            key: const ValueKey('web-composer-measurement-note'),
            style: QubitQuestTypography.body,
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              const Text('Classical bit', style: QubitQuestTypography.body),
              DropdownButton<int>(
                key: const ValueKey('web-composer-measurement-classical-bit'),
                value: measurement.classicalBit,
                isDense: true,
                items: [
                  for (var bit = 0; bit < width; bit++)
                    if (usedBits[bit] case final user?
                        when user != measurement.qubit)
                      DropdownMenuItem(
                        value: bit,
                        enabled: false,
                        child: Text('c$bit (used by q$user)'),
                      )
                    else
                      DropdownMenuItem(value: bit, child: Text('c$bit')),
                ],
                onChanged: onBitChanged,
              ),
              _ActionButton(
                key: const ValueKey('web-composer-delete-selected-gate'),
                icon: Icons.delete_outline,
                label: 'Delete',
                destructive: true,
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'The measurement outcome (0 or 1) will be stored in this '
            'classical bit.',
            key: ValueKey('web-composer-classical-bit-help'),
            style: QubitQuestTypography.supporting,
          ),
        ],
      );
}

/// Inspector-first rotation editing.
///
/// Slider movement, presets typed into the field and typed values only
/// change a local *draft* (label and numeric matrix update immediately).
/// Exactly one [onCommit] happens per gesture: on slider release, on preset
/// choice, or on Enter / leaving the field with a valid value. Escape or an
/// invalid value discards the draft. The circuit, its history and its
/// autosave therefore change once per committed edit. The parent keys this
/// widget by gate ID, so a selection change discards any draft.
class RotationAngleEditor extends StatefulWidget {
  const RotationAngleEditor({
    super.key,
    required this.type,
    required this.committedAngle,
    required this.editable,
    required this.onCommit,
    this.info,
  });

  final SelectedGateType type;
  final double committedAngle;
  final bool editable;
  final ValueChanged<double> onCommit;
  final GateEducationalInfo? info;

  static const presets = <(String, double)>[
    ('0', 0),
    ('π/4', math.pi / 4),
    ('π/2', math.pi / 2),
    ('π', math.pi),
    ('3π/2', 3 * math.pi / 2),
  ];

  @override
  State<RotationAngleEditor> createState() => _RotationAngleEditorState();
}

class _RotationAngleEditorState extends State<RotationAngleEditor> {
  late final TextEditingController _text;
  final FocusNode _focus = FocusNode();
  double? _draft;
  String? _error;

  double get _shown => _draft ?? widget.committedAngle;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: formatAngleAsPi(widget.committedAngle));
    _focus.addListener(() {
      if (!_focus.hasFocus) _submitText();
    });
  }

  @override
  void didUpdateWidget(covariant RotationAngleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.committedAngle != widget.committedAngle) {
      // Undo/redo or another commit: show the authoritative value.
      _draft = null;
      _error = null;
      if (!_focus.hasFocus) {
        _text.text = formatAngleAsPi(widget.committedAngle);
      }
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(double angle) {
    setState(() {
      _draft = null;
      _error = null;
      _text.text = formatAngleAsPi(angle);
    });
    if (angle != widget.committedAngle) widget.onCommit(angle);
  }

  void _submitText() {
    if (!mounted) return;
    final parsed = parseAngleExpression(_text.text);
    if (parsed == null) {
      setState(() => _error =
          'Enter an angle in radians or as a multiple of π, e.g. π/2 or 1.57.');
      return;
    }
    _commit(parsed);
  }

  void _revert() {
    setState(() {
      _draft = null;
      _error = null;
      _text.text = formatAngleAsPi(widget.committedAngle);
    });
  }

  String get _axis => switch (widget.type) {
        SelectedGateType.rx => 'X',
        SelectedGateType.ry => 'Y',
        _ => 'Z',
      };

  List<List<Complex>> get _matrix => _rotationMatrix(widget.type, _shown);

  @override
  Widget build(BuildContext context) {
    const fullTurn = 2 * math.pi;
    final sliderValue =
        _shown.isFinite ? (_shown % fullTurn + fullTurn) % fullTurn : 0.0;
    final drafting = _draft != null;
    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rotates the state by θ about the Bloch-sphere $_axis axis.',
          style: QqType.body.copyWith(fontSize: 14.5),
        ),
        const SizedBox(height: 6),
        Text(
          'Angle: ${(widget.committedAngle / math.pi).toStringAsFixed(3)}π '
          '(${widget.committedAngle.toStringAsFixed(6)} rad)',
          key: const ValueKey('web-composer-selected-rotation-angle'),
          style: QqType.meta.copyWith(fontFeatures: QqType.tabular),
        ),
        if (widget.editable) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('θ =', style: QubitQuestTypography.body),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape): _revert,
                  },
                  child: TextField(
                    key: const ValueKey('composer-angle-field'),
                    controller: _text,
                    focusNode: _focus,
                    onSubmitted: (_) => _submitText(),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    style: const TextStyle(
                      color: QubitQuestColors.textPrimary,
                      fontSize: 14,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      border: const OutlineInputBorder(),
                      errorText: _error == null ? null : '',
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      hintText: 'π/2',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  drafting
                      ? 'Draft ${formatAngleAsPi(_shown)} · release to apply'
                      : '${_shown.toStringAsFixed(4)} rad',
                  key: const ValueKey('composer-angle-draft-label'),
                  overflow: TextOverflow.ellipsis,
                  style: QubitQuestTypography.supporting.copyWith(
                    color: drafting
                        ? QubitQuestColors.warning
                        : QubitQuestColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              key: const ValueKey('composer-angle-error'),
              style:
                  const TextStyle(color: QubitQuestColors.error, fontSize: 12),
            ),
          ],
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              key: const ValueKey('composer-angle-slider'),
              min: 0,
              max: fullTurn,
              divisions: 48,
              value: sliderValue,
              label: formatAngleAsPi(sliderValue),
              onChanged: (value) => setState(() {
                _draft = value;
                _error = null;
              }),
              onChangeEnd: _commit,
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, value) in RotationAngleEditor.presets)
                ChoiceChip(
                  key: ValueKey('composer-angle-preset-$label'),
                  label: Text(label),
                  selected: (widget.committedAngle - value).abs() < 1e-12 &&
                      !drafting,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _commit(value),
                ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 6),
          const Text(
            'This activity sets the angle for you.',
            key: ValueKey('composer-angle-locked'),
            style: QubitQuestTypography.supporting,
          ),
        ],
      ],
    );
    final matrix = _NumericMatrix(
      key: const ValueKey('composer-inspector-matrix'),
      title: drafting
          ? 'Draft R${_axis.toLowerCase()}(${formatAngleAsPi(_shown)})'
          : 'R${_axis.toLowerCase()}(${formatAngleAsPi(_shown)})',
      entries: _matrix,
      draft: drafting,
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 560
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: editor),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: matrix),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [editor, const SizedBox(height: 12), matrix],
            ),
    );
  }
}

/// The simulator's own rotation matrix (not a re-derivation).
List<List<Complex>> _rotationMatrix(SelectedGateType type, double angle) =>
    switch (type) {
      SelectedGateType.rx => QuantumMatrix.rx(angle),
      SelectedGateType.ry => QuantumMatrix.ry(angle),
      _ => QuantumMatrix.rz(angle),
    }
        .toComplexList();

String _formatEntry(Complex c) {
  double clean(num v) => v.abs() < 5e-7 ? 0 : v.toDouble();
  final re = clean(c.real);
  final im = clean(c.imaginary);
  String n(double v) => v.toStringAsFixed(3);
  if (im == 0) return n(re);
  if (re == 0) return '${n(im)}i';
  return '${n(re)} ${im < 0 ? '−' : '+'} ${n(im.abs())}i';
}

/// A numeric 2×2 (or larger) matrix drawn with plain text so it can update
/// on every slider tick without re-rendering LaTeX.
class _NumericMatrix extends StatelessWidget {
  const _NumericMatrix({
    super.key,
    required this.title,
    required this.entries,
    this.draft = false,
  });

  final String title;
  final List<List<Complex>> entries;
  final bool draft;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: QubitQuestTypography.supporting.copyWith(
              color:
                  draft ? QubitQuestColors.warning : QubitQuestColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: QubitQuestColors.textMuted),
              ),
            ),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                for (final row in entries)
                  TableRow(children: [
                    for (final value in row)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        child: Text(
                          _formatEntry(value),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: QubitQuestColors.textPrimary,
                            fontSize: 13,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                  ]),
              ],
            ),
          ),
        ],
      );
}

/// Inline mathematics rendered with MathJax (the catalogue's transformations
/// use commands such as \\cdot that native text does not render).
class _InlineMath extends StatelessWidget {
  const _InlineMath(this.math);
  final String math;

  static const _style = TextStyle(
    color: QubitQuestColors.textBody,
    fontSize: 16.5,
  );

  @override
  Widget build(BuildContext context) => LatexText(
        math: math,
        mathFontSize: 16.5,
        textStyle: _style,
        inlineMathColor: QubitQuestColors.textBody,
        inlineMathHeight: 20,
      );
}

/// Compact gate identity kept above the Mathematics and Learn sections, so
/// the subject never disappears when switching sections. Previews say so.
class _CompactIdentity extends StatelessWidget {
  const _CompactIdentity({required this.gate, required this.preview});
  final Gate gate;
  final bool preview;

  @override
  Widget build(BuildContext context) => Row(
        key: const ValueKey('composer-inspector-compact-identity'),
        children: [
          QubitQuestGateTile(
            gate: gate,
            size: 28,
            fontSize: isWideGateLabel(gate.type)
                ? 9
                : gate.requiresAngle
                    ? 7.5
                    : 13,
            onPressed: null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: _gateName(gate.type),
                  style: QubitQuestTypography.heading.copyWith(fontSize: 14.5),
                ),
                TextSpan(
                  text: preview ? '  ·  palette preview' : '  ·  selected',
                  style: QubitQuestTypography.supporting,
                ),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}
