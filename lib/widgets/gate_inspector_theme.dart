import 'package:flutter/material.dart';

/// The single typography contract for every Gate Inspector presentation.
///
/// Educational metadata contains content only. Inspector widgets choose one of
/// these semantic roles, so newly mapped gates inherit the same hierarchy.
abstract final class GateInspectorTheme {
  static const Color bodyColor = Color(0xFFD6E3F8);
  static const Color mutedColor = Color(0xFF95A4BC);

  static const TextStyle title = TextStyle(
    color: Colors.white,
    fontSize: 19,
    fontWeight: FontWeight.w900,
    height: 1.12,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  static const TextStyle body = TextStyle(
    color: bodyColor,
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    color: mutedColor,
    fontSize: 12,
    height: 1.4,
  );

  static const TextStyle mathPrimary = TextStyle(
    color: bodyColor,
    fontSize: 15,
    height: 1.35,
  );

  static const TextStyle mathSecondary = TextStyle(
    color: bodyColor,
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle mathTertiary = TextStyle(
    color: bodyColor,
    fontSize: 12,
    height: 1.65,
  );

  static const double mathPrimaryInlineHeight = 20;
  static const double mathPrimaryDisplayHeight = 28;
  static const double mathSecondaryInlineHeight = 16;
  static const double mathSecondaryDisplayHeight = 20;
  static const double mathTertiaryInlineHeight = 11;
  static const double mathTertiaryDisplayHeight = 12;

  static const double visualAxisLabelSize = 9;
  static const double visualGateNameSize = 19;
  static const double visualBehaviorSize = 11;
  static const double visualCaptionSize = 10;
  static const double visualStateSize = 15;
  static const double visualDiagramGateSize = 16;
}
