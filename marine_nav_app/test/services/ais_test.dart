import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/ais_target.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/services/ais_collision.dart';

void main() {
  group('AisTarget', () {
    test('creates with required fields', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime(2024, 1, 1),
      );

      expect(target.mmsi, 211234567);
      expect(target.position.latitude, 43.5);
      expect(target.position.longitude, 16.4);
      expect(target.navStatus, AisNavStatus.unknown);
      expect(target.shipType, 0);
      expect(target.category, ShipCategory.other);
    });

    test('displayName returns name when available', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
        name: 'JADROLINIJA',
      );
      expect(target.displayName, 'JADROLINIJA');
    });

    test('displayName returns MMSI when name is null', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
      );
      expect(target.displayName, 'MMSI 211234567');
    });

    test('displayName returns MMSI when name is blank', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
        name: '   ',
      );
      expect(target.displayName, 'MMSI 211234567');
    });

    test('isStale returns true after 5 minutes', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 6)),
      );
      expect(target.isStale, isTrue);
    });

    test('isStale returns false for recent update', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
      );
      expect(target.isStale, isFalse);
    });

    test('merge combines position + static data', () {
      final original = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime(2024, 1, 1),
        name: 'JADROLINIJA',
        shipType: 60,
      );

      final update = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.6, longitude: 16.5),
        lastUpdate: DateTime(2024, 1, 1, 0, 1),
        sog: 12.5,
        cog: 180.0,
      );

      final merged = original.merge(update);
      expect(merged.position.latitude, 43.6);
      expect(merged.sog, 12.5);
      expect(merged.name, 'JADROLINIJA');
      expect(merged.shipType, 60);
    });

    test('equality based on MMSI', () {
      final a = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime(2024, 1, 1),
      );
      final b = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 44.0, longitude: 17.0),
        lastUpdate: DateTime(2024, 1, 2),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('lengthMeters and beamMeters from dimensions', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
        dimensions: const [50, 150, 10, 20],
      );
      expect(target.lengthMeters, 200.0);
      expect(target.beamMeters, 30.0);
    });

    test('lengthMeters null when no dimensions', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
      );
      expect(target.lengthMeters, isNull);
      expect(target.beamMeters, isNull);
    });
  });

  group('AisNavStatus', () {
    test('fromCode returns correct status', () {
      expect(AisNavStatus.fromCode(0), AisNavStatus.underWayEngine);
      expect(AisNavStatus.fromCode(1), AisNavStatus.atAnchor);
      expect(AisNavStatus.fromCode(5), AisNavStatus.moored);
      expect(AisNavStatus.fromCode(7), AisNavStatus.fishing);
      expect(AisNavStatus.fromCode(8), AisNavStatus.underWaySailing);
      expect(AisNavStatus.fromCode(15), AisNavStatus.unknown);
    });

    test('fromCode returns unknown for invalid code', () {
      expect(AisNavStatus.fromCode(99), AisNavStatus.unknown);
    });
  });

  group('ShipCategory', () {
    test('fromTypeCode maps correctly', () {
      expect(ShipCategory.fromTypeCode(70), ShipCategory.cargo);
      expect(ShipCategory.fromTypeCode(80), ShipCategory.tanker);
      expect(ShipCategory.fromTypeCode(60), ShipCategory.passenger);
      expect(ShipCategory.fromTypeCode(30), ShipCategory.fishing);
      expect(ShipCategory.fromTypeCode(36), ShipCategory.sailing);
      expect(ShipCategory.fromTypeCode(37), ShipCategory.pleasure);
      expect(ShipCategory.fromTypeCode(51), ShipCategory.searchAndRescue);
      expect(ShipCategory.fromTypeCode(0), ShipCategory.other);
    });
  });

  group('CpaResult', () {
    test('isWarning when CPA < 1.0 NM and TCPA 0-30 min', () {
      const result = CpaResult(cpaNm: 0.8, tcpaMinutes: 15.0);
      expect(result.isWarning, isTrue);
      expect(result.isDanger, isFalse);
    });

    test('isDanger when CPA < 0.5 NM and TCPA 0-15 min', () {
      const result = CpaResult(cpaNm: 0.3, tcpaMinutes: 10.0);
      expect(result.isWarning, isTrue);
      expect(result.isDanger, isTrue);
    });

    test('not warning when diverging', () {
      const result = CpaResult(cpaNm: 0.3, tcpaMinutes: -5.0);
      expect(result.isWarning, isFalse);
    });

    test('not warning when CPA > 1.0 NM', () {
      const result = CpaResult(cpaNm: 2.0, tcpaMinutes: 10.0);
      expect(result.isWarning, isFalse);
    });
  });

  group('AisCollisionCalculator', () {
    test('compute returns null when target has no SOG/COG', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
      );

      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 6.0,
        ownCogDegrees: 0.0,
        target: target,
      );
      expect(result, isNull);
    });

    test('compute returns null when both stationary', () {
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        lastUpdate: DateTime.now(),
        sog: 0.0,
        cog: 0.0,
      );

      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 0.0,
        ownCogDegrees: 0.0,
        target: target,
      );
      expect(result, isNull);
    });

    test('compute detects head-on collision', () {
      // Two vessels heading towards each other on same line
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.1, longitude: 16.0),
        lastUpdate: DateTime.now(),
        sog: 10.0,
        cog: 180.0, // Heading south
      );

      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0, // Heading north
        target: target,
      );

      expect(result, isNotNull);
      expect(result!.cpaNm, lessThan(0.5)); // Very close CPA
      expect(result.tcpaMinutes, greaterThan(0)); // Converging
    });

    test('compute detects diverging vessels', () {
      // Two vessels heading away from each other
      final target = AisTarget(
        mmsi: 211234567,
        position: const LatLng(latitude: 43.1, longitude: 16.0),
        lastUpdate: DateTime.now(),
        sog: 10.0,
        cog: 0.0, // Heading north (away)
      );

      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 180.0, // Heading south (away)
        target: target,
      );

      expect(result, isNotNull);
      expect(result!.tcpaMinutes, lessThan(0)); // Diverging
    });

    test('computeWarnings filters by CPA threshold', () {
      final targets = [
        // Close target - should warn
        AisTarget(
          mmsi: 1,
          position: const LatLng(latitude: 43.005, longitude: 16.0),
          lastUpdate: DateTime.now(),
          sog: 10.0,
          cog: 180.0,
        ),
        // Far target - should not warn
        AisTarget(
          mmsi: 2,
          position: const LatLng(latitude: 44.0, longitude: 17.0),
          lastUpdate: DateTime.now(),
          sog: 5.0,
          cog: 90.0,
        ),
      ];

      final warnings = AisCollisionCalculator.computeWarnings(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        targets: targets,
      );

      // Should have at most the close target as warning
      expect(warnings.length, lessThanOrEqualTo(1));
      if (warnings.isNotEmpty) {
        expect(warnings.first.mmsi, 1);
        expect(warnings.first.cpa, isNotNull);
        expect(warnings.first.tcpa, isNotNull);
      }
    });
  });
}
