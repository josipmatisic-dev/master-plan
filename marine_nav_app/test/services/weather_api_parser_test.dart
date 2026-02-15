import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/services/weather_api.dart'; // for Exception
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
      
      // Check first point
      expect(result.windPoints[0].position.latitude, 45.0);
      expect(result.windPoints[0].speedKnots, 12.0);
      
      // Check second point
      expect(result.windPoints[1].position.latitude, 46.0);
      expect(result.windPoints[1].speedKnots, 12.0);
      
      // Frames are parsed from the first point
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
      expect(result.windPoints[0].position.latitude, 45.0); // Uses (south, west)
      expect(result.windPoints[0].position.longitude, 14.0);
    });

    test('handles partial data gracefully', () {
      // Missing current data
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
  });
}
