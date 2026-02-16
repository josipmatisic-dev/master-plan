import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart' as vp;
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/widgets/map/painters/wind_painter.dart';

void main() {
  // Common test data
  late WeatherData weatherData;
  late List<GeoParticle> particles;
  late vp.Viewport viewport;
  final random = Random(42); // Fixed seed for reproducibility

  setUp(() {
    // 1. Generate 50x50 grid (2500 points)
    // Covering lat 0-50, lng 0-50
    final windPoints = List.generate(2500, (i) {
      final lat = (i ~/ 50).toDouble();
      final lng = (i % 50).toDouble();
      return WindDataPoint(
        position: LatLng(latitude: lat, longitude: lng),
        speedKnots: 10.0 + random.nextDouble() * 20.0, // 10-30 knots
        directionDegrees: random.nextDouble() * 360.0,
      );
    });

    weatherData = WeatherData(
      windPoints: windPoints,
      wavePoints: const [],
      fetchedAt: DateTime.now(),
      gridResolution: 1.0, // 1 degree resolution
    );

    viewport = const vp.Viewport(
      center: LatLng(latitude: 25.0, longitude: 25.0),
      zoom: 5.0,
      size: Size(800, 600),
      rotation: 0,
    );

    // 2. Generate 2000 particles with trails
    particles = List.generate(2000, (_) {
      final p = GeoParticle(
        lat: 10.0 + random.nextDouble() * 30.0,
        lng: 10.0 + random.nextDouble() * 30.0,
        maxAge: 100,
      );
      p.age = 50; // Mid-life
      p.speed = 15.0;

      // Add 20 points of trail history
      for (int i = 0; i < 20; i++) {
        p.trail.add((
          lat: p.lat + (i * 0.01),
          lng: p.lng + (i * 0.01),
        ));
      }
      return p;
    });
  });

  test('WeatherData interpolation performance (Hot Path)', () {
    final stopwatch = Stopwatch()..start();
    const iterations = 100000;

    for (int i = 0; i < iterations; i++) {
      // Random lookup within bounds
      final lat = random.nextDouble() * 49.0;
      final lng = random.nextDouble() * 49.0;
      weatherData.getInterpolatedWind(lat, lng);
    }

    stopwatch.stop();
    final avgTimeUs = stopwatch.elapsedMicroseconds / iterations;

    debugPrint(
        'Interpolation: ${stopwatch.elapsedMilliseconds}ms total for $iterations calls');
    debugPrint('Average per call: ${avgTimeUs.toStringAsFixed(4)} µs');

    // Expect < 5µs (0.005ms) per call
    expect(avgTimeUs, lessThan(5.0),
        reason: 'Interpolation exceeds 5µs budget');
  });

  test('WindPainter render performance (Render Path)', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = WindPainter(
      particles: particles,
      viewport: viewport,
      isHolographic: false,
      frameCount: 100,
    );

    // Warmup
    painter.paint(canvas, const Size(800, 600));

    final stopwatch = Stopwatch()..start();
    const frames = 100;

    for (int i = 0; i < frames; i++) {
      // Create new canvas each time to simulate realistic frame clear
      final rec = PictureRecorder();
      final can = Canvas(rec);
      painter.paint(can, const Size(800, 600));
    }

    stopwatch.stop();
    final avgFrameMs = stopwatch.elapsedMilliseconds / frames;

    debugPrint(
        'Painting: ${stopwatch.elapsedMilliseconds}ms total for $frames frames');
    debugPrint('Average per frame: ${avgFrameMs.toStringAsFixed(2)} ms');

    // Expect < 16ms (60fps)
    expect(avgFrameMs, lessThan(16.0),
        reason: 'Rendering exceeds 16ms frame budget');
  });
}
