/// Wind overlay widget for rendering wind barbs on the map.
///
/// Uses [ProjectionService] to convert geographic coordinates to screen
/// pixels. Colors wind arrows by Beaufort scale (green → red).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;

import '../../models/viewport.dart';
import '../../models/weather_data.dart';
import '../../services/projection_service.dart';

/// Renders wind arrows/barbs at grid points on the map.
///
/// Colors follow Beaufort scale:
/// - Green: <10 kts
/// - Yellow: 10-20 kts
/// - Orange: 20-30 kts
/// - Red: >30 kts
///
/// Usage:
/// ```dart
/// WindOverlay(
///   windPoints: weatherProvider.data.windPoints,
///   viewport: mapProvider.viewport,
/// )
/// ```
class WindOverlay extends StatelessWidget {
  /// Wind data points to render.
  final List<WindDataPoint> windPoints;

  /// Current map viewport for coordinate projection.
  final Viewport viewport;

  /// Creates a [WindOverlay].
  const WindOverlay({
    super.key,
    required this.windPoints,
    required this.viewport,
  });

  @override
  Widget build(BuildContext context) {
    if (windPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _WindOverlayPainter(
          windPoints: windPoints,
          viewport: viewport,
        ),
        size: viewport.size,
      ),
    );
  }
}

/// Custom painter for wind arrows.
class _WindOverlayPainter extends CustomPainter {
  final List<WindDataPoint> windPoints;
  final Viewport viewport;

  /// Arrow length in logical pixels.
  static const double _arrowLength = 24.0;

  _WindOverlayPainter({
    required this.windPoints,
    required this.viewport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final point in windPoints) {
      final screenPos = ProjectionService.latLngToScreen(
        point.position,
        viewport,
      );

      // Cull points outside viewport (with margin for arrow length).
      if (!_isInViewport(screenPos, size)) continue;

      _drawWindArrow(canvas, screenPos, point);
    }
  }

  /// Checks if a screen position is within the visible viewport.
  bool _isInViewport(Offset pos, Size size) {
    const margin = _arrowLength * 2;
    return pos.dx >= -margin &&
        pos.dx <= size.width + margin &&
        pos.dy >= -margin &&
        pos.dy <= size.height + margin;
  }

  /// Draws a single wind arrow at a screen position.
  void _drawWindArrow(
    Canvas canvas,
    Offset center,
    WindDataPoint point,
  ) {
    final color = _beaufortColor(point.speedKnots);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Wind direction: meteorological convention (FROM direction).
    // Convert to radians, subtract 90 so 0° = up (North).
    final radians =
        (point.directionDegrees - 90) * math.pi / 180.0 + viewport.rotation;

    // Arrow shaft.
    final tipX = center.dx + _arrowLength * math.cos(radians);
    final tipY = center.dy + _arrowLength * math.sin(radians);
    canvas.drawLine(center, Offset(tipX, tipY), paint);

    // Arrow head.
    const headAngle = 0.5;
    const headLength = 8.0;
    final headLeft = Offset(
      tipX - headLength * math.cos(radians - headAngle),
      tipY - headLength * math.sin(radians - headAngle),
    );
    final headRight = Offset(
      tipX - headLength * math.cos(radians + headAngle),
      tipY - headLength * math.sin(radians + headAngle),
    );

    final headPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(headLeft.dx, headLeft.dy)
      ..moveTo(tipX, tipY)
      ..lineTo(headRight.dx, headRight.dy);
    canvas.drawPath(headPath, paint);

    // Small dot at origin.
    canvas.drawCircle(center, 2.5, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke; // Reset style.
  }

  /// Returns color based on wind speed (Beaufort scale).
  ///
  /// Green (<10 kts), Yellow (10-20 kts), Orange (20-30 kts), Red (>30 kts).
  Color _beaufortColor(double speedKnots) {
    if (speedKnots < 10) return const Color(0xFF4CAF50); // Green
    if (speedKnots < 20) return const Color(0xFFFFEB3B); // Yellow
    if (speedKnots < 30) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  @override
  bool shouldRepaint(covariant _WindOverlayPainter oldDelegate) {
    return oldDelegate.windPoints.length != windPoints.length ||
        oldDelegate.viewport != viewport;
  }
}
