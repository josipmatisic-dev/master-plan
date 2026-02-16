import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/services/weather_api.dart';
import 'package:marine_nav_app/services/weather_api_parser.dart';

void main() {
  group('WeatherApiParser', () {
    const marineBody = '''
    {
      "current": {
        "wave_height": 1.5,
        "wave_direction": 180,
        "wave_period": 5.5
      },
      "hourly": {
        "time": ["2023-10-27T00:00", "2023-10-27T01:00"],
        "wave_height": [1.0, 1.2],
        "wave_direction": [170, 175],
        "wave_period": [5.0, 5.2]
      }
    }
    ''';

    const forecastBody = '''
    {
      "current": {
        "wind_speed_10m": 12.0,
        "wind_direction_10m": 90
      },
      "hourly": {
        "time": ["2023-10-27T00:00", "2023-10-27T01:00"],
        "wind_speed_10m": [10.0, 11.0],
        "wind_direction_10m": [85, 88]
      }
    }
    ''';

    test('parseGridResponse parses single-point (legacy) response', () {
      final result = parseGridResponse(
        marineBody: marineBody,
        forecastBody: forecastBody,
        grid: [(45.0, 14.0)],
      );

      expect(result.windPoints, hasLength(1));
      expect(result.windPoints[0].speedKnots, 12.0);
      expect(result.wavePoints, hasLength(1));
      expect(result.wavePoints[0].heightMeters, 1.5);
      expect(result.frames, hasLength(2));
    });

    test('parseGridResponse parses multi-point (array) response', () {
      const marineArray = '[$marineBody, $marineBody]';
      const forecastArray = '[$forecastBody, $forecastBody]';

      final result = parseGridResponse(
        marineBody: marineArray,
        forecastBody: forecastArray,
        grid: [(45.0, 14.0), (46.0, 15.0)],
      );

      expect(result.windPoints, hasLength(2));
      expect(result.wavePoints, hasLength(2));
      expect(result.windPoints[0].position.latitude, 45.0);
      expect(result.windPoints[0].speedKnots, 12.0);
      expect(result.windPoints[1].position.latitude, 46.0);
      expect(result.windPoints[1].speedKnots, 12.0);
      expect(result.frames, hasLength(2));
    });

    test('parseDualResponse wraps parseGridResponse correctly', () {
      final result = parseDualResponse(
        marineBody: marineBody,
        forecastBody: forecastBody,
        south: 45.0,
        north: 45.0,
        west: 14.0,
        east: 14.0,
      );

      expect(result.windPoints, hasLength(1));
      expect(result.windPoints[0].position.latitude, 45.0);
      expect(result.windPoints[0].position.longitude, 14.0);
    });

    test('handles partial data gracefully', () {
      const partialBody = '{"hourly": {}}';
      final result = parseGridResponse(
        marineBody: partialBody,
        forecastBody: partialBody,
        grid: [(45.0, 14.0)],
      );

      expect(result.windPoints, isEmpty);
      expect(result.wavePoints, isEmpty);
      expect(result.frames, isEmpty);
    });

    test('throws WeatherApiException on malformed JSON', () {
      expect(
        () => parseGridResponse(
          marineBody: '{ invalid json }',
          forecastBody: '{}',
          grid: [(45.0, 14.0)],
        ),
        throwsA(isA<WeatherApiException>()),
      );
    });

    group('atmospheric data parsing', () {
      test('parses full atmospheric data from forecast response', () {
        final forecastWithAtmo = jsonEncode({
          'current': {
            'wind_speed_10m': 12.0,
            'wind_direction_10m': 90,
            'precipitation': 2.5,
            'cloud_cover': 75,
            'visibility': 8000,
            'pressure_msl': 1013.25,
            'temperature_2m': 18.5,
            'apparent_temperature': 16.2,
            'relative_humidity_2m': 65,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wind_speed_10m': [10.0],
            'wind_direction_10m': [85],
          },
        });

        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: forecastWithAtmo,
          grid: [(45.0, 14.0)],
        );

        expect(result.atmosphericPoints, hasLength(1));
        final atmo = result.atmosphericPoints[0];
        expect(atmo.precipitationMmH, 2.5);
        expect(atmo.cloudCoverPercent, 75);
        expect(atmo.visibilityMeters, 8000);
        expect(atmo.pressureHpa, 1013.25);
        expect(atmo.temperatureCelsius, 18.5);
        expect(atmo.apparentTempCelsius, 16.2);
        expect(atmo.humidityPercent, 65);
        expect(atmo.position.latitude, 45.0);
      });

      test('skips atmospheric when precipitation or cloud missing', () {
        final forecastNoAtmo = jsonEncode({
          'current': {
            'wind_speed_10m': 12.0,
            'wind_direction_10m': 90,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wind_speed_10m': [10.0],
            'wind_direction_10m': [85],
          },
        });

        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: forecastNoAtmo,
          grid: [(45.0, 14.0)],
        );

        expect(result.atmosphericPoints, isEmpty);
        expect(result.windPoints, hasLength(1));
      });

      test('parses atmospheric with only required fields', () {
        final forecastMinAtmo = jsonEncode({
          'current': {
            'wind_speed_10m': 12.0,
            'wind_direction_10m': 90,
            'precipitation': 0.0,
            'cloud_cover': 10,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wind_speed_10m': [10.0],
            'wind_direction_10m': [85],
          },
        });

        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: forecastMinAtmo,
          grid: [(45.0, 14.0)],
        );

        expect(result.atmosphericPoints, hasLength(1));
        final atmo = result.atmosphericPoints[0];
        expect(atmo.precipitationMmH, 0.0);
        expect(atmo.cloudCoverPercent, 10);
        expect(atmo.visibilityMeters, isNull);
        expect(atmo.pressureHpa, isNull);
      });

      test('multi-point atmospheric data uses correct positions', () {
        final point = jsonEncode({
          'current': {
            'wind_speed_10m': 12.0,
            'wind_direction_10m': 90,
            'precipitation': 1.0,
            'cloud_cover': 50,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wind_speed_10m': [10.0],
            'wind_direction_10m': [85],
          },
        });
        final forecastArray = '[$point, $point]';
        const marineArray = '[$marineBody, $marineBody]';

        final result = parseGridResponse(
          marineBody: marineArray,
          forecastBody: forecastArray,
          grid: [(43.0, 15.0), (44.0, 16.0)],
        );

        expect(result.atmosphericPoints, hasLength(2));
        expect(result.atmosphericPoints[0].position.latitude, 43.0);
        expect(result.atmosphericPoints[1].position.latitude, 44.0);
      });
    });

    group('grid/response length mismatch', () {
      test('handles more grid points than API results', () {
        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: forecastBody,
          grid: [(45.0, 14.0), (46.0, 15.0), (47.0, 16.0)],
        );

        // Only 1 API result, 3 grid points — should parse just the 1
        expect(result.windPoints, hasLength(1));
        expect(result.wavePoints, hasLength(1));
      });

      test('handles more API results than grid points', () {
        const marineArray = '[$marineBody, $marineBody, $marineBody]';
        const forecastArray = '[$forecastBody, $forecastBody, $forecastBody]';

        final result = parseGridResponse(
          marineBody: marineArray,
          forecastBody: forecastArray,
          grid: [(45.0, 14.0)],
        );

        // Only 1 grid point, 3 API results — should parse just 1
        expect(result.windPoints, hasLength(1));
        expect(result.wavePoints, hasLength(1));
      });

      test('handles empty grid', () {
        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: forecastBody,
          grid: [],
        );

        expect(result.windPoints, isEmpty);
        expect(result.wavePoints, isEmpty);
        expect(result.frames, isEmpty);
      });
    });

    group('wind gusts and wave periods', () {
      test('parses wind gusts when present', () {
        final withGusts = jsonEncode({
          'current': {
            'wind_speed_10m': 15.0,
            'wind_direction_10m': 180,
            'wind_gusts_10m': 25.0,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wind_speed_10m': [15.0],
            'wind_direction_10m': [180],
            'wind_gusts_10m': [25.0],
          },
        });

        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: withGusts,
          grid: [(45.0, 14.0)],
        );

        expect(result.windPoints[0].gustKnots, 25.0);
        expect(result.frames[0].windPoints[0].gustKnots, 25.0);
      });

      test('handles missing gusts gracefully', () {
        final noGusts = jsonEncode({
          'current': {
            'wind_speed_10m': 15.0,
            'wind_direction_10m': 180,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wind_speed_10m': [15.0],
            'wind_direction_10m': [180],
          },
        });

        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: noGusts,
          grid: [(45.0, 14.0)],
        );

        expect(result.windPoints[0].gustKnots, isNull);
        expect(result.frames[0].windPoints[0].gustKnots, isNull);
      });

      test('handles missing wave period', () {
        final noPeriod = jsonEncode({
          'current': {
            'wave_height': 2.0,
            'wave_direction': 200,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wave_height': [2.0],
            'wave_direction': [200],
          },
        });

        final result = parseGridResponse(
          marineBody: noPeriod,
          forecastBody: forecastBody,
          grid: [(45.0, 14.0)],
        );

        expect(result.wavePoints[0].periodSeconds, isNull);
      });
    });

    group('hourly frame parsing', () {
      test('frames with only wind and no waves', () {
        const emptyMarine = '{"hourly": {}}';
        final result = parseGridResponse(
          marineBody: emptyMarine,
          forecastBody: forecastBody,
          grid: [(45.0, 14.0)],
        );

        expect(result.frames, hasLength(2));
        expect(result.frames[0].windPoints, hasLength(1));
        expect(result.frames[0].wavePoints, isEmpty);
      });

      test('frames with only waves and no wind', () {
        const emptyForecast = '{"hourly": {}}';
        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: emptyForecast,
          grid: [(45.0, 14.0)],
        );

        // No time array from forecast, so no frames can be constructed
        expect(result.frames, isEmpty);
      });

      test('skips malformed timestamps in hourly arrays', () {
        final badTimes = jsonEncode({
          'current': {
            'wind_speed_10m': 12.0,
            'wind_direction_10m': 90,
          },
          'hourly': {
            'time': ['2023-10-27T00:00', 'not-a-date', '2023-10-27T02:00'],
            'wind_speed_10m': [10.0, 11.0, 12.0],
            'wind_direction_10m': [85, 88, 90],
          },
        });

        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: badTimes,
          grid: [(45.0, 14.0)],
        );

        // Should skip the bad timestamp and parse the other 2
        expect(result.frames, hasLength(2));
      });

      test('handles null hourly data in forecast', () {
        final noHourly = jsonEncode({
          'current': {
            'wind_speed_10m': 12.0,
            'wind_direction_10m': 90,
          },
        });

        final result = parseGridResponse(
          marineBody: marineBody,
          forecastBody: noHourly,
          grid: [(45.0, 14.0)],
        );

        expect(result.frames, isEmpty);
        expect(result.windPoints, hasLength(1));
      });

      test('multi-point frames collect all grid points per timestep', () {
        final point1 = jsonEncode({
          'current': {
            'wind_speed_10m': 10.0,
            'wind_direction_10m': 90,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wind_speed_10m': [10.0],
            'wind_direction_10m': [90],
          },
        });
        final point2 = jsonEncode({
          'current': {
            'wind_speed_10m': 20.0,
            'wind_direction_10m': 180,
          },
          'hourly': {
            'time': ['2023-10-27T00:00'],
            'wind_speed_10m': [20.0],
            'wind_direction_10m': [180],
          },
        });

        final result = parseGridResponse(
          marineBody: '[$marineBody, $marineBody]',
          forecastBody: '[$point1, $point2]',
          grid: [(43.0, 15.0), (44.0, 16.0)],
        );

        expect(result.frames, hasLength(1));
        // Frame should have 2 wind points (one per grid point)
        expect(result.frames[0].windPoints, hasLength(2));
        expect(result.frames[0].windPoints[0].speedKnots, 10.0);
        expect(result.frames[0].windPoints[1].speedKnots, 20.0);
      });
    });
  });
}
