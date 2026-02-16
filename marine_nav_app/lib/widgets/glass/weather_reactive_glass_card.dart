/// Weather-Reactive Glass Card — glass surface responds to live conditions.
///
/// Wraps [GlassCard] with layered weather effects driven by real data:
/// - Rain drops sliding down glass (wind speed > 15 kts)
/// - Spray mist (wind speed > 25 kts)
/// - Fog blur intensification (wave height proxy for low vis)
/// - Storm border glow (Beaufort 8+)
/// Uses CustomPainter for rain drops to avoid shader sampler issues on iOS.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/holographic_colors.dart';

/// Severity level derived from weather conditions.
enum WeatherSeverity {
  /// Calm conditions — no effects.
  calm,

  /// Light weather — subtle rain drops.
  light,

  /// Moderate weather — rain + slight blur.
  moderate,

  /// Heavy weather — dense rain + spray + border glow.
  heavy,

  /// Storm — everything + pulsing glow + intense blur.
  storm,
}

/// Glass card that visually reacts to weather conditions.
///
/// Layer effects on top of the standard [GlassCard] appearance:
/// - Rain drops: slide down the glass surface at wind-driven angles
/// - Spray mist: horizontal streaks at high wind speeds
/// - Fog haze: additional backdrop blur when visibility is low
/// - Storm glow: border pulses orange/red in severe conditions
class WeatherReactiveGlassCard extends StatefulWidget {
  /// Child widget inside the card.
  final Widget child;

  /// Wind speed in knots — drives rain intensity and angle.
  final double windSpeedKnots;

  /// Wave height in meters — proxy for spray/visibility.
  final double waveHeightMeters;

  /// Wind direction in degrees — drives drop angle.
  final double windDirectionDegrees;

  /// Whether holographic theme is active.
  final bool isHolographic;

  /// Padding variant for the inner glass card.
  final GlassCardPaddingValue padding;

  /// Whether effects are enabled (for performance toggle).
  final bool effectsEnabled;

  /// Creates a weather-reactive glass card.
  const WeatherReactiveGlassCard({
    super.key,
    required this.child,
    this.windSpeedKnots = 0,
    this.waveHeightMeters = 0,
    this.windDirectionDegrees = 0,
    this.isHolographic = false,
    this.padding = GlassCardPaddingValue.medium,
    this.effectsEnabled = true,
  });

  @override
  State<WeatherReactiveGlassCard> createState() =>
      _WeatherReactiveGlassCardState();
}

/// Padding values matching GlassCard's enum.
enum GlassCardPaddingValue {
  /// 12px
  small(12.0),

  /// 16px
  medium(16.0),

  /// 24px
  large(24.0),

  /// 0px
  none(0.0);

  /// The padding value in logical pixels.
  final double value;
  const GlassCardPaddingValue(this.value);
}

