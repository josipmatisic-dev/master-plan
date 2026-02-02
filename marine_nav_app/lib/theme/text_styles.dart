/// Ocean Glass Design System - Typography
///
/// Defines the complete typography system following the Ocean Glass
/// design language with SF Pro Display / Poppins font stack.
library;

import 'package:flutter/material.dart';

/// Typography styles for Ocean Glass design system
class OceanTextStyles {
  OceanTextStyles._(); // Private constructor

  // ============ Font Configuration ============

  /// Primary font family (SF Pro Display on Apple, Poppins fallback)
  static const String fontFamily = 'Poppins';

  // ============ Data Display Styles ============

  /// Data Value: 56pt Bold - Large numeric displays (SOG, COG)
  static const TextStyle dataValue = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  // ============ Heading Styles ============

  /// Heading 1: 32pt Semibold - Screen titles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: -0.5,
  );

  /// Heading 2: 24pt Semibold - Section headers
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: fontFamily,
    letterSpacing: -0.3,
  );

  // ============ Body Text Styles ============

  /// Body Large: 18pt Regular - Prominent body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  /// Body: 16pt Regular - Standard content
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  /// Body Small: 14pt Regular - Secondary content
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
    letterSpacing: 0,
  );

  // ============ Label Styles ============

  /// Label Large: 14pt Medium - Form labels, units
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  /// Label: 12pt Medium - Small labels, captions
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  /// Label Small: 10pt Medium - Tiny labels, hints
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
    fontFamily: fontFamily,
    letterSpacing: 0.8,
  );
}
