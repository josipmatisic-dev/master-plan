import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart' as vp;
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/providers/ais_provider.dart';
import 'package:marine_nav_app/providers/boat_provider.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/nmea_provider.dart';
import 'package:marine_nav_app/providers/quality_provider.dart';
import 'package:marine_nav_app/providers/route_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/theme_provider.dart';
import 'package:marine_nav_app/providers/weather_provider.dart';
import 'package:marine_nav_app/widgets/map/boat_marker_overlay.dart';
import 'package:marine_nav_app/widgets/map/fog_overlay.dart';
import 'package:marine_nav_app/widgets/map/lightning_overlay.dart';
import 'package:marine_nav_app/widgets/map/maplibre_map_widget.dart';
import 'package:marine_nav_app/widgets/map/ocean_surface_overlay.dart';
import 'package:marine_nav_app/widgets/map/rain_overlay.dart';
import 'package:marine_nav_app/widgets/map/weather_layer_stack.dart';
import 'package:marine_nav_app/widgets/map/wind_particle_overlay.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('WeatherLayerStack builds all layers when conditions met',
      (WidgetTester tester) async {
    // Mock Providers
    final settingsProvider = SettingsProvider();
    final cacheProvider = CacheProvider();
    final themeProvider = ThemeProvider();
    final mapProvider = MapProvider(
        settingsProvider: settingsProvider, cacheProvider: cacheProvider);
    final weatherProvider = WeatherProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    final aisProvider = AisProvider(settingsProvider: settingsProvider);
    final nmeaProvider = NMEAProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    final routeProvider = RouteProvider();
    final boatProvider = BoatProvider(
      nmeaProvider: nmeaProvider,
      mapProvider: mapProvider,
      routeProvider: routeProvider,
    );

    // Setup Mock Data
    // Wind & Wave data
    final weatherData = WeatherData(
      windPoints: const [
        WindDataPoint(
          position: LatLng(latitude: 45.0, longitude: 15.0),
          speedKnots: 25.0, // Should trigger wind & storm
          directionDegrees: 90.0,
        )
      ],
      wavePoints: const [
        WaveDataPoint(
          position: LatLng(latitude: 45.0, longitude: 15.0),
          heightMeters: 2.0,
          directionDegrees: 90.0,
        )
      ],
      fetchedAt: DateTime.now(),
    );
    weatherProvider.updateData(weatherData);

    // Viewport
    mapProvider.updateViewport(
      const vp.Viewport(
        center: LatLng(latitude: 45.0, longitude: 15.0),
        zoom: 10.0,
        size: Size(800, 600),
        rotation: 0.0,
      ),
    );

    // Boat Position
    boatProvider.updatePositionForTesting(BoatPosition(
      position: const LatLng(latitude: 45.0, longitude: 15.0),
      timestamp: DateTime.now(),
      heading: 90.0,
    ));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: cacheProvider),
          ChangeNotifierProvider.value(value: nmeaProvider),
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: weatherProvider),
          ChangeNotifierProvider.value(value: mapProvider),
          ChangeNotifierProvider.value(value: aisProvider),
          ChangeNotifierProvider.value(value: boatProvider),
          ChangeNotifierProvider.value(value: routeProvider),
          ChangeNotifierProvider<QualityProvider>.value(
            value: QualityProvider(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: WeatherLayerStack(),
            ),
          ),
        ),
      ),
    );

    await tester
        .pump(const Duration(milliseconds: 500)); // Allow animations to tick
    await tester
        .pump(const Duration(milliseconds: 500)); // Second tick for updates

    // Verify Map Layer
    expect(find.byType(MapLibreMapWidget), findsOneWidget);

    // Verify Ocean Layer (hasWaves = true)
    expect(find.byType(OceanSurfaceOverlay), findsOneWidget);

    // Verify Wind Layer (hasWind = true)
    expect(find.byType(WindParticleOverlay), findsOneWidget);

    // Verify Boat Marker (position != null)
    expect(find.byType(BoatMarkerOverlay), findsOneWidget);

    // Rain/Storm layers depend on wind speed logic in build method.
    // 25 knots → precipIntensity = 0.6, stormIntensity = 0.4
    expect(find.byType(RainOverlay), findsOneWidget);
    expect(find.byType(LightningOverlay), findsOneWidget);

    // Fog now derived from wave intensity (2.0m / 4.0 = 0.5 → fogDensity 0.4)
    expect(find.byType(FogOverlay), findsOneWidget);
  });
}
