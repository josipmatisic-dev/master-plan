import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:marine_nav_app/models/route.dart';

void main() {
  group('Waypoint serialization', () {
    test('toJson/fromJson round-trip with all fields', () {
      final wp = Waypoint(
        id: 'wp1',
        position: const ll.LatLng(43.5, 16.4),
        name: 'Split Harbor',
        description: 'Fuel stop',
        timestamp: DateTime.utc(2025, 6, 15, 10, 30),
      );

      final json = wp.toJson();
      final restored = Waypoint.fromJson(json);

      expect(restored.id, 'wp1');
      expect(restored.position.latitude, 43.5);
      expect(restored.position.longitude, 16.4);
      expect(restored.name, 'Split Harbor');
      expect(restored.description, 'Fuel stop');
      expect(restored.timestamp, DateTime.utc(2025, 6, 15, 10, 30));
    });

    test('toJson/fromJson round-trip without description', () {
      final wp = Waypoint(
        id: 'wp2',
        position: const ll.LatLng(42.0, 15.0),
        name: 'Anchorage',
        timestamp: DateTime.utc(2025, 7, 1),
      );

      final json = wp.toJson();
      expect(json.containsKey('description'), isFalse);
      final restored = Waypoint.fromJson(json);
      expect(restored.description, isNull);
    });

    test('survives jsonEncode/jsonDecode', () {
      final wp = Waypoint(
        id: 'wp3',
        position: const ll.LatLng(44.1, 17.2),
        name: 'Marina <Šibenik>',
        timestamp: DateTime.utc(2025, 8, 20, 14, 0),
      );

      final encoded = jsonEncode(wp.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = Waypoint.fromJson(decoded);

      expect(restored.name, 'Marina <Šibenik>');
      expect(restored.position.latitude, closeTo(44.1, 0.001));
    });
  });

  group('Route serialization', () {
    Route makeRoute({bool withDescription = false}) {
      return Route(
        id: 'r1',
        name: 'Adriatic Crossing',
        waypoints: [
          Waypoint(
            id: 'wp1',
            position: const ll.LatLng(43.5, 16.4),
            name: 'Split',
            timestamp: DateTime.utc(2025, 6, 15, 8, 0),
          ),
          Waypoint(
            id: 'wp2',
            position: const ll.LatLng(42.6, 18.1),
            name: 'Dubrovnik',
            timestamp: DateTime.utc(2025, 6, 15, 18, 0),
          ),
        ],
        isActive: true,
        createdAt: DateTime.utc(2025, 6, 14),
        updatedAt: DateTime.utc(2025, 6, 15),
        description: withDescription ? 'Summer cruise' : null,
      );
    }

    test('toJson/fromJson round-trip with all fields', () {
      final route = makeRoute(withDescription: true);
      final json = route.toJson();
      final restored = Route.fromJson(json);

      expect(restored.id, 'r1');
      expect(restored.name, 'Adriatic Crossing');
      expect(restored.waypoints.length, 2);
      expect(restored.waypoints[0].name, 'Split');
      expect(restored.waypoints[1].name, 'Dubrovnik');
      expect(restored.isActive, isTrue);
      expect(restored.description, 'Summer cruise');
      expect(restored.createdAt, DateTime.utc(2025, 6, 14));
      expect(restored.updatedAt, DateTime.utc(2025, 6, 15));
    });

    test('toJson/fromJson without description', () {
      final route = makeRoute();
      final json = route.toJson();
      expect(json.containsKey('description'), isFalse);
      final restored = Route.fromJson(json);
      expect(restored.description, isNull);
    });

    test('isActive defaults to false when missing', () {
      final json = makeRoute().toJson()..remove('isActive');
      final restored = Route.fromJson(json);
      expect(restored.isActive, isFalse);
    });

    test('empty waypoints list round-trips', () {
      final route = Route(
        id: 'r2',
        name: 'Empty',
        waypoints: const [],
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      );

      final restored = Route.fromJson(route.toJson());
      expect(restored.waypoints, isEmpty);
    });

    test('survives jsonEncode/jsonDecode', () {
      final route = makeRoute(withDescription: true);
      final encoded = jsonEncode(route.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = Route.fromJson(decoded);

      expect(restored.waypoints.length, 2);
      expect(restored.waypoints[0].position.latitude, closeTo(43.5, 0.001));
      expect(restored.waypoints[1].position.longitude, closeTo(18.1, 0.001));
    });
  });
}
