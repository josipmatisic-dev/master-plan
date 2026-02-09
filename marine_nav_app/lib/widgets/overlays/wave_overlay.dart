/// Wave overlay widget for rendering wave height on the map.
///
/// Uses [ProjectionService] to convert geographic coordinates to screen
/// pixels. Draws directional arrows with height-based blue gradient.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;

import '../../models/viewport.dart';
import '../../models/weather_data.dart';
import '../../services/projection_service.dart';

/// Renders wave height and direction indicators at grid points.
///
/// Colors follow a blue gradient (0-8m):
/// - Light blue: <1m
/// - Blue: 1-3m
/// - Dark blue: 3-5m
/// - Deep blue/purple: >5m
///
/// Usage:
/// ```dart
/// WaveOverlay(
///   wavePoints: weatherProvider.data.wavePoints,
///   viewport: mapProvider.viewport,
/// )
/// ```
class WaveOverlay extends StatelessWidget {
  /// Wave data points to render.
  final List<WaveDataPoint> wavePoints;

  /// Current map viewport for coordinate projection.
  final Viewport viewport;

  /// Creates a [WaveOverlay].
  const WaveOverlay({
    super.key,
    required this.wavePoints,
    required this.viewport,
  });

  @override
  Widget build(BuildContext context) {
    if (wavePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _WaveOverlayPainter(
          wavePoints: wavePoints,
          viewport: viewport,
        ),
        size: viewport.size,
      ),
    );
  }
}

/// Custom painter for wave height indicators.
class _WaveOverlayPainter extends CustomPainter {
  final List<WaveDataPoint> wavePoints;
  final Viewport viewport;

  /// Base indicator size in logical pixels.
  static const double _indicatorSize = 20.0;

  _WaveOverlayPainter({
    required this.wavePoints,
    required this.viewport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final point in wavePoints) {
      final screenPos = ProjectionService.latLngToScreen(
        point.position,
        viewport,
      );

      // Cull points outside viewport.
      if (!_isInViewport(screenPos, size)) continue;

      _drawWaveIndicator(canvas, screenPos, point);
    }
  }

  /// Checks if a screen position is within the visible viewport.
  bool _isInViewport(Offset pos, Size size) {
    const margin = _indicatorSize * 2;
    return pos.dx >= -margin &&
        pos.dx <= size.width + margin &&
        pos.dy >= -margin &&
        pos.dy <= size.height + margin;
  }

  /// Draws a wave height indicator at a screen position.
  void _drawWaveIndicator(
    Canvas canvas,
    Offset center,
    WaveDataPoint point,
  ) {
    final color = _waveHeightColor(point.heightMeters);

    // Filled circle sized by wave height (capped at 2× base size).
    final radius =
        (_indicatorSize * (point.heightMeters / 4.0).clamp(0.3, 2.0)) / 2;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, strokePaint);

    // Direction arrow from center.
    final radians =
        (point.directionDegrees - 90) * math.pi / 180.0 + viewport.rotation;
    final arrowLen = radius + 8.0;
    final tipX = center.dx + arrowLen * math.cos(radians);
    final tipY = center.dy + arrowLen * math.sin(radians);

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(tipX, tipY), arrowPaint);

    // Small arrow head.
    const headAngle = 0.5;
    const headLength = 5.0;
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
    canvas.drawPath(headPath, arrowPaint);
  }

  /// Returns color based on wave height (blue gradient 0-8m).
  Color _waveHeightColor(double heightMeters) {
    if (heightMeters < 1) return const Color(0xFF81D4FA); // Light blue
    if (heightMeters < 3) return const Color(0xFF42A5F5); // Blue
    if (heightMeters < 5) return const Color(0xFF1565C0); // Dark blue
    return const Color(0xFF7B1FA2); // Purple (dangerous)
  }

  @override
  bool shouldRepaint(covariant _WaveOverlayPainter oldDelegate) {
    return oldDelegate.wavePoints.length != wavePoints.length ||
        oldDelegate.viewport != viewport;
  }
}
