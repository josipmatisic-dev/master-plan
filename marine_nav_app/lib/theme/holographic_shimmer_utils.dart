/// Holographic Cyberpunk Design System - Shimmer & Glow Utilities
///
/// Text glow effects, responsive glow scaling, and glow animation
/// transition helpers. Part of the holographic effects system.
library;

import 'package:flutter/material.dart';
import 'holographic_effects.dart';

/// Provides text shadow configurations for glowing text effects.
class TextGlow {
  TextGlow._();

  /// Strong glow effect for large data value text (56pt).
  static List<Shadow> dataValue(Color color) {
    return [
      Shadow(
        color: color.withValues(alpha: 0.6),
        blurRadius: 20,
        offset: Offset.zero,
      ),
      Shadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 40,
        offset: Offset.zero,
      ),
    ];
  }

  /// Medium glow effect for heading text (32pt).
  static List<Shadow> heading(Color color) {
    return [
      Shadow(
        color: color.withValues(alpha: 0.4),
        blurRadius: 12,
        offset: Offset.zero,
      ),
    ];
  }

  /// Light glow effect for body text and labels.
  static List<Shadow> subtle(Color color) {
    return [
      Shadow(
        color: color.withValues(alpha: 0.2),
        blurRadius: 6,
        offset: Offset.zero,
      ),
    ];
  }

  /// Glowing text with inner and outer bloom layers.
  static List<Shadow> prominent({
    required Color color,
    double intensity = 1.0,
  }) {
    if (intensity <= 0) intensity = 1.0;
    return [
      Shadow(
        color: color.withValues(alpha: 0.5),
        blurRadius: 12 * intensity,
        offset: Offset.zero,
      ),
      Shadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 24 * intensity,
        offset: Offset.zero,
      ),
    ];
  }
}

/// Utility for creating responsive glow effects based on device size.
class ResponsiveGlow {
  ResponsiveGlow._();

  /// Gets the appropriate intensity multiplier for current device size.
  static double getIntensityMultiplier(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) {
      return 1.0;
    } else if (width > 600) {
      return 0.8;
    } else {
      return 0.6;
    }
  }

  /// Gets a neon glow with responsive intensity.
  static BoxDecoration responsiveNeonGlow(
    BuildContext context, {
    required Color color,
    bool isActive = false,
  }) {
    final intensity = getIntensityMultiplier(context);
    return NeonGlowDecoration.neonGlow(
      color: color,
      intensity: intensity,
      isActive: isActive,
    );
  }

  /// Gets shadow list with responsive intensity.
  static List<BoxShadow> responsiveShadows(
    BuildContext context, {
    required Color color,
  }) {
    final intensity = getIntensityMultiplier(context);
    return GlowShadows.intensified(color: color, intensity: intensity);
  }
}

/// Utility for glow animations and transitions.
class GlowAnimation {
  GlowAnimation._();

  /// Duration for hover/glow state transitions.
  static const Duration hoverDuration = Duration(milliseconds: 200);

  /// Curve for hover/glow intensification.
  static const Curve hoverCurve = Curves.easeOut;

  /// Duration for button press animations.
  static const Duration pressDuration = Duration(milliseconds: 80);

  /// Curve for button press scale down.
  static const Curve pressScaleCurve = Curves.easeOut;

  /// Duration for button release/bounce back.
  static const Duration releaseDuration = Duration(milliseconds: 120);

  /// Curve for button release elastic bounce.
  static const Curve releaseCurve = Curves.elasticOut;

  /// Duration for pulsing/breathing glow animation.
  static const Duration pulseDuration = Duration(milliseconds: 2000);

  /// Gets glow shadows transitioning from idle to active state.
  static List<BoxShadow> transitionGlow(Color color, double animationValue) {
    animationValue = animationValue.clamp(0.0, 1.0);

    const idleOpacity1 = 0.2;
    const idleOpacity2 = 0.3;
    const idleOpacity3 = 0.4;
    const activeOpacity1 = 0.5;
    const activeOpacity2 = 0.6;
    const activeOpacity3 = 0.5;

    final opacity1 =
        idleOpacity1 + (activeOpacity1 - idleOpacity1) * animationValue;
    final opacity2 =
        idleOpacity2 + (activeOpacity2 - idleOpacity2) * animationValue;
    final opacity3 =
        idleOpacity3 + (activeOpacity3 - idleOpacity3) * animationValue;

    const idleBlur1 = 8.0;
    const idleBlur2 = 20.0;
    const idleBlur3 = 40.0;
    const activeBlur1 = 12.0;
    const activeBlur2 = 30.0;
    const activeBlur3 = 60.0;

    final blur1 = idleBlur1 + (activeBlur1 - idleBlur1) * animationValue;
    final blur2 = idleBlur2 + (activeBlur2 - idleBlur2) * animationValue;
    final blur3 = idleBlur3 + (activeBlur3 - idleBlur3) * animationValue;

    return [
      BoxShadow(
        color: color.withValues(alpha: opacity1),
        blurRadius: blur1,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: color.withValues(alpha: opacity2),
        blurRadius: blur2,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
      BoxShadow(
        color: color.withValues(alpha: opacity3),
        blurRadius: blur3,
        spreadRadius: -10,
        offset: Offset.zero,
      ),
    ];
  }
}
