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
    final glowIntensity =
        animated ? 0.5 + 0.5 * math.sin(_controller.value * math.pi * 2) : 1.0;

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
            filter: ImageFilter.blur(sigmaX: totalBlur, sigmaY: totalBlur),
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
      WeatherSeverity.heavy => OceanColors.safetyOrange.withValues(alpha: 0.4),
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

/// Paints rain drops, rivulets, condensation, and spray on glass.
///
/// Visual layers (bottom to top):
/// 1. Condensation beads — static water droplets with refraction highlights
/// 2. Rivulets — bezier curves crawling down glass with variable width
/// 3. Falling drops — angled streaks driven by wind
/// 4. Impact splashes — radial bursts where drops hit
/// 5. Spray streaks — horizontal mist in heavy conditions
/// 6. Water pooling — gradient at bottom edge
class _RainDropPainter extends CustomPainter {
  final double progress;
  final WeatherSeverity severity;
  final double windAngle;
  final bool isHolographic;

  final Paint _paint = Paint();
  final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  _RainDropPainter({
    required this.progress,
    required this.severity,
    required this.windAngle,
    required this.isHolographic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final windRad = (windAngle - 90) * math.pi / 180;
    final windPush = math.sin(windRad);

    // Layer 1: Condensation beads (static, always present when raining)
    _drawCondensation(canvas, size, rng);

    // Layer 2: Rivulets (bezier curves crawling down)
    _drawRivulets(canvas, size, rng, windPush);

    // Layer 3: Falling drops
    _drawFallingDrops(canvas, size, rng, windPush);

    // Layer 4: Impact splashes
    _drawSplashes(canvas, size, rng);

    // Layer 5: Spray streaks (heavy/storm only)
    if (severity.index >= WeatherSeverity.heavy.index) {
      _drawSpray(canvas, size, rng);
    }

    // Layer 6: Water pooling at bottom
    if (severity.index >= WeatherSeverity.moderate.index) {
      _drawPooling(canvas, size);
    }
  }

  void _drawCondensation(Canvas canvas, Size size, math.Random rng) {
    final count = switch (severity) {
      WeatherSeverity.calm => 0,
      WeatherSeverity.light => 8,
      WeatherSeverity.moderate => 18,
      WeatherSeverity.heavy => 28,
      WeatherSeverity.storm => 40,
    };

    final baseAlpha = isHolographic ? 0.20 : 0.12;
    final highlightAlpha = isHolographic ? 0.45 : 0.30;

    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 1.2 + rng.nextDouble() * 2.5;

      // Bead body
      _paint
        ..style = PaintingStyle.fill
        ..color =
            (isHolographic ? HolographicColors.electricBlue : Colors.white)
                .withValues(alpha: baseAlpha);
      canvas.drawCircle(Offset(x, y), radius, _paint);

      // Refraction highlight — bright spot offset up-left
      _paint.color = (isHolographic ? HolographicColors.neonCyan : Colors.white)
          .withValues(alpha: highlightAlpha);
      canvas.drawCircle(
        Offset(x - radius * 0.3, y - radius * 0.3),
        radius * 0.35,
        _paint,
      );
    }
  }

  void _drawRivulets(
      Canvas canvas, Size size, math.Random rng, double windPush) {
    final count = switch (severity) {
      WeatherSeverity.calm => 0,
      WeatherSeverity.light => 2,
      WeatherSeverity.moderate => 4,
      WeatherSeverity.heavy => 6,
      WeatherSeverity.storm => 9,
    };

    final color = isHolographic
        ? HolographicColors.electricBlue.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.12);

    for (var i = 0; i < count; i++) {
      final startX = rng.nextDouble() * size.width;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = (progress * speed + rng.nextDouble()) % 1.0;

      // Rivulet flows from top, pausing at random points
      final rivuletLength = size.height * (0.3 + rng.nextDouble() * 0.5);
      final headY = phase * (size.height + rivuletLength) - rivuletLength * 0.3;
      final tailY = headY - rivuletLength;

      if (headY < 0 || tailY > size.height) continue;

      // Build bezier path with wind-influenced wobble
      final path = Path();
      const segments = 5;
      final clampedTail = tailY.clamp(0.0, size.height);
      final clampedHead = headY.clamp(0.0, size.height);
      path.moveTo(startX, clampedTail);

      for (var s = 1; s <= segments; s++) {
        final t = s / segments;
        final segY = clampedTail + (clampedHead - clampedTail) * t;
        final wobble = math.sin(t * math.pi * 3 + i * 1.7) * 4 * windPush +
            windPush * 8 * t;
        path.lineTo(startX + wobble, segY);
      }

      // Width tapers: thick at head, thin at tail
      _paint
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = 1.5 + severity.index * 0.3
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, _paint);

