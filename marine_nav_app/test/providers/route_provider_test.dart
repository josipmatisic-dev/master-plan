import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:marine_nav_app/models/route.dart';
import 'package:marine_nav_app/providers/route_provider.dart';

void main() {
  group('RouteProvider', () {
    late RouteProvider routeProvider;
    late Route testRoute;
    late List<Waypoint> testWaypoints;

    setUp(() {
      routeProvider = RouteProvider();
      testWaypoints = [
        Waypoint(
          id: 'wp-1',
          position: const LatLng(0.0, 0.0),
          name: 'Start',
          timestamp: DateTime.now(),
        ),
        Waypoint(
          id: 'wp-2',
          position: const LatLng(1.0, 0.0),
          name: 'Mid',
          timestamp: DateTime.now(),
        ),
        Waypoint(
          id: 'wp-3',
          position: const LatLng(2.0, 0.0),
          name: 'End',
          timestamp: DateTime.now(),
        ),
      ];

      testRoute = Route(
        id: 'route-1',
        name: 'Test Route',
        waypoints: testWaypoints,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('Initialization', () {
      test('creates provider with no active route', () {
        expect(routeProvider.activeRoute, isNull);
        expect(routeProvider.currentWaypointIndex, equals(-1));
        expect(routeProvider.currentPosition, isNull);
      });

      test('has zero distance metrics with no active route', () {
        expect(routeProvider.distanceToNextWaypoint, equals(0.0));
        expect(routeProvider.bearingToNextWaypoint, equals(0.0));
        expect(routeProvider.totalRouteDistance, equals(0.0));
        expect(routeProvider.distanceRemaining, equals(0.0));
        expect(routeProvider.routeProgress, equals(0.0));
      });
    });

    group('activateRoute', () {
      test('activates route and resets to first waypoint', () {
        routeProvider.activateRoute(testRoute);

        expect(routeProvider.activeRoute, isNotNull);
        expect(routeProvider.activeRoute!.isActive, isTrue);
        expect(routeProvider.activeRoute!.name, equals('Test Route'));
        expect(routeProvider.currentWaypointIndex, equals(0));
        expect(routeProvider.currentPosition, isNull);
      });

      test('notifies listeners when route is activated', () {
        var notified = false;
        routeProvider.addListener(() {
          notified = true;
        });

        routeProvider.activateRoute(testRoute);

        expect(notified, isTrue);
      });

      test('nextWaypoint returns correct waypoint after activation', () {
        routeProvider.activateRoute(testRoute);

        expect(routeProvider.nextWaypoint, isNotNull);
        expect(routeProvider.nextWaypoint!.id, equals('wp-2'));
        expect(routeProvider.nextWaypoint!.name, equals('Mid'));
      });
    });

    group('updatePosition', () {
      test('updates current position', () {
        routeProvider.activateRoute(testRoute);
        const newPosition = LatLng(0.5, 0.0);

        routeProvider.updatePosition(newPosition);

        expect(routeProvider.currentPosition, equals(newPosition));
      });

      test('notifies listeners when position is updated', () {
        routeProvider.activateRoute(testRoute);
        var notified = false;
        routeProvider.addListener(() {
          notified = true;
        });

        routeProvider.updatePosition(const LatLng(0.5, 0.0));

        expect(notified, isTrue);
      });

      test('calculates correct distance to next waypoint', () {
        routeProvider.activateRoute(testRoute);
        const currentPosition = LatLng(0.5, 0.0);

        routeProvider.updatePosition(currentPosition);
        final distance = routeProvider.distanceToNextWaypoint;

        // Should be approximately 30nm (half of 1 degree)
        expect(distance, greaterThan(25.0));
        expect(distance, lessThan(35.0));
      });

      test('calculates correct bearing to next waypoint', () {
        routeProvider.activateRoute(testRoute);
        const currentPosition = LatLng(0.5, 0.0);

        routeProvider.updatePosition(currentPosition);
        final bearing = routeProvider.bearingToNextWaypoint;

        // Should be approximately north (0° or 360°)
        expect(bearing, closeTo(0.0, 2.0));
      });

      test('automatically advances waypoint when reached', () {
        routeProvider.activateRoute(testRoute);

        // Move very close to wp-2
        const nearWaypoint = LatLng(0.99999, 0.00001);
        routeProvider.updatePosition(nearWaypoint);

        expect(routeProvider.currentWaypointIndex, equals(1));
      });
    });

    group('advanceWaypoint', () {
      test('advances to next waypoint when available', () {
        routeProvider.activateRoute(testRoute);
        expect(routeProvider.currentWaypointIndex, equals(0));

        routeProvider.advanceWaypoint();

        expect(routeProvider.currentWaypointIndex, equals(1));
      });

      test('does not advance beyond last waypoint', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.advanceWaypoint(); // 0 -> 1
        routeProvider.advanceWaypoint(); // 1 -> 2
        routeProvider.advanceWaypoint(); // 2 -> 2 (no change)

        expect(routeProvider.currentWaypointIndex, equals(2));
      });

      test('notifies listeners when waypoint is advanced', () {
        routeProvider.activateRoute(testRoute);
        var notified = false;
        routeProvider.addListener(() {
          notified = true;
        });

        routeProvider.advanceWaypoint();

        expect(notified, isTrue);
      });

      test('does nothing if no active route', () {
        routeProvider.advanceWaypoint();
        expect(routeProvider.currentWaypointIndex, equals(-1));
      });
    });

    group('revertWaypoint', () {
      test('reverts to previous waypoint when available', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.advanceWaypoint(); // 0 -> 1
        expect(routeProvider.currentWaypointIndex, equals(1));

        routeProvider.revertWaypoint();

        expect(routeProvider.currentWaypointIndex, equals(0));
      });

      test('does not revert below first waypoint', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.revertWaypoint(); // 0 -> 0 (no change)

        expect(routeProvider.currentWaypointIndex, equals(0));
      });

      test('notifies listeners when waypoint is reverted', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.advanceWaypoint();
        var notified = false;
        routeProvider.addListener(() {
          notified = true;
        });

        routeProvider.revertWaypoint();

        expect(notified, isTrue);
      });

      test('does nothing if no active route', () {
        routeProvider.revertWaypoint();
        expect(routeProvider.currentWaypointIndex, equals(-1));
      });
    });

    group('deactivateRoute', () {
      test('clears active route and resets state', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(0.5, 0.0));
        routeProvider.advanceWaypoint();

        routeProvider.deactivateRoute();

        expect(routeProvider.activeRoute, isNull);
        expect(routeProvider.currentWaypointIndex, equals(-1));
        expect(routeProvider.currentPosition, isNull);
      });

      test('notifies listeners when route is deactivated', () {
        routeProvider.activateRoute(testRoute);
        var notified = false;
        routeProvider.addListener(() {
          notified = true;
        });

        routeProvider.deactivateRoute();

        expect(notified, isTrue);
      });
    });

    group('clearPosition', () {
      test('clears position but keeps active route', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(0.5, 0.0));

        routeProvider.clearPosition();

        expect(routeProvider.activeRoute, isNotNull);
        expect(routeProvider.currentPosition, isNull);
        expect(routeProvider.distanceToNextWaypoint, equals(0.0));
      });

      test('notifies listeners when position is cleared', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(0.5, 0.0));
        var notified = false;
        routeProvider.addListener(() {
          notified = true;
        });

        routeProvider.clearPosition();

        expect(notified, isTrue);
      });
    });

    group('Distance and Progress Metrics', () {
      test('calculates total route distance correctly', () {
        routeProvider.activateRoute(testRoute);

        final totalDistance = routeProvider.totalRouteDistance;

        // Should be ~120nm (2 segments of ~60nm each)
        expect(totalDistance, greaterThan(100.0));
        expect(totalDistance, lessThan(140.0));
      });

      test('calculates distance remaining correctly', () {
        routeProvider.activateRoute(testRoute);
        const currentPosition = LatLng(0.5, 0.0);
        routeProvider.updatePosition(currentPosition);

        final remaining = routeProvider.distanceRemaining;

        // Should be less than total distance
        expect(remaining, lessThan(routeProvider.totalRouteDistance));
      });

      test('calculates route progress correctly', () {
        routeProvider.activateRoute(testRoute);
        const currentPosition = LatLng(0.5, 0.0);
        routeProvider.updatePosition(currentPosition);

        final progress = routeProvider.routeProgress;

        // Should be between 0 and 1
        expect(progress, greaterThanOrEqualTo(0.0));
        expect(progress, lessThanOrEqualTo(1.0));
      });

      test('route progress increases with position', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(0.5, 0.0));
        final progress1 = routeProvider.routeProgress;

        routeProvider.updatePosition(const LatLng(1.5, 0.0));
        final progress2 = routeProvider.routeProgress;

        expect(progress2, greaterThanOrEqualTo(progress1));
      });
    });

    group('ETA Calculations', () {
      test('calculates ETA to next waypoint with speed', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(0.5, 0.0));

        final eta = routeProvider.getETAToNextWaypoint(10.0);

        // ETA should be positive
        expect(eta, greaterThan(0.0));
      });

      test('returns zero ETA with zero speed', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(0.5, 0.0));

        final eta = routeProvider.getETAToNextWaypoint(0.0);

        expect(eta, equals(0.0));
      });

      test('returns zero ETA with no next waypoint', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(2.0, 0.0));
        routeProvider.advanceWaypoint();
        routeProvider.advanceWaypoint();

        final eta = routeProvider.getETAToNextWaypoint(10.0);

        expect(eta, equals(0.0));
      });

      test('ETA decreases with higher speed', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(0.5, 0.0));

        final eta1 = routeProvider.getETAToNextWaypoint(10.0);
        final eta2 = routeProvider.getETAToNextWaypoint(20.0);

        expect(eta2, lessThan(eta1));
      });
    });

    group('Route CRUD (in-memory)', () {
      test('savedRoutes starts empty', () {
        expect(routeProvider.savedRoutes, isEmpty);
      });

      test('createRoute adds to savedRoutes and returns the route', () async {
        final route = await routeProvider.createRoute(
          name: 'New Route',
          waypoints: testWaypoints,
          description: 'A test route',
        );

        expect(route.name, equals('New Route'));
        expect(route.waypoints.length, equals(3));
        expect(route.description, equals('A test route'));
        expect(routeProvider.savedRoutes.length, equals(1));
        expect(routeProvider.savedRoutes.first.id, equals(route.id));
      });

      test('saveRoute updates existing route with same ID', () async {
        await routeProvider.saveRoute(testRoute);
        expect(routeProvider.savedRoutes.length, equals(1));

        final updated = Route(
          id: testRoute.id,
          name: 'Updated Route',
          waypoints: testWaypoints,
          createdAt: testRoute.createdAt,
          updatedAt: DateTime.now(),
        );
        await routeProvider.saveRoute(updated);

        expect(routeProvider.savedRoutes.length, equals(1));
        expect(routeProvider.savedRoutes.first.name, equals('Updated Route'));
      });

      test('deleteRoute removes from list', () async {
        await routeProvider.saveRoute(testRoute);
        expect(routeProvider.savedRoutes.length, equals(1));

        await routeProvider.deleteRoute(testRoute.id);

        expect(routeProvider.savedRoutes, isEmpty);
      });

      test('deleteRoute deactivates if the deleted route was active', () async {
        await routeProvider.saveRoute(testRoute);
        routeProvider.activateRoute(testRoute);
        expect(routeProvider.activeRoute, isNotNull);

        await routeProvider.deleteRoute(testRoute.id);

        expect(routeProvider.activeRoute, isNull);
        expect(routeProvider.savedRoutes, isEmpty);
      });
    });

    group('crossTrackError', () {
      test('returns zero when no active route', () {
        expect(routeProvider.crossTrackError, 0.0);
      });

      test('returns zero when no position set', () {
        routeProvider.activateRoute(testRoute);
        expect(routeProvider.crossTrackError, 0.0);
      });

      test('returns near-zero when on track', () {
        routeProvider.activateRoute(testRoute);
        // Position on the line from (0,0) to (1,0) — due north
        routeProvider.updatePosition(const LatLng(0.5, 0.0));
        expect(routeProvider.crossTrackError.abs(), lessThan(0.01));
      });

      test('returns positive when right of track', () {
        routeProvider.activateRoute(testRoute);
        // East of a north-bound track = right
        routeProvider.updatePosition(const LatLng(0.5, 0.1));
        expect(routeProvider.crossTrackError, greaterThan(0));
      });

      test('returns negative when left of track', () {
        routeProvider.activateRoute(testRoute);
        // West of a north-bound track = left
        routeProvider.updatePosition(const LatLng(0.5, -0.1));
        expect(routeProvider.crossTrackError, lessThan(0));
      });

      test('returns zero at last waypoint', () {
        routeProvider.activateRoute(testRoute);
        routeProvider.updatePosition(const LatLng(0.5, 0.0));
        // Advance to last waypoint
        routeProvider.advanceWaypoint(); // index 1
        routeProvider.advanceWaypoint(); // index 2 (last)
        expect(routeProvider.crossTrackError, 0.0);
      });
    });
  });
}
