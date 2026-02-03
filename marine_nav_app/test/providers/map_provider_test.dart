/// Map Provider Tests
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MapProvider', () {
    late SettingsProvider settingsProvider;
    late CacheProvider cacheProvider;
    late MapProvider mapProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsProvider = SettingsProvider();
      await settingsProvider.init();
      cacheProvider = CacheProvider();
      await cacheProvider.init();
      mapProvider = MapProvider(
        settingsProvider: settingsProvider,
        cacheProvider: cacheProvider,
      );
      await mapProvider.init();
    });

    test('initializes with defaults', () {
      expect(mapProvider.isInitialized, isTrue);
      expect(
        mapProvider.viewport.center,
        const LatLng(latitude: 0, longitude: 0),
      );
      expect(mapProvider.viewport.zoom, 3);
    });

    test('clamps zoom between 1 and 20', () {
      mapProvider.setZoom(25);
      expect(mapProvider.viewport.zoom, 20);
      mapProvider.setZoom(0.5);
      expect(mapProvider.viewport.zoom, 1);
    });

    test('updates viewport size', () {
      mapProvider.setSize(const Size(320, 200));
      expect(mapProvider.viewport.size, const Size(320, 200));
    });
  });
}
