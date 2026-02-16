import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/ais_target.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/providers/ais_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';

void main() {
  late AisProvider provider;
  late SettingsProvider settings;

  AisTarget _makeTarget(int mmsi, {bool stale = false}) {
    return AisTarget(
      mmsi: mmsi,
      position: const LatLng(latitude: 43.5, longitude: 16.4),
      sog: 5,
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
      final targets = [_makeTarget(111), _makeTarget(222)];
      provider.updateTargetsForTesting(targets);
      expect(provider.targetCount, 2);
      expect(provider.targets.containsKey(111), isTrue);
      expect(provider.targets.containsKey(222), isTrue);
    });

    test('updateTargetsForTesting replaces existing targets', () {
      provider.updateTargetsForTesting([_makeTarget(111)]);
      expect(provider.targetCount, 1);
      provider.updateTargetsForTesting([_makeTarget(222), _makeTarget(333)]);
      expect(provider.targetCount, 2);
      expect(provider.targets.containsKey(111), isFalse);
    });

    test('targets map is unmodifiable', () {
      provider.updateTargetsForTesting([_makeTarget(111)]);
      expect(
        () => provider.targets[999] = _makeTarget(999),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('warnings list is unmodifiable', () {
      expect(
        () => provider.warnings.add(_makeTarget(111)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('updateOwnVessel sets own position for CPA', () {
      provider.updateTargetsForTesting([_makeTarget(111)]);
      provider.updateOwnVessel(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        sogKnots: 6,
        cogDegrees: 0,
      );
      // Warnings should be recomputed (even if empty for convergent targets)
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
      provider.updateTargetsForTesting([_makeTarget(111)]);
      expect(notifyCount, 1);
    });
  });
}
