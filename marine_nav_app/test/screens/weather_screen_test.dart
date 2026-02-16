import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/ais_target.dart';
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/route.dart' as app_route;
import 'package:marine_nav_app/models/viewport.dart' as app_viewport;
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/providers/ais_provider.dart';
import 'package:marine_nav_app/providers/boat_provider.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/quality_provider.dart';
import 'package:marine_nav_app/providers/route_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/theme_provider.dart';
import 'package:marine_nav_app/providers/timeline_provider.dart';
import 'package:marine_nav_app/providers/weather_provider.dart';
import 'package:marine_nav_app/screens/weather_screen.dart';
import 'package:marine_nav_app/services/ais_service.dart';
import 'package:marine_nav_app/services/anchor_alarm_service.dart';
import 'package:marine_nav_app/services/mob_service.dart';
import 'package:marine_nav_app/theme/app_theme.dart';
import 'package:marine_nav_app/theme/theme_variant.dart';
import 'package:provider/provider.dart';

// --- Manual Mocks ---
// We need comprehensive manual mocks because the app uses a deep provider hierarchy.
// All overrides must match the exact signature of the real classes.

class MockWeatherProvider extends ChangeNotifier implements WeatherProvider {
  bool _isLoading = false;
  WeatherData _data = WeatherData.empty;
  String? _errorMessage;
  final Set<WeatherLayer> _activeLayers = {
    WeatherLayer.wind,
    WeatherLayer.wave
  };

  @override
  bool get isLoading => _isLoading;
  @override
  WeatherData get data => _data;
  @override
  bool get hasData => !_data.isEmpty;
  @override
  String? get errorMessage => _errorMessage;
  @override
  bool get isWindVisible => _activeLayers.contains(WeatherLayer.wind);
  @override
  bool get isWaveVisible => _activeLayers.contains(WeatherLayer.wave);
  @override
  bool get isStale => false;
  @override
  CacheProvider get cache => MockCacheProvider();
  @override
  SettingsProvider get settings => MockSettingsProvider();

  @override
  bool isLayerActive(WeatherLayer layer) => _activeLayers.contains(layer);

  @override
  void toggleLayer(WeatherLayer layer) {
    if (_activeLayers.contains(layer)) {
      _activeLayers.remove(layer);
    } else {
      _activeLayers.add(layer);
    }
    notifyListeners();
  }

  @override
  void setLayerActive(WeatherLayer layer, {required bool active}) {
    if (active) {
      _activeLayers.add(layer);
    } else {
      _activeLayers.remove(layer);
    }
    notifyListeners();
  }

