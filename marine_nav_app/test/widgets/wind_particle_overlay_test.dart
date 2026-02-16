import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart' as vp;
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/widgets/map/painters/wind_painter.dart';
import 'package:marine_nav_app/widgets/map/wind_particle_overlay.dart';

void main() {
  testWidgets('WindParticleOverlay initializes and renders', (tester) async {
    final windPoints = [
      WindDataPoint(
        position: const LatLng(latitude: 0, longitude: 0),
        speedKnots: 10,
        directionDegrees: 90,
      ),
      WindDataPoint(
        position: const LatLng(latitude: 10, longitude: 10),
        speedKnots: 20,
        directionDegrees: 180,
      ),
    ];

    final weatherData = WeatherData(
      windPoints: windPoints,
      wavePoints: [],
      fetchedAt: DateTime.now(),
    );

    const testViewport = vp.Viewport(
      center: LatLng(latitude: 5, longitude: 5),
      zoom: 5,
      size: Size(400, 800),
      rotation: 0,
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
              viewport: testViewport,
              maxParticles: 100,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);

    final customPaintFinder = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is WindPainter);
    expect(customPaintFinder, findsOneWidget);

    final customPaint = tester.widget<CustomPaint>(customPaintFinder);
    final painter = customPaint.painter as WindPainter;
    expect(painter.particles.length, 100);
    expect(painter.viewport.center.latitude, 5);
  });

  testWidgets('WindParticleOverlay advects particles', (tester) async {
    final windPoints = [
      WindDataPoint(
        position: const LatLng(latitude: 0, longitude: 0),
        speedKnots: 10,
        directionDegrees: 0,
      ),
    ];

    final weatherData = WeatherData(
      windPoints: windPoints,
      wavePoints: [],
      fetchedAt: DateTime.now(),
      gridResolution: 1.0,
    );

    const testViewport = vp.Viewport(
      center: LatLng(latitude: 0, longitude: 0),
      zoom: 8,
      size: Size(400, 800),
      rotation: 0,
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
              viewport: testViewport,
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

    await tester.pump(const Duration(milliseconds: 100));

    final customPaintFinder2 = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is WindPainter);
    final customPaint2 = tester.widget<CustomPaint>(customPaintFinder2);
    final painter2 = customPaint2.painter as WindPainter;

    bool moved = false;
    for (int i = 0; i < painter2.particles.length; i++) {
      if (painter2.particles[i].lat != particles1[i].lat ||
          painter2.particles[i].lng != particles1[i].lng) {
        moved = true;
        break;
      }
    }

    expect(moved, isTrue);
  });
}
