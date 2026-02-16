import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart';
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/providers/ais_provider.dart';
import 'package:marine_nav_app/providers/boat_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/route_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/theme_provider.dart';
import 'package:marine_nav_app/providers/timeline_provider.dart';
import 'package:marine_nav_app/providers/weather_provider.dart';
import 'package:marine_nav_app/widgets/map/fog_overlay.dart';
import 'package:marine_nav_app/widgets/map/lightning_overlay.dart';
import 'package:marine_nav_app/widgets/map/maplibre_map_widget.dart';
import 'package:marine_nav_app/widgets/map/ocean_surface_overlay.dart';
import 'package:marine_nav_app/widgets/map/rain_overlay.dart';
import 'package:marine_nav_app/widgets/map/weather_layer_stack.dart';
import 'package:marine_nav_app/widgets/map/wind_particle_overlay.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'weather_stack_integration_test.mocks.dart';

@GenerateMocks([
  AisProvider,
  BoatProvider,
  MapProvider,
  WeatherProvider,
  RouteProvider,
  TimelineProvider,
  SettingsProvider,
  ThemeProvider,
])
void main() {
  late MockAisProvider mockAisProvider;
  late MockBoatProvider mockBoatProvider;
  late MockMapProvider mockMapProvider;
  late MockWeatherProvider mockWeatherProvider;
  late MockRouteProvider mockRouteProvider;
  late MockTimelineProvider mockTimelineProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockThemeProvider mockThemeProvider;

  setUp(() {
    mockAisProvider = MockAisProvider();
    mockBoatProvider = MockBoatProvider();
    mockMapProvider = MockMapProvider();
    mockWeatherProvider = MockWeatherProvider();
    mockRouteProvider = MockRouteProvider();
    mockTimelineProvider = MockTimelineProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockThemeProvider = MockThemeProvider();

    when(mockMapProvider.settingsProvider).thenReturn(mockSettingsProvider);
    when(mockSettingsProvider.hasMapTilerApiKey).thenReturn(false);
    when(mockSettingsProvider.mapTilerApiKey).thenReturn('');
    when(mockMapProvider.viewport).thenReturn(const Viewport(
      center: LatLng(latitude: 0, longitude: 0),
      zoom: 10,
      rotation: 0,
      size: Size(800, 600),
    ));

    // Stubs for WeatherProvider
    when(mockWeatherProvider.hasData).thenReturn(true);
    when(mockWeatherProvider.isWindVisible).thenReturn(true);
    when(mockWeatherProvider.isWaveVisible).thenReturn(true);
    when(mockWeatherProvider.isLayerActive(any)).thenReturn(true);

    // Sample wind data
    final windPoints = [
      const WindDataPoint(
        position: LatLng(latitude: 10, longitude: 10),
        speedKnots: 20,
        directionDegrees: 90,
      ),
      const WindDataPoint(
        position: LatLng(latitude: 0, longitude: 0),
        speedKnots: 15,
        directionDegrees: 180,
      ),
    ];
    // Sample wave data
    final wavePoints = [
      const WaveDataPoint(
        position: LatLng(latitude: 10, longitude: 10),
        heightMeters: 2.0,
        directionDegrees: 90,
      ),
    ];

    final weatherData = WeatherData(
      fetchedAt: DateTime.now(),
      windPoints: windPoints,
      wavePoints: wavePoints,
    );
    when(mockWeatherProvider.data).thenReturn(weatherData);

    // Stubs for TimelineProvider
    when(mockTimelineProvider.hasFrames).thenReturn(false);
    when(mockTimelineProvider.activeWindPoints).thenReturn([]);
    when(mockTimelineProvider.activeWavePoints).thenReturn([]);

    // Stubs for ThemeProvider
    when(mockThemeProvider.isHolographic).thenReturn(false);
    when(mockThemeProvider.themeMode).thenReturn(AppThemeMode.light);

    // Stubs for AisProvider
    when(mockAisProvider.targets).thenReturn({});
    when(mockAisProvider.isConnected).thenReturn(false);

    // Stubs for BoatProvider
    when(mockBoatProvider.currentPosition).thenReturn(null);
    when(mockBoatProvider.trackHistory).thenReturn([]);
    when(mockBoatProvider.showTrack).thenReturn(true);
  });

  testWidgets(
      'WeatherLayerStack renders correct layers based on provider state',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AisProvider>.value(value: mockAisProvider),
          ChangeNotifierProvider<BoatProvider>.value(value: mockBoatProvider),
          ChangeNotifierProvider<MapProvider>.value(value: mockMapProvider),
          ChangeNotifierProvider<WeatherProvider>.value(
              value: mockWeatherProvider),
          ChangeNotifierProvider<RouteProvider>.value(value: mockRouteProvider),
          ChangeNotifierProvider<TimelineProvider>.value(
              value: mockTimelineProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WeatherLayerStack(),
          ),
        ),
      ),
    );

    // Verify MapLibreMapWidget is present (Layer 1)
    expect(find.byType(MapLibreMapWidget), findsOneWidget);

    // Verify OceanSurfaceOverlay is present (Layer 2) - conditional on waves/weather
    expect(find.byType(OceanSurfaceOverlay), findsOneWidget);

    // Verify WindParticleOverlay is present (Layer 3) - conditional on wind/weather
    expect(find.byType(WindParticleOverlay), findsOneWidget);

    // Verify other layers are present (conditions now met by wave/wind data)
    // FogOverlay triggers when wave intensity ≥ 0.3 (2.0m / 4.0 = 0.5)
    expect(find.byType(FogOverlay), findsOneWidget);

    // RainOverlay triggers at avgWindSpeed ≥ 8 kts ((20+15)/2 = 17.5)
    expect(find.byType(RainOverlay), findsOneWidget);

    // LightningOverlay requires avgWindSpeed ≥ 25 (17.5 < 25, not met)
    expect(find.byType(LightningOverlay), findsNothing);
  });

  testWidgets('WeatherLayerStack hides layers when weather provider says so',
      (tester) async {
    // Hide wind
    when(mockWeatherProvider.isWindVisible).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AisProvider>.value(value: mockAisProvider),
          ChangeNotifierProvider<BoatProvider>.value(value: mockBoatProvider),
          ChangeNotifierProvider<MapProvider>.value(value: mockMapProvider),
          ChangeNotifierProvider<WeatherProvider>.value(
              value: mockWeatherProvider),
          ChangeNotifierProvider<RouteProvider>.value(value: mockRouteProvider),
          ChangeNotifierProvider<TimelineProvider>.value(
              value: mockTimelineProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WeatherLayerStack(),
          ),
        ),
      ),
    );

    // Verify WindParticleOverlay is GONE
    expect(find.byType(WindParticleOverlay), findsNothing);

    // Verify OceanSurfaceOverlay is STILL present (waves still there)
    expect(find.byType(OceanSurfaceOverlay), findsOneWidget);
  });
}
