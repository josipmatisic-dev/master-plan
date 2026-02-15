/// Track overlay widget for rendering vessel breadcrumb trail on the map.
///
/// Uses [ProjectionService] to convert geographic coordinates to screen
/// pixels. Draws a gradient line connecting track history points.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Viewport;

import '../../models/boat_position.dart';
import '../../models/viewport.dart';
import '../../services/projection_service.dart';
import '../../theme/colors.dart';

/// Renders the vessel track as a gradient breadcrumb trail on the map.
///
/// Requires [trackHistory] and [viewport] to compute screen placement.
/// Older points fade to transparent, newer points are fully opaque.
///
/// Usage:
/// ```dart
/// TrackOverlay(
///   trackHistory: boatProvider.trackHistory,
///   viewport: mapProvider.viewport,
/// )
/// ```
class TrackOverlay extends StatelessWidget {
  /// List of track history positions, oldest first.
  final List<BoatPosition> trackHistory;

  /// Current map viewport for coordinate projection.
  final Viewport viewport;

  /// Creates a [TrackOverlay] breadcrumb trail.
  const TrackOverlay({
    super.key,
    required this.trackHistory,
    required this.viewport,
  });

  @override
  Widget build(BuildContext context) {
    if (trackHistory.length < 2) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _TrackOverlayPainter(
          trackHistory: trackHistory,
          viewport: viewport,
        ),
        size: viewport.size,
      ),
    );
  }
}

/// Custom painter for the track trail line.
class _TrackOverlayPainter extends CustomPainter {
  final List<BoatPosition> trackHistory;
  final Viewport viewport;

  /// Minimum screen distance between points to draw (avoid overdraw).
  static const double _minPointDistance = 2.0;

  _TrackOverlayPainter({
    required this.trackHistory,
    required this.viewport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trackHistory.length < 2) return;

    // Convert all positions to screen coordinates
    final screenPoints = <Offset>[];
    for (final pos in trackHistory) {
      final screen = ProjectionService.latLngToScreen(
        pos.position,
        viewport,
      );
      screenPoints.add(screen);
    }

    // Filter out points that are too close together on screen
    final filteredPoints = _filterClosePoints(screenPoints);
    if (filteredPoints.length < 2) return;

    // Draw gradient trail from oldest (transparent) to newest (opaque)
    _drawGradientTrail(canvas, filteredPoints);

    // Draw small dots at each visible track point
    _drawTrackDots(canvas, filteredPoints);
  }

  /// Filters out screen points that are closer than [_minPointDistance].
  List<Offset> _filterClosePoints(List<Offset> points) {
    if (points.isEmpty) return points;

    final filtered = <Offset>[points.first];
    for (int i = 1; i < points.length; i++) {
      final dist = (points[i] - filtered.last).distance;
      if (dist >= _minPointDistance) {
        filtered.add(points[i]);
      }
    }

    // Always include the last point for accuracy
    if (filtered.last != points.last) {
      filtered.add(points.last);
    }

    return filtered;
  }

  /// Draws the gradient trail line connecting all points.
  void _drawGradientTrail(Canvas canvas, List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Gradient from transparent (oldest) to seafoam green (newest)
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
        points.first,
        points.last,
        [
          OceanColors.seafoamGreen.withValues(alpha: 0.1),
          OceanColors.seafoamGreen.withValues(alpha: 0.8),
        ],
      );

    canvas.drawPath(path, trailPaint);
  }

  /// Draws small dots at track point positions for visual clarity.
  void _drawTrackDots(Canvas canvas, List<Offset> points) {
    // Only draw dots for every Nth point to avoid clutter
    final step = (points.length / 20).ceil().clamp(1, points.length);
    final dotPaint = Paint()
      ..color = OceanColors.seafoamGreen.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i += step) {
      // Opacity increases with recency
      final t = i / (points.length - 1);
      dotPaint.color =
          OceanColors.seafoamGreen.withValues(alpha: 0.2 + t * 0.5);
      canvas.drawCircle(points[i], 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackOverlayPainter oldDelegate) {
    return oldDelegate.trackHistory.length != trackHistory.length ||
        oldDelegate.viewport != viewport ||
        (trackHistory.isNotEmpty &&
            oldDelegate.trackHistory.isNotEmpty &&
            oldDelegate.trackHistory.last != trackHistory.last);
  }
}
