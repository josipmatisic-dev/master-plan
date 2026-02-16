import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/widgets/map/wind_particle_overlay.dart';

void main() {
  testWidgets('WindParticleOverlay performance smoke test',
      (WidgetTester tester) async {
    final List<WindDataPoint> windPoints = List.generate(100, (i) {
      return WindDataPoint(
        position: LatLng(latitude: 45.0 + i * 0.01, longitude: 15.0 + i * 0.01),
        speedKnots: 10.0 + (i % 5),
        directionDegrees: 90.0 + (i % 30),
      );
    });

    const bounds = (south: 44.0, north: 46.0, west: 14.0, east: 16.0);

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: WindParticleOverlay(
              windPoints: windPoints,
              bounds: bounds,
              isHolographic: false,
              maxParticles: 2500,
            ),
          ),
        ),
      ),
    );

    // Warm up logic
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final stopwatch = Stopwatch()..start();
    int frames = 0;
    // Simulate 60 logic updates (frames)
    for (int i = 0; i < 60; i++) {
      // Pump with duration triggers the ticker
      await tester.pump(const Duration(milliseconds: 32));
      frames++;
    }
    stopwatch.stop();

    debugPrint(
        'Simulated $frames logic frames in ${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(2000),
        reason: 'Logic too slow');
  });
}
