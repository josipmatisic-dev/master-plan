/// Wind particle flow field visualization using CustomPainter.
///
/// Renders thousands of particles that follow actual wind data,
/// creating a Windy-style flow visualization over the map.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/weather_data.dart';
import '../../models/wind_particle.dart';

/// Renders wind flow particles over the map using CustomPainter.
class WindParticleOverlay extends StatefulWidget {
  /// Wind data points for interpolation.
  final List<WindDataPoint> windPoints;

  /// Whether to use holographic theme colors.
  final bool isHolographic;

  /// Wind data bounds for coordinate mapping.
  final ({double south, double north, double west, double east})? bounds;

  const WindParticleOverlay({
    super.key,
    required this.windPoints,
    this.isHolographic = false,
    this.bounds,
  });

  @override
  State<WindParticleOverlay> createState() => _WindParticleOverlayState();
}

class _WindParticleOverlayState extends State<WindParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  List<WindParticle> _particles = [];
  int _targetCount = 2000;
  static const _trailLength = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_updateParticles);
  }

  void _initParticles() {
    _particles = List.generate(_targetCount, (_) => _spawnParticle());
  }

  WindParticle _spawnParticle() {
    return WindParticle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      lifetime: 3.0 + _random.nextDouble() * 3.0,
    );
  }

  void _updateParticles() {
    if (_particles.isEmpty) _initParticles();
    if (widget.windPoints.isEmpty) return;

    const dt = 1.0 / 60.0;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];

      // Look up wind at particle position (bilinear interpolation)
      final wind = _interpolateWind(p.x, p.y);
      p.vx = wind.dx * 0.0008;
      p.vy = wind.dy * 0.0008;
      p.speed = wind.distance;

      // Store trail position
      p.trail.insert(0, Offset(p.x, p.y));
      if (p.trail.length > _trailLength) {
        p.trail.removeRange(_trailLength, p.trail.length);
      }

      // Advect
      final speedMult = widget.isHolographic ? 1.2 : 0.8;
      p.x += p.vx * speedMult;
      p.y += p.vy * speedMult;
      p.age += dt;

      // Respawn if dead or out of bounds
      if (p.isDead || p.x < -0.05 || p.x > 1.05 || p.y < -0.05 || p.y > 1.05) {
        _particles[i] = _spawnParticle();
      }
    }
    setState(() {});
  }

  /// Bilinear interpolation of wind field at normalized position.
  Offset _interpolateWind(double nx, double ny) {
    if (widget.windPoints.isEmpty) return Offset.zero;

    // IDW (inverse distance weighting) interpolation
    double uSum = 0, vSum = 0, wSum = 0;
    for (final wp in widget.windPoints) {
      final bounds = widget.bounds;
      if (bounds == null) continue;

      // Normalize wind point position to 0-1
      final wpx =
          (wp.position.longitude - bounds.west) / (bounds.east - bounds.west);
      final wpy = 1.0 -
          (wp.position.latitude - bounds.south) / (bounds.north - bounds.south);

      final dx = nx - wpx;
      final dy = ny - wpy;
      final dist = sqrt(dx * dx + dy * dy) + 0.001;
      final w = 1.0 / (dist * dist);

      // Convert wind speed/direction to u,v components
      final rad = wp.directionDegrees * pi / 180.0;
      final u = -wp.speedKnots * sin(rad);
      final v = -wp.speedKnots * cos(rad);

      uSum += u * w;
      vSum += v * w;
      wSum += w;
    }

    if (wSum == 0) return Offset.zero;
    return Offset(uSum / wSum, vSum / wSum);
  }

  @override
  void didUpdateWidget(WindParticleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adapt particle count based on screen size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final screenArea = size.width * size.height;
      if (screenArea < 300000) {
        _targetCount = 1500;
      } else if (screenArea < 800000) {
        _targetCount = 2500;
      } else {
        _targetCount = 4000;
      }
      // Adjust particle list size
      while (_particles.length < _targetCount) {
        _particles.add(_spawnParticle());
      }
      if (_particles.length > _targetCount) {
        _particles = _particles.sublist(0, _targetCount);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParticles);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.windPoints.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: CustomPaint(
        painter: _WindPainter(
          particles: _particles,
          isHolographic: widget.isHolographic,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WindPainter extends CustomPainter {
  final List<WindParticle> particles;
  final bool isHolographic;

  _WindPainter({required this.particles, required this.isHolographic});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.trail.length < 2) continue;

      final alpha = p.alpha;
      if (alpha < 0.01) continue;

      final color = _colorForSpeed(p.speed, alpha);

      // Draw trail as tapered polyline
      for (int i = 0; i < p.trail.length - 1; i++) {
        final t0 = p.trail[i];
        final t1 = p.trail[i + 1];
        final trailAlpha = alpha * (1.0 - i / p.trail.length);
        final width = isHolographic
            ? 1.0 + (1.0 - i / p.trail.length) * 1.0
            : 1.5 + (1.0 - i / p.trail.length) * 1.5;

        final paint = Paint()
          ..color = color.withValues(alpha: trailAlpha * color.a / 255.0)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round;

        // Holographic: add glow to trail
        if (isHolographic && i == 0) {
          paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        }

        canvas.drawLine(
          Offset(t0.dx * size.width, t0.dy * size.height),
          Offset(t1.dx * size.width, t1.dy * size.height),
          paint,
        );
      }
    }
  }

  Color _colorForSpeed(double speedKnots, double alpha) {
    if (isHolographic) {
      if (speedKnots < 5) {
        return Color.fromRGBO(0, 255, 255, 0.4 * alpha); // neonCyan
      } else if (speedKnots < 15) {
        return Color.fromRGBO(0, 217, 255, 0.6 * alpha); // electricBlue
      } else if (speedKnots < 25) {
        return Color.fromRGBO(255, 0, 255, 0.8 * alpha); // neonMagenta
      } else {
        return Color.fromRGBO(255, 0, 255, 1.0 * alpha); // neonMagenta full
      }
    } else {
      if (speedKnots < 5) {
        return Color.fromRGBO(255, 255, 255, 0.3 * alpha); // white gentle
      } else if (speedKnots < 15) {
        return Color.fromRGBO(0, 201, 167, 0.5 * alpha); // seafoamGreen
      } else if (speedKnots < 25) {
        return Color.fromRGBO(255, 154, 61, 0.7 * alpha); // safetyOrange
      } else {
        return Color.fromRGBO(255, 107, 107, 0.9 * alpha); // coralRed
      }
    }
  }

  @override
  bool shouldRepaint(_WindPainter oldDelegate) => true; // Continuous animation
}
