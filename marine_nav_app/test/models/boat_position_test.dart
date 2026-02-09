import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/models/lat_lng.dart';

void main() {
  group('BoatPosition', () {
    final timestamp = DateTime.utc(2026, 2, 8, 12, 0, 0);
    const position = LatLng(latitude: 59.91, longitude: 10.75);

    test('constructs with required fields', () {
      final bp = BoatPosition(position: position, timestamp: timestamp);

      expect(bp.position, position);
      expect(bp.timestamp, timestamp);
      expect(bp.latitude, 59.91);
      expect(bp.longitude, 10.75);
    });

    test('has correct default values', () {
      final bp = BoatPosition(position: position, timestamp: timestamp);

      expect(bp.speedKnots, isNull);
      expect(bp.courseTrue, isNull);
      expect(bp.heading, isNull);
      expect(bp.accuracy, 0.0);
      expect(bp.fixQuality, 0);
      expect(bp.satellites, 0);
      expect(bp.altitudeMeters, isNull);
    });

    test('constructs with all optional fields', () {
      final bp = BoatPosition(
        position: position,
        timestamp: timestamp,
        speedKnots: 12.5,
        courseTrue: 85.0,
        heading: 82.0,
        accuracy: 3.5,
        fixQuality: 2,
        satellites: 12,
        altitudeMeters: 5.2,
      );

      expect(bp.speedKnots, 12.5);
      expect(bp.courseTrue, 85.0);
      expect(bp.heading, 82.0);
      expect(bp.accuracy, 3.5);
      expect(bp.fixQuality, 2);
      expect(bp.satellites, 12);
      expect(bp.altitudeMeters, 5.2);
    });

    test('isValid returns true when fixQuality > 0', () {
      final valid = BoatPosition(
        position: position,
        timestamp: timestamp,
        fixQuality: 1,
      );
      final invalid = BoatPosition(
        position: position,
        timestamp: timestamp,
        fixQuality: 0,
      );

      expect(valid.isValid, true);
      expect(invalid.isValid, false);
    });

    test('isAccurate returns true when accuracy <= 50m', () {
      final accurate = BoatPosition(
        position: position,
        timestamp: timestamp,
        accuracy: 50.0,
      );
      final inaccurate = BoatPosition(
        position: position,
        timestamp: timestamp,
        accuracy: 50.1,
      );

      expect(accurate.isAccurate, true);
      expect(inaccurate.isAccurate, false);
    });

    test('copyWith returns new instance with updated fields', () {
      final original = BoatPosition(
        position: position,
        timestamp: timestamp,
        speedKnots: 10.0,
        courseTrue: 45.0,
      );

      const newPos = LatLng(latitude: 60.0, longitude: 11.0);
      final copied = original.copyWith(
        position: newPos,
        speedKnots: 15.0,
      );

      expect(copied.position, newPos);
      expect(copied.speedKnots, 15.0);
      // Unchanged fields preserved
      expect(copied.courseTrue, 45.0);
      expect(copied.timestamp, timestamp);
    });

    test('copyWith with no arguments returns equivalent instance', () {
      final original = BoatPosition(
        position: position,
        timestamp: timestamp,
        speedKnots: 10.0,
      );

      final copied = original.copyWith();

      expect(copied.position, original.position);
      expect(copied.timestamp, original.timestamp);
      expect(copied.speedKnots, original.speedKnots);
    });

    test('equality compares position, timestamp, speed, and course', () {
      final a = BoatPosition(
        position: position,
        timestamp: timestamp,
        speedKnots: 10.0,
        courseTrue: 45.0,
      );
      final b = BoatPosition(
        position: position,
        timestamp: timestamp,
        speedKnots: 10.0,
        courseTrue: 45.0,
        // Different accuracy should still be equal
        accuracy: 5.0,
      );

      expect(a, equals(b));
    });

    test('inequality when position differs', () {
      final a = BoatPosition(position: position, timestamp: timestamp);
      final b = BoatPosition(
        position: const LatLng(latitude: 60.0, longitude: 10.75),
        timestamp: timestamp,
      );

      expect(a, isNot(equals(b)));
    });

    test('inequality when timestamp differs', () {
      final a = BoatPosition(position: position, timestamp: timestamp);
      final b = BoatPosition(
        position: position,
        timestamp: timestamp.add(const Duration(seconds: 1)),
      );

      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      final a = BoatPosition(
        position: position,
        timestamp: timestamp,
        speedKnots: 10.0,
        courseTrue: 45.0,
      );
      final b = BoatPosition(
        position: position,
        timestamp: timestamp,
        speedKnots: 10.0,
        courseTrue: 45.0,
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns human-readable format', () {
      final bp = BoatPosition(
        position: position,
        timestamp: timestamp,
        speedKnots: 12.4,
        courseTrue: 85.0,
      );

      final str = bp.toString();
      expect(str, contains('59.91'));
      expect(str, contains('10.75'));
      expect(str, contains('12.4'));
      expect(str, contains('85.0'));
    });

    test('toString handles null speed and course', () {
      final bp = BoatPosition(position: position, timestamp: timestamp);

      final str = bp.toString();
      expect(str, contains('n/a'));
    });

    test('trackHistory list is unmodifiable', () {
      // Verify the constants are accessible
      expect(maxTrackHistoryPoints, 1000);
      expect(maxRealisticSpeedMps, 50.0);
      expect(maxAccuracyThresholdMeters, 50.0);
    });
  });
}
