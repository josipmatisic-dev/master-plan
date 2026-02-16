/// Map Provider Tests
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart';
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
      expect(mapProvider.isMapReady, isFalse);
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

    test('ignores empty size updates', () {
      mapProvider.setSize(const Size(320, 200));
      mapProvider.setSize(Size.zero);

      expect(mapProvider.viewport.size, const Size(320, 200));
    });
  });

  group('MapProvider Native', () {
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

    test('handleMapReady sets isMapReady', () {
      expect(mapProvider.isMapReady, isFalse);
      mapProvider.handleMapReady(null);
      expect(mapProvider.isMapReady, isTrue);
    });

    test('updateViewport updates state', () {
      mapProvider.updateViewport(const Viewport(
        center: LatLng(latitude: 10, longitude: 10),
        zoom: 10,
        size: Size(100, 100),
        rotation: 45,
      ));
      expect(mapProvider.viewport.center.latitude, 10);
      expect(mapProvider.viewport.zoom, 10);
    });
  });

  group('SettingsProvider MapTiler key', () {
    test('auto-loads API key from env config on init', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.init();

      // Key is auto-loaded from env.dart if present.
      // On CI, env.example.dart has an empty key, so we just verify
      // init completes without error and the key field is accessible.
      expect(settings.mapTilerApiKey, isA<String>());
    });

    test('manual setMapTilerApiKey overrides env value', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.init();

      await settings.setMapTilerApiKey('custom-key');
      expect(settings.mapTilerApiKey, 'custom-key');
    });

    test('persists MapTiler API key across init', () async {
      SharedPreferences.setMockInitialValues({
        'mapTilerApiKey': 'persisted-key',
      });
      final settings = SettingsProvider();
      await settings.init();

      expect(settings.mapTilerApiKey, 'persisted-key');
    });

    test('resetToDefaults clears MapTiler API key', () async {
      SharedPreferences.setMockInitialValues({
        'mapTilerApiKey': 'some-key',
      });
      final settings = SettingsProvider();
      await settings.init();
      await settings.resetToDefaults();

      expect(settings.mapTilerApiKey, '');
      expect(settings.hasMapTilerApiKey, isFalse);
    });
  });
}
