import 'package:flutter/material.dart';
import 'package:quantumquiz/models/selected_gate_type.dart';

class GateGradientStyle {
  final Color top;
  final Color middle;
  final Color bottom;

  const GateGradientStyle({
    required this.top,
    required this.middle,
    required this.bottom,
  });

  List<Color> get colors => [top, middle, bottom];
}

class QubitQuestGateStyle {
  static const Color border = Color(0xFF31405F);
  static const double borderWidth = 1.2;
  static const double buttonRadius = 10;

  static const GateGradientStyle xFamily = GateGradientStyle(
    top: Color(0xFF4A8DFF),
    middle: Color(0xFF2F6FEA),
    bottom: Color(0xFF1F4FC7),
  );

  static const GateGradientStyle y = GateGradientStyle(
    top: Color(0xFF62D8F6),
    middle: Color(0xFF3FB8DD),
    bottom: Color(0xFF238CB3),
  );

  static const GateGradientStyle z = GateGradientStyle(
    top: Color(0xFF386EFF),
    middle: Color(0xFF244ED2),
    bottom: Color(0xFF162D8F),
  );

  static const GateGradientStyle h = GateGradientStyle(
    top: Color(0xFFFF6A63),
    middle: Color(0xFFE44747),
    bottom: Color(0xFFB92B2B),
  );

  static const GateGradientStyle s = GateGradientStyle(
    top: Color(0xFF8AA2FF),
    middle: Color(0xFF6577E8),
    bottom: Color(0xFF3A47B8),
  );

  static const GateGradientStyle phase = GateGradientStyle(
    top: Color(0xFFB65CFF),
    middle: Color(0xFF8E46E8),
    bottom: Color(0xFF6126C9),
  );

  static const GateGradientStyle cz = GateGradientStyle(
    top: Color(0xFF4BCBFF),
    middle: Color(0xFF3193E8),
    bottom: Color(0xFF2356B8),
  );

  static const GateGradientStyle delete = GateGradientStyle(
    top: Color(0xFF39C784),
    middle: Color(0xFF239D66),
    bottom: Color(0xFF166D49),
  );

  static GateGradientStyle forGate(Gate gate) {
    switch (gate.type) {
      case SelectedGateType.hadamard:
        return h;
      case SelectedGateType.x:
      case SelectedGateType.cnot:
      case SelectedGateType.ccnot:
      case SelectedGateType.rx:
        return xFamily;
      case SelectedGateType.y:
      case SelectedGateType.ry:
        return y;
      case SelectedGateType.z:
        return z;
      case SelectedGateType.s:
        return s;
      case SelectedGateType.t:
      case SelectedGateType.rz:
        return phase;
      case SelectedGateType.cz:
        return cz;
      case SelectedGateType.delete:
        return delete;
      default:
        return GateGradientStyle(
          top: gate.color,
          middle: Color.lerp(gate.color, Colors.black, 0.18)!,
          bottom: Color.lerp(gate.color, Colors.black, 0.34)!,
        );
    }
  }
}
