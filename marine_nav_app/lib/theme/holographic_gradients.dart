/// Holographic Cyberpunk Design System - Gradient Builders
///
/// Pre-configured shadow lists for different neon colors and
/// intensified glow states. Part of the holographic effects system.
library;

import 'package:flutter/material.dart';
import 'holographic_colors.dart';

/// Provides pre-configured shadow lists for different neon colors.
///
/// Each color variant contains 3-layer shadow configurations optimized
/// for neon glow effects.
class GlowShadows {
  GlowShadows._();

  /// Electric Blue glow shadows (default primary glow).
  static List<BoxShadow> electricBlue({double intensity = 1.0}) {
    if (intensity <= 0) intensity = 1.0;
    return [
      BoxShadow(
        color: HolographicColors.electricBlue.withValues(alpha: 0.2),
        blurRadius: 8 * intensity,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: HolographicColors.electricBlue.withValues(alpha: 0.3),
        blurRadius: 20 * intensity,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: HolographicColors.electricBlue.withValues(alpha: 0.4),
        blurRadius: 40 * intensity,
        spreadRadius: -10,
        offset: Offset.zero,
      ),
    ];
  }

  /// Neon Magenta glow shadows (alerts and warnings).
  static List<BoxShadow> neonMagenta({double intensity = 1.0}) {
    if (intensity <= 0) intensity = 1.0;
    return [
      BoxShadow(
        color: HolographicColors.neonMagenta.withValues(alpha: 0.2),
        blurRadius: 8 * intensity,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: HolographicColors.neonMagenta.withValues(alpha: 0.3),
        blurRadius: 20 * intensity,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: HolographicColors.neonMagenta.withValues(alpha: 0.4),
        blurRadius: 40 * intensity,
        spreadRadius: -10,
        offset: Offset.zero,
      ),
    ];
  }

  /// Neon Cyan glow shadows (success and secondary accents).
  static List<BoxShadow> neonCyan({double intensity = 1.0}) {
    if (intensity <= 0) intensity = 1.0;
    return [
      BoxShadow(
        color: HolographicColors.neonCyan.withValues(alpha: 0.2),
        blurRadius: 8 * intensity,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: HolographicColors.neonCyan.withValues(alpha: 0.3),
        blurRadius: 20 * intensity,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: HolographicColors.neonCyan.withValues(alpha: 0.4),
        blurRadius: 40 * intensity,
        spreadRadius: -10,
        offset: Offset.zero,
      ),
    ];
  }

  /// Intensified glow shadows for active/hover states.
  static List<BoxShadow> intensified({
    required Color color,
    double intensity = 1.0,
  }) {
    if (intensity <= 0) intensity = 1.0;
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.5),
        blurRadius: 12 * intensity,
        spreadRadius: 2,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.6),
        blurRadius: 30 * intensity,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.5),
        blurRadius: 60 * intensity,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
    ];
  }
}
