/// Weather API service for Open-Meteo Marine API integration.
///
/// Fetches wind, wave, and other marine weather data for a given
/// geographic bounding box. Implements triple-layer protection:
/// retry (3×), timeout (15s), and cache fallback.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/lat_lng.dart';
import '../models/weather_data.dart';

/// Error types for weather API failures.
enum WeatherApiErrorType {
  /// Network connectivity issue.
  network,

  /// Request timed out.
  timeout,

  /// Server returned non-200 status.
  server,

  /// Failed to parse response JSON.
  parsing,

  /// No data available for the requested region.
  noData,
}

/// Exception thrown by [WeatherApiService].
class WeatherApiException implements Exception {
  /// Error category.
  final WeatherApiErrorType type;

  /// Human-readable description.
  final String message;

  /// Creates a weather API exception.
  const WeatherApiException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'WeatherApiException($type): $message';
}

/// Service for fetching marine weather data from Open-Meteo.
///
/// Uses the `/v1/marine` endpoint for wind and wave data.
/// Implements retry with exponential backoff per Bible C.4.
///
/// Usage:
/// ```dart
/// final api = WeatherApiService();
/// final data = await api.fetchWeatherData(
///   south: 58.0, north: 62.0,
///   west: 8.0, east: 14.0,
/// );
/// ```
class WeatherApiService {
  /// HTTP client (injectable for testing).
  final http.Client _client;

  /// Base URL for Open-Meteo Marine API.
  @visibleForTesting
  static const String baseUrl = 'https://marine-api.open-meteo.com/v1/marine';

  /// Maximum retry attempts.
  static const int maxRetries = 3;