      // Glow effect for holographic
      if (isHolographic) {
        _glowPaint.color =
            HolographicColors.electricBlue.withValues(alpha: 0.06);
        _glowPaint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;
        canvas.drawPath(path, _glowPaint);
      }

      // Drip bead at the head
      _paint
        ..style = PaintingStyle.fill
        ..color =
            (isHolographic ? HolographicColors.electricBlue : Colors.white)
                .withValues(alpha: 0.25);
      final headOffset = Offset(
        startX + windPush * 8,
        clampedHead,
      );
      canvas.drawOval(
        Rect.fromCenter(center: headOffset, width: 3.5, height: 5.0),
        _paint,
      );
    }
  }

  void _drawFallingDrops(
      Canvas canvas, Size size, math.Random rng, double windPush) {
    final count = switch (severity) {
      WeatherSeverity.calm => 0,
      WeatherSeverity.light => 5,
      WeatherSeverity.moderate => 12,
      WeatherSeverity.heavy => 20,
      WeatherSeverity.storm => 30,
    };

    final dropColor = isHolographic
        ? HolographicColors.electricBlue.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.14);

    for (var i = 0; i < count; i++) {
      final seed = rng.nextDouble();
      final speed = 0.4 + seed * 0.6;
      final phase = (progress * speed + seed) % 1.0;
      final x = (rng.nextDouble() + windPush * 0.15 * phase) * size.width;
      final y = phase * size.height;
      final length = 6.0 + severity.index * 3.0 + seed * 6.0;
      final width = 1.0 + seed * 1.2;

      final dx = windPush * length * 0.4;

      _paint
        ..style = PaintingStyle.stroke
        ..color = dropColor
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + dx, y + length),
        _paint,
      );
    }
  }

  void _drawSplashes(Canvas canvas, Size size, math.Random rng) {
    final count = switch (severity) {
      WeatherSeverity.calm => 0,
      WeatherSeverity.light => 2,
      WeatherSeverity.moderate => 5,
      WeatherSeverity.heavy => 8,
      WeatherSeverity.storm => 14,
    };

    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final seed = rng.nextDouble();

      // Each splash appears briefly during the animation cycle
      final splashPhase = (progress * 2.0 + seed) % 1.0;
      if (splashPhase > 0.15) continue; // Only visible for 15% of cycle

      final splashProgress = splashPhase / 0.15; // 0→1 during splash
      final radius = 3.0 + splashProgress * 8.0;
      final alpha = (1.0 - splashProgress) * (isHolographic ? 0.20 : 0.12);

      // Expanding ring
      _paint
        ..style = PaintingStyle.stroke
        ..color = (isHolographic ? HolographicColors.neonCyan : Colors.white)
            .withValues(alpha: alpha)
        ..strokeWidth = 0.8;
      canvas.drawCircle(Offset(x, y), radius, _paint);

      // Tiny satellite droplets flying outward
      for (var j = 0; j < 4; j++) {
        final angle = j * math.pi / 2 + seed * math.pi;
        final dist = radius * 1.2;
        final sx = x + math.cos(angle) * dist;
        final sy = y + math.sin(angle) * dist;
        _paint
          ..style = PaintingStyle.fill
          ..color =
              (isHolographic ? HolographicColors.electricBlue : Colors.white)
                  .withValues(alpha: alpha * 0.7);
        canvas.drawCircle(Offset(sx, sy), 0.8, _paint);
      }
    }
  }

  void _drawSpray(Canvas canvas, Size size, math.Random rng) {
    final count = severity == WeatherSeverity.storm ? 10 : 5;
    final color = isHolographic
        ? HolographicColors.neonCyan.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.05);

    _paint
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < count; i++) {
      final sy = rng.nextDouble() * size.height;
      final phase2 = (progress * 1.8 + rng.nextDouble()) % 1.0;
      final sx = phase2 * size.width * 1.3 - size.width * 0.15;
      final len = 12.0 + rng.nextDouble() * 30.0;
      final jitter = rng.nextDouble() * 2 - 1;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx + len, sy + jitter),
        _paint,
      );
    }
  }

  void _drawPooling(Canvas canvas, Size size) {
    final intensity = switch (severity) {
      WeatherSeverity.calm => 0.0,
      WeatherSeverity.light => 0.0,
      WeatherSeverity.moderate => 0.04,
      WeatherSeverity.heavy => 0.07,
      WeatherSeverity.storm => 0.10,
    };

    final poolColor =
        isHolographic ? HolographicColors.electricBlue : Colors.white;

    final poolHeight = 6.0 + severity.index * 3.0;

    _paint
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          poolColor.withValues(alpha: 0.0),
          poolColor.withValues(alpha: intensity),
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height - poolHeight, size.width, poolHeight),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height - poolHeight, size.width, poolHeight),
      _paint,
    );

    // Reset shader
    _paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant _RainDropPainter oldDelegate) {
    return progress != oldDelegate.progress || severity != oldDelegate.severity;
  }
}
