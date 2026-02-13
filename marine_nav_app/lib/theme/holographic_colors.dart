/// Holographic Cyberpunk Design System - Color Palette
///
/// Defines the complete color system for the Holographic Cyberpunk theme
/// with vibrant neon colors and cosmic backgrounds.
library;

import 'package:flutter/material.dart';

/// Color palette for Holographic Cyberpunk theme variant
class HolographicColors {
  HolographicColors._();

  // ============ Primary Neon Colors ============

  /// Electric Blue (#00D9FF) - Primary accent, active states, main glow color
  static const Color electricBlue = Color(0xFF00D9FF);

  /// Neon Cyan (#00FFFF) - Secondary accent, highlights
  static const Color neonCyan = Color(0xFF00FFFF);

  /// Neon Magenta (#FF00FF) - Tertiary accent, warnings, alert glow
  static const Color neonMagenta = Color(0xFFFF00FF);

  /// Cyber Purple (#8B00FF) - Gradient component, depth accent
  static const Color cyberPurple = Color(0xFF8B00FF);

  /// Deep Purple (#4B0082) - Gradient component, backgrounds
  static const Color deepPurple = Color(0xFF4B0082);

  // ============ Background Colors ============

  /// Cosmic Black (#0A0A1A) - Primary background color
  static const Color cosmicBlack = Color(0xFF0A0A1A);

  /// Space Navy (#1A1A2E) - Secondary background, surface color
  static const Color spaceNavy = Color(0xFF1A1A2E);

  /// Pure White (#FFFFFF) - Text, icons
  static const Color pureWhite = Color(0xFFFFFFFF);

  // ============ Semantic Colors ============

  /// Primary accent color
  static const Color primary = electricBlue;

  /// Secondary color
  static const Color secondary = neonCyan;

  /// Background color
  static const Color background = cosmicBlack;

  /// Surface color for cards and containers
  static const Color surface = spaceNavy;

  /// Error states (brighter magenta)
  static const Color error = neonMagenta;

  /// Warning states (electric blue with orange tint)
  static const Color warning = Color(0xFFFFAA00);

  /// Success states (cyan)
  static const Color success = neonCyan;

  // ============ Text Colors ============

  /// Primary text color
  static const Color textPrimary = pureWhite;

  /// Secondary text color (dimmed white)
  static const Color textSecondary = Color(0xFFB8B8D0);

  /// Disabled text color
  static const Color textDisabled = Color(0xFF5A5A70);

  // ============ Glassmorphism Effect Colors ============

  /// Glass background with 15% opacity (more transparent than Ocean Glass)
  static final Color glassBackground = spaceNavy.withValues(alpha: 0.15);

  /// Glass border - Electric Blue with 30% opacity
  static final Color glassBorder = electricBlue.withValues(alpha: 0.3);

  /// Glass border (hover/active state) - 50% opacity
  static final Color glassBorderActive = electricBlue.withValues(alpha: 0.5);

  /// Glass shadow color for depth
  static final Color glassShadow = Colors.black.withValues(alpha: 0.5);

  // ============ Glow Effect Colors ============

  /// Electric Blue glow variants for multi-layer shadows
  static final Color glowInner = electricBlue.withValues(alpha: 0.5);
  static final Color glowMiddle = electricBlue.withValues(alpha: 0.6);
  static final Color glowOuter = electricBlue.withValues(alpha: 0.5);

  /// Magenta glow variants (for alerts)
  static final Color glowMagentaInner = neonMagenta.withValues(alpha: 0.5);
  static final Color glowMagentaMiddle = neonMagenta.withValues(alpha: 0.6);
  static final Color glowMagentaOuter = neonMagenta.withValues(alpha: 0.5);

  /// Cyan glow variants (for success)
  static final Color glowCyanInner = neonCyan.withValues(alpha: 0.5);
  static final Color glowCyanMiddle = neonCyan.withValues(alpha: 0.6);
  static final Color glowCyanOuter = neonCyan.withValues(alpha: 0.5);

  // ============ Gradient Definitions ============

  /// Purple-to-Blue gradient (diagonal)
  static const LinearGradient purpleToBlue = LinearGradient(
    colors: [cyberPurple, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Magenta-to-Cyan gradient (diagonal)
  static const LinearGradient magentaToCyan = LinearGradient(
    colors: [neonMagenta, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep space background gradient (vertical)
  static const LinearGradient deepSpaceBackground = LinearGradient(
    colors: [
      cosmicBlack,
      spaceNavy,
      deepPurple,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.6, 1.0],
  );

  /// Radial gradient for orbs (center to edge)
  static const RadialGradient orbGradient = RadialGradient(
    colors: [
      deepPurple,
      Colors.transparent,
    ],
    stops: [0.0, 1.0],
  );

  // ============ Particle Colors ============

  /// Particle color options (randomly selected)
  static const List<Color> particleColors = [
    electricBlue,
    neonCyan,
    neonMagenta,
  ];
}
