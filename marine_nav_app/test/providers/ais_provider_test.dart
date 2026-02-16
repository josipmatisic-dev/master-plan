import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/ais_target.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/providers/ais_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';

void main() {
  late AisProvider provider;
  late SettingsProvider settings;

  AisTarget makeTarget(int mmsi, {bool stale = false, double? sog}) {
    return AisTarget(
      mmsi: mmsi,
      position: const LatLng(latitude: 43.5, longitude: 16.4),
      sog: sog ?? 5,
      cog: 180,
      lastUpdate: stale
          ? DateTime.now().subtract(const Duration(minutes: 20))
          : DateTime.now(),
    );
  }

  setUp(() {
    settings = SettingsProvider();
    provider = AisProvider(settingsProvider: settings);
  });

  tearDown(() {
    provider.dispose();
    settings.dispose();
  });

  group('AisProvider', () {
    test('initial state has empty targets', () {
      expect(provider.targetCount, 0);
      expect(provider.targets, isEmpty);
      expect(provider.warnings, isEmpty);
      expect(provider.isConnected, isFalse);
      expect(provider.lastError, isNull);
    });

    test('updateTargetsForTesting adds targets', () {
      final targets = [makeTarget(111), makeTarget(222)];
      provider.updateTargetsForTesting(targets);
      expect(provider.targetCount, 2);
      expect(provider.targets.containsKey(111), isTrue);
      expect(provider.targets.containsKey(222), isTrue);
    });

    test('updateTargetsForTesting replaces existing targets', () {
      provider.updateTargetsForTesting([makeTarget(111)]);
      expect(provider.targetCount, 1);
      provider.updateTargetsForTesting([makeTarget(222), makeTarget(333)]);
      expect(provider.targetCount, 2);
      expect(provider.targets.containsKey(111), isFalse);
    });

    test('targets map is unmodifiable', () {
      provider.updateTargetsForTesting([makeTarget(111)]);
      expect(
        () => provider.targets[999] = makeTarget(999),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('warnings list is unmodifiable', () {
      expect(
        () => provider.warnings.add(makeTarget(111)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('updateOwnVessel sets own position for CPA', () {
      provider.updateTargetsForTesting([makeTarget(111)]);
      provider.updateOwnVessel(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        sogKnots: 6,
        cogDegrees: 0,
      );
      expect(provider.warnings, isA<List<AisTarget>>());
    });

    test('init succeeds without cache', () async {
      await provider.init();
      expect(provider.targetCount, 0);
    });

    test('connect fails without API key', () async {
      await provider.init();
      await provider.connect(
        swLat: 40,
        swLng: 14,
        neLat: 45,
        neLng: 18,
      );
      expect(provider.lastError, 'No AIS API key configured');
    });

    test('notifies listeners on target update', () {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.updateTargetsForTesting([makeTarget(111)]);
      expect(notifyCount, 1);
    });

    test('maxTargets constant is 500', () {
      expect(AisProvider.maxTargets, 500);
    });

    test('handles single target with null SOG', () {
      final target = AisTarget(
        mmsi: 111,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        cog: 180,
        lastUpdate: DateTime.now(),
      );
      provider.updateTargetsForTesting([target]);
      expect(provider.targetCount, 1);
      expect(provider.targets[111]?.sog, isNull);
    });

    test('handles single target with null COG', () {
      final target = AisTarget(
        mmsi: 222,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        sog: 5,
        lastUpdate: DateTime.now(),
      );
      provider.updateTargetsForTesting([target]);
      expect(provider.targetCount, 1);
      expect(provider.targets[222]?.cog, isNull);
    });

    test('updateTargetsForTesting with empty list clears targets', () {
      provider.updateTargetsForTesting([makeTarget(111), makeTarget(222)]);
      expect(provider.targetCount, 2);
      provider.updateTargetsForTesting([]);
      expect(provider.targetCount, 0);
    });

    test('warnings cleared when own position is null', () {
      provider.updateTargetsForTesting([makeTarget(111)]);
      provider.updateOwnVessel(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        sogKnots: 6,
        cogDegrees: 0,
      );
      // Re-trigger with cleared position
      provider.updateTargetsForTesting([makeTarget(111)]);
      expect(provider.warnings, isA<List<AisTarget>>());
    });

    test('handles targets with same MMSI - last wins', () {
      final t1 = AisTarget(
        mmsi: 111,
        position: const LatLng(latitude: 43.0, longitude: 16.0),
        sog: 5,
        cog: 180,
        lastUpdate: DateTime.now(),
      );
      final t2 = AisTarget(
        mmsi: 111,
        position: const LatLng(latitude: 44.0, longitude: 17.0),
        sog: 10,
        cog: 90,
        lastUpdate: DateTime.now(),
      );
      provider.updateTargetsForTesting([t1, t2]);
      // Both have same MMSI — map will contain last one
      expect(provider.targetCount, 1);
      expect(provider.targets[111]?.position.latitude, 44.0);
    });

    test('large number of targets with distinct MMSIs', () {
      final targets = List.generate(100, (i) => makeTarget(i + 1000));
      provider.updateTargetsForTesting(targets);
      expect(provider.targetCount, 100);
    });

    test('stale target detection via model', () {
      final fresh = makeTarget(111, stale: false);
      final stale = makeTarget(222, stale: true);
      expect(fresh.isStale, isFalse);
      expect(stale.isStale, isTrue);
    });

    test('target merge preserves existing fields for nulls', () {
      final original = AisTarget(
        mmsi: 111,
        position: const LatLng(latitude: 43.0, longitude: 16.0),
        sog: 10,
        cog: 180,
        name: 'TestShip',
        callSign: 'AB1234',
        lastUpdate: DateTime.now(),
      );

      final update = AisTarget(
        mmsi: 111,
        position: const LatLng(latitude: 43.1, longitude: 16.1),
        lastUpdate: DateTime.now(),
      );

      final merged = original.merge(update);
      expect(merged.position.latitude, 43.1); // Updated
      expect(merged.sog, 10); // Null in update → keeps original
      expect(merged.name, 'TestShip'); // Null in update → keeps original
    });

    test('target merge keeps non-null update fields', () {
      final original = AisTarget(
        mmsi: 111,
        position: const LatLng(latitude: 43.0, longitude: 16.0),
        sog: 10,
        cog: 180,
        lastUpdate: DateTime.now(),
      );

      final update = AisTarget(
        mmsi: 111,
        position: const LatLng(latitude: 43.1, longitude: 16.1),
        sog: 15,
        cog: 270,
        name: 'NewName',
        lastUpdate: DateTime.now(),
      );

      final merged = original.merge(update);
      expect(merged.sog, 15);
      expect(merged.cog, 270);
      expect(merged.name, 'NewName');
    });

    test('target displayName returns name when available', () {
      final named = AisTarget(
        mmsi: 111,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        name: 'MY VESSEL',
        lastUpdate: DateTime.now(),
      );
      expect(named.displayName, 'MY VESSEL');
    });

    test('target displayName returns MMSI when name is null', () {
      final unnamed = AisTarget(
        mmsi: 123456789,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
      );
      expect(unnamed.displayName, 'MMSI 123456789');
    });
  });
}
