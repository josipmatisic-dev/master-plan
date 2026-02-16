/// Custom painter for wind particle visualization.
/// Ported from Cameron Beccario's 'earth' project (MIT License).
/// https://github.com/cambecc/earth
library;

import 'dart:math';
import 'package:flutter/material.dart';

/// Particle in geographic space.
class GeoParticle {
  /// Current latitude.
  double lat;

  /// Current longitude.
  double lng;

  /// Age in seconds.
  double age;

  /// Total lifetime in seconds.
  double lifetime;

  /// Current speed in knots (set during advection).
  double speed;

  /// Trail history: latitude values.
  final List<double> trailLat;

  /// Trail history: longitude values.
  final List<double> trailLng;

  /// Current X position on canvas (screen coordinates).
  double x;

  /// Current Y position on canvas (screen coordinates).
  double y;

  /// X velocity on canvas (screen coordinates).
  double dx;

  /// Y velocity on canvas (screen coordinates).
  double dy;

  /// Creates a GeoParticle.
  GeoParticle({
    required this.lat,
    required this.lng,
    required this.lifetime,
    this.age = 0,
    this.speed = 0,
  })  : x = 0,
        y = 0,
        dx = 0,
        dy = 0,
        trailLat = <double>[],
        trailLng = <double>[];
}

/// Pre-computed wind vector for grid interpolation.
class WindVector {
  /// Latitude of this wind observation.
  final double lat;

  /// Longitude of this wind observation.
  final double lng;

  /// U component (east-west) in knots.
  final double u;

  /// V component (north-south) in knots.
  final double v;

  /// Wind speed magnitude in knots.
  final double speed;

  /// Creates a WindVector.
  const WindVector({
    required this.lat,
    required this.lng,
    required this.u,
    required this.v,
    required this.speed,
  });
}

/// Painter that renders wind particles on a canvas using bilinear interpolation.
class WindPainter extends CustomPainter {
  /// List of active particles to draw.
  final List<GeoParticle> particles;

  /// Map bounds to project geographic coordinates to canvas.
  final ({double south, double north, double west, double east}) bounds;

  /// Whether to render in holographic theme mode.
  final bool isHolographic;

  /// Reusable paint objects.
  final Paint _particlePaint = Paint()..strokeCap = StrokeCap.round;

  /// Frame counter for shouldRepaint.
  final int frameCount;

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

    // Pre-calculate projection scale
    final scaleX = size.width / lngRange;

    for (final p in particles) {
      // Fade in/out: 0.5s fade in, 0.5s fade out
      double alpha = 1.0;
      if (p.age < 0.5) {
        alpha = p.age / 0.5;
      } else if (p.age > p.lifetime - 0.5) {
        alpha = (p.lifetime - p.age) / 0.5;
      }

      if (alpha <= 0) continue;

      // Calculate screen position
      // Using linear interpolation for now (Web Mercator approx)
      final sx = (p.lng - bounds.west) * scaleX;
      // Latitude is inverted (top is 0)
      final sy = (1.0 - (p.lat - bounds.south) / latRange) * size.height;

      // Color based on approximate speed (magnitude of delta)
      // Since dx/dy are screen deltas, they depend on zoom level.
      // Ideally we'd use the particle's actual speed in m/s stored in the particle.
      // For this port, we approximate intensity by vector length.
      final speedFactor = sqrt(p.dx * p.dx + p.dy * p.dy);

      final color = _colorForSpeed(speedFactor, alpha);

      _particlePaint
        ..color = color
        ..strokeWidth = isHolographic ? 1.5 : 2.0;

      // Draw particle as a short trail from previous position
      // (sx - dx, sy - dy) -> (sx, sy)
      // This creates the "streak" effect without storing full history
      canvas.drawLine(
        Offset(sx - p.dx * 3.0, sy - p.dy * 3.0),
        Offset(sx, sy),
        _particlePaint,
      );
    }
  }

  /// Returns color based on wind speed intensity.
  Color _colorForSpeed(double intensity, double alpha) {
    // Tuning: expected screen speed 0.5 - 5.0 pixels/frame
    if (isHolographic) {
      if (intensity < 1.0) return Color.fromRGBO(0, 255, 255, 0.4 * alpha);
      if (intensity < 3.0) return Color.fromRGBO(0, 217, 255, 0.6 * alpha);
      return Color.fromRGBO(255, 0, 255, 0.9 * alpha);
    } else {
      if (intensity < 1.0) return Color.fromRGBO(255, 255, 255, 0.3 * alpha);
      if (intensity < 3.0) return Color.fromRGBO(0, 201, 167, 0.5 * alpha);
      if (intensity < 5.0) return Color.fromRGBO(255, 154, 61, 0.7 * alpha);
      return Color.fromRGBO(255, 107, 107, 0.9 * alpha);
    }
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) =>
      frameCount != oldDelegate.frameCount;
}
