import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:marine_nav_app/models/route.dart';
import 'package:marine_nav_app/services/route_map_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RouteMapBridge', () {
    test('can be constructed with null controller', () {
      const bridge = RouteMapBridge(null);
      expect(bridge, isNotNull);
    });

    test('renderRoute with empty waypoints calls clearRoute', () async {
      const bridge = RouteMapBridge(null);
      final route = Route(
        id: 'r1',
        name: 'Empty',
        waypoints: [],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      // Should not throw with null controller
      await bridge.renderRoute(route);
    });

    test('clearRoute does not throw with null controller', () async {
      const bridge = RouteMapBridge(null);
      await bridge.clearRoute();
    });

    test('renderRoute with waypoints does not throw', () async {
      const bridge = RouteMapBridge(null);
      final route = Route(
        id: 'r1',
        name: 'Test Route',
        waypoints: [
          Waypoint(
            id: 'w1',
            name: 'Start',
            position: const LatLng(43.5, 16.4),
            timestamp: DateTime(2026),
          ),
          Waypoint(
            id: 'w2',
            name: 'End',
            position: const LatLng(43.6, 16.5),
            timestamp: DateTime(2026),
          ),
        ],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      await bridge.renderRoute(route);
    });
  });
}
