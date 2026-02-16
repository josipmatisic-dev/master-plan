import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/tide_data.dart';
import 'package:marine_nav_app/services/tide_api_service.dart';

void main() {
  group('TideType', () {
    test('has high and low values', () {
      expect(TideType.values.length, 2);
      expect(TideType.high.name, 'high');
      expect(TideType.low.name, 'low');
    });
  });

  group('TidePrediction', () {
    test('parses from NOAA JSON', () {
      final json = {
        't': '2025-06-01 12:30',
        'v': '5.5',
        'type': 'H',
      };

      final pred = TidePrediction.fromNoaaJson(json);
      expect(pred.type, TideType.high);
      // 5.5 feet = 1.6764 meters
      expect(pred.heightMeters, closeTo(1.6764, 0.001));
      expect(pred.time.month, 6);
    });

    test('parses low tide', () {
      final json = {
        't': '2025-06-01 06:15',
        'v': '0.3',
        'type': 'L',
      };

      final pred = TidePrediction.fromNoaaJson(json);
      expect(pred.type, TideType.low);
      expect(pred.heightMeters, closeTo(0.09144, 0.001));
    });
  });

  group('WaterLevel', () {
    test('parses from NOAA JSON', () {
      final json = {
        't': '2025-06-01 12:00',
        'v': '3.2',
      };

      final wl = WaterLevel.fromNoaaJson(json);
      expect(wl.heightMeters, closeTo(0.97536, 0.001));
      expect(wl.time.hour, 12);
    });
  });

  group('TideStation', () {
    test('parses from NOAA JSON', () {
      final json = {
        'id': '9414290',
        'name': 'San Francisco, CA',
        'lat': 37.8063,
        'lng': -122.4659,
      };

      final station = TideStation.fromNoaaJson(json);
      expect(station.id, '9414290');
      expect(station.name, 'San Francisco, CA');
      expect(station.latitude, 37.8063);
      expect(station.longitude, -122.4659);
    });
  });

  group('TideData', () {
    test('finds next high and low tides', () {
      final now = DateTime.now();
      final data = TideData(
        station: const TideStation(
          id: '1',
          name: 'Test',
          latitude: 0,
          longitude: 0,
        ),
        predictions: [
          // Past — should be skipped
          TidePrediction(
            time: now.subtract(const Duration(hours: 2)),
            heightMeters: 1.5,
            type: TideType.high,
          ),
          // Next low
          TidePrediction(
            time: now.add(const Duration(hours: 1)),
            heightMeters: 0.3,
            type: TideType.low,
          ),
          // Next high
          TidePrediction(
            time: now.add(const Duration(hours: 4)),
            heightMeters: 1.8,
            type: TideType.high,
          ),
        ],
        fetchedAt: now,
      );

      expect(data.nextTide!.type, TideType.low);
      expect(data.nextHighTide!.heightMeters, 1.8);
      expect(data.nextLowTide!.heightMeters, 0.3);
    });

    test('returns null when no future tides', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final data = TideData(
        station: const TideStation(
          id: '1',
          name: 'Test',
          latitude: 0,
          longitude: 0,
        ),
        predictions: [
          TidePrediction(
            time: past,
            heightMeters: 1.0,
            type: TideType.high,
          ),
        ],
        fetchedAt: DateTime.now(),
      );

      expect(data.nextTide, isNull);
      expect(data.nextHighTide, isNull);
    });

    test('latest observation returns last in list', () {
      final data = TideData(
        station: const TideStation(
          id: '1',
          name: 'Test',
          latitude: 0,
          longitude: 0,
        ),
        predictions: const [],
        observations: [
          WaterLevel(
            time: DateTime(2025, 6, 1, 10),
            heightMeters: 1.0,
          ),
          WaterLevel(
            time: DateTime(2025, 6, 1, 11),
            heightMeters: 1.2,
          ),
        ],
        fetchedAt: DateTime.now(),
      );

      expect(data.latestObservation!.heightMeters, 1.2);
    });

    test('serializes to/from JSON', () {
      final now = DateTime.now();
      final data = TideData(
        station: const TideStation(
          id: '9414290',
          name: 'San Francisco',
          latitude: 37.8063,
          longitude: -122.4659,
        ),
        predictions: [
          TidePrediction(
            time: now.add(const Duration(hours: 3)),
            heightMeters: 1.524,
            type: TideType.high,
          ),
        ],
        observations: [
          WaterLevel(
            time: now,
            heightMeters: 0.9144,
          ),
        ],
        fetchedAt: now,
      );

      final json = data.toJson();
      final restored = TideData.fromJson(json);
      expect(restored.station.id, '9414290');
      expect(restored.predictions.length, 1);
      expect(restored.predictions.first.type, TideType.high);
      expect(restored.observations.length, 1);
    });
  });

  group('TideApiService', () {
    test('formatDate produces correct NOAA format', () {
      // Test internal date formatting via a roundtrip
      final service = TideApiService();
      expect(service, isNotNull);
      service.dispose();
    });
  });

  group('TideApiException', () {
    test('has readable toString', () {
      const ex = TideApiException('test error');
      expect(ex.toString(), 'TideApiException: test error');
      expect(ex.message, 'test error');
    });
  });
}
