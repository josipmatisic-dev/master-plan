/// Boat marker overlay — renders own vessel position and track trail on map.
///
/// Uses the same geo-to-screen projection as AisTargetOverlay and
/// WindParticleOverlay. Shows a directional boat icon with heading
/// indicator, accuracy circle, and optional breadcrumb trail.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/boat_position.dart';

/// Renders own vessel marker and track trail on the map.
///
/// The boat icon rotates by heading/COG, with an accuracy ring
/// and a speed-colored track trail behind it.
class BoatMarkerOverlay extends StatelessWidget {
  /// Current boat position (null = no fix).
  final BoatPosition? position;

  /// Track trail points (oldest first).
  final List<TrackPoint> trackHistory;

  /// Whether to show the track trail.
  final bool showTrack;

  /// Geographic bounds of the current map viewport.
  final ({double south, double north, double west, double east}) bounds;

  /// Current map zoom level.
  final double zoom;

  /// Whether the holographic theme is active.
  final bool isHolographic;

  /// Creates a boat marker overlay.
  const BoatMarkerOverlay({
    super.key,
    required this.position,
    required this.trackHistory,
    required this.showTrack,
    required this.bounds,
    required this.zoom,
    this.isHolographic = false,
  });

  @override
  Widget build(BuildContext context) {
    if (position == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: CustomPaint(
        painter: _BoatMarkerPainter(
          position: position!,
          trackHistory: trackHistory,
          showTrack: showTrack,
          bounds: bounds,
          zoom: zoom,
          isHolographic: isHolographic,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// CustomPainter that draws own vessel and track trail.
class _BoatMarkerPainter extends CustomPainter {
  final BoatPosition position;
  final List<TrackPoint> trackHistory;
  final bool showTrack;
  final ({double south, double north, double west, double east}) bounds;
  final double zoom;
  final bool isHolographic;

  // Reusable paints
  final Paint _boatFill = Paint()..style = PaintingStyle.fill;
  final Paint _boatStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _accuracyPaint = Paint()..style = PaintingStyle.fill;
  final Paint _accuracyStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final Paint _trailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _headingLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  final Paint _keelPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  _BoatMarkerPainter({
    required this.position,
    required this.trackHistory,
    required this.showTrack,
    required this.bounds,
    required this.zoom,
    required this.isHolographic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final latRange = bounds.north - bounds.south;
    final lngRange = bounds.east - bounds.west;
    if (latRange <= 0 || lngRange <= 0) return;

    // Draw track trail first (behind boat)
    if (showTrack && trackHistory.length >= 2) {
      _drawTrackTrail(canvas, size, latRange, lngRange);
    }

    // Project boat position to screen
    final sx =
        (position.position.longitude - bounds.west) / lngRange * size.width;
    final sy = (1.0 - (position.position.latitude - bounds.south) / latRange) *
        size.height;
    final center = Offset(sx, sy);

    // Draw accuracy circle
    if (position.accuracy > 1) {
      _drawAccuracyCircle(canvas, center, size, latRange);
    }

    // Draw glow (holographic theme)
    if (isHolographic) {
      _drawGlow(canvas, center);
    }

    // Draw heading/COG line extending ahead
    final heading = position.bestHeading;
    if (heading != null) {
      _drawHeadingLine(canvas, center, heading);
    }

    // Draw boat icon
    _drawBoatIcon(canvas, center, heading);
  }

  /// Draw speed-colored track trail breadcrumbs.
  void _drawTrackTrail(
      Canvas canvas, Size size, double latRange, double lngRange) {
    final path = Path();
    var started = false;

    for (int i = 0; i < trackHistory.length; i++) {
      final pt = trackHistory[i];

      // Cull off-screen points
      if (pt.lat < bounds.south ||
          pt.lat > bounds.north ||
          pt.lng < bounds.west ||
          pt.lng > bounds.east) {
        started = false;
        continue;
      }

      final sx = (pt.lng - bounds.west) / lngRange * size.width;
      final sy = (1.0 - (pt.lat - bounds.south) / latRange) * size.height;

      if (!started) {
        path.moveTo(sx, sy);
        started = true;
      } else {
        path.lineTo(sx, sy);
      }
    }

    // Trail color: faded version of boat color
    final trailColor = isHolographic
        ? const Color(0xFF00D9FF).withValues(alpha: 0.4)
        : const Color(0xFF00C9A7).withValues(alpha: 0.4);

    _trailPaint
      ..color = trailColor
      ..strokeWidth = math.max(1.5, zoom * 0.2);
    canvas.drawPath(path, _trailPaint);
  }

  /// Draw GPS accuracy circle.
  void _drawAccuracyCircle(
      Canvas canvas, Offset center, Size size, double latRange) {
    // Convert accuracy meters to screen pixels
    // ~111320 meters per degree of latitude
    const degreesPerMeter = 1.0 / 111320.0;
    final accuracyDegrees = position.accuracy * degreesPerMeter;
    final radiusPx = (accuracyDegrees / latRange) * size.height;

    // Only draw if meaningful (> 3px, < half screen)
    if (radiusPx < 3 || radiusPx > size.height * 0.5) return;

    final fillColor = isHolographic
        ? const Color(0xFF00D9FF).withValues(alpha: 0.08)
        : const Color(0xFF00C9A7).withValues(alpha: 0.08);
    final strokeColor = isHolographic
        ? const Color(0xFF00D9FF).withValues(alpha: 0.25)
        : const Color(0xFF00C9A7).withValues(alpha: 0.25);

    _accuracyPaint.color = fillColor;
    canvas.drawCircle(center, radiusPx, _accuracyPaint);

    _accuracyStrokePaint.color = strokeColor;
    canvas.drawCircle(center, radiusPx, _accuracyStrokePaint);
  }

  /// Draw neon glow behind boat (holographic theme only).
  void _drawGlow(Canvas canvas, Offset center) {
    _glowPaint.color = const Color(0xFF00D9FF).withValues(alpha: 0.3);
    canvas.drawCircle(center, 20, _glowPaint);
  }

  /// Draw heading/COG line extending ahead of the vessel.
  void _drawHeadingLine(Canvas canvas, Offset center, double headingDeg) {
    final rad = headingDeg * math.pi / 180.0;
    final lineLength = 30.0 + zoom * 2;

    final endX = center.dx + lineLength * math.sin(rad);
    final endY = center.dy - lineLength * math.cos(rad);

    final lineColor = isHolographic
        ? const Color(0xFF00D9FF).withValues(alpha: 0.5)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.5);

    _headingLinePaint.color = lineColor;
    canvas.drawLine(center, Offset(endX, endY), _headingLinePaint);

    // Dashed extension (future heading projection)
    final dashEnd = Offset(
      center.dx + (lineLength * 2) * math.sin(rad),
      center.dy - (lineLength * 2) * math.cos(rad),
    );
    _headingLinePaint.color = lineColor.withValues(alpha: 0.2);
    canvas.drawLine(Offset(endX, endY), dashEnd, _headingLinePaint);
  }

  /// Draw the boat icon — directional arrow shape.
  void _drawBoatIcon(Canvas canvas, Offset center, double? headingDeg) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    if (headingDeg != null) {
      canvas.rotate(headingDeg * math.pi / 180.0);
    }

    final s = _boatSize;
    final path = Path()
      // Pointed bow
      ..moveTo(0, -s * 1.5)
      // Port hull
      ..lineTo(-s * 0.8, -s * 0.2)
      ..lineTo(-s * 0.7, s * 0.9)
      // Stern
      ..quadraticBezierTo(-s * 0.3, s * 1.2, 0, s * 1.0)
      ..quadraticBezierTo(s * 0.3, s * 1.2, s * 0.7, s * 0.9)
      // Starboard hull
      ..lineTo(s * 0.8, -s * 0.2)
      ..close();

    // Fill
    _boatFill.color =
        isHolographic ? const Color(0xFF00D9FF) : const Color(0xFF00C9A7);
    canvas.drawPath(path, _boatFill);

    // Stroke outline
    _boatStroke.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _boatStroke);

    // Keel line (center stripe)
    _keelPaint.color = const Color(0xFF0A1F3F).withValues(alpha: 0.4);
    canvas.drawLine(Offset(0, -s * 0.8), Offset(0, s * 0.6), _keelPaint);

    canvas.restore();
  }

  /// Boat icon size — adaptive to zoom.
  double get _boatSize {
    if (zoom >= 14) return 14;
    if (zoom >= 12) return 12;
    if (zoom >= 10) return 10;
    return 8;
  }

  @override
  bool shouldRepaint(covariant _BoatMarkerPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.showTrack != showTrack ||
        oldDelegate.trackHistory.length != trackHistory.length ||
        oldDelegate.bounds != bounds ||
        oldDelegate.zoom != zoom ||
        oldDelegate.isHolographic != isHolographic;
  }
}
