import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/ais_target.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/providers/ais_provider.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsProvider settings;

  AisTarget makeTarget(int mmsi, {bool stale = false}) {
    return AisTarget(
      mmsi: mmsi,
      position: const LatLng(latitude: 43.5, longitude: 16.4),
      sog: 5.0,
      cog: 180.0,
      heading: 178,
      name: 'VESSEL_$mmsi',
      lastUpdate: stale
          ? DateTime.now().subtract(const Duration(minutes: 20))
          : DateTime.now(),
    );
  }

  setUp(() {
    settings = SettingsProvider();
  });

  tearDown(() {
    settings.dispose();
  });

  group('AIS cache round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.512, longitude: 16.440),
        sog: 12.5,
        cog: 270.0,
        heading: 268,
        navStatus: AisNavStatus.underWayEngine,
        rateOfTurn: -5.2,
        name: 'TEST VESSEL',
        callSign: 'D5AB7',
        imo: 9876543,
        shipType: 70,
        dimensions: const [100, 50, 15, 15],
        destination: 'SPLIT',
        draught: 8.5,
        lastUpdate: DateTime.utc(2026, 2, 16, 12, 0, 0),
      );

      final json = target.toJson();
      final restored = AisTarget.fromJson(json);

      expect(restored.mmsi, target.mmsi);
      expect(restored.position.latitude, target.position.latitude);
      expect(restored.position.longitude, target.position.longitude);
      expect(restored.sog, target.sog);
      expect(restored.cog, target.cog);
      expect(restored.heading, target.heading);
      expect(restored.navStatus, target.navStatus);
      expect(restored.rateOfTurn, target.rateOfTurn);
      expect(restored.name, target.name);
      expect(restored.callSign, target.callSign);
      expect(restored.imo, target.imo);
      expect(restored.shipType, target.shipType);
      expect(restored.dimensions, target.dimensions);
      expect(restored.destination, target.destination);
      expect(restored.draught, target.draught);
      expect(restored.lastUpdate, target.lastUpdate);
    });

    test('toJson/fromJson with minimal fields', () {
      final target = AisTarget(
        mmsi: 100,
        position: const LatLng(latitude: 0.0, longitude: 0.0),
        lastUpdate: DateTime.utc(2026, 1, 1),
      );

      final json = target.toJson();
      final restored = AisTarget.fromJson(json);

      expect(restored.mmsi, 100);
      expect(restored.sog, isNull);
      expect(restored.cog, isNull);
      expect(restored.heading, isNull);
      expect(restored.name, isNull);
      expect(restored.dimensions, isNull);
    });

    test('JSON round-trip through jsonEncode/Decode', () {
      final target = makeTarget(555);
      final encoded = jsonEncode(target.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = AisTarget.fromJson(decoded);

      expect(restored.mmsi, 555);
      expect(restored.name, 'VESSEL_555');
      expect(restored.sog, 5.0);
    });
  });

  group('AIS cache with CacheProvider', () {
    test('init loads fresh targets from cache', () async {
      SharedPreferences.setMockInitialValues({});

      final cacheService = CacheService();
      await cacheService.init();
      final cache = CacheProvider(cacheService: cacheService);
      await cache.init();

      // Store targets via the cache API
      await cache.putJson('ais_targets', {
        'targets': [makeTarget(100).toJson(), makeTarget(200).toJson()],
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      });

      final provider = AisProvider(
        settingsProvider: settings,
        cacheProvider: cache,
      );
      await provider.init();

      expect(provider.targetCount, 2);
      expect(provider.targets.containsKey(100), isTrue);
      expect(provider.targets.containsKey(200), isTrue);

      provider.dispose();
      cache.dispose();
    });

    test('init filters stale targets from cache', () async {
      SharedPreferences.setMockInitialValues({});

      final cacheService = CacheService();
      await cacheService.init();
      final cache = CacheProvider(cacheService: cacheService);
      await cache.init();

      await cache.putJson('ais_targets', {
        'targets': [
          makeTarget(100, stale: false).toJson(),
          makeTarget(200, stale: true).toJson(),
          makeTarget(300, stale: true).toJson(),
        ],
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      });

      final provider = AisProvider(
        settingsProvider: settings,
        cacheProvider: cache,
      );
      await provider.init();

      // Only the fresh target should survive
      expect(provider.targetCount, 1);
      expect(provider.targets.containsKey(100), isTrue);
      expect(provider.targets.containsKey(200), isFalse);

      provider.dispose();
      cache.dispose();
    });

    test('init handles empty cache gracefully', () async {
      SharedPreferences.setMockInitialValues({});

      final cacheService = CacheService();
      await cacheService.init();
      final cache = CacheProvider(cacheService: cacheService);
      await cache.init();

      final provider = AisProvider(
        settingsProvider: settings,
        cacheProvider: cache,
      );
      await provider.init();

      expect(provider.targetCount, 0);
      expect(provider.targets, isEmpty);

      provider.dispose();
      cache.dispose();
    });

    test('init handles corrupted cache data gracefully', () async {
      SharedPreferences.setMockInitialValues({});

      final cacheService = CacheService();
      await cacheService.init();
      final cache = CacheProvider(cacheService: cacheService);
      await cache.init();

      // Store invalid JSON string directly
      await cache.put('ais_targets', 'not valid json {{{{');

      final provider = AisProvider(
        settingsProvider: settings,
        cacheProvider: cache,
      );

      // Should not throw
      await provider.init();
      expect(provider.targetCount, 0);

      provider.dispose();
      cache.dispose();
    });

    test('init with null cache provider works', () async {
      final provider = AisProvider(settingsProvider: settings);
      await provider.init();

      expect(provider.targetCount, 0);
      expect(provider.isConnected, isFalse);

      provider.dispose();
    });
  });

  group('AIS target capacity', () {
    test('maxTargets constant is 500', () {
      expect(AisProvider.maxTargets, 500);
    });

    test('updateTargetsForTesting with many targets works', () {
      final provider = AisProvider(settingsProvider: settings);
      final targets = List.generate(600, (i) => makeTarget(i + 1));
      provider.updateTargetsForTesting(targets);

      // updateTargetsForTesting doesn't enforce maxTargets limit
      // (that's done in _processBatch during live streaming)
      expect(provider.targetCount, 600);

      provider.dispose();
    });
  });

  group('AIS stale cleanup', () {
    test('stale target detected by model', () {
      final stale = makeTarget(100, stale: true);
      expect(stale.isStale, isTrue);
    });

    test('fresh target not stale', () {
      final fresh = makeTarget(200, stale: false);
      expect(fresh.isStale, isFalse);
    });

    test('all-stale cache restores zero targets', () async {
      SharedPreferences.setMockInitialValues({});

      final cacheService = CacheService();
      await cacheService.init();
      final cache = CacheProvider(cacheService: cacheService);
      await cache.init();

      await cache.putJson('ais_targets', {
        'targets': [
          makeTarget(1, stale: true).toJson(),
          makeTarget(2, stale: true).toJson(),
        ],
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      });

      final provider = AisProvider(
        settingsProvider: settings,
        cacheProvider: cache,
      );
      await provider.init();

      expect(provider.targetCount, 0);

      provider.dispose();
      cache.dispose();
    });
  });
}
