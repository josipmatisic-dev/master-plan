import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/anchor_alarm.dart';
import 'package:marine_nav_app/models/lat_lng.dart';

void main() {
  const anchorPos = LatLng(latitude: 43.5, longitude: 16.4);
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

  group('AnchorAlarm serialization', () {
    test('toJson/fromJson round-trip with safe state', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5083, longitude: 16.4400),
        radiusMeters: 50.0,
        setAt: DateTime.utc(2025, 6, 15, 22, 0),
        currentDistanceMeters: 10.0,
        state: AnchorAlarmState.safe,
        maxDriftMeters: 15.0,
      );
      final restored = AnchorAlarm.fromJson(alarm.toJson());

      expect(restored.anchorPosition.latitude, closeTo(43.5083, 0.0001));
      expect(restored.anchorPosition.longitude, closeTo(16.4400, 0.0001));
      expect(restored.radiusMeters, 50.0);
      expect(restored.currentDistanceMeters, 10.0);
      expect(restored.state, AnchorAlarmState.safe);
      expect(restored.maxDriftMeters, 15.0);
      expect(restored.setAt, DateTime.utc(2025, 6, 15, 22, 0));
    });

    test('toJson/fromJson with triggered state', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 50.0,
        setAt: DateTime.utc(2025, 1, 1),
        currentDistanceMeters: 55.0,
        state: AnchorAlarmState.triggered,
        maxDriftMeters: 55.0,
      );
      final restored = AnchorAlarm.fromJson(alarm.toJson());
      expect(restored.state, AnchorAlarmState.triggered);
      expect(restored.currentDistanceMeters, 55.0);
    });

    test('fromJson defaults missing fields', () {
      final json = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 50.0,
        setAt: DateTime.utc(2025, 1, 1),
      ).toJson()
        ..remove('currentDistanceMeters')
        ..remove('maxDriftMeters');
      final restored = AnchorAlarm.fromJson(json);
      expect(restored.currentDistanceMeters, 0);
      expect(restored.maxDriftMeters, 0);
    });

    test('fromJson defaults to safe for unknown state', () {
      final json = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 50.0,
        setAt: DateTime.utc(2025, 1, 1),
      ).toJson()
        ..['state'] = 'bogus';
      final restored = AnchorAlarm.fromJson(json);
      expect(restored.state, AnchorAlarmState.safe);
    });

    test('survives jsonEncode/jsonDecode', () {
      final alarm = AnchorAlarm(
        anchorPosition: const LatLng(latitude: 43.5, longitude: 16.4),
        radiusMeters: 100.0,
        setAt: DateTime.utc(2025, 8, 1),
        currentDistanceMeters: 41.5,
        state: AnchorAlarmState.warning,
        maxDriftMeters: 42.0,
      );
      final encoded = jsonEncode(alarm.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = AnchorAlarm.fromJson(decoded);
      expect(restored.state, AnchorAlarmState.warning);
      expect(restored.currentDistanceMeters, 41.5);
    });
  });
}
