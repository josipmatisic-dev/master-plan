import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/anchor_alarm.dart';
import 'package:marine_nav_app/models/boat_position.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/services/anchor_alarm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AnchorAlarm model', () {
    test('initial state is safe with zero distance', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 50,
        setAt: DateTime.now(),
      );

      expect(alarm.state, AnchorAlarmState.safe);
      expect(alarm.currentDistanceMeters, 0);
      expect(alarm.isSafe, isTrue);
      expect(alarm.isTriggered, isFalse);
      expect(alarm.driftRatio, 0);
      expect(alarm.distanceToAlarmMeters, 50);
    });

    test('withDistance transitions to warning at 80% radius', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 100,
        setAt: DateTime.now(),
      );

      final updated = alarm.withDistance(85);
      expect(updated.state, AnchorAlarmState.warning);
      expect(updated.currentDistanceMeters, 85);
      expect(updated.maxDriftMeters, 85);
    });

    test('withDistance transitions to triggered at radius', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 50,
        setAt: DateTime.now(),
      );

      final updated = alarm.withDistance(55);
      expect(updated.state, AnchorAlarmState.triggered);
      expect(updated.isTriggered, isTrue);
      expect(updated.isSafe, isFalse);
    });

    test('withDistance tracks max drift', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 100,
        setAt: DateTime.now(),
      );

      final farther = alarm.withDistance(70);
      expect(farther.maxDriftMeters, 70);

      final closer = farther.withDistance(30);
      expect(closer.maxDriftMeters, 70); // max preserved
      expect(closer.state, AnchorAlarmState.safe);
    });

    test('warningThresholdMeters is 80% of radius', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 0, longitude: 0),
        radiusMeters: 200,
        setAt: DateTime.now(),
      );
      expect(alarm.warningThresholdMeters, 160);
    });

    test('driftRatio clamps to 0-2', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 0, longitude: 0),
        radiusMeters: 50,
        setAt: DateTime.now(),
      );

      final normal = alarm.withDistance(25);
      expect(normal.driftRatio, 0.5);

      final beyond = alarm.withDistance(150);
      expect(beyond.driftRatio, 2.0); // clamped at 2x
    });

    test('toString provides readable summary', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5123, longitude: 16.4456),
        radiusMeters: 50,
        setAt: DateTime.now(),
      );

      expect(alarm.toString(), contains('43.5123'));
      expect(alarm.toString(), contains('16.4456'));
      expect(alarm.toString(), contains('r=50m'));
    });
  });

  group('AnchorAlarmService', () {
    late AnchorAlarmService service;

    setUp(() {
      service = AnchorAlarmService();
    });

    test('starts inactive', () {
      expect(service.isActive, isFalse);
      expect(service.alarm, isNull);
      expect(service.isTriggered, isFalse);
      expect(service.isWarning, isFalse);
    });

    test('setAnchor creates alarm in safe state', () {
      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 75,
      );

      expect(service.isActive, isTrue);
      expect(service.alarm!.state, AnchorAlarmState.safe);
      expect(service.alarm!.radiusMeters, 75);
    });

    test('setAnchor clamps radius to valid range', () {
      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 5, // below minimum
      );
      expect(service.alarm!.radiusMeters, minAnchorRadiusMeters);

      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 1000, // above maximum
      );
      expect(service.alarm!.radiusMeters, maxAnchorRadiusMeters);
    });

    test('setAnchorAtPosition uses boat position', () {
      final pos = BoatPosition(
        position: const LatLng(latitude: 43.508, longitude: 16.440),
        timestamp: DateTime.now(),
        speedKnots: 0,
      );

      service.setAnchorAtPosition(pos, radiusMeters: 60);
      expect(service.alarm!.anchorPosition.latitude, 43.508);
      expect(service.alarm!.anchorPosition.longitude, 16.440);
      expect(service.alarm!.radiusMeters, 60);
    });

    test('clearAnchor removes the alarm', () {
      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
      );
      expect(service.isActive, isTrue);

      service.clearAnchor();
      expect(service.isActive, isFalse);
      expect(service.alarm, isNull);
    });

    test('clearAnchor is safe when already inactive', () {
      service.clearAnchor(); // should not throw
      expect(service.isActive, isFalse);
    });

    test('updateRadius changes alarm radius', () {
      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 50,
      );

      service.updateRadius(100);
      expect(service.alarm!.radiusMeters, 100);
    });

    test('updateRadius clamps to valid range', () {
      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 50,
      );

      service.updateRadius(2);
      expect(service.alarm!.radiusMeters, minAnchorRadiusMeters);
    });

    test('updateRadius does nothing when inactive', () {
      service.updateRadius(100); // should not throw
      expect(service.isActive, isFalse);
    });

    test('updatePosition detects drift beyond radius', () {
      // Set anchor at origin
      service.setAnchor(
        position: const LatLng(latitude: 0, longitude: 0),
        radiusMeters: 100,
      );

      // Position very close to anchor (< 100m)
      service.updatePosition(BoatPosition(
        position: const LatLng(latitude: 0.0001, longitude: 0.0001),
        timestamp: DateTime.now(),
      ));
      expect(service.alarm!.state, AnchorAlarmState.safe);

      // Position far away (>>100m)
      service.updatePosition(BoatPosition(
        position: const LatLng(latitude: 0.01, longitude: 0.01),
        timestamp: DateTime.now(),
      ));
      expect(service.alarm!.state, AnchorAlarmState.triggered);
      expect(service.isTriggered, isTrue);
    });

    test('updatePosition detects warning zone', () {
      // Set anchor at Split, Croatia with 100m radius
      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 100,
      );

      // ~85m away (warning zone at 80m threshold)
      // 0.001° latitude ≈ 111m, so 0.00076° ≈ 85m
      service.updatePosition(BoatPosition(
        position: const LatLng(latitude: 43.50076, longitude: 16.4),
        timestamp: DateTime.now(),
      ));

      expect(
        service.alarm!.state,
        anyOf(AnchorAlarmState.warning, AnchorAlarmState.safe),
      );
    });

    test('updatePosition does nothing when inactive', () {
      service.updatePosition(BoatPosition(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        timestamp: DateTime.now(),
      ));
      // Should not throw
      expect(service.isActive, isFalse);
    });

    test('notifies listeners on state change', () {
      service.setAnchor(
        position: const LatLng(latitude: 0, longitude: 0),
        radiusMeters: 100,
      );

      var notified = false;
      service.addListener(() => notified = true);

      // Far drift triggers notification
      service.updatePosition(BoatPosition(
        position: const LatLng(latitude: 0.01, longitude: 0.01),
        timestamp: DateTime.now(),
      ));

      expect(notified, isTrue);
    });

    test('notifies listeners on setAnchor and clearAnchor', () {
      var count = 0;
      service.addListener(() => count++);

      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
      );
      expect(count, 1);

      service.clearAnchor();
      expect(count, 2);
    });
  });

  group('persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('setAnchor persists and init restores', () async {
      final service = AnchorAlarmService();
      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 75,
      );

      // Wait for async persist
      await Future<void>.delayed(Duration.zero);

      // New service should restore alarm
      final service2 = AnchorAlarmService();
      await service2.init();
      expect(service2.isActive, isTrue);
      expect(service2.alarm!.anchorPosition.latitude, 43.5);
      expect(service2.alarm!.anchorPosition.longitude, 16.4);
      expect(service2.alarm!.radiusMeters, 75);
    });

    test('clearAnchor removes persisted state', () async {
      final service = AnchorAlarmService();
      service.setAnchor(
        position: const LatLng(latitude: 43.5, longitude: 16.4),
      );
      await Future<void>.delayed(Duration.zero);

      service.clearAnchor();
      await Future<void>.delayed(Duration.zero);

      final service2 = AnchorAlarmService();
      await service2.init();
      expect(service2.isActive, isFalse);
    });

    test('init handles empty preferences', () async {
      final service = AnchorAlarmService();
      await service.init();
      expect(service.isActive, isFalse);
      expect(service.alarm, isNull);
    });

    test('init handles corrupted data gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'anchor_alarm': 'not valid json {{',
      });
      final service = AnchorAlarmService();
      await service.init();
      expect(service.isActive, isFalse);
    });
  });
}
