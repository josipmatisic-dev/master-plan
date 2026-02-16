/// Wind particle flow field visualization using CustomPainter.
///
/// Particles live in geographic (lat/lng) coordinates and are
/// projected to screen space each frame, so they track correctly
/// when the map pans or zooms — like Windy.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../models/viewport.dart';
import '../../models/weather_data.dart';
import 'painters/wind_painter.dart';

/// Renders wind flow particles over the map using CustomPainter.
///
/// Particles advect in geographic space using bilinear-interpolated
/// wind vectors from [WeatherData], and are projected to screen
/// coordinates each frame by [WindPainter] via [ProjectionService].
class WindParticleOverlay extends StatefulWidget {
  /// Full weather data for bilinear interpolation.
  final WeatherData? weatherData;

  /// Wind data points (used for non-empty check).
  final List<WindDataPoint> windPoints;

  /// Whether to use holographic theme colors.
  final bool isHolographic;

  /// Full map viewport for Mercator projection.
  final Viewport viewport;

  /// Maximum number of particles to render.
  final int maxParticles;

  /// Creates a wind particle overlay.
  const WindParticleOverlay({
    super.key,
    this.weatherData,
    required this.windPoints,
    this.isHolographic = false,
    required this.viewport,
    this.maxParticles = 800,
  });

  @override
  State<WindParticleOverlay> createState() => _WindParticleOverlayState();
}

class _WindParticleOverlayState extends State<WindParticleOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final _random = Random();

  final List<GeoParticle> _particles = [];

  int _frameCount = 0;

  /// Velocity scale: converts knots to degrees/frame at ~60fps.
  /// Adjusted to match Windy.com visual speed (approx 100x real-time).
  static const _velocityScale = 0.00001;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _initParticles();
  }

  @override
  void didUpdateWidget(WindParticleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Max particles changed → trim or expand
    if (widget.maxParticles != oldWidget.maxParticles) {
      _adjustParticleCount();
    }
  }

  void _initParticles() {
    _particles.clear();
    final b = widget.viewport.bounds;
    if (widget.viewport.size.isEmpty) return;
    for (int i = 0; i < widget.maxParticles; i++) {
      _particles.add(_spawnInBounds(b));
    }
  }

  void _adjustParticleCount() {
    final b = widget.viewport.bounds;
    if (widget.viewport.size.isEmpty) return;
    while (_particles.length > widget.maxParticles) {
      _particles.removeLast();
    }
    while (_particles.length < widget.maxParticles) {
      _particles.add(_spawnInBounds(b));
    }
  }

  GeoParticle _spawnInBounds(
    ({double south, double north, double west, double east}) b,
  ) {
    final latRange = b.north - b.south;
    final lngRange = b.east - b.west;

    final p = GeoParticle(
      lat: b.south + _random.nextDouble() * latRange,
      lng: b.west + _random.nextDouble() * lngRange,
      maxAge: 60.0 + _random.nextInt(60), // 1-2 seconds at 60fps
    );
    // Stagger initial age to prevent all particles spawning at once
    p.age = _random.nextDouble() * p.maxAge * 0.5;
    return p;
  }

  void _onTick(Duration elapsed) {
    _frameCount++;

    final data = widget.weatherData;
    if (widget.viewport.size.isEmpty || data == null || data.isEmpty) return;

    final b = widget.viewport.bounds;
    final latRange = b.north - b.south;
    final lngRange = b.east - b.west;
    if (latRange == 0 || lngRange == 0) return;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.age++;

      // Respawn if dead or out of bounds
      if (p.age >= p.maxAge ||
          p.lat < b.south ||
          p.lat > b.north ||
          p.lng < b.west ||
          p.lng > b.east) {
        _particles[i] = _spawnInBounds(b);
        continue;
      }

      // Bilinear-interpolated wind at particle position
      final wind = data.getInterpolatedWind(p.lat, p.lng);

      // Advect in geographic space
      // Adjust dLng by cos(lat) to maintain constant physical speed
      final cosLat = cos(p.lat * pi / 180.0);
      final dLat = wind.v * _velocityScale;
      final dLng =
          (wind.u * _velocityScale) / (cosLat.abs() < 0.01 ? 0.01 : cosLat);

      p.lat += dLat;
      p.lng += dLng;

      // Update trail
      p.trail.add((lat: p.lat, lng: p.lng));
      if (p.trail.length > 20) {
        p.trail.removeAt(0);
      }

      // Store speed for color mapping
      p.speed = sqrt(wind.u * wind.u + wind.v * wind.v);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.windPoints.isEmpty || widget.viewport.size.isEmpty) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: WindPainter(
          particles: _particles,
          viewport: widget.viewport,
          isHolographic: widget.isHolographic,
          frameCount: _frameCount,
        ),
        size: Size.infinite,
      ),
    );
  }
}
