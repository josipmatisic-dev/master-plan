import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/anchor_alarm.dart';
import 'package:marine_nav_app/models/lat_lng.dart';

void main() {
  final anchorPos = const LatLng(latitude: 43.5, longitude: 16.4);
  final setTime = DateTime(2026, 2, 16, 12, 0);

  group('AnchorAlarm', () {
    test('defaults to safe state and zero distance', () {
      final alarm = AnchorAlarm(
        anchorPosition: anchorPos,
        radiusMeters: 50,
        setAt: setTime,
      );
      expect(alarm.state, AnchorAlarmState.safe);
      expect(alarm.currentDistanceMeters, 0);
      expect(alarm.maxDriftMeters, 0);
      expect(alarm.isSafe, isTrue);
      expect(alarm.isTriggered, isFalse);
    });

    test('warningThresholdMeters is 80% of radius', () {
      final alarm = AnchorAlarm(
        anchorPosition: anchorPos,
        radiusMeters: 100,
        setAt: setTime,
      );
      expect(alarm.warningThresholdMeters, 80.0);
    });

    test('distanceToAlarmMeters clamps correctly', () {
      final alarm = AnchorAlarm(
        anchorPosition: anchorPos,
        radiusMeters: 50,
        setAt: setTime,
        currentDistanceMeters: 30,
      );
      expect(alarm.distanceToAlarmMeters, 20);
    });

    test('driftRatio computes correctly', () {
      final alarm = AnchorAlarm(
        anchorPosition: anchorPos,
        radiusMeters: 100,
        setAt: setTime,
        currentDistanceMeters: 50,
      );
      expect(alarm.driftRatio, 0.5);
    });

    test('driftRatio clamps at 2.0', () {
      final alarm = AnchorAlarm(
        anchorPosition: anchorPos,
        radiusMeters: 50,
        setAt: setTime,
        currentDistanceMeters: 200,
      );
      expect(alarm.driftRatio, 2.0);
    });

    test('driftRatio returns 0 when radius is 0', () {
      final alarm = AnchorAlarm(
        anchorPosition: anchorPos,
        radiusMeters: 0,
        setAt: setTime,
      );
      expect(alarm.driftRatio, 0);
    });

    group('withDistance', () {
      test('returns safe when within threshold', () {
        final alarm = AnchorAlarm(
          anchorPosition: anchorPos,
          radiusMeters: 100,
          setAt: setTime,
        );
        final updated = alarm.withDistance(50);
        expect(updated.state, AnchorAlarmState.safe);
        expect(updated.currentDistanceMeters, 50);
      });

      test('returns warning when >= 80% of radius', () {
        final alarm = AnchorAlarm(
          anchorPosition: anchorPos,
          radiusMeters: 100,
          setAt: setTime,
        );
        final updated = alarm.withDistance(85);
        expect(updated.state, AnchorAlarmState.warning);
      });

      test('returns triggered when >= radius', () {
        final alarm = AnchorAlarm(
          anchorPosition: anchorPos,
          radiusMeters: 100,
          setAt: setTime,
        );
        final updated = alarm.withDistance(100);
        expect(updated.state, AnchorAlarmState.triggered);
        expect(updated.isTriggered, isTrue);
      });

      test('tracks maxDriftMeters', () {
        final alarm = AnchorAlarm(
          anchorPosition: anchorPos,
          radiusMeters: 100,
          setAt: setTime,
          maxDriftMeters: 70,
        );
        final updated = alarm.withDistance(80);
        expect(updated.maxDriftMeters, 80);
      });

      test('preserves maxDriftMeters when decreasing', () {
        final alarm = AnchorAlarm(
          anchorPosition: anchorPos,
          radiusMeters: 100,
          setAt: setTime,
          maxDriftMeters: 90,
        );
        final updated = alarm.withDistance(50);
        expect(updated.maxDriftMeters, 90);
      });
    });

    test('toString contains key info', () {
      final alarm = AnchorAlarm(
        anchorPosition: anchorPos,
        radiusMeters: 50,
        setAt: setTime,
        currentDistanceMeters: 25,
        state: AnchorAlarmState.safe,
      );
      final str = alarm.toString();
      expect(str, contains('43.5'));
      expect(str, contains('16.4'));
      expect(str, contains('50m'));
      expect(str, contains('25.0m'));
      expect(str, contains('safe'));
    });
  });
}
