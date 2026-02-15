import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:marine_nav_app/models/route.dart';
import 'package:marine_nav_app/services/geo_utils.dart';

void main() {
  group('GeoUtils', () {
    group('distanceBetween', () {
      test('calculates distance between two points', () {
        // Washington DC to New York City (approximately 177 nautical miles)
        const dcPosition = LatLng(38.9072, -77.0369);
        const nycPosition = LatLng(40.7128, -74.0060);

        final distance = GeoUtils.distanceBetween(dcPosition, nycPosition);

        // Allow 5 nm tolerance for rounding
        expect(distance, greaterThan(170));
        expect(distance, lessThan(185));
      });

      test('returns zero for same point', () {
        const point = LatLng(40.7128, -74.0060);
        final distance = GeoUtils.distanceBetween(point, point);

        expect(distance, equals(0.0));
      });

      test('distance is symmetric', () {
        const point1 = LatLng(38.9072, -77.0369);
        const point2 = LatLng(40.7128, -74.0060);

        final distance1 = GeoUtils.distanceBetween(point1, point2);
        final distance2 = GeoUtils.distanceBetween(point2, point1);

        expect(distance1, closeTo(distance2, 0.01));
      });
    });

    group('bearingBetween', () {
      test('calculates bearing between two points', () {
        // North bearing
        const start = LatLng(0.0, 0.0);
        const north = LatLng(1.0, 0.0);

        final bearing = GeoUtils.bearingBetween(start, north);

        // Should be approximately north (0° or 360°)
        expect(bearing, closeTo(0.0, 1.0));
      });

      test('calculates east bearing', () {
        const start = LatLng(0.0, 0.0);
        const east = LatLng(0.0, 1.0);

        final bearing = GeoUtils.bearingBetween(start, east);

        // Should be approximately east (90°)
        expect(bearing, closeTo(90.0, 1.0));
      });

      test('returns bearing in 0-360 range', () {
        const point1 = LatLng(38.9072, -77.0369);
        const point2 = LatLng(40.7128, -74.0060);

        final bearing = GeoUtils.bearingBetween(point1, point2);

        expect(bearing, greaterThanOrEqualTo(0.0));
        expect(bearing, lessThan(360.0));
      });
    });

    group('getTotalRouteDistance', () {
      test('calculates total distance of a route', () {
        final waypoints = [
          Waypoint(
            id: '1',
            position: const LatLng(0.0, 0.0),
            name: 'Start',
            timestamp: DateTime.now(),
          ),
          Waypoint(
            id: '2',
            position: const LatLng(1.0, 0.0),
            name: 'Mid',
            timestamp: DateTime.now(),
          ),
          Waypoint(
            id: '3',
            position: const LatLng(2.0, 0.0),
            name: 'End',
            timestamp: DateTime.now(),
          ),
        ];

        final route = Route(
          id: 'test-route',
          name: 'Test Route',
          waypoints: waypoints,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final distance = GeoUtils.getTotalRouteDistance(route);

        // Should be sum of two 1-degree segments (approximately 60 nm each)
        expect(distance, greaterThan(100.0));
        expect(distance, lessThan(140.0));
      });

      test('returns zero for route with less than 2 waypoints', () {
        final route = Route(
          id: 'empty-route',
          name: 'Empty Route',
          waypoints: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final distance = GeoUtils.getTotalRouteDistance(route);

        expect(distance, equals(0.0));
      });
    });

    group('getDistanceToNextWaypoint', () {
      test('calculates distance to next waypoint', () {
        final waypoints = [
          Waypoint(
            id: '1',
            position: const LatLng(0.0, 0.0),
            name: 'Start',
            timestamp: DateTime.now(),
          ),
          Waypoint(
            id: '2',
            position: const LatLng(1.0, 0.0),
            name: 'Next',
            timestamp: DateTime.now(),
          ),
        ];

        final route = Route(
          id: 'test-route',
          name: 'Test Route',
          waypoints: waypoints,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        const currentPosition = LatLng(0.5, 0.0);
        final distance =
            GeoUtils.getDistanceToNextWaypoint(route, currentPosition, 0);

        // Should be approximately 30 nm (half of 1 degree)
        expect(distance, greaterThan(25.0));
        expect(distance, lessThan(35.0));
      });

      test('returns zero when at last waypoint', () {
        final waypoints = [
          Waypoint(
            id: '1',
            position: const LatLng(0.0, 0.0),
            name: 'Start',
            timestamp: DateTime.now(),
          ),
        ];

        final route = Route(
          id: 'test-route',
          name: 'Test Route',
          waypoints: waypoints,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final distance = GeoUtils.getDistanceToNextWaypoint(
            route, const LatLng(0.0, 0.0), 0);

        expect(distance, equals(0.0));
      });
    });

    group('getBearingToNextWaypoint', () {
      test('calculates bearing to next waypoint', () {
        final waypoints = [
          Waypoint(
            id: '1',
            position: const LatLng(0.0, 0.0),
            name: 'Start',
            timestamp: DateTime.now(),
          ),
          Waypoint(
            id: '2',
            position: const LatLng(1.0, 0.0),
            name: 'Next',
            timestamp: DateTime.now(),
          ),
        ];

        final route = Route(
          id: 'test-route',
          name: 'Test Route',
          waypoints: waypoints,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final bearing = GeoUtils.getBearingToNextWaypoint(
          route,
          const LatLng(0.0, 0.0),
          0,
        );

        // Should be approximately north (0°)
        expect(bearing, closeTo(0.0, 1.0));
      });

      test('returns zero when at last waypoint', () {
        final waypoints = [
          Waypoint(
            id: '1',
            position: const LatLng(0.0, 0.0),
            name: 'Start',
            timestamp: DateTime.now(),
          ),
        ];

        final route = Route(
          id: 'test-route',
          name: 'Test Route',
          waypoints: waypoints,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final bearing = GeoUtils.getBearingToNextWaypoint(
          route,
          const LatLng(0.0, 0.0),
          0,
        );

        expect(bearing, equals(0.0));
      });
    });

    group('crossTrackDistance', () {
      test('returns zero when on the track', () {
        // Midpoint of a north-south line is on the line
        const from = LatLng(0.0, 0.0);
        const to = LatLng(2.0, 0.0);
        const onTrack = LatLng(1.0, 0.0);

        final xte = GeoUtils.crossTrackDistance(from, to, onTrack);

        expect(xte.abs(), lessThan(0.01));
      });

      test('returns positive when right of track', () {
        // Sailing north — position to the east (right)
        const from = LatLng(0.0, 0.0);
        const to = LatLng(2.0, 0.0);
        const rightOfTrack = LatLng(1.0, 0.1);

        final xte = GeoUtils.crossTrackDistance(from, to, rightOfTrack);

        expect(xte, greaterThan(0));
      });

      test('returns negative when left of track', () {
        // Sailing north — position to the west (left)
        const from = LatLng(0.0, 0.0);
        const to = LatLng(2.0, 0.0);
        const leftOfTrack = LatLng(1.0, -0.1);

        final xte = GeoUtils.crossTrackDistance(from, to, leftOfTrack);

        expect(xte, lessThan(0));
      });

      test('magnitude matches approximate distance', () {
        // 0.1° longitude at equator ≈ 6 nm
        const from = LatLng(0.0, 0.0);
        const to = LatLng(2.0, 0.0);
        const offset = LatLng(1.0, 0.1);

        final xte = GeoUtils.crossTrackDistance(from, to, offset);

        expect(xte.abs(), greaterThan(4));
        expect(xte.abs(), lessThan(8));
      });
    });
  });
}
