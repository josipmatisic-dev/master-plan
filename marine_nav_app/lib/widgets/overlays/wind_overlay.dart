/// Windy.com-style wind overlay with smooth color gradient heatmap
/// and animated wind particles.
///
/// Uses IDW (inverse distance weighting) interpolation to create a
/// full-viewport color field from sparse wind data points.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;

import '../../models/viewport.dart';
import '../../models/weather_data.dart';
import '../../services/projection_service.dart';

/// Wind speed color stops (knots → color).
const _kWindColors = <(double, Color)>[
  (0, Color(0xFF00E676)),
  (5, Color(0xFF76FF03)),
  (10, Color(0xFFFFEB3B)),
  (15, Color(0xFFFFC107)),
  (20, Color(0xFFFF9800)),
  (25, Color(0xFFF44336)),
  (30, Color(0xFF9C27B0)),
  (40, Color(0xFF4A148C)),
];

const _kGridStep = 3;
const _kHeatmapAlpha = 0.55;
const _kParticleAlpha = 0.85;
const _kParticleCount = 400;

Color _windColor(double knots) {
  if (knots <= _kWindColors.first.$1) return _kWindColors.first.$2;
  for (var i = 1; i < _kWindColors.length; i++) {
    if (knots <= _kWindColors[i].$1) {
      final t = (knots - _kWindColors[i - 1].$1) /
          (_kWindColors[i].$1 - _kWindColors[i - 1].$1);
      return Color.lerp(_kWindColors[i - 1].$2, _kWindColors[i].$2, t)!;
    }
  }
  return _kWindColors.last.$2;
}

/// Windy.com-style wind overlay with heatmap and animated particles.
class WindOverlay extends StatefulWidget {
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
  State<WindOverlay> createState() => _WindOverlayState();
}

class _WindOverlayState extends State<WindOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = List.generate(_kParticleCount, (_) => _randomParticle());
  }

  _Particle _randomParticle() => _Particle(
        x: _rng.nextDouble() * (widget.viewport.size.width),
        y: _rng.nextDouble() * (widget.viewport.size.height),
        age: _rng.nextDouble(),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.windPoints.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _WindHeatmapPainter(
              windPoints: widget.windPoints,
              viewport: widget.viewport,
              particles: _particles,
              rng: _rng,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, age;
  _Particle({required this.x, required this.y, required this.age});
}

/// Precomputed screen-space point for fast IDW lookups.
class _ScreenPoint {
  final Offset pos;
  final double speedKnots;
  final double dirRad;
  _ScreenPoint(this.pos, this.speedKnots, this.dirRad);
}

class _WindHeatmapPainter extends CustomPainter {
  final List<WindDataPoint> windPoints;
  final Viewport viewport;
  final List<_Particle> particles;
  final math.Random rng;

  _WindHeatmapPainter({
    required this.windPoints,
    required this.viewport,
    required this.particles,
    required this.rng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = _projectPoints();
    if (pts.isEmpty) return;
    _paintHeatmap(canvas, size, pts);
    _advanceAndPaintParticles(canvas, size, pts);
  }

  List<_ScreenPoint> _projectPoints() => windPoints.map((wp) {
        final s = ProjectionService.latLngToScreen(wp.position, viewport);
        final rad = wp.directionDegrees * math.pi / 180.0;
        return _ScreenPoint(s, wp.speedKnots, rad);
      }).toList();

  void _paintHeatmap(Canvas canvas, Size size, List<_ScreenPoint> pts) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width.ceil();
    final h = size.height.ceil();

    for (var py = 0; py < h; py += _kGridStep) {
      for (var px = 0; px < w; px += _kGridStep) {
        final speed = _idwSpeed(px.toDouble(), py.toDouble(), pts);
        final c = _windColor(speed);
        paint.color = c.withValues(alpha: _kHeatmapAlpha);
        canvas.drawRect(
          Rect.fromLTWH(px.toDouble(), py.toDouble(), _kGridStep.toDouble(),
              _kGridStep.toDouble()),
          paint,
        );
      }
    }
  }

  double _idwSpeed(double x, double y, List<_ScreenPoint> pts) {
    var wSum = 0.0;
    var vSum = 0.0;
    for (final p in pts) {
      final dx = x - p.pos.dx;
      final dy = y - p.pos.dy;
      final d2 = dx * dx + dy * dy;
      if (d2 < 1.0) return p.speedKnots;
      final w = 1.0 / (d2); // power=2 via squared distance
      wSum += w;
      vSum += w * p.speedKnots;
    }
    return wSum > 0 ? vSum / wSum : 0;
  }

  /// Returns interpolated wind direction (radians) at (x,y).
  double _idwDirection(double x, double y, List<_ScreenPoint> pts) {
    var wxSum = 0.0;
    var wySum = 0.0;
    var wSum = 0.0;
    for (final p in pts) {
      final dx = x - p.pos.dx;
      final dy = y - p.pos.dy;
      final d2 = dx * dx + dy * dy;
      if (d2 < 1.0) return p.dirRad;
      final w = 1.0 / d2;
      wxSum += w * math.cos(p.dirRad);
      wySum += w * math.sin(p.dirRad);
      wSum += w;
    }
    if (wSum == 0) return 0;
    return math.atan2(wySum / wSum, wxSum / wSum);
  }

  void _advanceAndPaintParticles(
      Canvas canvas, Size size, List<_ScreenPoint> pts) {
    final paint = Paint()..style = PaintingStyle.fill;
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final p in particles) {
      final dir = _idwDirection(p.x, p.y, pts);
      final speed = _idwSpeed(p.x, p.y, pts);
      final velocity = 0.5 + speed * 0.08;

      final prevX = p.x;
      final prevY = p.y;

      // Move in wind direction.
      p.x += math.cos(dir) * velocity;
      p.y += math.sin(dir) * velocity;
      p.age += 0.005;

      // Wrap around viewport.
      if (p.x < 0) p.x += size.width;
      if (p.x > size.width) p.x -= size.width;
      if (p.y < 0) p.y += size.height;
      if (p.y > size.height) p.y -= size.height;

      // Reset old particles.
      if (p.age > 1.0) {
        p.x = rng.nextDouble() * size.width;
        p.y = rng.nextDouble() * size.height;
        p.age = 0;
        continue;
      }

      // Fade based on age.
      final alpha = _kParticleAlpha * (1.0 - p.age);
      final c = _windColor(speed).withValues(alpha: alpha);

      // Trail line.
      final dist = math
          .sqrt((p.x - prevX) * (p.x - prevX) + (p.y - prevY) * (p.y - prevY));
      if (dist < 20) {
        trailPaint.color = c.withValues(alpha: alpha * 0.4);
        canvas.drawLine(Offset(prevX, prevY), Offset(p.x, p.y), trailPaint);
      }

      // Dot.
      paint.color = c;
      canvas.drawCircle(Offset(p.x, p.y), 1.5 + speed * 0.03, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindHeatmapPainter old) =>
      !identical(old.windPoints, windPoints) ||
      old.viewport != viewport ||
      true; // Always repaint for particle animation.
}
