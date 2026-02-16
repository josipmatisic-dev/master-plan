import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/services/mob_service.dart';

void main() {
  group('MobMarker', () {
    test('creates from BoatPosition', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime(2024, 6, 1, 12, 0),
        speedKnots: 6.5,
        courseTrue: 180.0,
      );

      final marker = MobMarker.fromPosition(pos);
      expect(marker.position.latitude, 43.5);
      expect(marker.position.longitude, 16.4);
      expect(marker.speedKnots, 6.5);
      expect(marker.courseTrue, 180.0);
      expect(marker.state, MobState.active);
      expect(marker.id, isNotEmpty);
    });

    test('copyWith updates state', () {
      final marker = MobMarker(
        id: '1',
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime(2024, 6, 1),
      );

      final recovered = marker.copyWith(state: MobState.recovered);
      expect(recovered.state, MobState.recovered);
      expect(recovered.id, '1');
      expect(recovered.position.latitude, 43.5);
    });

    test('JSON serialization round-trip', () {
      final marker = MobMarker(
        id: 'test-123',
        position: const LatLng(latitude: 43.5081, longitude: 16.4402),
        timestamp: DateTime.utc(2024, 6, 1, 12, 0),
        state: MobState.active,
        speedKnots: 7.2,
        courseTrue: 225.0,
      );

      final json = marker.toJson();
      final restored = MobMarker.fromJson(json);

      expect(restored.id, 'test-123');
      expect(restored.position.latitude, 43.5081);
      expect(restored.position.longitude, 16.4402);
      expect(restored.state, MobState.active);
      expect(restored.speedKnots, 7.2);
      expect(restored.courseTrue, 225.0);
    });

    test('JSON handles null optional fields', () {
      final marker = MobMarker(
        id: 'test',
        position: const LatLng(latitude: 0, longitude: 0),
        timestamp: DateTime.utc(2024),
      );

      final json = marker.toJson();
      expect(json.containsKey('speedKnots'), false);
      expect(json.containsKey('courseTrue'), false);

      final restored = MobMarker.fromJson(json);
      expect(restored.speedKnots, isNull);
      expect(restored.courseTrue, isNull);
    });
  });

  group('MobService', () {
    late MobService service;

    setUp(() {
      service = MobService();
    });

    test('initial state is empty', () {
      expect(service.markers, isEmpty);
      expect(service.activeMarkers, isEmpty);
      expect(service.hasActiveMob, false);
      expect(service.latestActiveMob, isNull);
    });

    test('markMob creates active marker', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
        speedKnots: 5.0,
      );

      final marker = service.markMob(pos);
      expect(marker.state, MobState.active);
      expect(service.markers.length, 1);
      expect(service.hasActiveMob, true);
      expect(service.latestActiveMob, isNotNull);
    });

    test('recover marks marker as recovered', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
      );

      final marker = service.markMob(pos);
      service.recover(marker.id);

      expect(service.markers.first.state, MobState.recovered);
      expect(service.hasActiveMob, false);
    });

    test('cancel marks marker as cancelled', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
      );

      final marker = service.markMob(pos);
      service.cancel(marker.id);

      expect(service.markers.first.state, MobState.cancelled);
      expect(service.hasActiveMob, false);
    });

    test('multiple MOBs tracked independently', () {
      final pos1 = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
      );
      final pos2 = BoatPosition(
        position: const LatLng(latitude: 43.6, longitude: 16.5),
        timestamp: DateTime.now(),
      );

      final m1 = service.markMob(pos1);
      service.markMob(pos2);

      expect(service.activeMarkers.length, 2);

      service.recover(m1.id);
      expect(service.activeMarkers.length, 1);
      expect(service.markers.length, 2);
    });

    test('clearResolved removes non-active markers', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
      );

      final m1 = service.markMob(pos);
      service.markMob(pos);
      service.recover(m1.id);

      expect(service.markers.length, 2);
      service.clearResolved();
      expect(service.markers.length, 1);
      expect(service.markers.first.state, MobState.active);
    });

    test('notifies listeners on state changes', () {
      int notifications = 0;
      service.addListener(() => notifications++);

      final pos = BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
      );

      service.markMob(pos); // +1
      final m = service.markers.first;
      service.recover(m.id); // +1
      service.clearResolved(); // +1

      expect(notifications, 3);
    });
  });
}