class _WeatherReactiveGlassCardState extends State<WeatherReactiveGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.effectsEnabled && _severity != WeatherSeverity.calm) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WeatherReactiveGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sev = _severity;
    if (widget.effectsEnabled && sev != WeatherSeverity.calm) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  WeatherSeverity get _severity {
    final ws = widget.windSpeedKnots;
    final wh = widget.waveHeightMeters;
    if (ws >= 34 || wh >= 4.0) return WeatherSeverity.storm;
    if (ws >= 25 || wh >= 2.5) return WeatherSeverity.heavy;
    if (ws >= 15 || wh >= 1.5) return WeatherSeverity.moderate;
    if (ws >= 8 || wh >= 0.5) return WeatherSeverity.light;
    return WeatherSeverity.calm;
  }

  @override
  Widget build(BuildContext context) {
    final severity = _severity;
    const radius = OceanDimensions.radius;

    if (!widget.effectsEnabled || severity == WeatherSeverity.calm) {
      return _buildBaseCard(radius, severity);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildBaseCard(radius, severity, animated: true);
      },
    );
  }

  Widget _buildBaseCard(double radius, WeatherSeverity severity,
      {bool animated = false}) {
    final blurExtra = switch (severity) {
      WeatherSeverity.calm => 0.0,
      WeatherSeverity.light => 1.0,
      WeatherSeverity.moderate => 3.0,
      WeatherSeverity.heavy => 5.0,
      WeatherSeverity.storm => 8.0,
    };

    final baseBlur = widget.isHolographic ? 20.0 : OceanDimensions.glassBlur;
    final totalBlur = baseBlur + blurExtra;

    final borderColor = _borderColorForSeverity(severity);
    final glowColor = _glowColorForSeverity(severity);
    final glowIntensity = animated
        ? 0.5 + 0.5 * math.sin(_controller.value * math.pi * 2)
        : 1.0;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: widget.isHolographic
              ? HolographicColors.spaceNavy.withValues(alpha: 0.4)
              : OceanColors.deepNavy
                  .withValues(alpha: OceanDimensions.glassOpacity),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor,
            width: severity.index >= WeatherSeverity.moderate.index ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (severity.index >= WeatherSeverity.moderate.index)
              BoxShadow(
                color: glowColor.withValues(alpha: 0.15 * glowIntensity),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            if (severity == WeatherSeverity.storm)
              BoxShadow(
                color: glowColor.withValues(alpha: 0.08 * glowIntensity),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            BoxShadow(
              color: OceanColors.glassShadow,
              blurRadius: OceanDimensions.shadowBlur,
              offset: const Offset(0, OceanDimensions.shadowOffsetY),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: totalBlur, sigmaY: totalBlur),
            child: Stack(
              children: [
                // Rain/spray overlay
                if (severity.index >= WeatherSeverity.light.index && animated)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RainDropPainter(
                          progress: _controller.value,
                          severity: severity,
                          windAngle: widget.windDirectionDegrees,
                          isHolographic: widget.isHolographic,
                        ),
                      ),
                    ),
                  ),
                // Fog haze overlay
                if (severity.index >= WeatherSeverity.moderate.index)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _fogColor.withValues(
                                  alpha: _fogOpacity(severity) * 0.6),
                              _fogColor.withValues(
                                  alpha: _fogOpacity(severity) * 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: EdgeInsets.all(widget.padding.value),
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _fogColor => widget.isHolographic
      ? HolographicColors.cyberPurple
      : const Color(0xFF8EAFC0);

  double _fogOpacity(WeatherSeverity severity) {
    return switch (severity) {
      WeatherSeverity.calm => 0.0,
      WeatherSeverity.light => 0.0,
      WeatherSeverity.moderate => 0.06,
      WeatherSeverity.heavy => 0.10,
      WeatherSeverity.storm => 0.15,
    };
  }

  Color _borderColorForSeverity(WeatherSeverity severity) {
    if (widget.isHolographic) {
      return switch (severity) {
        WeatherSeverity.calm =>
          HolographicColors.electricBlue.withValues(alpha: 0.4),
        WeatherSeverity.light =>
          HolographicColors.electricBlue.withValues(alpha: 0.5),
        WeatherSeverity.moderate =>
          HolographicColors.neonCyan.withValues(alpha: 0.6),
        WeatherSeverity.heavy => const Color(0xFFFFAA00).withValues(alpha: 0.7),
        WeatherSeverity.storm =>
          HolographicColors.neonMagenta.withValues(alpha: 0.8),
      };
    }
    return switch (severity) {
      WeatherSeverity.calm => OceanColors.glassBorder,
      WeatherSeverity.light => OceanColors.glassBorder,
      WeatherSeverity.moderate =>
        OceanColors.seafoamGreen.withValues(alpha: 0.3),
      WeatherSeverity.heavy =>
        OceanColors.safetyOrange.withValues(alpha: 0.4),
      WeatherSeverity.storm => OceanColors.coralRed.withValues(alpha: 0.5),
    };
  }

  Color _glowColorForSeverity(WeatherSeverity severity) {
    if (widget.isHolographic) {
      return switch (severity) {
        WeatherSeverity.calm => HolographicColors.electricBlue,
        WeatherSeverity.light => HolographicColors.electricBlue,
        WeatherSeverity.moderate => HolographicColors.neonCyan,
        WeatherSeverity.heavy => const Color(0xFFFFAA00),
        WeatherSeverity.storm => HolographicColors.neonMagenta,
      };
    }
    return switch (severity) {
      WeatherSeverity.calm => Colors.transparent,
      WeatherSeverity.light => Colors.transparent,
      WeatherSeverity.moderate => OceanColors.seafoamGreen,
      WeatherSeverity.heavy => OceanColors.safetyOrange,
      WeatherSeverity.storm => OceanColors.coralRed,
    };
  }
}

/// Paints rain drops and spray streaks sliding down/across the glass.
class _RainDropPainter extends CustomPainter {
  final double progress;
  final WeatherSeverity severity;
  final double windAngle;
  final bool isHolographic;

  // Pre-allocated paint objects
  final Paint _dropPaint = Paint()..style = PaintingStyle.fill;
  final Paint _streakPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  _RainDropPainter({
    required this.progress,
    required this.severity,
    required this.windAngle,
    required this.isHolographic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final dropCount = switch (severity) {
      WeatherSeverity.calm => 0,
      WeatherSeverity.light => 6,
      WeatherSeverity.moderate => 14,
      WeatherSeverity.heavy => 24,
      WeatherSeverity.storm => 36,
    };

    // Wind pushes drops sideways (simplified: 0° = north, 90° = east)
    final windRad = (windAngle - 90) * math.pi / 180;
    final windPush = math.sin(windRad) * 0.15;

    final dropColor = isHolographic
        ? HolographicColors.electricBlue.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.15);

    _dropPaint.color = dropColor;

    for (var i = 0; i < dropCount; i++) {
      final seed = rng.nextDouble();
      final speed = 0.5 + seed * 0.5;

      // Each drop has its own phase offset so they don't all sync
      final phase = (progress * speed + seed) % 1.0;
      final x = (rng.nextDouble() + windPush * phase) * size.width;
      final y = phase * size.height;

      // Drop length varies with speed and severity
      final length = 4.0 + severity.index * 2.0 + seed * 4.0;
      final width = 1.0 + seed * 1.5;

      // Draw the drop as a short rounded line
      _streakPaint
        ..color = dropColor
        ..strokeWidth = width;

      final dx = windPush * length * 2;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + dx, y + length),
        _streakPaint,
      );

      // Small splash dot at the bottom of some drops
      if (phase > 0.85 && i.isEven) {
        _dropPaint.color = dropColor.withValues(alpha: 0.1);
        canvas.drawCircle(Offset(x + dx, y + length), width * 2, _dropPaint);
      }
    }

    // Spray streaks for heavy/storm
    if (severity.index >= WeatherSeverity.heavy.index) {
      final sprayCount = severity == WeatherSeverity.storm ? 8 : 4;
      final sprayColor = isHolographic
          ? HolographicColors.neonCyan.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.06);
      _streakPaint
        ..color = sprayColor
        ..strokeWidth = 0.8;

      for (var i = 0; i < sprayCount; i++) {
        final sy = rng.nextDouble() * size.height;
        final phase2 = (progress * 1.5 + rng.nextDouble()) % 1.0;
        final sx = phase2 * size.width * 1.2 - size.width * 0.1;
        final len = 15.0 + rng.nextDouble() * 25.0;
        canvas.drawLine(
          Offset(sx, sy),
          Offset(sx + len, sy + rng.nextDouble() * 3 - 1.5),
          _streakPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainDropPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        severity != oldDelegate.severity;
  }
}