  @override
  void fetchForViewport({
    required double south,
    required double north,
    required double west,
    required double east,
    double? zoomLevel,
  }) {
    debugPrint('MockWeatherProvider: fetchForViewport called');
    _isLoading = true;
    notifyListeners();
    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 100), () {
      debugPrint('MockWeatherProvider: fetchForViewport finished');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  Future<void> refresh({
    required double south,
    required double north,
    required double west,
    required double east,
    double? zoomLevel,
    bool force = true,
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoading = false;
    notifyListeners();
  }

  @override
  void clearData() {
    _data = WeatherData.empty;
    notifyListeners();
  }

  @override
  void updateData(WeatherData data) {
    _data = data;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  AppThemeMode get themeMode => AppThemeMode.system;
  ThemeVariant get variant => ThemeVariant.oceanGlass;
  bool get isDarkMode => false;
  @override
  bool get isHolographic => false;
  ThemeData get themeData => AppTheme.getThemeForVariant(false, variant);

  @override
  Future<void> init() async {}

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {}

  void setVariant(ThemeVariant variant) {}

  @override
  Future<void> toggleTheme() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMapProvider extends ChangeNotifier implements MapProvider {
  app_viewport.Viewport _viewport = const app_viewport.Viewport(
    center: LatLng(latitude: 0, longitude: 0),
    zoom: 10,
    rotation: 0,
    size: Size(100, 100),
  );

  @override
  app_viewport.Viewport get viewport => _viewport;

  bool get isReady => true;
  @override
  bool get isInitialized => true;
  @override
  bool get isMapReady => true;

  @override
  Future<void> init() async {}

  @override
  void setCenter(LatLng center) {
    _viewport = _viewport.copyWith(center: center);
    notifyListeners();
  }

  @override
  void setZoom(double zoom) {
    _viewport = _viewport.copyWith(zoom: zoom);
    notifyListeners();
  }

  @override
  void updateViewport(app_viewport.Viewport v) {
    _viewport = v;
    notifyListeners();
  }

  @override
  void setSize(Size size) {
    if (size != _viewport.size) {
      _viewport = _viewport.copyWith(size: size);
      notifyListeners();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  DistanceUnit get distanceUnit => DistanceUnit.nauticalMiles;
  @override
  SpeedUnit get speedUnit => SpeedUnit.knots;
  @override
  String get aisStreamApiKey => 'test-key';
  bool get showGrid => true;
  double get minWindSpeed => 0;
  @override
  bool get hasMapTilerApiKey => false;
  @override
  String get mapTilerApiKey => '';

  @override
  Future<void> init() async {}
  @override
  Future<void> setDistanceUnit(DistanceUnit unit) async {}
  @override
  Future<void> setSpeedUnit(SpeedUnit unit) async {}
  @override
  Future<void> setAisStreamApiKey(String key) async {}
  Future<void> setBoolean(String key, bool value) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCacheProvider extends ChangeNotifier implements CacheProvider {
  @override
  Future<void> init() async {}
  @override
  String? getString(String key) => null;
  @override
  Future<void> put(String key, String value, {Duration? ttl}) async {}

  @override
  Future<void> invalidate(String key) async {}

  @override
  Future<void> clear() async {}
  @override
  Map<String, dynamic>? getJson(String key) => null;
  @override
  bool get isInitialized => true;
  @override
  Future<void> putJson(String key, Map<String, dynamic> json,
      {Duration? ttl}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAisProvider extends ChangeNotifier implements AisProvider {
  @override
  Map<int, AisTarget> get targets => {};
  @override
  List<AisTarget> get warnings => [];
  @override
  int get targetCount => 0;
  @override
  bool get isConnected => false;
  @override
  String? get lastError => null;
  @override
  AisConnectionState get connectionState => AisConnectionState.disconnected;

  @override
  Future<void> init() async {}
  @override
  Future<void> connect({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> updateViewport({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {}
  @override
  void updateOwnVessel({
    required LatLng position,
    required double sogKnots,
    required double cogDegrees,
  }) {}
  @override
  void updateTargetsForTesting(List<AisTarget> targets) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBoatProvider extends ChangeNotifier implements BoatProvider {
  @override
  BoatPosition? get currentPosition => null;
  @override
  PositionSource get source => PositionSource.none;
  @override
  bool get followBoat => true;
  @override
  bool get showTrack => true;
  @override
  List<TrackPoint> get trackHistory => [];
  @override
  int get trackPointCount => 0;
  @override
  AnchorAlarmService get anchorAlarm => AnchorAlarmService();

  @override
  set followBoat(bool value) {}
  @override
  set showTrack(bool value) {}
  @override
  void clearTrack() {}
  @override
  MobMarker? triggerMob() => null;
  @override
  void updatePositionForTesting(BoatPosition position) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockQualityProvider extends ChangeNotifier implements QualityProvider {
  @override
  QualityLevel get level => QualityLevel.high;
  @override
  double get currentFps => 60.0;
  @override
  bool get autoQuality => false;
  @override
  bool get showFog => true;
  @override
  bool get showRain => true;
  @override
  bool get showLightning => true;
  @override
  bool get showOceanSurface => true;
  @override
  bool get showWind => true;
  @override
  int get maxParticles => 800;

  @override
  Future<void> init() async {}
  @override
  void setAutoQuality({required bool enabled}) {}
  @override
  void setQualityLevel(QualityLevel level) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRouteProvider extends ChangeNotifier implements RouteProvider {
  @override
  app_route.Route? get activeRoute => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTimelineProvider extends ChangeNotifier implements TimelineProvider {
  @override
  int get frameIndex => 0;

  @override
  int get frameCount => 1;

  @override
  bool get hasFrames => true;

  @override
  PlaybackState get playbackState => PlaybackState.paused;

  @override
  bool get isPlaying => false;

  @override
  WeatherFrame? get activeFrame => null;

  @override
  double get scrubberPosition => 0.0;

  @override
  String get activeTimeLabel => "12:00";

  @override
  List<WindDataPoint> get activeWindPoints => [];

  @override
  List<WaveDataPoint> get activeWavePoints => [];

  @override
  List<WeatherFrame> get windowedFrames => [];

  @override
  int get windowedIndex => 0;

  @override
  void setFrameIndex(int index) {}

  @override
  void setScrubberPosition(double position) {}

  @override
  void nextFrame() {}

  @override
  void previousFrame() {}

  @override
  void play() {}

  @override
  void pause() {}

  @override
  void togglePlayback() {}

  @override
  void reset() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('WeatherScreen renders and interacts correctly',
      (WidgetTester tester) async {
    // 1. Create mocks
    final mockWeather = MockWeatherProvider();
    final mockTheme = MockThemeProvider();
    final mockMap = MockMapProvider();
    final mockSettings = MockSettingsProvider();
    final mockCache = MockCacheProvider();
    final mockAis = MockAisProvider();
    final mockBoat = MockBoatProvider();
    final mockQuality = MockQualityProvider();
    final mockRoute = MockRouteProvider();
    final mockTimeline = MockTimelineProvider();

    // 2. Build widget tree with ALL required providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WeatherProvider>.value(value: mockWeather),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockTheme),
          ChangeNotifierProvider<MapProvider>.value(value: mockMap),
          ChangeNotifierProvider<SettingsProvider>.value(value: mockSettings),
          ChangeNotifierProvider<CacheProvider>.value(value: mockCache),
          ChangeNotifierProvider<AisProvider>.value(value: mockAis),
          ChangeNotifierProvider<BoatProvider>.value(value: mockBoat),
          ChangeNotifierProvider<QualityProvider>.value(value: mockQuality),
          ChangeNotifierProvider<RouteProvider>.value(value: mockRoute),
          ChangeNotifierProvider<TimelineProvider>.value(value: mockTimeline),
        ],
        child: MaterialApp(
          home: const WeatherScreen(),
          theme: AppTheme.getThemeForVariant(false, ThemeVariant.oceanGlass),
        ),
      ),
    );

    // 3. Verify initial state (empty/loading)
    // Wait for initial build
    await tester.pump();

    // Pump with duration to allow timers (simulated network delay) to complete
    // We cannot use pumpAndSettle because WindParticleOverlay has an infinite Ticker
    await tester.pump(const Duration(milliseconds: 200));

    debugPrint(
        'Test: isLoading=${mockWeather.isLoading}, hasData=${mockWeather.hasData}');

    // The title is "Weather"
    expect(find.text('Weather'), findsOneWidget);

    // 4. Test toggling layers
    // The switch tile has text "Wind Layer"
    // However, layers are only shown if hasData is true or in the bottom sheet.
    // In initial state hasData is false (mockWeather._data = WeatherData.empty).
    // So _buildFallbackOverlay is shown.

    expect(find.text('No weather data available'), findsOneWidget);

    // 5. Simulate loading state
    mockWeather._isLoading = true;
    mockWeather.notifyListeners();
    await tester.pump();
    // One in top bar, one in overlay
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

    // 6. Simulate data loaded
    mockWeather._isLoading = false;
    // Set minimal data to ensure "Map Layers" fits on screen without scrolling
    // Set minimal data to ensure "Map Layers" fits on screen without scrolling
    // We need at least one frame so isEmpty is false (hasData is true)
    // But empty windPoints/wavePoints so DetailCards are skipped.
    mockWeather._data = WeatherData(
      windPoints: const [],
      wavePoints: const [],
      frames: [WeatherFrame(time: DateTime.now())],
      fetchedAt: DateTime.now(),
    );
    mockWeather.notifyListeners();
    // Use pump with duration instead of pumpAndSettle due to infinite animation
    await tester.pump(const Duration(milliseconds: 100));

    // Now the bottom sheet should be built instead of fallback overlay.
    debugPrint(
        'After data: hasData=${mockWeather.hasData}, isEmpty=${mockWeather.data.isEmpty}');
    expect(find.text('No weather data available'), findsNothing);

    // The DraggableScrollableSheet starts at 30% height.
    // We need to expand it by dragging up to reveal all content.
    final sheetFinder = find.byType(DraggableScrollableSheet);
    expect(sheetFinder, findsOneWidget);

    // Drag up to expand the sheet so all content is visible
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify "Current Conditions" header
    expect(find.text('Current Conditions'), findsOneWidget);

    // Verify layer toggles are visible after scrolling
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Map Layers'), findsOneWidget);
    expect(find.text('Wind Layer'), findsOneWidget);
  });
}
