/// Holographic Cyberpunk Design System - Effects Utilities
///
/// Provides reusable utilities for neon glow effects, shadows, and text glows
/// that are central to the holographic cyberpunk theme.
///
/// Based on HOLOGRAPHIC_THEME_SPEC.md visual specifications.
library;

import 'package:flutter/material.dart';

export 'holographic_gradients.dart';
export 'holographic_shimmer_utils.dart';

/// Provides neon glow decoration utilities for the holographic theme.
///
/// Creates multi-layer BoxDecoration with customizable glow intensity
/// and active/idle state support.
class NeonGlowDecoration {
  NeonGlowDecoration._();

  /// Creates a neon glow BoxDecoration with multi-layer shadow effects.
  static BoxDecoration neonGlow({
    required Color color,
    double intensity = 1.0,
    bool isActive = false,
  }) {
    if (intensity <= 0) intensity = 1.0;

    if (isActive) {
      return BoxDecoration(
        boxShadow: [
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
        ],
      );
    } else {
      return BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8 * intensity,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20 * intensity,
            spreadRadius: -5,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 40 * intensity,
            spreadRadius: -10,
            offset: Offset.zero,
          ),
        ],
      );
    }
  }

  /// Creates a neon glow BoxDecoration with combined border and shadow.
  static BoxDecoration neonGlowWithBorder({
    required Color color,
    double borderWidth = 1.5,
    double intensity = 1.0,
    double borderRadius = 16,
  }) {
    if (intensity <= 0) intensity = 1.0;

    return BoxDecoration(
      border: Border.all(
        color: color.withValues(alpha: 0.3),
        width: borderWidth,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 8 * intensity,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 20 * intensity,
          spreadRadius: -5,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 40 * intensity,
          spreadRadius: -10,
        ),
      ],
    );
  }
}
