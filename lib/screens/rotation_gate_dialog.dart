import 'package:flutter/material.dart';
import 'dart:math' as math;

void showRotationGateDialog(BuildContext context, Function(double) onAngleSelected) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return RotationGateDialog(onAngleSelected: onAngleSelected);
    },
  );
}

class RotationGateDialog extends StatefulWidget {
  final Function(double) onAngleSelected;

  const RotationGateDialog({Key? key, required this.onAngleSelected}) : super(key: key);

  @override
  _RotationGateDialogState createState() => _RotationGateDialogState();
}

class _RotationGateDialogState extends State<RotationGateDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _numericalController = TextEditingController();
  final TextEditingController _numeratorController = TextEditingController();
  final TextEditingController _denominatorController = TextEditingController();

  double _calculatedAngle = 0.0;
  bool _isPiMode = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _numeratorController.text = '1';
    _denominatorController.text = '1';
    _updateAngle();
  }

  void _onTabChanged() {
    setState(() {
      _updateAngle();
    });
  }

  void _updateAngle() {
    if (_tabController.index == 0) { // Numerical Input
      double? value = double.tryParse(_numericalController.text);
      _calculatedAngle = value ?? 0.0;
    } else { // Fractional Input
      double numerator = double.tryParse(_numeratorController.text) ?? 0.0;
      double denominator = double.tryParse(_denominatorController.text) ?? 1.0;
      if (denominator == 0) denominator = 1.0;
      if (_isPiMode) {
        _calculatedAngle = (numerator / denominator) * math.pi;
      } else {
        _calculatedAngle = numerator / denominator;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _numericalController.dispose();
    _numeratorController.dispose();
    _denominatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Set Rotation Angle",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Numerical"),
                Tab(text: "Fractional"),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNumericalInput(),
                  _buildFractionalInput(),
                ],
              ),
            ),
            _buildCalculatedAngleDisplay(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton("Cancel", () {
                  Navigator.of(context).pop();
                }),
                _buildButton("OK", () {
                  widget.onAngleSelected(_calculatedAngle);
                  Navigator.of(context).pop();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericalInput() {
    return Column(
      children: [
        const Text(
          "Enter angle in radians",
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _numericalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "e.g. 3.14159",
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
            filled: true,
            fillColor: const Color(0xFF2D2E40),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => _updateAngle(),
        ),
      ],
    );
  }

  Widget _buildFractionalInput() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Multiply by π?",
              style: TextStyle(color: Colors.white70),
            ),
            Switch(
              value: _isPiMode,
              onChanged: (bool value) {
                setState(() {
                  _isPiMode = value;
                  _updateAngle();
                });
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: _numeratorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(),
                onChanged: (_) => _updateAngle(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "/",
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _denominatorController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(),
                onChanged: (_) => _updateAngle(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      hintText: "1",
      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
      filled: true,
      fillColor: const Color(0xFF2D2E40),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildCalculatedAngleDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2E40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "Final Angle: ${_calculatedAngle.toStringAsFixed(3)} rad",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF1E1E2C),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.blue, width: 2),
        ),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.5),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
