import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:marine_nav_app/models/route.dart';

void main() {
  group('Waypoint', () {
    test('creates waypoint with all properties', () {
      const position = LatLng(40.7128, -74.0060);
      final now = DateTime.now();

      final waypoint = Waypoint(
        id: 'wp-1',
        position: position,
        name: 'New York',
        description: 'Test waypoint',
        timestamp: now,
      );

      expect(waypoint.id, equals('wp-1'));
      expect(waypoint.position, equals(position));
      expect(waypoint.name, equals('New York'));
      expect(waypoint.description, equals('Test waypoint'));
      expect(waypoint.timestamp, equals(now));
    });

    test('copyWith returns new instance with updated fields', () {
      const position = LatLng(40.7128, -74.0060);
      const newPosition = LatLng(38.9072, -77.0369);
      final now = DateTime.now();

      final waypoint = Waypoint(
        id: 'wp-1',
        position: position,
        name: 'Original',
        timestamp: now,
      );

      final updated = waypoint.copyWith(
        name: 'Updated',
        position: newPosition,
      );

      expect(updated.id, equals(waypoint.id));
      expect(updated.position, equals(newPosition));
      expect(updated.name, equals('Updated'));
      expect(updated.timestamp, equals(waypoint.timestamp));
    });

    test('toString returns expected format', () {
      final waypoint = Waypoint(
        id: 'wp-1',
        position: const LatLng(40.7128, -74.0060),
        name: 'New York',
        timestamp: DateTime.now(),
      );

      expect(
        waypoint.toString(),
        contains('wp-1'),
      );
      expect(
        waypoint.toString(),
        contains('New York'),
      );
    });
  });

  group('Route', () {
    late List<Waypoint> waypoints;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      waypoints = [
        Waypoint(
          id: 'wp-1',
          position: const LatLng(0.0, 0.0),
          name: 'Start',
          timestamp: now,
        ),
        Waypoint(
          id: 'wp-2',
          position: const LatLng(1.0, 0.0),
          name: 'Mid',
          timestamp: now,
        ),
        Waypoint(
          id: 'wp-3',
          position: const LatLng(2.0, 0.0),
          name: 'End',
          timestamp: now,
        ),
      ];
    });

    test('creates route with all properties', () {
      final route = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: waypoints,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        description: 'Test description',
      );

      expect(route.id, equals('route-1'));
      expect(route.name, equals('Test Route'));
      expect(route.waypoints, equals(waypoints));
      expect(route.isActive, equals(true));
      expect(route.createdAt, equals(now));
      expect(route.updatedAt, equals(now));
      expect(route.description, equals('Test description'));
    });

    test('creates inactive route by default', () {
      final route = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: waypoints,
        createdAt: now,
        updatedAt: now,
      );

      expect(route.isActive, equals(false));
    });

    test('copyWith returns new instance with updated fields', () {
      final route = Route(
        id: 'route-1',
        name: 'Original',
        waypoints: waypoints,
        isActive: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = route.copyWith(
        name: 'Updated',
        isActive: true,
      );

      expect(updated.id, equals(route.id));
      expect(updated.name, equals('Updated'));
      expect(updated.isActive, equals(true));
      expect(updated.waypoints, equals(route.waypoints));
    });

    test('getTotalDistance delegates to GeoUtils', () {
      final route = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: waypoints,
        createdAt: now,
        updatedAt: now,
      );

      final distance = route.getTotalDistance();

      // Should be greater than zero for a valid route
      expect(distance, greaterThan(0.0));
    });

    test('getTotalDistance returns zero for empty route', () {
      final route = Route(
        id: 'route-1',
        name: 'Empty Route',
        waypoints: [],
        createdAt: now,
        updatedAt: now,
      );

      final distance = route.getTotalDistance();

      expect(distance, equals(0.0));
    });

    test('distanceToNextWaypoint returns valid distance', () {
      final route = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: waypoints,
        createdAt: now,
        updatedAt: now,
      );

      const currentPosition = LatLng(0.5, 0.0);
      final distance = route.distanceToNextWaypoint(currentPosition, 0);

      expect(distance, greaterThan(0.0));
    });

    test('distanceToNextWaypoint returns zero at last waypoint', () {
      final route = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: waypoints,
        createdAt: now,
        updatedAt: now,
      );

      final lastWaypointIndex = waypoints.length - 1;
      final distance = route.distanceToNextWaypoint(
        waypoints[lastWaypointIndex].position,
        lastWaypointIndex,
      );

      expect(distance, equals(0.0));
    });

    test('bearingToNextWaypoint returns valid bearing', () {
      final route = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: waypoints,
        createdAt: now,
        updatedAt: now,
      );

      final bearing = route.bearingToNextWaypoint(
        waypoints[0].position,
        0,
      );

      expect(bearing, greaterThanOrEqualTo(0.0));
      expect(bearing, lessThan(360.0));
    });

    test('bearingToNextWaypoint returns zero at last waypoint', () {
      final route = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: waypoints,
        createdAt: now,
        updatedAt: now,
      );

      final lastWaypointIndex = waypoints.length - 1;
      final bearing = route.bearingToNextWaypoint(
        waypoints[lastWaypointIndex].position,
        lastWaypointIndex,
      );

      expect(bearing, equals(0.0));
    });

    test('toString returns expected format', () {
      final route = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: waypoints,
        createdAt: now,
        updatedAt: now,
      );

      expect(route.toString(), contains('route-1'));
      expect(route.toString(), contains('Test Route'));
      expect(route.toString(), contains('3'));
    });
  });
}
