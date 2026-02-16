/// Custom painter for wind particle visualization.
/// Ported from Cameron Beccario's 'earth' project (MIT License).
/// https://github.com/cambecc/earth
library;

import 'package:flutter/material.dart' hide Viewport;

import '../../../models/lat_lng.dart';
import '../../../models/viewport.dart';
import '../../../services/projection_service.dart';

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

  /// Trail history (recent positions).
  /// Newest at end.
  final List<({double lat, double lng})> trail = [];

  /// Creates a GeoParticle.
  GeoParticle({
    required this.lat,
    required this.lng,
    required this.maxAge,
  })  : age = 0,
        speed = 0;
}

/// Painter that renders wind particles as streaks on the canvas.
///
/// Does NOT own physics — the overlay widget handles advection.
/// Projects particles to screen via [ProjectionService] so they
/// stay geo-anchored to the map during pan/zoom.
class WindPainter extends CustomPainter {
  /// List of active particles to draw.
  final List<GeoParticle> particles;

  /// Full map viewport for Mercator projection.
  final Viewport viewport;

  /// Whether to render in holographic theme mode.
  final bool isHolographic;

  /// Frame counter for shouldRepaint.
  final int frameCount;

  /// Reusable paint object.
  final Paint _particlePaint = Paint()..strokeCap = StrokeCap.round;

  /// Creates a WindPainter.
  WindPainter({
    required this.particles,
    required this.viewport,
    required this.isHolographic,
    required this.frameCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    for (final p in particles) {
      // Fade in over 20 frames, fade out over 20 frames
      double alpha = 1.0;
      if (p.age < 20) {
        alpha = p.age / 20.0;
      } else if (p.age > p.maxAge - 20) {
        alpha = (p.maxAge - p.age) / 20.0;
      }

      if (alpha <= 0 || p.trail.length < 2) continue;

      final color = _colorForSpeed(p.speed, alpha);

      _particlePaint
        ..color = color
        ..strokeWidth = isHolographic ? 1.5 : 2.0
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool first = true;

      for (final pt in p.trail) {
        final screen = ProjectionService.latLngToScreen(
          LatLng(latitude: pt.lat, longitude: pt.lng),
          viewport,
        );

        if (first) {
          path.moveTo(screen.dx, screen.dy);
          first = false;
        } else {
          path.lineTo(screen.dx, screen.dy);
        }
      }

      canvas.drawPath(path, _particlePaint);
    }
  }

  /// Returns color based on wind speed in knots.
  Color _colorForSpeed(double speedKnots, double alpha) {
    // Smoother gradient like Windy
    if (isHolographic) {
      // ... same ...
    } else {
      // Use seafoam green base but vary intensity more smoothly
      if (speedKnots < 5) return Color.fromRGBO(255, 255, 255, 0.4 * alpha);
      if (speedKnots < 10) return Color.fromRGBO(0, 201, 167, 0.6 * alpha);
      if (speedKnots < 20)
        return Color.fromRGBO(0, 229, 255, 0.8 * alpha); // Blue for mid
      if (speedKnots < 30)
        return Color.fromRGBO(255, 154, 61, 0.9 * alpha); // Orange
      return Color.fromRGBO(255, 82, 82, 1.0 * alpha); // Red
    }
    return Colors.white.withValues(alpha: alpha); // Fallback
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) =>
      frameCount != oldDelegate.frameCount;
}
