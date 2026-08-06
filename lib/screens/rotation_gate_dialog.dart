import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quantumquiz/widgets/qubit_quest_dialog.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

enum AngleInputMode { numerical, fractional }

class RotationGateDialog extends StatefulWidget {
  final SelectedGateType? gateType;
  final double? initialAngle;

  const RotationGateDialog({
    super.key,
    this.gateType,
    this.initialAngle,
  });

  @override
  State<RotationGateDialog> createState() => _RotationGateDialogState();
}

class _RotationGateDialogState extends State<RotationGateDialog> {
  AngleInputMode _inputMode = AngleInputMode.fractional;
  final TextEditingController _numericalController = TextEditingController();
  final TextEditingController _numeratorController = TextEditingController();
  final TextEditingController _denominatorController = TextEditingController();

  double _calculatedAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _initialiseFields(widget.initialAngle);

    _numericalController.addListener(_updateAngle);
    _numeratorController.addListener(_updateAngle);
    _denominatorController.addListener(_updateAngle);
  }

  void _initialiseFields(double? angle) {
    if (angle == null || !angle.isFinite) {
      _numeratorController.text = '1';
      _denominatorController.text = '1';
      _calculatedAngle = math.pi;
      return;
    }
    const denominators = [1, 2, 3, 4, 5, 6, 7, 8, 9, 16];
    for (final denominator in denominators) {
      final numerator = angle / math.pi * denominator;
      if ((numerator - numerator.round()).abs() <= 1e-9) {
        _inputMode = AngleInputMode.fractional;
        _numeratorController.text = numerator.round().toString();
        _denominatorController.text = denominator.toString();
        _calculatedAngle = angle;
        return;
      }
    }
    _inputMode = AngleInputMode.numerical;
    _numericalController.text = angle.toString();
    _calculatedAngle = angle;
  }

  @override
  void dispose() {
    _numericalController.removeListener(_updateAngle);
    _numeratorController.removeListener(_updateAngle);
    _denominatorController.removeListener(_updateAngle);

    _numericalController.dispose();
    _numeratorController.dispose();
    _denominatorController.dispose();
    super.dispose();
  }

  void _updateAngle() {
    setState(() {
      if (_inputMode == AngleInputMode.numerical) {
        final double? value = double.tryParse(_numericalController.text);
        _calculatedAngle = value ?? 0.0;
      } else {
        final double numerator =
            double.tryParse(_numeratorController.text) ?? 0.0;
        final double denominator =
            double.tryParse(_denominatorController.text) ?? 1.0;

        if (denominator == 0) {
          _calculatedAngle = 0.0;
        } else {
          _calculatedAngle = (numerator / denominator) * math.pi;
        }
      }
    });
  }

  void _validateAndSubmit() {
    Navigator.of(context).pop({
      'angle1': _calculatedAngle,
    });
  }

  List<TextInputFormatter> _getFormatters(bool allowNegative) {
    final String regex = allowNegative ? r'^-?\d*\.?\d*' : r'^\d*\.?\d*';
    return [
      FilteringTextInputFormatter.allow(RegExp(regex)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return QubitQuestDialog(
      title: widget.gateType == null
          ? 'Set Rotation Angle'
          : 'Edit ${_gateName(widget.gateType!)} Angle',
      maxWidth: 500,
      actions: [
        QubitQuestDialogButton.secondary(
          label: 'Cancel',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        QubitQuestDialogButton.primary(
          label: 'Apply',
          onPressed: _validateAndSubmit,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildModeSelection(),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            child: _inputMode == AngleInputMode.numerical
                ? _buildNumericalInput()
                : _buildFractionalInput(),
          ),
          const SizedBox(height: 14),
          _AnglePreview(angle: _calculatedAngle),
        ],
      ),
    );
  }

  String _gateName(SelectedGateType type) => switch (type) {
        SelectedGateType.rx => 'Rx',
        SelectedGateType.ry => 'Ry',
        SelectedGateType.rz => 'Rz',
        _ => Gate.fromIdentifier(type).label,
      };

  Widget _buildModeSelection() {
    return Container(
      decoration: BoxDecoration(
        color: QubitQuestDialog.innerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildModeButton(
            title: 'Fractional (π)',
            mode: AngleInputMode.fractional,
          ),
          _buildModeButton(
            title: 'Numerical (rad)',
            mode: AngleInputMode.numerical,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required AngleInputMode mode,
  }) {
    final bool selected = _inputMode == mode;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _inputMode = mode;
            _updateAngle();
          });
        },
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? QubitQuestDialog.purple.withValues(alpha: 0.24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? QubitQuestDialog.purple.withValues(alpha: 0.62)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFB9C6DD),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericalInput() {
    return TextField(
      key: const ValueKey('numerical-angle-input'),
      controller: _numericalController,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      inputFormatters: _getFormatters(true),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      cursorColor: QubitQuestDialog.cyan,
      decoration: _inputDecoration(hintText: 'Enter angle in radians'),
    );
  }

  Widget _buildFractionalInput() {
    return Row(
      key: const ValueKey('fractional-angle-input'),
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('fractional-angle-numerator'),
            controller: _numeratorController,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: _getFormatters(true),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            cursorColor: QubitQuestDialog.cyan,
            decoration: _inputDecoration(hintText: 'Numerator'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '/',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            key: const ValueKey('fractional-angle-denominator'),
            controller: _denominatorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _getFormatters(false),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            cursorColor: QubitQuestDialog.cyan,
            decoration: _inputDecoration(hintText: 'Denominator'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text(
            'π',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: QubitQuestDialog.mutedText,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: QubitQuestDialog.innerColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: QubitQuestDialog.borderSoftColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: QubitQuestDialog.cyan.withValues(alpha: 0.72),
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: QubitQuestDialog.borderSoftColor),
      ),
    );
  }
}

class _AnglePreview extends StatelessWidget {
  const _AnglePreview({required this.angle});

  final double angle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QubitQuestDialog.cardColor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: QubitQuestDialog.borderSoftColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          'Angle: ${angle.toStringAsFixed(4)} rad',
          style: const TextStyle(
            color: Color(0xFFD6E3F8),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
