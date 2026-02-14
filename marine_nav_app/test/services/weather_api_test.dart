import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marine_nav_app/services/weather_api.dart';

/// Sample Forecast API response (wind).
const _forecastResponse = '''
{
  "latitude": 60.0,
  "longitude": 10.0,
  "current": {
    "wind_speed_10m": 12.5,
    "wind_direction_10m": 225.0
  },
  "hourly": {
    "time": ["2026-02-09T00:00", "2026-02-09T01:00", "2026-02-09T02:00"],
    "wind_speed_10m": [10.0, 12.5, 14.0],
    "wind_direction_10m": [220.0, 225.0, 230.0]
  }
}
''';

/// Sample Marine API response (waves).
const _marineResponse = '''
{
  "latitude": 60.0,
  "longitude": 10.0,
  "current": {
    "wave_height": 1.8,
    "wave_direction": 180.0,
    "wave_period": 6.5
  },
  "hourly": {
    "time": ["2026-02-09T00:00", "2026-02-09T01:00", "2026-02-09T02:00"],
    "wave_height": [1.5, 1.8, 2.0],
    "wave_direction": [175.0, 180.0, 185.0],
    "wave_period": [6.0, 6.5, 7.0]
  }
}
''';

/// Empty response (no data for region).
const _emptyResponse = '''
{
  "latitude": 60.0,
  "longitude": 10.0
}
''';

/// Routes mock requests to the correct response by URL.
MockClient _dualMockClient({
  String marine = _marineResponse,
  String forecast = _forecastResponse,
  int marineStatus = 200,
  int forecastStatus = 200,
}) {
  return MockClient((request) async {
    if (request.url.host == 'api.open-meteo.com') {
      return http.Response(forecast, forecastStatus);
    }
    return http.Response(marine, marineStatus);
  });
}

void main() {
  group('WeatherApiService', () {
    test('fetchWeatherData parses dual response with 25-point grid', () async {
      final api = WeatherApiService(client: _dualMockClient());
      final data = await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      // 5×5 grid = 25 points each
      expect(data.windPoints.length, 25);
      expect(data.wavePoints.length, 25);
      expect(data.isEmpty, false);
      expect(data.hasWind, true);
      expect(data.hasWaves, true);

      // Verify wind values are near the base (12.5 kts ±10%)
      for (final w in data.windPoints) {
        expect(w.speedKnots, closeTo(12.5, 1.5));
      }
      // Verify wave values are near the base (1.8 m ±10%)
      for (final w in data.wavePoints) {
        expect(w.heightMeters, closeTo(1.8, 0.25));
      }

      api.dispose();
    });

    test('fetchWeatherData handles empty responses', () async {
      final api = WeatherApiService(
        client:
            _dualMockClient(marine: _emptyResponse, forecast: _emptyResponse),
      );
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

    test('fetchWeatherData throws on marine server error', () async {
      final api = WeatherApiService(
        client: _dualMockClient(marineStatus: 500),
      );

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

    test('fetchWeatherData throws on forecast server error', () async {
      final api = WeatherApiService(
        client: _dualMockClient(forecastStatus: 500),
      );

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
      final api = WeatherApiService(
        client: _dualMockClient(forecast: 'not json'),
      );

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
        if (callCount <= 2) {
          throw http.ClientException('Connection refused');
        }
        // After retry, both calls succeed (callCount 3+ covers both endpoints)
        if (_.url.host == 'api.open-meteo.com') {
          return http.Response(_forecastResponse, 200);
        }
        return http.Response(_marineResponse, 200);
      });

      final api = WeatherApiService(client: mockClient);
      final data = await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(data.hasWind, true);
      expect(data.hasWaves, true);

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

    test('builds correct URIs for dual endpoints', () async {
      final capturedUris = <Uri>[];
      final mockClient = MockClient((request) async {
        capturedUris.add(request.url);
        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(_forecastResponse, 200);
        }
        return http.Response(_marineResponse, 200);
      });

      final api = WeatherApiService(client: mockClient);
      await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(capturedUris.length, 2);

      final marineUri =
          capturedUris.firstWhere((u) => u.host == 'marine-api.open-meteo.com');
      expect(marineUri.path, '/v1/marine');
      expect(marineUri.queryParameters['latitude'], '60.0000');
      expect(marineUri.queryParameters['longitude'], '10.0000');
      expect(marineUri.queryParameters['current'], contains('wave_height'));
      // Marine should NOT have wind params
      expect(
          marineUri.queryParameters['current'], isNot(contains('wind_speed')));

      final forecastUri =
          capturedUris.firstWhere((u) => u.host == 'api.open-meteo.com');
      expect(forecastUri.path, '/v1/forecast');
      expect(forecastUri.queryParameters['wind_speed_unit'], 'kn');
      expect(
          forecastUri.queryParameters['current'], contains('wind_speed_10m'));
      // Forecast should NOT have wave params
      expect(forecastUri.queryParameters['current'],
          isNot(contains('wave_height')));

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

    test('hourly frames contain both wind and wave data', () async {
      final api = WeatherApiService(client: _dualMockClient());
      final data = await api.fetchWeatherData(
        south: 58.0,
        north: 62.0,
        west: 8.0,
        east: 12.0,
      );

      expect(data.frames.length, 3);
      for (final frame in data.frames) {
        expect(frame.hasWind, true);
        expect(frame.hasWave, true);
      }

      api.dispose();
    });
  });
}
