import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/trip_log.dart';

void main() {
  group('TripWaypoint', () {
    test('construction and fields', () {
      const wp = TripWaypoint(
        lat: 43.5,
        lng: 16.4,
        speedKnots: 7.2,
        timestamp: '2026-02-16T12:00:00.000Z',
        cogDegrees: 180,
      );
      expect(wp.lat, 43.5);
      expect(wp.lng, 16.4);
      expect(wp.speedKnots, 7.2);
      expect(wp.cogDegrees, 180);
    });

    test('JSON round-trip with all fields', () {
      const original = TripWaypoint(
        lat: 43.5,
        lng: 16.4,
        speedKnots: 6.0,
        timestamp: '2026-02-16T12:00:00.000Z',
        cogDegrees: 90,
      );
      final json = original.toJson();
      final restored = TripWaypoint.fromJson(json);
      expect(restored.lat, original.lat);
      expect(restored.lng, original.lng);
      expect(restored.speedKnots, original.speedKnots);
      expect(restored.cogDegrees, original.cogDegrees);
      expect(restored.timestamp, original.timestamp);
    });

    test('JSON round-trip without optional fields', () {
      const original = TripWaypoint(
        lat: 43.5,
        lng: 16.4,
        speedKnots: 0,
        timestamp: '2026-02-16T12:00:00.000Z',
      );
      final json = original.toJson();
      expect(json.containsKey('cogDegrees'), isFalse);
      final restored = TripWaypoint.fromJson(json);
      expect(restored.cogDegrees, isNull);
    });
  });

  group('TripLog', () {
    final start = DateTime.utc(2026, 2, 16, 10);
    final end = DateTime.utc(2026, 2, 16, 14);
    final waypoints = [
      const TripWaypoint(
        lat: 43.5,
        lng: 16.4,
        speedKnots: 5,
        timestamp: '2026-02-16T10:00:00.000Z',
      ),
      const TripWaypoint(
        lat: 43.6,
        lng: 16.5,
        speedKnots: 8,
        timestamp: '2026-02-16T11:00:00.000Z',
      ),
      const TripWaypoint(
        lat: 43.7,
        lng: 16.6,
        speedKnots: 6,
        timestamp: '2026-02-16T12:00:00.000Z',
      ),
    ];

    test('isRecording when no endTime', () {
      final trip = TripLog(
        id: 't1',
        name: 'Test',
        startTime: start,
        waypoints: waypoints,
      );
      expect(trip.isRecording, isTrue);
    });

    test('not recording when endTime set', () {
      final trip = TripLog(
        id: 't1',
        name: 'Test',
        startTime: start,
        endTime: end,
        waypoints: waypoints,
      );
      expect(trip.isRecording, isFalse);
    });

    test('duration with endTime', () {
      final trip = TripLog(
        id: 't1',
        name: 'Test',
        startTime: start,
        endTime: end,
        waypoints: waypoints,
      );
      expect(trip.duration, const Duration(hours: 4));
    });

    test('avgSpeedKnots computed correctly', () {
      final trip = TripLog(
        id: 't1',
        name: 'Test',
        startTime: start,
        waypoints: waypoints,
      );
      expect(trip.avgSpeedKnots, closeTo(6.333, 0.01));
    });

    test('avgSpeedKnots returns 0 for empty waypoints', () {
      final trip = TripLog(
        id: 't1',
        name: 'Test',
        startTime: start,
        waypoints: const [],
      );
      expect(trip.avgSpeedKnots, 0);
    });

    test('maxSpeedKnots computed correctly', () {
      final trip = TripLog(
        id: 't1',
        name: 'Test',
        startTime: start,
        waypoints: waypoints,
      );
      expect(trip.maxSpeedKnots, 8);
    });

    test('maxSpeedKnots returns 0 for empty waypoints', () {
      final trip = TripLog(
        id: 't1',
        name: 'Test',
        startTime: start,
        waypoints: const [],
      );
      expect(trip.maxSpeedKnots, 0);
    });

    test('copyWith replaces fields', () {
      final trip = TripLog(
        id: 't1',
        name: 'Test',
        startTime: start,
        waypoints: waypoints,
        distanceNm: 10,
      );
      final updated = trip.copyWith(name: 'Updated', distanceNm: 20);
      expect(updated.name, 'Updated');
      expect(updated.distanceNm, 20);
      expect(updated.id, 't1');
      expect(updated.startTime, start);
    });

    test('JSON round-trip with all fields', () {
      final original = TripLog(
        id: 't1',
        name: 'Test Trip',
        startTime: start,
        endTime: end,
        waypoints: waypoints,
        distanceNm: 15.5,
      );
      final json = original.toJson();
      final restored = TripLog.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.distanceNm, original.distanceNm);
      expect(restored.waypoints.length, original.waypoints.length);
      expect(restored.endTime, isNotNull);
      expect(restored.isRecording, isFalse);
    });

    test('JSON round-trip without endTime', () {
      final original = TripLog(
        id: 't1',
        name: 'Active',
        startTime: start,
        waypoints: waypoints,
      );
      final json = original.toJson();
      expect(json.containsKey('endTime'), isFalse);
      final restored = TripLog.fromJson(json);
      expect(restored.endTime, isNull);
      expect(restored.isRecording, isTrue);
    });
  });
}
