import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marine_nav_app/services/weather_api.dart';

/// Sample Open-Meteo Marine API response for testing.
const _sampleResponse = '''
{
  "latitude": 60.0,
  "longitude": 10.0,
  "generationtime_ms": 0.5,
  "utc_offset_seconds": 0,
  "current_units": {
    "wind_speed_10m": "kn",
    "wind_direction_10m": "°",
    "wave_height": "m",
    "wave_direction": "°",
    "wave_period": "s"
  },
  "current": {
    "wind_speed_10m": 12.5,
    "wind_direction_10m": 225.0,
    "wave_height": 1.8,
    "wave_direction": 180.0,
    "wave_period": 6.5
  },
  "hourly_units": {
    "wind_speed_10m": "kn",
    "wind_direction_10m": "°",
    "wave_height": "m",
    "wave_direction": "°",
    "wave_period": "s"
  },
  "hourly": {
    "time": ["2026-02-09T00:00", "2026-02-09T01:00", "2026-02-09T02:00"],
    "wind_speed_10m": [10.0, 12.5, 14.0],
    "wind_direction_10m": [220.0, 225.0, 230.0],
    "wave_height": [1.5, 1.8, 2.0],
    "wave_direction": [175.0, 180.0, 185.0],
    "wave_period": [6.0, 6.5, 7.0]
  }
}
''';

/// Sample response with only current data (no hourly).
const _currentOnlyResponse = '''
{
  "latitude": 60.0,
  "longitude": 10.0,
  "current": {
    "wind_speed_10m": 8.0,
    "wind_direction_10m": 90.0,
    "wave_height": 0.5,
    "wave_direction": 45.0
  }
}
''';

/// Sample empty response (no data for region).
const _emptyResponse = '''
{
  "latitude": 60.0,
  "longitude": 10.0
}
''';

void main() {
  group('WeatherApiService', () {
    test('fetchWeatherData parses full response', () async {
      final mockClient = MockClient((_) async {
        return http.Response(_sampleResponse, 200);
      });

      final api = WeatherApiService(client: mockClient);
      final data = await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      // Should have current + 3 hourly = 4 wind points
      expect(data.windPoints.length, 4);
      // Should have current + 3 hourly = 4 wave points
      expect(data.wavePoints.length, 4);

      // Verify current data point
      expect(data.windPoints.first.speedKnots, 12.5);
      expect(data.windPoints.first.directionDegrees, 225.0);
      expect(data.wavePoints.first.heightMeters, 1.8);
      expect(data.wavePoints.first.directionDegrees, 180.0);

      // Verify position comes from response metadata
      expect(data.windPoints.first.position.latitude, 60.0);
      expect(data.windPoints.first.position.longitude, 10.0);

      expect(data.isEmpty, false);
      expect(data.hasWind, true);
      expect(data.hasWaves, true);

      api.dispose();
    });

    test('fetchWeatherData parses current-only response', () async {
      final mockClient = MockClient((_) async {
        return http.Response(_currentOnlyResponse, 200);
      });

      final api = WeatherApiService(client: mockClient);
      final data = await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(data.windPoints.length, 1);
      expect(data.wavePoints.length, 1);
      expect(data.windPoints.first.speedKnots, 8.0);
      expect(data.wavePoints.first.heightMeters, 0.5);

      api.dispose();
    });

    test('fetchWeatherData handles empty response', () async {
      final mockClient = MockClient((_) async {
        return http.Response(_emptyResponse, 200);
      });

      final api = WeatherApiService(client: mockClient);
      final data = await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(data.isEmpty, true);
      expect(data.windPoints, isEmpty);
      expect(data.wavePoints, isEmpty);

      api.dispose();
    });

    test('fetchWeatherData throws on server error', () async {
      final mockClient = MockClient((_) async {
        return http.Response('Internal Server Error', 500);
      });

      final api = WeatherApiService(client: mockClient);

      expect(
        () => api.fetchWeatherData(
          south: 58.0,
          north: 62.0,
          west: 8.0,
          east: 12.0,
        ),
        throwsA(isA<WeatherApiException>().having(
          (e) => e.type,
          'type',
          WeatherApiErrorType.server,
        )),
      );

      api.dispose();
    });

    test('fetchWeatherData throws on invalid JSON', () async {
      final mockClient = MockClient((_) async {
        return http.Response('not json at all', 200);
      });

      final api = WeatherApiService(client: mockClient);

      expect(
        () => api.fetchWeatherData(
          south: 58.0,
          north: 62.0,
          west: 8.0,
          east: 12.0,
        ),
        throwsA(isA<WeatherApiException>().having(
          (e) => e.type,
          'type',
          WeatherApiErrorType.parsing,
        )),
      );

      api.dispose();
    });

    test('fetchWeatherData retries on network error', () async {
      int callCount = 0;
      final mockClient = MockClient((_) async {
        callCount++;
        if (callCount < 3) {
          throw http.ClientException('Connection refused');
        }
        return http.Response(_sampleResponse, 200);
      });

      final api = WeatherApiService(client: mockClient);
      final data = await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(callCount, 3);
      expect(data.hasWind, true);

      api.dispose();
    });

    test('fetchWeatherData throws after max retries', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('Connection refused');
      });

      final api = WeatherApiService(client: mockClient);

      expect(
        () => api.fetchWeatherData(
          south: 58.0,
          north: 62.0,
          west: 8.0,
          east: 12.0,
        ),
        throwsA(isA<WeatherApiException>().having(
          (e) => e.type,
          'type',
          WeatherApiErrorType.network,
        )),
      );

      api.dispose();
    });

    test('builds correct URI with center coordinates', () async {
      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(_sampleResponse, 200);
      });

      final api = WeatherApiService(client: mockClient);
      await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(capturedUri, isNotNull);
      expect(capturedUri!.host, 'marine-api.open-meteo.com');
      expect(capturedUri!.path, '/v1/marine');
      // Center: (58+62)/2=60, (8+12)/2=10
      expect(capturedUri!.queryParameters['latitude'], '60.0000');
      expect(capturedUri!.queryParameters['longitude'], '10.0000');
      expect(capturedUri!.queryParameters['wind_speed_unit'], 'kn');

      api.dispose();
    });

    test('WeatherApiException toString is descriptive', () {
      const e = WeatherApiException(
        type: WeatherApiErrorType.timeout,
        message: 'Request timed out',
      );
      expect(e.toString(), contains('timeout'));
      expect(e.toString(), contains('Request timed out'));
    });
  });
}
