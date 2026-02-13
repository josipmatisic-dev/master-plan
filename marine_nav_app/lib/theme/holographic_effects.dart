/// Holographic Cyberpunk Design System - Effects Utilities
///
/// Provides reusable utilities for neon glow effects, shadows, and text glows
/// that are central to the holographic cyberpunk theme.
///
/// Based on HOLOGRAPHIC_THEME_SPEC.md visual specifications.
library;

import 'package:flutter/material.dart';
import 'holographic_colors.dart';

/// Provides neon glow decoration utilities for the holographic theme.
///
/// Creates multi-layer BoxDecoration with customizable glow intensity
/// and active/idle state support.
class NeonGlowDecoration {
  NeonGlowDecoration._();

  /// Creates a neon glow BoxDecoration with multi-layer shadow effects.
  ///
  /// The glow consists of 3 shadow layers:
  /// - Inner glow: Subtle, close to the element
  /// - Middle glow: Medium intensity
  /// - Outer bloom: Extended, diffused halo
  ///
  /// Parameters:
  /// - [color]: The neon color for the glow effect
  /// - [intensity]: Multiplier for blur radius (default: 1.0)
  /// - [isActive]: Whether to use intensified active state glow (default: false)
  ///
  /// Returns: A [BoxDecoration] with pre-configured neon glow shadows
  static BoxDecoration neonGlow({
    required Color color,
    double intensity = 1.0,
    bool isActive = false,
  }) {
    // Validate intensity is positive
    if (intensity <= 0) {
      intensity = 1.0;
    }

    if (isActive) {
      // Intensified active state: higher opacity and larger blur
      return BoxDecoration(
        boxShadow: [
          // Inner glow (bright)
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 12 * intensity,
            spreadRadius: 2,
            offset: Offset.zero,
          ),
          // Middle glow
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 30 * intensity,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
          // Outer bloom (extended)
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 60 * intensity,
            spreadRadius: -5,
            offset: Offset.zero,
          ),
        ],
      );
    } else {
      // Default idle state: subtle, focused glow
      return BoxDecoration(
        boxShadow: [
          // Inner glow (subtle)
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8 * intensity,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
          // Middle glow
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20 * intensity,
            spreadRadius: -5,
            offset: Offset.zero,
          ),
          // Outer bloom
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
  ///
  /// Useful for cards and containers that need both a glowing border
  /// and shadow effect.
  ///
  /// Parameters:
  /// - [color]: The neon color for both glow and border
  /// - [borderWidth]: Width of the border (default: 1.5)
  /// - [intensity]: Multiplier for blur radius (default: 1.0)
  /// - [borderRadius]: Border radius (default: 16)
  ///
  /// Returns: A [BoxDecoration] with border and glow effect
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

/// Provides pre-configured shadow lists for different neon colors.
///
/// Each color variant contains 3-layer shadow configurations optimized
/// for neon glow effects.
class GlowShadows {
  GlowShadows._();

  /// Electric Blue glow shadows (default primary glow).
  ///
  /// Three-layer shadow configuration using Electric Blue (#00D9FF)
  /// for primary accent glows and active states.
  ///
  /// Parameters:
  /// - [intensity]: Multiplier for blur radius (default: 1.0)
  ///
  /// Returns: A list of [BoxShadow] for electric blue glow effect
  static List<BoxShadow> electricBlue({double intensity = 1.0}) {
    if (intensity <= 0) intensity = 1.0;

    return [
      // Inner glow (subtle)
      BoxShadow(
        color: HolographicColors.electricBlue.withValues(alpha: 0.2),
        blurRadius: 8 * intensity,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      // Middle glow
      BoxShadow(
        color: HolographicColors.electricBlue.withValues(alpha: 0.3),
        blurRadius: 20 * intensity,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
      // Outer bloom
      BoxShadow(
        color: HolographicColors.electricBlue.withValues(alpha: 0.4),
        blurRadius: 40 * intensity,
        spreadRadius: -10,
        offset: Offset.zero,
      ),
    ];
  }

  /// Neon Magenta glow shadows (alerts and warnings).
  ///
  /// Three-layer shadow configuration using Neon Magenta (#FF00FF)
  /// for alert states, warnings, and critical notifications.
  ///
  /// Parameters:
  /// - [intensity]: Multiplier for blur radius (default: 1.0)
  ///
  /// Returns: A list of [BoxShadow] for neon magenta glow effect
  static List<BoxShadow> neonMagenta({double intensity = 1.0}) {
    if (intensity <= 0) intensity = 1.0;

    return [
      // Inner glow
      BoxShadow(
        color: HolographicColors.neonMagenta.withValues(alpha: 0.2),
        blurRadius: 8 * intensity,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      // Middle glow
      BoxShadow(
        color: HolographicColors.neonMagenta.withValues(alpha: 0.3),
        blurRadius: 20 * intensity,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
      // Outer bloom
      BoxShadow(
        color: HolographicColors.neonMagenta.withValues(alpha: 0.4),
        blurRadius: 40 * intensity,
        spreadRadius: -10,
        offset: Offset.zero,
      ),
    ];
  }

  /// Neon Cyan glow shadows (success and secondary accents).
  ///
  /// Three-layer shadow configuration using Neon Cyan (#00FFFF)
  /// for success states, secondary accents, and positive feedback.
  ///
  /// Parameters:
  /// - [intensity]: Multiplier for blur radius (default: 1.0)
  ///
  /// Returns: A list of [BoxShadow] for neon cyan glow effect
  static List<BoxShadow> neonCyan({double intensity = 1.0}) {
    if (intensity <= 0) intensity = 1.0;

    return [
      // Inner glow
      BoxShadow(
        color: HolographicColors.neonCyan.withValues(alpha: 0.2),
        blurRadius: 8 * intensity,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      // Middle glow
      BoxShadow(
        color: HolographicColors.neonCyan.withValues(alpha: 0.3),
        blurRadius: 20 * intensity,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
      // Outer bloom
      BoxShadow(
        color: HolographicColors.neonCyan.withValues(alpha: 0.4),
        blurRadius: 40 * intensity,
        spreadRadius: -10,
        offset: Offset.zero,
      ),
    ];
  }

  /// Intensified glow shadows for active/hover states.
  ///
  /// Higher opacity and larger blur radius for when elements
  /// are in active or hovered state.
  ///
  /// Parameters:
  /// - [color]: The neon color for the glow
  /// - [intensity]: Multiplier for blur radius (default: 1.0)
  ///
  /// Returns: A list of [BoxShadow] for intensified glow effect
  static List<BoxShadow> intensified({
    required Color color,
    double intensity = 1.0,
  }) {
    if (intensity <= 0) intensity = 1.0;

    return [
      // Inner glow (bright)
      BoxShadow(
        color: color.withValues(alpha: 0.5),
        blurRadius: 12 * intensity,
        spreadRadius: 2,
        offset: Offset.zero,
      ),
      // Middle glow
      BoxShadow(
        color: color.withValues(alpha: 0.6),
        blurRadius: 30 * intensity,
        spreadRadius: 0,
        offset: Offset.zero,
      ),
      // Outer bloom (extended)
      BoxShadow(
        color: color.withValues(alpha: 0.5),
        blurRadius: 60 * intensity,
        spreadRadius: -5,
        offset: Offset.zero,
      ),
    ];
  }
}

/// Provides text shadow configurations for glowing text effects.
///
/// Different text glow levels optimized for various typography sizes
/// and contexts in the holographic theme.
class TextGlow {
  TextGlow._();

  /// Strong glow effect for large data value text (56pt).
  ///
  /// Creates a prominent bloom effect suitable for large, impactful
  /// numerical displays with two-layer shadow configuration.
  ///
  /// Parameters:
  /// - [color]: The neon color for the text glow
  ///
  /// Returns: A list of [Shadow] for data value glowing text
  static List<Shadow> dataValue(Color color) {
    return [
      // First bloom layer
      Shadow(
        color: color.withValues(alpha: 0.6),
        blurRadius: 20,
        offset: Offset.zero,
      ),
      // Extended bloom layer
      Shadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 40,
        offset: Offset.zero,
      ),
    ];
  }

  /// Medium glow effect for heading text (32pt).
  ///
  /// Creates a balanced glow suitable for section headings and
  /// medium-sized text that needs emphasis.
  ///
  /// Parameters:
  /// - [color]: The neon color for the text glow
  ///
  /// Returns: A list of [Shadow] for heading text glow
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
  ///
  /// Creates a subtle glow suitable for regular body text while
  /// maintaining readability.
  ///
  /// Parameters:
  /// - [color]: The neon color for the text glow
  ///
  /// Returns: A list of [Shadow] for subtle text glow
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
  ///
  /// Creates a more dramatic glow effect with multiple layers,
  /// suitable for emphasized text and call-to-action labels.
  ///
  /// Parameters:
  /// - [color]: The neon color for the text glow
  /// - [intensity]: Multiplier for blur radius (default: 1.0)
  ///
  /// Returns: A list of [Shadow] for prominent glowing text
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
///
/// Automatically scales glow intensity based on screen width,
/// following the responsive breakpoints from the design specification.
class ResponsiveGlow {
  ResponsiveGlow._();

  /// Gets the appropriate intensity multiplier for current device size.
  ///
  /// Breakpoints:
  /// - Desktop (>1200px): 1.0x
  /// - Tablet (600-1200px): 0.8x
  /// - Mobile (<600px): 0.6x
  ///
  /// Parameters:
  /// - [context]: The build context to get screen dimensions
  ///
  /// Returns: The intensity multiplier (0.6 to 1.0)
  static double getIntensityMultiplier(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 1200) {
      return 1.0; // Desktop
    } else if (width > 600) {
      return 0.8; // Tablet
    } else {
      return 0.6; // Mobile
    }
  }

  /// Gets a neon glow with responsive intensity.
  ///
  /// Parameters:
  /// - [context]: The build context for size detection
  /// - [color]: The neon color for the glow
  /// - [isActive]: Whether to use active state glow
  ///
  /// Returns: A [BoxDecoration] with responsive glow intensity
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
  ///
  /// Parameters:
  /// - [context]: The build context for size detection
  /// - [color]: The neon color for the shadows
  ///
  /// Returns: A list of [BoxShadow] with responsive intensity
  static List<BoxShadow> responsiveShadows(
    BuildContext context, {
    required Color color,
  }) {
    final intensity = getIntensityMultiplier(context);
    return GlowShadows.intensified(color: color, intensity: intensity);
  }
}

/// Utility for glow animations and transitions.
///
/// Provides helpers for animating glow effects with appropriate
/// timing curves and durations from the design specification.
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
  ///
  /// Parameters:
  /// - [color]: The neon color
  /// - [animationValue]: Value between 0.0 (idle) and 1.0 (active)
  ///
  /// Returns: A list of [BoxShadow] interpolated between states
  static List<BoxShadow> transitionGlow(
    Color color,
    double animationValue,
  ) {
    // Clamp value between 0 and 1
    animationValue = animationValue.clamp(0.0, 1.0);

    // Interpolate between idle and active states
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
