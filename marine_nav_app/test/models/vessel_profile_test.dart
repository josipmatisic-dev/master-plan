import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/vessel_profile.dart';

void main() {
  group('VesselProfile', () {
    test('empty profile has default values', () {
      expect(VesselProfile.empty.name, '');
      expect(VesselProfile.empty.type, 'Sailing Yacht');
      expect(VesselProfile.empty.isConfigured, isFalse);
      expect(VesselProfile.empty.mmsi, isNull);
    });

    test('isConfigured when name is set', () {
      const profile = VesselProfile(name: 'My Boat');
      expect(profile.isConfigured, isTrue);
    });

    test('copyWith replaces specified fields', () {
      const original = VesselProfile(
        name: 'Boat A',
        loaMeters: 12,
        draftMeters: 1.8,
      );
      final updated = original.copyWith(
        name: 'Boat B',
        beamMeters: 4.2,
      );
      expect(updated.name, 'Boat B');
      expect(updated.beamMeters, 4.2);
      expect(updated.loaMeters, 12);
      expect(updated.draftMeters, 1.8);
    });

    test('copyWith preserves all fields when none specified', () {
      const original = VesselProfile(
        name: 'Test',
        mmsi: 123456789,
        flag: 'HR',
      );
      final copy = original.copyWith();
      expect(copy.name, original.name);
      expect(copy.mmsi, original.mmsi);
      expect(copy.flag, original.flag);
    });

    test('JSON round-trip with all fields', () {
      const original = VesselProfile(
        name: 'SailStream',
        type: 'Motor Yacht',
        mmsi: 123456789,
        callSign: 'AB1234',
        imo: 9876543,
        flag: 'HR',
        homePort: 'Split',
        loaMeters: 15.5,
        beamMeters: 4.8,
        draftMeters: 2.1,
        displacementKg: 12000,
        mastHeightMeters: 20,
        engineModel: 'Yanmar 4JH',
        engineHours: 1500,
        fuelCapacityLiters: 300,
        waterCapacityLiters: 400,
      );
      final json = original.toJson();
      final restored = VesselProfile.fromJson(json);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.mmsi, original.mmsi);
      expect(restored.callSign, original.callSign);
      expect(restored.imo, original.imo);
      expect(restored.flag, original.flag);
      expect(restored.homePort, original.homePort);
      expect(restored.loaMeters, original.loaMeters);
      expect(restored.beamMeters, original.beamMeters);
      expect(restored.draftMeters, original.draftMeters);
      expect(restored.displacementKg, original.displacementKg);
      expect(restored.mastHeightMeters, original.mastHeightMeters);
      expect(restored.engineModel, original.engineModel);
      expect(restored.engineHours, original.engineHours);
      expect(restored.fuelCapacityLiters, original.fuelCapacityLiters);
      expect(restored.waterCapacityLiters, original.waterCapacityLiters);
    });

    test('JSON round-trip with minimal fields', () {
      const original = VesselProfile(name: 'Simple');
      final json = original.toJson();
      expect(json.containsKey('mmsi'), isFalse);
      expect(json.containsKey('loaMeters'), isFalse);
      final restored = VesselProfile.fromJson(json);
      expect(restored.name, 'Simple');
      expect(restored.mmsi, isNull);
      expect(restored.type, 'Sailing Yacht');
    });

    test('fromJson handles missing name gracefully', () {
      final json = <String, dynamic>{'type': 'Motor Yacht'};
      final profile = VesselProfile.fromJson(json);
      expect(profile.name, '');
      expect(profile.isConfigured, isFalse);
    });
  });
}
