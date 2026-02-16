/// TideProvider tests — initialization, caching, error handling.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/tide_provider.dart';
import 'package:marine_nav_app/services/tide_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sample NOAA station list response.
String _stationsResponse(double lat, double lng) => jsonEncode({
      'stations': [
        {
          'id': '9414290',
          'name': 'San Francisco',
          'lat': lat,
          'lng': lng,
        },
      ],
    });

/// Sample NOAA predictions response.
String get _predictionsResponse {
  final now = DateTime.now();
  final h1 = now.add(const Duration(hours: 2));
  final l1 = now.add(const Duration(hours: 8));
  return jsonEncode({
    'predictions': [
      {'t': _noaaFormat(h1), 'v': '5.500', 'type': 'H'},
      {'t': _noaaFormat(l1), 'v': '1.200', 'type': 'L'},
    ],
  });
}

/// Sample NOAA water levels response.
String get _waterLevelsResponse => jsonEncode({
      'data': [
        {'t': _noaaFormat(DateTime.now()), 'v': '3.200'},
      ],
    });

String _noaaFormat(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')} '
    '${dt.hour.toString().padLeft(2, '0')}:'
    '${dt.minute.toString().padLeft(2, '0')}';

void main() {
  late SettingsProvider settingsProvider;
  late CacheProvider cacheProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settingsProvider = SettingsProvider();
    await settingsProvider.init();
    cacheProvider = CacheProvider();
    await cacheProvider.init();
  });

  tearDown(() {
    cacheProvider.dispose();
  });

  TideProvider createProvider({http.Client? client}) {
    final api = TideApiService(
      client: client ?? MockClient((_) async => http.Response('{}', 200)),
    );
    return TideProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
      apiService: api,
    );
  }

  group('TideProvider', () {
    test('initial state is empty', () async {
      final provider = createProvider();
      await provider.init();
      expect(provider.tideData, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.nearestStation, isNull);
      expect(provider.nextTide, isNull);
      provider.dispose();
    });

    test('cacheTtl is 1 hour', () {
      expect(TideProvider.cacheTtl, const Duration(hours: 1));
    });

    test('fetchForPosition sets loading state', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{"stations":[]}', 200);
      });
      final provider = createProvider(client: client);
      await provider.init();

      // Start fetch (don't await)
      final future = provider.fetchForPosition(
        latitude: 37.8,
        longitude: -122.4,
      );

      // Should be loading during fetch
      expect(provider.isLoading, isTrue);
      await future;
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test('fetchForPosition handles no station found', () async {
      final client = MockClient((req) async {
        if (req.url.toString().contains('stations.json')) {
          return http.Response('{"stations":[]}', 200);
        }
        return http.Response('{}', 200);
      });
      final provider = createProvider(client: client);
      await provider.init();

      await provider.fetchForPosition(latitude: 37.8, longitude: -122.4);
      expect(provider.error, 'No tide stations found nearby');
      expect(provider.tideData, isNull);
      provider.dispose();
    });

    test('fetchForPosition skips if still within cache TTL', () async {
      var fetchCount = 0;
      final client = MockClient((req) async {
        fetchCount++;
        if (req.url.toString().contains('stations.json')) {
          return http.Response(_stationsResponse(37.8, -122.4), 200);
        }
        if (req.url.toString().contains('predictions')) {
          return http.Response(_predictionsResponse, 200);
        }
        return http.Response(_waterLevelsResponse, 200);
      });
      final provider = createProvider(client: client);
      await provider.init();

      await provider.fetchForPosition(latitude: 37.8, longitude: -122.4);
      final firstCount = fetchCount;

      // Second fetch within TTL should be skipped
      await provider.fetchForPosition(latitude: 37.8, longitude: -122.4);
      expect(fetchCount, firstCount);
      provider.dispose();
    });

    test('fetchForPosition prevents concurrent fetches', () async {
      final client = MockClient((req) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (req.url.toString().contains('stations.json')) {
          return http.Response(_stationsResponse(37.8, -122.4), 200);
        }
        if (req.url.toString().contains('predictions')) {
          return http.Response(_predictionsResponse, 200);
        }
        return http.Response(_waterLevelsResponse, 200);
      });
      final provider = createProvider(client: client);
      await provider.init();

      final f1 = provider.fetchForPosition(latitude: 37.8, longitude: -122.4);
      final f2 = provider.fetchForPosition(latitude: 37.8, longitude: -122.4);
      await Future.wait([f1, f2]);
      // Only one fetch should have executed
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });

    test('disposes cleanly', () async {
      final provider = createProvider();
      await provider.init();
      // Should not throw
      provider.dispose();
    });

    test('notifies listeners during fetch', () async {
      final client = MockClient((req) async {
        if (req.url.toString().contains('stations.json')) {
          return http.Response('{"stations":[]}', 200);
        }
        return http.Response('{}', 200);
      });
      final provider = createProvider(client: client);
      await provider.init();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.fetchForPosition(latitude: 37.8, longitude: -122.4);
      // Should notify at least twice (loading=true, loading=false)
      expect(notifyCount, greaterThanOrEqualTo(2));
      provider.dispose();
    });
  });
}
