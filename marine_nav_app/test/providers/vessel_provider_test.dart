import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/vessel_profile.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/vessel_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('VesselProfile', () {
    test('empty profile is not configured', () {
      expect(VesselProfile.empty.isConfigured, false);
      expect(VesselProfile.empty.name, '');
    });

    test('profile with name is configured', () {
      const p = VesselProfile(name: 'SV Adriatic Star');
      expect(p.isConfigured, true);
    });

    test('JSON serialization round-trip', () {
      const profile = VesselProfile(
        name: 'SV Test',
        type: 'Motor Yacht',
        mmsi: 123456789,
        callSign: 'TEST1',
        imo: 9876543,
        flag: 'HR',
        homePort: 'Split',
        loaMeters: 12.8,
        beamMeters: 4.1,
        draftMeters: 1.9,
        displacementKg: 9200,
        mastHeightMeters: 18.5,
        engineModel: 'Yanmar 3YM30',
        engineHours: 1247,
        fuelCapacityLiters: 200,
        waterCapacityLiters: 350,
      );

      final json = profile.toJson();
      final restored = VesselProfile.fromJson(json);

      expect(restored.name, 'SV Test');
      expect(restored.type, 'Motor Yacht');
      expect(restored.mmsi, 123456789);
      expect(restored.callSign, 'TEST1');
      expect(restored.imo, 9876543);
      expect(restored.flag, 'HR');
      expect(restored.homePort, 'Split');
      expect(restored.loaMeters, 12.8);
      expect(restored.beamMeters, 4.1);
      expect(restored.draftMeters, 1.9);
      expect(restored.displacementKg, 9200);
      expect(restored.mastHeightMeters, 18.5);
      expect(restored.engineModel, 'Yanmar 3YM30');
      expect(restored.engineHours, 1247);
      expect(restored.fuelCapacityLiters, 200);
      expect(restored.waterCapacityLiters, 350);
    });

    test('JSON handles missing optional fields', () {
      final restored = VesselProfile.fromJson(const {'name': 'Test'});
      expect(restored.name, 'Test');
      expect(restored.type, 'Sailing Yacht');
      expect(restored.mmsi, isNull);
      expect(restored.loaMeters, isNull);
    });

    test('copyWith replaces fields', () {
      const p = VesselProfile(name: 'Old', loaMeters: 10.0);
      final updated = p.copyWith(name: 'New', beamMeters: 4.0);
      expect(updated.name, 'New');
      expect(updated.loaMeters, 10.0);
      expect(updated.beamMeters, 4.0);
    });
  });

  group('VesselProvider', () {
    late VesselProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      final cache = CacheProvider();
      await settings.init();
      await cache.init();
      provider = VesselProvider(
        settingsProvider: settings,
        cacheProvider: cache,
      );
      await provider.init();
    });

    test('starts with empty profile', () {
      expect(provider.isConfigured, false);
      expect(provider.name, '');
      expect(provider.mmsi, isNull);
    });

    test('updateProfile sets profile', () async {
      const profile = VesselProfile(
        name: 'SV Adriatic Star',
        mmsi: 238123456,
      );
      await provider.updateProfile(profile);

      expect(provider.isConfigured, true);
      expect(provider.name, 'SV Adriatic Star');
      expect(provider.mmsi, 238123456);
    });

    test('updateField changes single field', () async {
      await provider.updateProfile(
        const VesselProfile(name: 'Test Boat'),
      );
      await provider.updateField(loaMeters: 15.5);

      expect(provider.profile.name, 'Test Boat');
      expect(provider.profile.loaMeters, 15.5);
    });

    test('updateEngineHours updates hours', () async {
      await provider.updateProfile(
        const VesselProfile(name: 'Test'),
      );
      await provider.updateEngineHours(500);
      expect(provider.profile.engineHours, 500);
    });

    test('clearProfile resets to empty', () async {
      await provider.updateProfile(
        const VesselProfile(name: 'Test', mmsi: 123),
      );
      await provider.clearProfile();

      expect(provider.isConfigured, false);
      expect(provider.name, '');
    });

    test('notifies listeners on changes', () async {
      int count = 0;
      provider.addListener(() => count++);

      await provider.updateProfile(
        const VesselProfile(name: 'Test'),
      );
      await provider.updateField(draftMeters: 2.0);
      await provider.clearProfile();

      expect(count, 3);
    });
  });
}