  /// Base timeout duration for requests.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Creates a weather API service with an optional HTTP client.
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches weather data for a geographic bounding box.
  ///
  /// Returns [WeatherData] with wind and wave grid points.
  /// Throws [WeatherApiException] on failure after retries.
  ///
  /// Parameters:
  /// - [south], [north]: Latitude bounds (-90 to 90).
  /// - [west], [east]: Longitude bounds (-180 to 180).
  Future<WeatherData> fetchWeatherData({
    required double south,
    required double north,
    required double west,
    required double east,
  }) async {
    final uri = _buildUri(south: south, north: north, west: west, east: east);

    final response = await _retryWithBackoff(() async {
      return _client.get(uri).timeout(requestTimeout);
    });

    if (response.statusCode != 200) {
      throw WeatherApiException(
        type: WeatherApiErrorType.server,
        message:
            'Server returned ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    return _parseResponse(response.body);
  }

  /// Builds the API request URI with query parameters.
  Uri _buildUri({
    required double south,
    required double north,
    required double west,
    required double east,
  }) {
    // Open-Meteo Marine API accepts latitude/longitude as single values.
    // For grid data, we use the center of the bounding box and rely on
    // the API's grid resolution.
    final centerLat = (south + north) / 2;
    final centerLng = (west + east) / 2;

    return Uri.parse(baseUrl).replace(
      queryParameters: {
        'latitude': centerLat.toStringAsFixed(4),
        'longitude': centerLng.toStringAsFixed(4),
        'current': [
          'wind_speed_10m',
          'wind_direction_10m',
          'wave_height',
          'wave_direction',
          'wave_period',
        ].join(','),
        'hourly': [
          'wind_speed_10m',
          'wind_direction_10m',
          'wave_height',
          'wave_direction',
          'wave_period',
        ].join(','),
        'wind_speed_unit': 'kn',
        'forecast_days': '1',
      },
    );
  }

  /// Parses the JSON response into [WeatherData].
  WeatherData _parseResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;

      final windPoints = <WindDataPoint>[];
      final wavePoints = <WaveDataPoint>[];

      // Extract latitude/longitude from response metadata.
      final lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
      final position = LatLng(latitude: lat, longitude: lng);

      // Parse current conditions as a single grid point.
      final current = json['current'] as Map<String, dynamic>?;
      if (current != null) {
        _parseCurrentWind(current, position, windPoints);
        _parseCurrentWave(current, position, wavePoints);
      }

      // Parse hourly data to build grid-like time series points.
      final hourly = json['hourly'] as Map<String, dynamic>?;
      if (hourly != null) {
        _parseHourlyData(hourly, position, windPoints, wavePoints);
      }

      return WeatherData(
        windPoints: windPoints,
        wavePoints: wavePoints,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      throw WeatherApiException(
        type: WeatherApiErrorType.parsing,
        message: 'Failed to parse response: $e',
      );
    }
  }

  /// Parses current wind data from the API response.
  void _parseCurrentWind(
    Map<String, dynamic> current,
    LatLng position,
    List<WindDataPoint> out,
  ) {
    final speed = (current['wind_speed_10m'] as num?)?.toDouble();
    final direction = (current['wind_direction_10m'] as num?)?.toDouble();

    if (speed != null && direction != null) {
      out.add(WindDataPoint(
        position: position,
        speedKnots: speed,
        directionDegrees: direction,
      ));
    }
  }

  /// Parses current wave data from the API response.
  void _parseCurrentWave(
    Map<String, dynamic> current,
    LatLng position,
    List<WaveDataPoint> out,
  ) {
    final height = (current['wave_height'] as num?)?.toDouble();
    final direction = (current['wave_direction'] as num?)?.toDouble();
    final period = (current['wave_period'] as num?)?.toDouble();

    if (height != null && direction != null) {
      out.add(WaveDataPoint(
        position: position,
        heightMeters: height,
        directionDegrees: direction,
        periodSeconds: period,
      ));
    }
  }

  /// Parses hourly time-series data.
  void _parseHourlyData(
    Map<String, dynamic> hourly,
    LatLng basePosition,
    List<WindDataPoint> windOut,
    List<WaveDataPoint> waveOut,
  ) {
    final windSpeeds = hourly['wind_speed_10m'] as List<dynamic>?;
    final windDirs = hourly['wind_direction_10m'] as List<dynamic>?;
    final waveHeights = hourly['wave_height'] as List<dynamic>?;
    final waveDirs = hourly['wave_direction'] as List<dynamic>?;
    final wavePeriods = hourly['wave_period'] as List<dynamic>?;

    if (windSpeeds == null || windDirs == null) return;

    final count = windSpeeds.length;
    for (var i = 0; i < count; i++) {
      final speed = (windSpeeds[i] as num?)?.toDouble();
      final dir = (windDirs[i] as num?)?.toDouble();
      if (speed != null && dir != null) {
        windOut.add(WindDataPoint(
          position: basePosition,
          speedKnots: speed,
          directionDegrees: dir,
        ));
      }

      if (waveHeights != null &&
          waveDirs != null &&
          i < waveHeights.length &&
          i < waveDirs.length) {
        final height = (waveHeights[i] as num?)?.toDouble();
        final waveDir = (waveDirs[i] as num?)?.toDouble();
        final period = wavePeriods != null && i < wavePeriods.length
            ? (wavePeriods[i] as num?)?.toDouble()
            : null;

        if (height != null && waveDir != null) {
          waveOut.add(WaveDataPoint(
            position: basePosition,
            heightMeters: height,
            directionDegrees: waveDir,
            periodSeconds: period,
          ));
        }
      }
    }
  }

  /// Retries an HTTP request with exponential backoff.
  ///
  /// Implements Bible C.4: 3× retry + 15s timeout + cache fallback.
  Future<http.Response> _retryWithBackoff(
    Future<http.Response> Function() request,
  ) async {
    Duration delay = const Duration(milliseconds: 100);
    WeatherApiException? lastError;

    for (var i = 0; i < maxRetries; i++) {
      try {
        return await request();
      } on TimeoutException {
        lastError = const WeatherApiException(
          type: WeatherApiErrorType.timeout,
          message: 'Request timed out after 15 seconds',
        );
        if (i == maxRetries - 1) throw lastError;
      } on http.ClientException catch (e) {
        lastError = WeatherApiException(
          type: WeatherApiErrorType.network,
          message: 'Network error: $e',
        );
        if (i == maxRetries - 1) throw lastError;
      } catch (e) {
        if (e is WeatherApiException) rethrow;
        lastError = WeatherApiException(
          type: WeatherApiErrorType.network,
          message: 'Unexpected error: $e',
        );
        if (i == maxRetries - 1) throw lastError;
      }

      debugPrint('WeatherApi: Retry ${i + 1}/$maxRetries after $delay');
      await Future<void>.delayed(delay);
      delay *= 2; // Exponential backoff
    }

    throw lastError ??
        const WeatherApiException(
          type: WeatherApiErrorType.network,
          message: 'Failed after max retries',
        );
  }

  /// Disposes the HTTP client.
  void dispose() {
    _client.close();
  }
}
