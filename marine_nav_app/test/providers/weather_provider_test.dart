import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/weather_provider.dart';
import 'package:marine_nav_app/services/weather_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sample Forecast API response for tests (wind).
const _forecastResponse = '''
[
  {
    "latitude": 60.0,
    "longitude": 10.0,
    "current": {
      "wind_speed_10m": 12.5,
      "wind_direction_10m": 225.0
    },
    "hourly": {
      "time": ["2026-02-09T00:00", "2026-02-09T01:00"],
      "wind_speed_10m": [10.0, 12.5],
      "wind_direction_10m": [220.0, 225.0]
    }
  },
  {
    "latitude": 60.0,
    "longitude": 12.0,
    "current": {
      "wind_speed_10m": 11.0,
      "wind_direction_10m": 230.0
    },
    "hourly": {
      "time": ["2026-02-09T00:00", "2026-02-09T01:00"],
      "wind_speed_10m": [9.0, 11.0],
      "wind_direction_10m": [215.0, 230.0]
    }
  }
]
''';

/// Sample Marine API response for tests (waves).
const _marineResponse = '''
[
  {
    "latitude": 60.0,
    "longitude": 10.0,
    "current": {
      "wave_height": 1.8,
      "wave_direction": 180.0,
      "wave_period": 6.5
    },
    "hourly": {
      "time": ["2026-02-09T00:00", "2026-02-09T01:00"],
      "wave_height": [1.5, 1.8],
      "wave_direction": [175.0, 180.0],
      "wave_period": [6.0, 6.5]
    }
  },
  {
    "latitude": 60.0,
    "longitude": 12.0,
    "current": {
      "wave_height": 1.7,
      "wave_direction": 185.0,
      "wave_period": 6.3
    },
    "hourly": {
      "time": ["2026-02-09T00:00", "2026-02-09T01:00"],
      "wave_height": [1.4, 1.7],
      "wave_direction": [170.0, 185.0],
      "wave_period": [5.9, 6.3]
    }
  }
]
''';

