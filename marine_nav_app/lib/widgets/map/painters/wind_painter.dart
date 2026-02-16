/// Custom painter for wind particle visualization.
/// Ported from Cameron Beccario's 'earth' project (MIT License).
/// https://github.com/cambecc/earth
library;

import 'package:flutter/material.dart';

/// Particle in geographic space.
class GeoParticle {
  /// Current latitude.
  double lat;

  /// Current longitude.
  double lng;

  /// Age in frames.
  double age;

  /// Total lifetime in frames.
  double maxAge;

  /// Wind speed at particle position in knots.
  double speed;

  /// X velocity on canvas (screen coordinates).
  double dx;

  /// Y velocity on canvas (screen coordinates).
  double dy;

  /// Creates a GeoParticle.
  GeoParticle({
    required this.lat,
    required this.lng,
    required this.maxAge,
  })  : age = 0,
        speed = 0,
        dx = 0,
        dy = 0;
}

/// Painter that renders wind particles as streaks on the canvas.
///
/// Does NOT own physics — the overlay widget handles advection.
/// This painter only projects particles to screen space and draws.
class WindPainter extends CustomPainter {
  /// List of active particles to draw.
  final List<GeoParticle> particles;

  /// Map bounds to project geographic coordinates to canvas.
  final ({double south, double north, double west, double east}) bounds;

  /// Whether to render in holographic theme mode.
  final bool isHolographic;

  /// Frame counter for shouldRepaint.
  final int frameCount;

  /// Reusable paint object.
  final Paint _particlePaint = Paint()..strokeCap = StrokeCap.round;

  /// Creates a WindPainter.
  WindPainter({
    required this.particles,
    required this.bounds,
    required this.isHolographic,
    required this.frameCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final latRange = bounds.north - bounds.south;
    final lngRange = bounds.east - bounds.west;
    if (latRange == 0 || lngRange == 0) return;

    final scaleX = size.width / lngRange;

    for (final p in particles) {
      // Fade in over 20 frames, fade out over 20 frames
      double alpha = 1.0;
      if (p.age < 20) {
        alpha = p.age / 20.0;
      } else if (p.age > p.maxAge - 20) {
        alpha = (p.maxAge - p.age) / 20.0;
      }

      if (alpha <= 0) continue;

      final sx = (p.lng - bounds.west) * scaleX;
      final sy = (1.0 - (p.lat - bounds.south) / latRange) * size.height;

      final color = _colorForSpeed(p.speed, alpha);

      _particlePaint
        ..color = color
        ..strokeWidth = isHolographic ? 1.5 : 2.0;

      // Trail length proportional to screen velocity
      canvas.drawLine(
        Offset(sx - p.dx * 5.0, sy - p.dy * 5.0),
        Offset(sx, sy),
        _particlePaint,
      );
    }
  }

  /// Returns color based on wind speed in knots.
  Color _colorForSpeed(double speedKnots, double alpha) {
    if (isHolographic) {
      if (speedKnots < 5) return Color.fromRGBO(0, 255, 255, 0.3 * alpha);
      if (speedKnots < 15) return Color.fromRGBO(0, 217, 255, 0.5 * alpha);
      if (speedKnots < 25) return Color.fromRGBO(0, 217, 255, 0.7 * alpha);
      return Color.fromRGBO(255, 0, 255, 0.9 * alpha);
    } else {
      if (speedKnots < 5) return Color.fromRGBO(255, 255, 255, 0.25 * alpha);
      if (speedKnots < 15) return Color.fromRGBO(0, 201, 167, 0.4 * alpha);
      if (speedKnots < 25) return Color.fromRGBO(255, 154, 61, 0.6 * alpha);
      if (speedKnots < 34) return Color.fromRGBO(255, 107, 107, 0.8 * alpha);
      return Color.fromRGBO(200, 50, 50, 0.9 * alpha);
    }
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) =>
      frameCount != oldDelegate.frameCount;
}
