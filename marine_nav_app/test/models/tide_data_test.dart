import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/tide_data.dart';

void main() {
  group('TidePrediction', () {
    test('fromNoaaJson parses high tide', () {
      final json = {'t': '2026-02-16 12:00', 'v': '5.000', 'type': 'H'};
      final pred = TidePrediction.fromNoaaJson(json);
      expect(pred.type, TideType.high);
      expect(pred.heightMeters, closeTo(5.0 * 0.3048, 0.001));
    });

    test('fromNoaaJson parses low tide', () {
      final json = {'t': '2026-02-16 18:00', 'v': '1.500', 'type': 'L'};
      final pred = TidePrediction.fromNoaaJson(json);
      expect(pred.type, TideType.low);
    });

    test('toString contains type and height', () {
      final pred = TidePrediction(
        time: DateTime(2026, 2, 16, 12),
        heightMeters: 1.5,
        type: TideType.high,
      );
      expect(pred.toString(), contains('high'));
      expect(pred.toString(), contains('1.50'));
    });
  });

  group('WaterLevel', () {
    test('fromNoaaJson parses observation', () {
      final json = {'t': '2026-02-16 12:00', 'v': '3.000'};
      final level = WaterLevel.fromNoaaJson(json);
      expect(level.heightMeters, closeTo(3.0 * 0.3048, 0.001));
    });
  });

  group('CurrentPrediction', () {
    test('fromNoaaJson parses current', () {
      final json = {
        'Time': '2026-02-16 12:00',
        'Velocity_Major': '1.5',
        'meanFloodDir': '180',
      };
      final current = CurrentPrediction.fromNoaaJson(json);
      expect(current.speedKnots, 1.5);
      expect(current.directionDegrees, 180);
    });

    test('fromNoaaJson uses abs for negative velocity', () {
      final json = {
        'Time': '2026-02-16 12:00',
        'Velocity_Major': '-2.0',
        'meanFloodDir': '90',
      };
      final current = CurrentPrediction.fromNoaaJson(json);
      expect(current.speedKnots, 2.0);
    });
  });

  group('TideStation', () {
    test('fromNoaaJson parses station', () {
      final json = {
        'id': '9414290',
        'name': 'San Francisco',
        'lat': 37.806,
        'lng': -122.465,
      };
      final station = TideStation.fromNoaaJson(json);
      expect(station.id, '9414290');
      expect(station.name, 'San Francisco');
      expect(station.latitude, 37.806);
    });

    test('toString contains id and name', () {
      const station = TideStation(
        id: '123',
        name: 'TestPort',
        latitude: 0,
        longitude: 0,
      );
      expect(station.toString(), 'TideStation(123: TestPort)');
    });
  });

  group('TideData', () {
    const station = TideStation(
      id: '9414290',
      name: 'SF',
      latitude: 37.8,
      longitude: -122.5,
    );
    final now = DateTime.now();
    final future1 = now.add(const Duration(hours: 2));
    final future2 = now.add(const Duration(hours: 5));
    final past = now.subtract(const Duration(hours: 2));

    test('nextTide returns first future prediction', () {
      final data = TideData(
        station: station,
        predictions: [
          TidePrediction(time: past, heightMeters: 1.0, type: TideType.low),
          TidePrediction(
            time: future1,
            heightMeters: 2.0,
            type: TideType.high,
          ),
          TidePrediction(
            time: future2,
            heightMeters: 0.5,
            type: TideType.low,
          ),
        ],
        fetchedAt: now,
      );
      expect(data.nextTide!.type, TideType.high);
    });

    test('nextHighTide skips low tides', () {
      final data = TideData(
        station: station,
        predictions: [
          TidePrediction(
            time: future1,
            heightMeters: 0.5,
            type: TideType.low,
          ),
          TidePrediction(
            time: future2,
            heightMeters: 2.0,
            type: TideType.high,
          ),
        ],
        fetchedAt: now,
      );
      expect(data.nextHighTide!.heightMeters, 2.0);
    });

    test('nextLowTide skips high tides', () {
      final data = TideData(
        station: station,
        predictions: [
          TidePrediction(
            time: future1,
            heightMeters: 2.0,
            type: TideType.high,
          ),
          TidePrediction(
            time: future2,
            heightMeters: 0.5,
            type: TideType.low,
          ),
        ],
        fetchedAt: now,
      );
      expect(data.nextLowTide!.heightMeters, 0.5);
    });

    test('latestObservation returns last entry', () {
      final data = TideData(
        station: station,
        predictions: const [],
        observations: [
          WaterLevel(time: past, heightMeters: 1.0),
          WaterLevel(time: now, heightMeters: 1.5),
        ],
        fetchedAt: now,
      );
      expect(data.latestObservation!.heightMeters, 1.5);
    });

    test('latestObservation returns null when empty', () {
      final data = TideData(
        station: station,
        predictions: const [],
        fetchedAt: now,
      );
      expect(data.latestObservation, isNull);
    });

    test('JSON round-trip preserves data', () {
      final data = TideData(
        station: station,
        predictions: [
          TidePrediction(
            time: DateTime.utc(2026, 2, 16, 12),
            heightMeters: 1.5 * 0.3048,
            type: TideType.high,
          ),
        ],
        observations: [
          WaterLevel(
            time: DateTime.utc(2026, 2, 16, 10),
            heightMeters: 1.2 * 0.3048,
          ),
        ],
        fetchedAt: DateTime.utc(2026, 2, 16, 11),
      );
      final json = data.toJson();
      final restored = TideData.fromJson(json);
      expect(restored.station.id, data.station.id);
      expect(restored.predictions.length, 1);
      expect(restored.observations.length, 1);
      expect(restored.predictions[0].type, TideType.high);
    });
  });
}
