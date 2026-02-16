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
      if (p.trail.length < 2) continue;

      // Particle lifecycle alpha (fade in / fade out)
      double lifeAlpha = 1.0;
      if (p.age < 30) {
        lifeAlpha = p.age / 30.0;
      } else if (p.age > p.maxAge - 30) {
        lifeAlpha = (p.maxAge - p.age) / 30.0;
      }
      if (lifeAlpha <= 0) continue;

      final trailLen = p.trail.length;
      final baseColor = _colorForSpeed(p.speed, 1.0);

      // Draw trail as tapered segments: thick+bright at head, thin+faint at tail
      for (int i = 1; i < trailLen; i++) {
        final prev = p.trail[i - 1];
        final cur = p.trail[i];

        final screenA = ProjectionService.latLngToScreen(
          LatLng(latitude: prev.lat, longitude: prev.lng),
          viewport,
        );
        final screenB = ProjectionService.latLngToScreen(
          LatLng(latitude: cur.lat, longitude: cur.lng),
          viewport,
        );

        // Progress 0.0 (oldest/tail) → 1.0 (newest/head)
        final progress = i / (trailLen - 1);

        // Taper: opacity and width increase toward head
        final segAlpha = (progress * progress * lifeAlpha).clamp(0.0, 1.0);
        final segWidth = isHolographic
            ? 0.3 + progress * 1.2 // 0.3 → 1.5
            : 0.4 + progress * 1.1; // 0.4 → 1.5

        _particlePaint
          ..color = baseColor.withValues(alpha: segAlpha * 0.8)
          ..strokeWidth = segWidth
          ..style = PaintingStyle.stroke;

        canvas.drawLine(screenA, screenB, _particlePaint);
      }

      // Bright head dot for visibility
      if (trailLen > 0) {
        final head = p.trail.last;
        final headScreen = ProjectionService.latLngToScreen(
          LatLng(latitude: head.lat, longitude: head.lng),
          viewport,
        );
        _particlePaint
          ..color = baseColor.withValues(alpha: lifeAlpha * 0.9)
          ..strokeWidth = isHolographic ? 1.8 : 2.0
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
            headScreen, isHolographic ? 0.8 : 1.0, _particlePaint);
      }
    }
  }

  /// Returns color based on wind speed in knots.
  Color _colorForSpeed(double speedKnots, double alpha) {
    if (isHolographic) {
      if (speedKnots < 5) return Color.fromRGBO(0, 255, 255, 0.5 * alpha);
      if (speedKnots < 10) return Color.fromRGBO(0, 217, 255, 0.65 * alpha);
      if (speedKnots < 20) return Color.fromRGBO(0, 180, 255, 0.8 * alpha);
      if (speedKnots < 30) return Color.fromRGBO(255, 0, 255, 0.9 * alpha);
      return Color.fromRGBO(255, 0, 255, 1.0 * alpha);
    }
    if (speedKnots < 5) return Color.fromRGBO(255, 255, 255, 0.4 * alpha);
    if (speedKnots < 10) return Color.fromRGBO(0, 201, 167, 0.6 * alpha);
    if (speedKnots < 20) return Color.fromRGBO(0, 229, 255, 0.8 * alpha);
    if (speedKnots < 30) return Color.fromRGBO(255, 154, 61, 0.9 * alpha);
    return Color.fromRGBO(255, 82, 82, 1.0 * alpha);
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) =>
      frameCount != oldDelegate.frameCount;
}