void main() {
  group('WeatherProvider', () {
    late SettingsProvider settingsProvider;
    late CacheProvider cacheProvider;
    late WeatherProvider weatherProvider;
    bool providerDisposed = false;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      providerDisposed = false;
      settingsProvider = SettingsProvider();
      await settingsProvider.init();
      cacheProvider = CacheProvider();
      await cacheProvider.init();
    });

    tearDown(() {
      if (!providerDisposed) {
        weatherProvider.dispose();
      }
      cacheProvider.dispose();
    });

    WeatherProvider createProvider({http.Client? client}) {
      final api = WeatherApiService(
          client: client ??
              MockClient((request) async {
                if (request.url.host == 'api.open-meteo.com') {
                  return http.Response(_forecastResponse, 200);
                }
                return http.Response(_marineResponse, 200);
              }));

      weatherProvider = WeatherProvider(
        settingsProvider: settingsProvider,
        cacheProvider: cacheProvider,
        api: api,
      );
      return weatherProvider;
    }

    // ============ Initialization ============

    test('initializes with empty data', () {
      createProvider();
      expect(weatherProvider.hasData, false);
      expect(weatherProvider.data.isEmpty, true);
      expect(weatherProvider.isLoading, false);
      expect(weatherProvider.errorMessage, isNull);
    });

    test('all layers active by default', () {
      createProvider();
      expect(weatherProvider.isWindVisible, true);
      expect(weatherProvider.isWaveVisible, true);
    });

    // ============ Layer Toggle ============

    test('toggleLayer toggles wind visibility', () {
      createProvider();
      expect(weatherProvider.isWindVisible, true);
      weatherProvider.toggleLayer(WeatherLayer.wind);
      expect(weatherProvider.isWindVisible, false);
      weatherProvider.toggleLayer(WeatherLayer.wind);
      expect(weatherProvider.isWindVisible, true);
    });

    test('toggleLayer toggles wave visibility', () {
      createProvider();
      weatherProvider.toggleLayer(WeatherLayer.wave);
      expect(weatherProvider.isWaveVisible, false);
    });

    test('toggleLayer notifies listeners', () {
      createProvider();
      int notifyCount = 0;
      weatherProvider.addListener(() => notifyCount++);
      weatherProvider.toggleLayer(WeatherLayer.wind);
      expect(notifyCount, 1);
    });

    test('setLayerActive sets specific layer', () {
      createProvider();
      weatherProvider.setLayerActive(WeatherLayer.wind, active: false);
      expect(weatherProvider.isWindVisible, false);
      weatherProvider.setLayerActive(WeatherLayer.wind, active: true);
      expect(weatherProvider.isWindVisible, true);
    });

    test('setLayerActive does not notify when unchanged', () {
      createProvider();
      int notifyCount = 0;
      weatherProvider.addListener(() => notifyCount++);
      // Wind is already active
      weatherProvider.setLayerActive(WeatherLayer.wind, active: true);
      expect(notifyCount, 0);
    });

    // ============ Data Fetching ============

    test('refresh fetches data successfully', () async {
      createProvider();
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(weatherProvider.hasData, true);
      expect(weatherProvider.data.hasWind, true);
      expect(weatherProvider.data.hasWaves, true);
      expect(weatherProvider.isLoading, false);
      expect(weatherProvider.errorMessage, isNull);
    });

    test('refresh sets loading state', () async {
      createProvider();
      final states = <bool>[];
      weatherProvider.addListener(() {
        states.add(weatherProvider.isLoading);
      });

      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      // Should have been true (loading start) then false (loading end)
      expect(states, contains(true));
      expect(states.last, false);
    });

    test('refresh sets error on failure', () async {
      createProvider(
        client: MockClient((_) async {
          return http.Response('Server Error', 500);
        }),
      );

      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(weatherProvider.errorMessage, isNotNull);
      expect(weatherProvider.isLoading, false);
    });

    test('refresh keeps stale data as fallback on error', () async {
      // 1. Setup provider with success client
      var clientShouldFail = false;
      final client = MockClient((request) async {
        if (clientShouldFail) {
          return http.Response('Error', 500);
        }
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(_forecastResponse, 200);
        }
        return http.Response(_marineResponse, 200);
      });

      createProvider(client: client);

      // 2. First fetch succeeds
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );
      expect(weatherProvider.hasData, true);
      final originalData = weatherProvider.data;

      // 3. Switch to failing mode
      clientShouldFail = true;

      // 4. Refresh again (should fail but keep data)
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(weatherProvider.errorMessage, isNotNull);
      expect(weatherProvider.hasData, true);
      expect(weatherProvider.data, equals(originalData));
    });

    test('refresh notifies listeners', () async {
      createProvider();
      int notifyCount = 0;
      weatherProvider.addListener(() => notifyCount++);

      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      // At least 2: loading=true, loading=false
      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    // ============ Debounced Fetch ============

    test('fetchForViewport debounces rapid calls', () async {
      int callCount = 0;
      createProvider(
        client: MockClient((request) async {
          callCount++;
          if (request.url.host == 'api.open-meteo.com') {
            return http.Response(_forecastResponse, 200);
          }
          return http.Response(_marineResponse, 200);
        }),
      );

      // Fire several rapid fetches
      for (var i = 0; i < 5; i++) {
        weatherProvider.fetchForViewport(
          south: 58.0 + i * 0.01,
          north: 62.0,
          west: 8.0,
          east: 12.0,
        );
      }

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 700));

      // Should only have fired once (debounced) — 2 calls = 1 fetch (dual endpoint)
      expect(callCount, 2);
    });

    // ============ clearData ============

    test('clearData resets weather data', () async {
      createProvider();
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );
      expect(weatherProvider.hasData, true);

      weatherProvider.clearData();

      expect(weatherProvider.hasData, false);
      expect(weatherProvider.data.isEmpty, true);
      expect(weatherProvider.errorMessage, isNull);
    });

    test('clearData notifies listeners', () async {
      createProvider();
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      int notifyCount = 0;
      weatherProvider.addListener(() => notifyCount++);
      weatherProvider.clearData();
      expect(notifyCount, 1);
    });

    // ============ isStale ============

    test('isStale reflects data age', () async {
      createProvider();
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      // Fresh data should not be stale
      expect(weatherProvider.isStale, false);
    });

    // ============ Dispose ============

    test('dispose cancels debounce timer', () {
      createProvider();
      weatherProvider.fetchForViewport(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );
      // Should not throw
      providerDisposed = true;
      weatherProvider.dispose();
    });

    // ============ Caching ============

    test('uses cached data if available and fresh', () async {
      // 1. Pre-populate cache with fresh data
      final cachedData = WeatherData(
        fetchedAt: DateTime.now(),
        windPoints: const [
          WindDataPoint(
            position: LatLng(latitude: 60.0, longitude: 10.0),
            speedKnots: 15.0,
            directionDegrees: 180.0,
          ),
        ],
        wavePoints: const [],
      );

      // Cache key for 58.0, 62.0, 8.0, 12.0 -> "weather_58.0_62.0_8.0_12.0"
      await cacheProvider.put(
        'weather_58.0_62.0_8.0_12.0',
        jsonEncode(cachedData.toJson()),
      );

      // 2. Create provider with failing API to prove it doesn't call API
      createProvider(
          client: MockClient((_) async => http.Response('Error', 500)));

      // 3. Request data
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
        force: false,
      );

      // 4. Verify data came from cache
      expect(weatherProvider.hasData, true);
      expect(weatherProvider.data.windPoints.first.speedKnots, 15.0);
      expect(weatherProvider.errorMessage, isNull);
    });

    test('fetches from API if cache miss', () async {
      // 1. Ensure cache empty
      await cacheProvider.clearCache();

      // 2. Create provider with working API
      int apiCalls = 0;
      createProvider(client: MockClient((request) async {
        apiCalls++;
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(_forecastResponse, 200);
        }
        return http.Response(_marineResponse, 200);
      }));

      // 3. Request data
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
        force: false,
      );

      // 4. Verify API called
      expect(apiCalls, 2); // 1 forecast + 1 marine
      expect(weatherProvider.hasData, true);
    });

    test('writes to cache after successful fetch', () async {
      // 1. Create provider with working API
      createProvider(client: MockClient((request) async {
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(_forecastResponse, 200);
        }
        return http.Response(_marineResponse, 200);
      }));

      // 2. Request data
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      // 3. Check cache
      final cachedJson = cacheProvider.getString('weather_58.0_62.0_8.0_12.0');
      expect(cachedJson, isNotNull);

      final data = WeatherData.fromJson(jsonDecode(cachedJson!));
      expect(data.windPoints.isNotEmpty, true);
    });

    test('preserves forecast frames in cache', () async {
      // 1. Pre-populate cache with data including frames
      final cachedData = WeatherData(
        fetchedAt: DateTime.now(),
        windPoints: const [],
        wavePoints: const [],
        frames: [
          WeatherFrame(
            time: DateTime.now(),
            windPoints: const [
              WindDataPoint(
                position: LatLng(latitude: 60.0, longitude: 10.0),
                speedKnots: 15.0,
                directionDegrees: 180.0,
              ),
            ],
          ),
        ],
      );

      await cacheProvider.put(
        'weather_58.0_62.0_8.0_12.0',
        jsonEncode(cachedData.toJson()),
      );

      // 2. Create provider
      createProvider(
          client: MockClient((_) async => http.Response('Error', 500)));

      // 3. Request data
      await weatherProvider.refresh(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
        force: false,
      );

      // 4. Verify frames came from cache
      expect(weatherProvider.hasData, true);
      expect(weatherProvider.data.frames.length, 1);
      expect(
          weatherProvider.data.frames.first.windPoints.first.speedKnots, 15.0);
    });
  });
}
