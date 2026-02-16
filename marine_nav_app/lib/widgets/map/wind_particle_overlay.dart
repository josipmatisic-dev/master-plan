/// Wind particle flow field visualization using CustomPainter.
///
/// Particles live in geographic (lat/lng) coordinates and are
/// projected to screen space each frame, so they track correctly
/// when the map pans or zooms — like Windy.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../models/weather_data.dart';

/// Renders wind flow particles over the map using CustomPainter.
///
/// Particles advect in geographic space using interpolated wind vectors,
/// and are projected to screen coordinates each frame.
class WindParticleOverlay extends StatefulWidget {
  /// Wind data points for interpolation.
  final List<WindDataPoint> windPoints;

  /// Whether to use holographic theme colors.
  final bool isHolographic;

  /// Geographic bounds of the visible map viewport.
  final ({double south, double north, double west, double east})? bounds;

  /// Creates a wind particle overlay with wind data for flow visualization.
  const WindParticleOverlay({
    super.key,
    required this.windPoints,
    this.isHolographic = false,
    this.bounds,
  });

  @override
  State<WindParticleOverlay> createState() => _WindParticleOverlayState();
}

class _WindParticleOverlayState extends State<WindParticleOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final _random = Random();

  // Geographic particles: lat/lng + velocity + trail in lat/lng
  final List<_GeoParticle> _particles = [];
  static const _maxParticles = 800;
  static const _trailLength = 5;

  // Pre-computed wind grid (u,v components) for fast interpolation
  List<_WindVector> _windGrid = [];

  // Frame throttle: paint at ~30fps
  int _frameCount = 0;

  // Track bounds to detect viewport changes
  ({double south, double north, double west, double east})? _lastBounds;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _rebuildWindGrid();
    _initParticles();
  }

  @override
  void didUpdateWidget(WindParticleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Wind data changed → rebuild grid
    if (!identical(widget.windPoints, oldWidget.windPoints)) {
      _rebuildWindGrid();
    }

    // Bounds changed → reset particles to new viewport
    if (widget.bounds != _lastBounds) {
      _lastBounds = widget.bounds;
      _resetParticles();
    }
  }

  /// Pre-compute wind u,v components once (not per particle per frame).
  void _rebuildWindGrid() {
    _windGrid = widget.windPoints.map((wp) {
      final rad = wp.directionDegrees * pi / 180.0;
      return _WindVector(
        lat: wp.position.latitude,
        lng: wp.position.longitude,
        u: -wp.speedKnots * sin(rad),
        v: -wp.speedKnots * cos(rad),
        speed: wp.speedKnots,
      );
    }).toList();
  }

  void _initParticles() {
    _particles.clear();
    final b = widget.bounds;
    if (b == null) return;
    for (int i = 0; i < _maxParticles; i++) {
      _particles.add(_spawnInBounds(b));
    }
  }

  void _resetParticles() {
    _particles.clear();
    _initParticles();
  }

  _GeoParticle _spawnInBounds(
    ({double south, double north, double west, double east}) b,
  ) {
    return _GeoParticle(
      lat: b.south + _random.nextDouble() * (b.north - b.south),
      lng: b.west + _random.nextDouble() * (b.east - b.west),
      age: _random.nextDouble() * 4.0, // stagger births
      lifetime: 4.0 + _random.nextDouble() * 4.0,
    );
  }

  void _onTick(Duration elapsed) {
    _frameCount++;
    // Throttle to ~30fps (skip odd frames)
    if (_frameCount % 2 != 0) return;

    final b = widget.bounds;
    if (b == null || _windGrid.isEmpty) return;

    const dt = 1.0 / 30.0;
    // Degrees-per-knot-per-second at equator ≈ 1/(60*3600) ≈ 4.6e-6
    // Scale factor for visible movement
    const degreesPerKnotSec = 0.00015;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.age += dt;

      // Interpolate wind at particle's geographic position
      final wind = _interpolateWindAt(p.lat, p.lng);

      // Advect in geographic space
      p.lng += wind.u * degreesPerKnotSec;
      p.lat += wind.v * degreesPerKnotSec;
      p.speed = wind.speed;

      // Store geographic trail
      p.trailLat.insert(0, p.lat);
      p.trailLng.insert(0, p.lng);
      if (p.trailLat.length > _trailLength) {
        p.trailLat.removeRange(_trailLength, p.trailLat.length);
        p.trailLng.removeRange(_trailLength, p.trailLng.length);
      }

      // Respawn if dead or out of bounds (with margin)
      final margin = (b.north - b.south) * 0.1;
      if (p.age >= p.lifetime ||
          p.lat < b.south - margin ||
          p.lat > b.north + margin ||
          p.lng < b.west - margin ||
          p.lng > b.east + margin) {
        _particles[i] = _spawnInBounds(b);
      }
    }

    setState(() {});
  }

  /// IDW interpolation using the 8 nearest wind grid points.
  ({double u, double v, double speed}) _interpolateWindAt(
    double lat,
    double lng,
  ) {
    if (_windGrid.isEmpty) return (u: 0, v: 0, speed: 0);

    // Compute distance² for all points, find nearest 8
    const maxNeighbors = 8;
    // Use a simple insertion-sort approach for small K
    final nearest = List<(double dist2, int idx)>.filled(
      maxNeighbors,
      (double.infinity, -1),
    );
    int filled = 0;

    for (int i = 0; i < _windGrid.length; i++) {
      final wv = _windGrid[i];
      final dlat = lat - wv.lat;
      final dlng = lng - wv.lng;
      final dist2 = dlat * dlat + dlng * dlng;

      if (dist2 < 0.000001) {
        return (u: wv.u, v: wv.v, speed: wv.speed);
      }

      if (filled < maxNeighbors || dist2 < nearest[filled - 1].$1) {
        // Insert in sorted position
        final insertAt = filled < maxNeighbors ? filled : filled - 1;
        nearest[insertAt] = (dist2, i);
        if (filled < maxNeighbors) filled++;
        // Bubble into sorted position
        for (int j = insertAt;
            j > 0 && nearest[j].$1 < nearest[j - 1].$1;
            j--) {
          final tmp = nearest[j];
          nearest[j] = nearest[j - 1];
          nearest[j - 1] = tmp;
        }
      }
    }

    double uSum = 0, vSum = 0, wSum = 0, sSum = 0;
    for (int i = 0; i < filled; i++) {
      final w = 1.0 / nearest[i].$1;
      final wv = _windGrid[nearest[i].$2];
      uSum += wv.u * w;
      vSum += wv.v * w;
      sSum += wv.speed * w;
      wSum += w;
    }

    if (wSum == 0) return (u: 0, v: 0, speed: 0);
    return (u: uSum / wSum, v: vSum / wSum, speed: sSum / wSum);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.windPoints.isEmpty || widget.bounds == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _WindPainter(
          particles: _particles,
          bounds: widget.bounds!,
          isHolographic: widget.isHolographic,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Particle in geographic space.
class _GeoParticle {
  double lat;
  double lng;
  double age;
  double lifetime;
  double speed;
  final List<double> trailLat;
  final List<double> trailLng;

  _GeoParticle({
    required this.lat,
    required this.lng,
    this.age = 0,
    this.lifetime = 6.0,
  })  : speed = 0,
        trailLat = [],
        trailLng = [];

  double get normalizedAge => (age / lifetime).clamp(0.0, 1.0);

  double get alpha {
    if (normalizedAge < 0.15) return normalizedAge / 0.15;
    if (normalizedAge > 0.8) return (1.0 - normalizedAge) / 0.2;
    return 1.0;
  }
}

/// Pre-computed wind vector at a grid point.
class _WindVector {
  final double lat, lng, u, v, speed;
  const _WindVector({
    required this.lat,
    required this.lng,
    required this.u,
    required this.v,
    required this.speed,
  });
}

class _WindPainter extends CustomPainter {
  final List<_GeoParticle> particles;
  final ({double south, double north, double west, double east}) bounds;
  final bool isHolographic;

  _WindPainter({
    required this.particles,
    required this.bounds,
    required this.isHolographic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final latRange = bounds.north - bounds.south;
    final lngRange = bounds.east - bounds.west;
    if (latRange == 0 || lngRange == 0) return;

    // Reuse paint objects to avoid allocation per segment
    final trailPaint = Paint()..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    for (final p in particles) {
      if (p.trailLat.length < 2) continue;
      final alpha = p.alpha;
      if (alpha < 0.02) continue;

      final color = _colorForSpeed(p.speed, alpha);

      for (int i = 0; i < p.trailLat.length - 1; i++) {
        final sx0 = (p.trailLng[i] - bounds.west) / lngRange * size.width;
        final sy0 =
            (1.0 - (p.trailLat[i] - bounds.south) / latRange) * size.height;
        final sx1 = (p.trailLng[i + 1] - bounds.west) / lngRange * size.width;
        final sy1 =
            (1.0 - (p.trailLat[i + 1] - bounds.south) / latRange) * size.height;

        final trailFade = 1.0 - i / p.trailLat.length;
        final w = isHolographic ? 1.0 + trailFade : 1.2 + trailFade * 1.3;
        final segAlpha = alpha * trailFade * 0.8;

        final from = Offset(sx0, sy0);
        final to = Offset(sx1, sy1);

        if (isHolographic && i == 0) {
          glowPaint
            ..color = color.withValues(alpha: segAlpha)
            ..strokeWidth = w;
          canvas.drawLine(from, to, glowPaint);
        } else {
          trailPaint
            ..color = color.withValues(alpha: segAlpha)
            ..strokeWidth = w;
          canvas.drawLine(from, to, trailPaint);
        }
      }
    }
  }

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
  bool shouldRepaint(_WindPainter oldDelegate) => true;
}
