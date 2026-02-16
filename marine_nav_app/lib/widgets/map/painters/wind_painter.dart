/// Custom painter for wind particle visualization.
library;

import 'package:flutter/material.dart';

/// Particle in geographic space with trail history.
class GeoParticle {
  /// Current latitude.
  double lat;

  /// Current longitude.
  double lng;

  /// Age in seconds since creation.
  double age;

  /// Total lifetime in seconds before respawn.
  double lifetime;

  /// Current speed in knots.
  double speed;

  /// History of latitude positions for trail.
  final List<double> trailLat;

  /// History of longitude positions for trail.
  final List<double> trailLng;

  /// Creates a GeoParticle at given position.
  GeoParticle({
    required this.lat,
    required this.lng,
    this.age = 0,
    this.lifetime = 6.0,
  })  : speed = 0,
        trailLat = [],
        trailLng = [];

  /// Returns normalized age (0.0 to 1.0).
  double get normalizedAge => (age / lifetime).clamp(0.0, 1.0);

  /// Returns opacity alpha value based on age (fade in/out).
  double get alpha {
    if (normalizedAge < 0.15) return normalizedAge / 0.15;
    if (normalizedAge > 0.8) return (1.0 - normalizedAge) / 0.2;
    return 1.0;
  }
}

/// Pre-computed wind vector at a grid point.
class WindVector {
  /// Latitude of grid point.
  final double lat;

  /// Longitude of grid point.
  final double lng;

  /// U component of wind vector (East-West).
  final double u;

  /// V component of wind vector (North-South).
  final double v;

  /// Magnitude of wind vector.
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

/// Painter that renders wind particles on a canvas.
class WindPainter extends CustomPainter {
  /// List of active particles to draw.
  final List<GeoParticle> particles;

  /// Map bounds to project geographic coordinates to canvas.
  final ({double south, double north, double west, double east}) bounds;

  /// Whether to render in holographic theme mode.
  final bool isHolographic;

  /// Reusable paint objects to avoid per-frame allocation.
  final Paint _trailPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _glowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

  /// Frame counter to detect animation changes.
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

    for (final p in particles) {
      if (p.trailLat.length < 2) continue;
      final alpha = p.alpha;
      if (alpha < 0.02) continue;

      final color = _colorForSpeed(p.speed, alpha);

      for (int i = 0; i < p.trailLat.length - 1; i++) {
        // Project lat/lng to canvas coordinates
        final sx0 = (p.trailLng[i] - bounds.west) / lngRange * size.width;
        final sy0 =
            (1.0 - (p.trailLat[i] - bounds.south) / latRange) * size.height;
        final sx1 = (p.trailLng[i + 1] - bounds.west) / lngRange * size.width;
        final sy1 =
            (1.0 - (p.trailLat[i + 1] - bounds.south) / latRange) * size.height;

        final trailFade = 1.0 - (i / p.trailLat.length);
        final w = isHolographic ? (1.5 * trailFade) : (2.0 * trailFade);
        final segAlpha = alpha * trailFade;

        final from = Offset(sx0, sy0);
        final to = Offset(sx1, sy1);

        // Draw glowing trails in holographic mode
        if (isHolographic && i < 2) {
          _glowPaint
            ..color = color.withValues(alpha: segAlpha)
            ..strokeWidth = w * 2.0;
          canvas.drawLine(from, to, _glowPaint);
        }

        _trailPaint
          ..color = color.withValues(alpha: segAlpha)
          ..strokeWidth = w;
        canvas.drawLine(from, to, _trailPaint);
      }
    }
  }

  /// Returns color based on wind speed.
  Color _colorForSpeed(double speedKnots, double alpha) {
    if (isHolographic) {
      if (speedKnots < 5) return Color.fromRGBO(0, 255, 255, 0.4 * alpha);
      if (speedKnots < 15) return Color.fromRGBO(0, 217, 255, 0.6 * alpha);
      if (speedKnots < 25) return Color.fromRGBO(255, 0, 255, 0.7 * alpha);
      return Color.fromRGBO(255, 0, 255, 0.9 * alpha);
    } else {
      if (speedKnots < 5) return Color.fromRGBO(255, 255, 255, 0.25 * alpha);
      if (speedKnots < 15) return Color.fromRGBO(0, 201, 167, 0.45 * alpha);
      if (speedKnots < 25) return Color.fromRGBO(255, 154, 61, 0.6 * alpha);
      return Color.fromRGBO(255, 107, 107, 0.8 * alpha);
    }
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) =>
      frameCount != oldDelegate.frameCount ||
      bounds != oldDelegate.bounds ||
      isHolographic != oldDelegate.isHolographic;
}
