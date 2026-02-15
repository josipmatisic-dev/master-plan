/// Wave overlay widget rendering a Windy.com-style smooth color gradient
/// heatmap using IDW interpolation, with animated ripple rings for
/// high-wave areas.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;

import '../../models/viewport.dart';
import '../../models/weather_data.dart';
import '../../services/projection_service.dart';

/// Renders a full-viewport wave height heatmap with animated ripples.
///
/// Usage:
/// ```dart
/// WaveOverlay(
///   wavePoints: weatherProvider.data.wavePoints,
///   viewport: mapProvider.viewport,
/// )
/// ```
class WaveOverlay extends StatefulWidget {
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
  State<WaveOverlay> createState() => _WaveOverlayState();
}

class _WaveOverlayState extends State<WaveOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wavePoints.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _rippleController,
          builder: (_, __) => CustomPaint(
            painter: _WaveHeatmapPainter(
              wavePoints: widget.wavePoints,
              viewport: widget.viewport,
              ripplePhase: _rippleController.value,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// Color stops for the wave height gradient (meters → color).
const _kColorStops = <(double, Color)>[
  (0.0, Color(0xFFE0F7FA)),
  (0.5, Color(0xFF80DEEA)),
  (1.0, Color(0xFF26C6DA)),
  (2.0, Color(0xFF0288D1)),
  (3.0, Color(0xFF01579B)),
  (5.0, Color(0xFF4A148C)),
  (8.0, Color(0xFF880E4F)),
];

class _WaveHeatmapPainter extends CustomPainter {
  final List<WaveDataPoint> wavePoints;
  final Viewport viewport;
  final double ripplePhase;

  static const int _step = 3;
  static const double _heatmapAlpha = 0.45;
  static const double _rippleAlpha = 0.55;
  static const double _rippleThreshold = 2.0;
  // IDW power parameter.
  static const double _idwPower = 2.0;

  _WaveHeatmapPainter({
    required this.wavePoints,
    required this.viewport,
    required this.ripplePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pre-compute screen positions for all data points.
    final screenPts = <(Offset, double)>[];
    for (final pt in wavePoints) {
      final pos = ProjectionService.latLngToScreen(pt.position, viewport);
      screenPts.add((pos, pt.heightMeters));
    }

    _paintHeatmap(canvas, size, screenPts);
    _paintRipples(canvas, size, screenPts);
  }

  void _paintHeatmap(
      Canvas canvas, Size size, List<(Offset, double)> screenPts) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width.ceil();
    final h = size.height.ceil();

    for (int y = 0; y < h; y += _step) {
      for (int x = 0; x < w; x += _step) {
        final height = _idwInterpolate(x.toDouble(), y.toDouble(), screenPts);
        final color = _colorForHeight(height);
        paint.color = color.withValues(alpha: _heatmapAlpha);
        canvas.drawRect(
          Rect.fromLTWH(
              x.toDouble(), y.toDouble(), _step.toDouble(), _step.toDouble()),
          paint,
        );
      }
    }
  }

  /// IDW interpolation: weighted average of nearby data point heights.
  double _idwInterpolate(
      double px, double py, List<(Offset, double)> screenPts) {
    double wSum = 0.0;
    double vSum = 0.0;
    for (final (pos, height) in screenPts) {
      final dx = px - pos.dx;
      final dy = py - pos.dy;
      final distSq = dx * dx + dy * dy;
      if (distSq < 1.0) return height;
      final w = 1.0 / math.pow(distSq, _idwPower / 2.0);
      wSum += w;
      vSum += w * height;
    }
    return wSum > 0.0 ? vSum / wSum : 0.0;
  }

  /// Lerp between color stops based on wave height.
  static Color _colorForHeight(double h) {
    if (h <= _kColorStops.first.$1) return _kColorStops.first.$2;
    for (int i = 1; i < _kColorStops.length; i++) {
      if (h <= _kColorStops[i].$1) {
        final t = (h - _kColorStops[i - 1].$1) /
            (_kColorStops[i].$1 - _kColorStops[i - 1].$1);
        return Color.lerp(_kColorStops[i - 1].$2, _kColorStops[i].$2, t)!;
      }
    }
    return _kColorStops.last.$2;
  }

  /// Draw animated concentric ripple rings around high-wave points.
  void _paintRipples(
      Canvas canvas, Size size, List<(Offset, double)> screenPts) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final (pos, height) in screenPts) {
      if (height < _rippleThreshold) continue;
      // Skip off-screen points (with generous margin for ripple radius).
      if (pos.dx < -120 ||
          pos.dx > size.width + 120 ||
          pos.dy < -120 ||
          pos.dy > size.height + 120) {
        continue;
      }

      final maxRadius = 20.0 + height * 8.0;
      const ringCount = 3;
      for (int i = 0; i < ringCount; i++) {
        final phase = (ripplePhase + i / ringCount) % 1.0;
        final radius = maxRadius * phase;
        final opacity = _rippleAlpha * (1.0 - phase);
        paint.color = _colorForHeight(height).withValues(alpha: opacity);
        canvas.drawCircle(pos, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveHeatmapPainter oldDelegate) {
    return oldDelegate.ripplePhase != ripplePhase ||
        oldDelegate.wavePoints.length != wavePoints.length ||
        oldDelegate.viewport != viewport;
  }
}
