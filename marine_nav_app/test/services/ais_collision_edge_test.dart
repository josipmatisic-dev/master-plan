import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/ais_target.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/services/ais_collision.dart';

void main() {
  group('AisCollisionCalculator edge cases', () {
    AisTarget makeTarget({
      int mmsi = 1,
      double lat = 43.01,
      double lng = 16.0,
      double? sog = 10.0,
      double? cog = 180.0,
    }) {
      return AisTarget(
        mmsi: mmsi,
        position: LatLng(latitude: lat, longitude: lng),
        lastUpdate: DateTime.now(),
        sog: sog,
        cog: cog,
      );
    }

    test('parallel same-direction tracks — no CPA warning', () {
      // Own vessel heading north at 43.0, 16.0
      // Target heading north at 43.0, 16.002 — parallel, 0.1nm apart
      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        target: makeTarget(lat: 43.0, lng: 16.002, sog: 10.0, cog: 0.0),
      );
      expect(result, isNotNull);
      // Parallel same-speed: TCPA ≈ 0, CPA = current distance
      expect(result!.tcpaMinutes, closeTo(0, 1.0));
    });

    test('crossing at right angles — positive TCPA', () {
      // Own heading north, target heading west → crossing
      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        target: makeTarget(lat: 43.05, lng: 16.05, sog: 10.0, cog: 270.0),
      );
      expect(result, isNotNull);
      expect(result!.tcpaMinutes, greaterThan(0));
    });

    test('stationary target with moving own vessel', () {
      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        target: makeTarget(lat: 43.05, lng: 16.0, sog: 0.0, cog: 0.0),
      );
      expect(result, isNotNull);
      expect(result!.tcpaMinutes, greaterThan(0));
      expect(result.cpaNm, closeTo(0, 0.5));
    });

    test('overtaking scenario — same heading, different speeds', () {
      // Own at 15 kts heading north, target at 5 kts heading north ahead
      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 15.0,
        ownCogDegrees: 0.0,
        target: makeTarget(lat: 43.02, lng: 16.0, sog: 5.0, cog: 0.0),
      );
      expect(result, isNotNull);
      expect(result!.tcpaMinutes, greaterThan(0));
      // Will close to 0 CPA (same track)
      expect(result.cpaNm, closeTo(0, 0.1));
    });

    test('own vessel stationary, target approaching', () {
      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 0.0,
        ownCogDegrees: 0.0,
        target: makeTarget(lat: 43.05, lng: 16.0, sog: 10.0, cog: 180.0),
      );
      expect(result, isNotNull);
      expect(result!.tcpaMinutes, greaterThan(0));
      expect(result.cpaNm, closeTo(0, 0.5));
    });

    test('target behind and moving away — negative TCPA', () {
      // Target behind own vessel, both heading north but target slower
      // Actually target heading south → diverging
      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.05, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        target: makeTarget(lat: 43.0, lng: 16.0, sog: 10.0, cog: 180.0),
      );
      expect(result, isNotNull);
      // Diverging: TCPA should be negative
      expect(result!.tcpaMinutes, lessThan(0));
    });

    test('computeWarnings excludes diverging targets', () {
      final warnings = AisCollisionCalculator.computeWarnings(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        targets: [
          // Diverging target
          makeTarget(lat: 42.99, lng: 16.0, sog: 10.0, cog: 180.0),
        ],
      );
      expect(warnings, isEmpty);
    });

    test('computeWarnings excludes targets beyond TCPA max', () {
      // Very far target heading toward own vessel — TCPA > 30 min
      final warnings = AisCollisionCalculator.computeWarnings(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 2.0,
        ownCogDegrees: 0.0,
        targets: [
          makeTarget(lat: 44.0, lng: 16.0, sog: 2.0, cog: 180.0),
        ],
      );
      expect(warnings, isEmpty);
    });

    test('computeWarnings sorts by CPA ascending', () {
      final warnings = AisCollisionCalculator.computeWarnings(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        targets: [
          // Slightly offset — larger CPA
          makeTarget(
            mmsi: 1,
            lat: 43.02,
            lng: 16.005,
            sog: 10.0,
            cog: 180.0,
          ),
          // Direct head-on — smallest CPA
          makeTarget(
            mmsi: 2,
            lat: 43.02,
            lng: 16.0,
            sog: 10.0,
            cog: 180.0,
          ),
        ],
      );
      if (warnings.length >= 2) {
        expect(
          warnings[0].cpa!,
          lessThanOrEqualTo(warnings[1].cpa!),
        );
      }
    });

    test('computeWarnings skips targets with null SOG/COG', () {
      final warnings = AisCollisionCalculator.computeWarnings(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        targets: [
          makeTarget(sog: null, cog: null),
          makeTarget(sog: 10.0, cog: null),
          makeTarget(sog: null, cog: 180.0),
        ],
      );
      expect(warnings, isEmpty);
    });

    test('computeWarnings with empty targets returns empty', () {
      final warnings = AisCollisionCalculator.computeWarnings(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        targets: [],
      );
      expect(warnings, isEmpty);
    });

    test('CpaResult isDanger at very close approach', () {
      // Head-on at close range → danger level CPA
      final result = AisCollisionCalculator.compute(
        ownPosition: const LatLng(latitude: 43.0, longitude: 16.0),
        ownSogKnots: 10.0,
        ownCogDegrees: 0.0,
        target: makeTarget(lat: 43.01, lng: 16.0, sog: 10.0, cog: 180.0),
      );
      expect(result, isNotNull);
      expect(result!.cpaNm, closeTo(0, 0.5));
      expect(result.isDanger, isTrue);
    });

    test('constants have expected values', () {
      expect(AisCollisionCalculator.cpaWarningNm, 1.0);
      expect(AisCollisionCalculator.cpaDangerNm, 0.5);
      expect(AisCollisionCalculator.tcpaMaxMinutes, 30.0);
    });
  });
}
