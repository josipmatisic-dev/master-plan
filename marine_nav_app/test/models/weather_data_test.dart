import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/weather_data.dart';

void main() {
  group('WindDataPoint', () {
    const position = LatLng(latitude: 59.91, longitude: 10.75);

    test('constructs with required fields', () {
      final point = WindDataPoint(
        position: position,
        speedKnots: 15.0,
        directionDegrees: 270.0,
      );

      expect(point.position, position);
      expect(point.speedKnots, 15.0);
      expect(point.directionDegrees, 270.0);
    });

    test('beaufortScale returns correct values', () {
      final calm = WindDataPoint(
        position: position,
        speedKnots: 0.5,
        directionDegrees: 0,
      );
      expect(calm.beaufortScale, 0);

      final gentle = WindDataPoint(
        position: position,
        speedKnots: 8.0,
        directionDegrees: 0,
      );
      expect(gentle.beaufortScale, 3);

      final nearGale = WindDataPoint(
        position: position,
        speedKnots: 30.0,
        directionDegrees: 0,
      );
      expect(nearGale.beaufortScale, 7);

      final hurricane = WindDataPoint(
        position: position,
        speedKnots: 70.0,
        directionDegrees: 0,
      );
      expect(hurricane.beaufortScale, 12);
    });

    test('beaufortScale boundary values', () {
      // Beaufort 4 starts at 11 knots
      final b3 = WindDataPoint(
        position: position,
        speedKnots: 10.9,
        directionDegrees: 0,
      );
      expect(b3.beaufortScale, 3);

      final b4 = WindDataPoint(
        position: position,
        speedKnots: 11.0,
        directionDegrees: 0,
      );
      expect(b4.beaufortScale, 4);
    });

    test('equality compares all fields', () {
      final a = WindDataPoint(
        position: position,
        speedKnots: 15.0,
        directionDegrees: 270.0,
      );
      final b = WindDataPoint(
        position: position,
        speedKnots: 15.0,
        directionDegrees: 270.0,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when fields differ', () {
      final a = WindDataPoint(
        position: position,
        speedKnots: 15.0,
        directionDegrees: 270.0,
      );
      final b = WindDataPoint(
        position: position,
        speedKnots: 20.0,
        directionDegrees: 270.0,
      );
      expect(a, isNot(equals(b)));
    });

    test('toString returns human-readable format', () {
      final point = WindDataPoint(
        position: position,
        speedKnots: 15.0,
        directionDegrees: 270.0,
      );
      final str = point.toString();
      expect(str, contains('59.91'));
      expect(str, contains('15.0'));
    });
  });

  group('WaveDataPoint', () {
    const position = LatLng(latitude: 59.91, longitude: 10.75);

    test('constructs with required fields', () {
      final point = WaveDataPoint(
        position: position,
        heightMeters: 2.5,
        directionDegrees: 180.0,
      );

      expect(point.position, position);
      expect(point.heightMeters, 2.5);
      expect(point.directionDegrees, 180.0);
      expect(point.periodSeconds, isNull);
    });

    test('constructs with optional period', () {
      final point = WaveDataPoint(
        position: position,
        heightMeters: 2.5,
        directionDegrees: 180.0,
        periodSeconds: 8.0,
      );

      expect(point.periodSeconds, 8.0);
    });

    test('equality compares position, height, and direction', () {
      final a = WaveDataPoint(
        position: position,
        heightMeters: 2.5,
        directionDegrees: 180.0,
      );
      final b = WaveDataPoint(
        position: position,
        heightMeters: 2.5,
        directionDegrees: 180.0,
        periodSeconds: 8.0, // Different period, still equal
      );
      // Note: periodSeconds is NOT in equality — only core fields
      // Actually our equality checks position, height, direction
      expect(a, equals(b));
    });

    test('inequality when height differs', () {
      final a = WaveDataPoint(
        position: position,
        heightMeters: 2.5,
        directionDegrees: 180.0,
      );
      final b = WaveDataPoint(
        position: position,
        heightMeters: 3.5,
        directionDegrees: 180.0,
      );
      expect(a, isNot(equals(b)));
    });

    test('toString returns human-readable format', () {
      final point = WaveDataPoint(
        position: position,
        heightMeters: 2.5,
        directionDegrees: 180.0,
      );
      final str = point.toString();
      expect(str, contains('2.5'));
    });
  });

  group('WeatherData', () {
    const position = LatLng(latitude: 59.91, longitude: 10.75);

    test('empty returns empty data', () {
      final empty = WeatherData.empty;
      expect(empty.isEmpty, true);
      expect(empty.hasWind, false);
      expect(empty.hasWaves, false);
    });

    test('constructs with wind and wave points', () {
      final data = WeatherData(
        windPoints: [
          WindDataPoint(
            position: position,
            speedKnots: 15.0,
            directionDegrees: 270.0,
          ),
        ],
        wavePoints: [
          WaveDataPoint(
            position: position,
            heightMeters: 2.5,
            directionDegrees: 180.0,
          ),
        ],
        fetchedAt: DateTime.now(),
      );

      expect(data.isEmpty, false);
      expect(data.hasWind, true);
      expect(data.hasWaves, true);
      expect(data.windPoints.length, 1);
      expect(data.wavePoints.length, 1);
    });

    test('isStale returns true for old data', () {
      final staleData = WeatherData(
        windPoints: [],
        wavePoints: [],
        fetchedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(staleData.isStale, true);
    });

    test('isStale returns false for fresh data', () {
      final freshData = WeatherData(
        windPoints: [],
        wavePoints: [],
        fetchedAt: DateTime.now(),
      );
      expect(freshData.isStale, false);
    });

    test('age returns duration since fetch', () {
      final data = WeatherData(
        windPoints: [],
        wavePoints: [],
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(data.age.inMinutes, greaterThanOrEqualTo(29));
      expect(data.age.inMinutes, lessThanOrEqualTo(31));
    });

    test('gridResolution defaults to 0.25', () {
      final data = WeatherData(
        windPoints: [],
        wavePoints: [],
        fetchedAt: DateTime.now(),
      );
      expect(data.gridResolution, 0.25);
    });

    test('toString returns summary', () {
      final data = WeatherData(
        windPoints: [
          WindDataPoint(
            position: position,
            speedKnots: 15.0,
            directionDegrees: 270.0,
          ),
        ],
        wavePoints: [],
        fetchedAt: DateTime.now(),
      );
      final str = data.toString();
      expect(str, contains('w:1'));
      expect(str, contains('wv:0'));
    });
  });

  group('WeatherFrame', () {
    const position = LatLng(latitude: 59.91, longitude: 10.75);
    final testTime = DateTime(2026, 2, 9, 12, 0);

    test('constructs with wind and wave lists', () {
      final frame = WeatherFrame(
        time: testTime,
        windPoints: [
          WindDataPoint(
            position: position,
            speedKnots: 15.0,
            directionDegrees: 270.0,
          ),
        ],
        wavePoints: [
          WaveDataPoint(
            position: position,
            heightMeters: 2.0,
            directionDegrees: 180.0,
          ),
        ],
      );
      expect(frame.hasWind, true);
      expect(frame.hasWave, true);
    });

    test('constructs with only wind', () {
      final frame = WeatherFrame(
        time: testTime,
        windPoints: [
          WindDataPoint(
            position: position,
            speedKnots: 10.0,
            directionDegrees: 90.0,
          ),
        ],
      );
      expect(frame.hasWind, true);
      expect(frame.hasWave, false);
    });

    test('equality compares time, windPoints, wavePoints', () {
      final a = WeatherFrame(
        time: testTime,
        windPoints: [
          WindDataPoint(
            position: position,
            speedKnots: 15.0,
            directionDegrees: 270.0,
          ),
        ],
      );
      final b = WeatherFrame(
        time: testTime,
        windPoints: [
          WindDataPoint(
            position: position,
            speedKnots: 15.0,
            directionDegrees: 270.0,
          ),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('WeatherData frames', () {
    test('hasFrames and frameCount work', () {
      final data = WeatherData(
        windPoints: [],
        wavePoints: [],
        frames: [
          WeatherFrame(time: DateTime(2026, 2, 9, 0, 0)),
          WeatherFrame(time: DateTime(2026, 2, 9, 1, 0)),
        ],
        fetchedAt: DateTime.now(),
      );
      expect(data.hasFrames, true);
      expect(data.frameCount, 2);
    });

    test('empty data has no frames', () {
      expect(WeatherData.empty.hasFrames, false);
      expect(WeatherData.empty.frameCount, 0);
    });
  });

  group('Constants', () {
    test('weatherCacheTtl is 1 hour', () {
      expect(weatherCacheTtl, const Duration(hours: 1));
    });

    test('weatherGridResolution is 0.25', () {
      expect(weatherGridResolution, 0.25);
    });
  });
}
