import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// Defines the two modes for angle input
enum AngleInputMode { numerical, fractional }

class RotationGateDialog extends StatefulWidget {

  const RotationGateDialog({super.key});

  @override
  State<RotationGateDialog> createState() => _RotationGateDialogState();
}

class _RotationGateDialogState extends State<RotationGateDialog> {
  AngleInputMode _inputMode = AngleInputMode.fractional; // Default to fractional (Pi mode)
  final TextEditingController _numericalController = TextEditingController();
  final TextEditingController _numeratorController = TextEditingController();
  final TextEditingController _denominatorController = TextEditingController();

  double _calculatedAngle = 0.0;

  @override
  void initState() {
    super.initState();
    // Set initial default values
    _numeratorController.text = '1';
    _denominatorController.text = '1';

    // Start listening to update angle on text change
    _numericalController.addListener(_updateAngle);
    _numeratorController.addListener(_updateAngle);
    _denominatorController.addListener(_updateAngle);

    // Calculate initial angle
    _updateAngle();
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
        double? value = double.tryParse(_numericalController.text);
        _calculatedAngle = value ?? 0.0;
      } else {
        // Fractional (Pi) mode
        double numerator = double.tryParse(_numeratorController.text) ?? 0.0;
        double denominator = double.tryParse(_denominatorController.text) ?? 1.0;

        // Prevent division by zero, default to 1
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

  // Helper function to create the correct input formatters based on the field
  List<TextInputFormatter> _getFormatters(bool allowNegative) {
    // Allows digits, decimal points, and optionally the minus sign
    final String regex = allowNegative ? r'^-?\d*\.?\d*' : r'^\d*\.?\d*';
    return [
      FilteringTextInputFormatter.allow(RegExp(regex)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Rotation Angle', style: TextStyle(color: Colors.white),),
      backgroundColor: Colors.grey[800], // Dark background for the dialog
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Radio Buttons for Mode Selection ---
            _buildModeSelection(),
            const SizedBox(height: 20),

            // --- Input Field based on Mode ---
            _inputMode == AngleInputMode.numerical
                ? _buildNumericalInput()
                : _buildFractionalInput(),

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRadioTile(
          title: 'Fractional (π)',
          mode: AngleInputMode.fractional,
        ),
        _buildRadioTile(
          title: 'Numerical (rad)',
          mode: AngleInputMode.numerical,
        ),
      ],
    );
  }

  Widget _buildRadioTile({required String title, required AngleInputMode mode}) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _inputMode = mode;
            _updateAngle(); // Recalculate based on the newly selected mode's values
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          child: Row(
            children: [
              Radio<AngleInputMode>(
                value: mode,
                groupValue: _inputMode,
                onChanged: (AngleInputMode? newValue) {
                  setState(() {
                    _inputMode = newValue!;
                    _updateAngle();
                  });
                },
                fillColor: MaterialStateProperty.all(Colors.blueAccent),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumericalInput() {
    return TextField(
      controller: _numericalController,
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      inputFormatters: _getFormatters(true), // Allow negative sign for full numerical input
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration().copyWith(hintText: 'Enter angle in radians'),
    );
  }

  Widget _buildFractionalInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _numeratorController,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            inputFormatters: _getFormatters(true), // Numerator can be negative
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration().copyWith(hintText: 'Numerator'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '/',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _denominatorController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _getFormatters(false), // Denominator must be non-negative
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration().copyWith(hintText: 'Denominator'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text('π', style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
      filled: true,
      fillColor: const Color(0xFF2D2E40),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
