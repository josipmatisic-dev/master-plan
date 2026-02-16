import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/widgets/map/wind_particle_overlay.dart';
import 'package:marine_nav_app/widgets/map/painters/wind_painter.dart';

void main() {
  testWidgets('WindParticleOverlay initializes and renders', (tester) async {
    final windPoints = [
      WindDataPoint(
        position: const LatLng(latitude: 0, longitude: 0),
        speedKnots: 10,
        directionDegrees: 90, // East wind (blowing West)
      ),
      WindDataPoint(
        position: const LatLng(latitude: 10, longitude: 10),
        speedKnots: 20,
        directionDegrees: 180, // South wind (blowing North)
      ),
    ];

    final weatherData = WeatherData(
      windPoints: windPoints,
      wavePoints: [],
      fetchedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: WindParticleOverlay(
              weatherData: weatherData,
              windPoints: windPoints,
              bounds: (south: -10, north: 20, west: -10, east: 20),
              maxParticles: 100,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);

    // Verify painter properties
    final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is WindPainter);
    expect(customPaintFinder, findsOneWidget);

    final customPaint = tester.widget<CustomPaint>(customPaintFinder);
    final painter = customPaint.painter as WindPainter;
    expect(painter.particles.length, 100);
    expect(painter.bounds.south, -10);
    expect(painter.bounds.north, 20);
  });

  testWidgets('WindParticleOverlay advects particles', (tester) async {
    // Single point with known wind (10 knots North -> blowing South)
    // u = 0, v = -10
    final windPoints = [
      WindDataPoint(
        position: const LatLng(latitude: 0, longitude: 0),
        speedKnots: 10,
        directionDegrees: 0,
      ),
    ];

    // Create dense grid to ensure interpolation works
    // 0,0 is covered
    final weatherData = WeatherData(
      windPoints: windPoints,
      wavePoints: [],
      fetchedAt: DateTime.now(),
      gridResolution: 1.0,
    );

    // Override internal grid for testing if possible, but here we rely on public API
    // WeatherData builds index in constructor

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: WindParticleOverlay(
              weatherData: weatherData,
              windPoints: windPoints,
              bounds: (south: -1, north: 1, west: -1, east: 1),
              maxParticles: 10,
            ),
          ),
        ),
      ),
    );

    final customPaintFinder1 = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is WindPainter);
    expect(customPaintFinder1, findsOneWidget);

    final customPaint1 = tester.widget<CustomPaint>(customPaintFinder1);
    final painter1 = customPaint1.painter as WindPainter;
    final particles1 = List<GeoParticle>.from(painter1.particles.map((p) =>
        GeoParticle(lat: p.lat, lng: p.lng, maxAge: p.maxAge)..age = p.age));

    // Advance time
    await tester.pump(const Duration(milliseconds: 100)); // ~6 frames

    final customPaintFinder2 = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is WindPainter);

    final customPaint2 = tester.widget<CustomPaint>(customPaintFinder2);
    final painter2 = customPaint2.painter as WindPainter;

    // Check if particles moved
    bool moved = false;
    for (int i = 0; i < painter2.particles.length; i++) {
      // Find corresponding particle? No ID, so just check if ANY moved
      // Actually particles are re-instantiated or mutated in place?
      // State holds list. Painter gets list.
      // So painter2.particles is same list instance if state didn't rebuild list.
      // But CustomPaint rebuilds painter.

      // We stored snapshot in particles1.
      // However, we can't easily match them 1:1 because order might change if respawned?
      // But in 100ms (6 frames), maxAge is >60 frames, so unlikely to respawn all.

      if (painter2.particles[i].lat != particles1[i].lat ||
          painter2.particles[i].lng != particles1[i].lng) {
        moved = true;
        break;
      }
    }

    expect(moved, isTrue);
  });
}
