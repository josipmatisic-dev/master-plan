/// Ocean Glass Design System - Color Palette
/// 
/// Defines the complete color system for the Marine Navigation App
/// following the Ocean Glass design language.
library;

import 'package:flutter/material.dart';

/// Primary color palette for Ocean Glass design system
class OceanColors {
  OceanColors._(); // Private constructor to prevent instantiation
  
  // ============ Primary Colors ============
  
  /// Deep Navy (#0A1F3F) - Primary background, night mode
  static const Color deepNavy = Color(0xFF0A1F3F);
  
  /// Teal (#1D566E) - Secondary accents, depth
  static const Color teal = Color(0xFF1D566E);
  
  /// Seafoam Green (#00C9A7) - Primary accent, active states
  static const Color seafoamGreen = Color(0xFF00C9A7);
  
  /// Safety Orange (#FF9A3D) - Warnings, alerts
  static const Color safetyOrange = Color(0xFFFF9A3D);
  
  /// Coral Red (#FF6B6B) - Danger, critical alerts
  static const Color coralRed = Color(0xFFFF6B6B);
  
  /// Pure White (#FFFFFF) - Text, icons, borders
  static const Color pureWhite = Color(0xFFFFFFFF);
  
  // ============ Semantic Colors ============
  
  /// Primary accent color
  static const Color primary = seafoamGreen;
  
  /// Secondary color for depth and accents
  static const Color secondary = teal;
  
  /// Background color for dark mode
  static const Color background = deepNavy;
  
  /// Surface color for cards and containers (lighter navy)
  static const Color surface = Color(0xFF1A2F4F);
  
  /// Error and danger states
  static const Color error = coralRed;
  
  /// Warning states
  static const Color warning = safetyOrange;
  
  /// Success states
  static const Color success = seafoamGreen;
  
  // ============ Text Colors ============
  
  /// Primary text color (pure white)
  static const Color textPrimary = pureWhite;
  
  /// Secondary text color (light steel blue)
  static const Color textSecondary = Color(0xFFB0C4DE);
  
  /// Disabled text color (medium gray-blue)
  static const Color textDisabled = Color(0xFF5A6F89);
  
  // ============ Glass Effect Colors ============
  
  /// Dark glass background with 75% opacity
  static final Color glassBackground = deepNavy.withOpacity(0.75);
  
  /// Light glass background with 85% opacity
  static final Color glassBackgroundLight = pureWhite.withOpacity(0.85);
  
  /// Glass border with 20% opacity
  static final Color glassBorder = pureWhite.withOpacity(0.2);
  
  /// Glass border for light mode
  static final Color glassBorderLight = Colors.black.withOpacity(0.1);
  
  /// Shadow color for glass effects
  static final Color glassShadow = Colors.black.withOpacity(0.3);
  
  // ============ Light Mode Colors ============
  
  /// Light background
  static const Color backgroundLight = Color(0xFFF5F9FC);
  
  /// Light surface
  static const Color surfaceLight = pureWhite;
  
  /// Light mode primary text
  static const Color textPrimaryLight = Color(0xFF0A1F3F);
  
  /// Light mode secondary text
  static const Color textSecondaryLight = Color(0xFF5A6F89);
}
