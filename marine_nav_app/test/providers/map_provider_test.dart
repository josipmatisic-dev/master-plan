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

  group('MapProvider JS Bridge', () {
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

    test('handles mapReady event', () {
      expect(mapProvider.isMapReady, isFalse);
      mapProvider.handleWebViewEvent('{"type":"mapReady"}');
      expect(mapProvider.isMapReady, isTrue);
    });

    test('handles viewportChanged event', () {
      mapProvider.handleWebViewEvent(
        '{"type":"viewportChanged","center":[43.5,16.4],"zoom":12.5,"rotation":0.5}',
      );
      expect(mapProvider.viewport.center.latitude, 43.5);
      expect(mapProvider.viewport.center.longitude, 16.4);
      expect(mapProvider.viewport.zoom, 12.5);
      expect(mapProvider.viewport.rotation, 0.5);
    });

    test('handles viewportChanged with clamped zoom', () {
      mapProvider.handleWebViewEvent(
        '{"type":"viewportChanged","center":[0,0],"zoom":25.0,"rotation":0}',
      );
      expect(mapProvider.viewport.zoom, 20.0);
    });

    test('handles error event via error stream', () async {
      final errors = <MapError>[];
      mapProvider.errors.listen(errors.add);

      mapProvider.handleWebViewEvent(
        '{"type":"error","message":"Tile load failed"}',
      );

      await Future<void>.delayed(Duration.zero);
      expect(errors, hasLength(1));
      expect(errors.first.message, 'Tile load failed');
      expect(errors.first.type, MapErrorType.render);
    });

    test('ignores malformed JSON gracefully', () {
      // Should not throw
      mapProvider.handleWebViewEvent('not json');
      mapProvider.handleWebViewEvent('{"type":"unknown"}');
      expect(mapProvider.isMapReady, isFalse);
    });

    test('ignores viewportChanged with missing center', () {
      final before = mapProvider.viewport.center;
      mapProvider.handleWebViewEvent(
        '{"type":"viewportChanged","zoom":10}',
      );
      expect(mapProvider.viewport.center, before);
    });

    test('notifies listeners on viewport change from JS', () {
      int notifyCount = 0;
      mapProvider.addListener(() => notifyCount++);

      mapProvider.handleWebViewEvent(
        '{"type":"viewportChanged","center":[1,2],"zoom":5,"rotation":0}',
      );
      expect(notifyCount, 1);
    });

    test('setCenter triggers syncToWebView without throwing', () {
      // No WebView attached — should not throw
      mapProvider.setCenter(const LatLng(latitude: 10, longitude: 20));
      expect(mapProvider.viewport.center.latitude, 10);
    });

    test('dispose cancels debounce timer', () {
      mapProvider.setCenter(const LatLng(latitude: 5, longitude: 5));
      // Should not throw on dispose even with pending timer
      mapProvider.dispose();
    });
  });

  group('SettingsProvider MapTiler key', () {
    test('auto-loads API key from env config on init', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.init();

      // Key is auto-loaded from env.dart if present
      expect(settings.hasMapTilerApiKey, isTrue);
      expect(settings.mapTilerApiKey, isNotEmpty);
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
