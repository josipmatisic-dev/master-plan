/// Glow Text Widget - Text with neon glow effects for Holographic theme
///
/// Provides text rendering with bloom/glow shadows for the
/// Holographic Cyberpunk theme variant.
library;

import 'package:flutter/material.dart';

import '../../theme/holographic_colors.dart';
import '../../theme/holographic_effects.dart';

/// Text style presets for glow text
enum GlowTextStyle {
  /// Strong bloom for large data values (56pt equivalent)
  dataValue,

  /// Medium glow for headings (24-32pt equivalent)
  heading,

  /// Subtle glow for body text (16-18pt equivalent)
  subtle,

  /// Prominent multi-layer glow for dramatic effect
  prominent,
}

/// Text widget with neon glow effect
///
/// Renders text with multi-layer shadow effects to create a
/// glowing neon appearance. Optimized for performance with
/// minimal repaints.
///
/// Example:
/// ```dart
/// GlowText(
///   'Speed',
///   style: GlowTextStyle.dataValue,
///   color: HolographicColors.electricBlue,
/// )
/// ```
class GlowText extends StatelessWidget {
  /// The text to display
  final String text;

  /// Glow style preset (affects shadow configuration)
  final GlowTextStyle glowStyle;

  /// Glow color (defaults to Electric Blue)
  final Color? color;

  /// Text style (font size, weight, etc.)
  final TextStyle? textStyle;

  /// Text alignment
  final TextAlign? textAlign;

  /// Maximum number of lines
  final int? maxLines;

  /// Text overflow behavior
  final TextOverflow? overflow;

  /// Glow intensity multiplier (default: 1.0)
  /// Use higher values for stronger glow
  final double intensity;

  /// Creates a [GlowText].
  const GlowText(
    this.text, {
    super.key,
    this.glowStyle = GlowTextStyle.subtle,
    this.color,
    this.textStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = color ?? HolographicColors.electricBlue;

    // Get shadow configuration based on style
    final List<Shadow> shadows = _getShadows(glowColor);

    // Get base text style with glow shadows
    final TextStyle effectiveStyle = (textStyle ?? const TextStyle()).copyWith(
      color: HolographicColors.pureWhite,
      shadows: shadows,
    );

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Get shadow configuration for the specified glow style
  List<Shadow> _getShadows(Color glowColor) {
    // Apply intensity multiplier to blur radii
    switch (glowStyle) {
      case GlowTextStyle.dataValue:
        return _scaleShadows(
          TextGlow.dataValue(glowColor),
          intensity,
        );

      case GlowTextStyle.heading:
        return _scaleShadows(
          TextGlow.heading(glowColor),
          intensity,
        );

      case GlowTextStyle.subtle:
        return _scaleShadows(
          TextGlow.subtle(glowColor),
          intensity,
        );

      case GlowTextStyle.prominent:
        return _scaleShadows(
          TextGlow.prominent(color: glowColor),
          intensity,
        );
    }
  }

  /// Scale shadow blur radii by intensity multiplier
  List<Shadow> _scaleShadows(List<Shadow> shadows, double scale) {
    if (scale == 1.0) return shadows;

    return shadows.map((shadow) {
      return Shadow(
        color: shadow.color,
        offset: shadow.offset,
        blurRadius: shadow.blurRadius * scale,
      );
    }).toList();
  }
}

/// Animated glow text with pulsing intensity
///
/// Text that pulses its glow intensity over time for
/// attention-grabbing effects.
///
/// Example:
/// ```dart
/// PulsingGlowText(
///   'ALERT',
///   glowStyle: GlowTextStyle.prominent,
///   color: HolographicColors.neonMagenta,
///   pulseDuration: Duration(seconds: 2),
/// )
/// ```
class PulsingGlowText extends StatefulWidget {
  /// The text to display
  final String text;

  /// Glow style preset
  final GlowTextStyle glowStyle;

  /// Glow color
  final Color? color;

  /// Text style
  final TextStyle? textStyle;

  /// Text alignment
  final TextAlign? textAlign;

  /// Duration of one pulse cycle
  final Duration pulseDuration;

  /// Minimum intensity (0.0-1.0)
  final double minIntensity;

  /// Maximum intensity (1.0-3.0)
  final double maxIntensity;

  /// Creates a [PulsingGlowText].
  const PulsingGlowText(
    this.text, {
    super.key,
    this.glowStyle = GlowTextStyle.prominent,
    this.color,
    this.textStyle,
    this.textAlign,
    this.pulseDuration = const Duration(seconds: 2),
    this.minIntensity = 0.6,
    this.maxIntensity = 1.5,
  });

  @override
  State<PulsingGlowText> createState() => _PulsingGlowTextState();
}

class _PulsingGlowTextState extends State<PulsingGlowText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _intensityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    );

    // Create sine wave intensity animation
    _intensityAnimation = Tween<double>(
      begin: widget.minIntensity,
      end: widget.maxIntensity,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Check if animations are disabled for accessibility
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _intensityAnimation,
      builder: (context, child) {
        return GlowText(
          widget.text,
          glowStyle: widget.glowStyle,
          color: widget.color,
          textStyle: widget.textStyle,
          textAlign: widget.textAlign,
          intensity: _intensityAnimation.value,
        );
      },
    );
  }
}
