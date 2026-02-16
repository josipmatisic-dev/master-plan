/// Weather API service for Open-Meteo Marine + Forecast API integration.
///
/// Makes parallel calls to the Marine API (waves) and Forecast API (wind)
/// for a given geographic bounding box. Implements triple-layer protection:
/// retry (3×), timeout (15s), and cache fallback.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/weather_data.dart';
import 'weather_api_parser.dart';

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
/// Uses `/v1/marine` for wave data and `/v1/forecast` for wind data.
/// Implements retry with exponential backoff per Bible C.4.
class WeatherApiService {
  /// HTTP client (injectable for testing).
  final http.Client _client;

  /// Base URL for Open-Meteo Marine API (waves).
  @visibleForTesting
  static const String marineUrl = 'https://marine-api.open-meteo.com/v1/marine';

  /// Base URL for Open-Meteo Forecast API (wind).
  @visibleForTesting
  static const String forecastUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Maximum retry attempts.
  static const int maxRetries = 3;

  /// Base timeout duration for requests.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Creates a weather API service with an optional HTTP client.
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Default grid size for multi-point fetch.
  static const int defaultGridSize = 5;

  /// Maximum grid size at high zoom.
  static const int maxGridSize = 8;

  /// Forecast horizon in days (2 days = 48 hourly frames).
  static const int forecastDays = 2;

  /// Fetches weather data for a geographic bounding box.
  ///
  /// [zoomLevel] controls adaptive grid density (higher = denser).
  Future<WeatherData> fetchWeatherData({
    required double south,
    required double north,
    required double west,
    required double east,
    double? zoomLevel,
  }) async {
    final effectiveGridSize = _adaptiveGridSize(zoomLevel);
    final grid = _buildGrid(south, north, west, east, effectiveGridSize);
    final lats = grid.map((p) => p.$1.toStringAsFixed(4)).join(',');
    final lngs = grid.map((p) => p.$2.toStringAsFixed(4)).join(',');

    final marineUri = _buildMarineUri(lats, lngs);
    final forecastUri = _buildForecastUri(lats, lngs);

    // Parallel fetch — Marine is optional, Forecast (wind) is critical.
    http.Response? marineResponse;
    late final http.Response forecastResponse;

    final results = await Future.wait([
      _retryWithBackoff(() => _client.get(marineUri).timeout(requestTimeout))
          .then<http.Response?>((r) => r)
          .onError<Exception>((_, __) => null),
      _retryWithBackoff(
          () => _client.get(forecastUri).timeout(requestTimeout)),
    ]);

    marineResponse = results[0];
    forecastResponse = results[1]!;

    // Marine failure is non-fatal — wind data from Forecast is primary
    if (marineResponse != null && marineResponse.statusCode != 200) {
      debugPrint(
        'WeatherApi: Marine API returned ${marineResponse.statusCode} '
        '(non-fatal, using wind-only data)',
      );
      marineResponse = null;
    }
    if (forecastResponse.statusCode != 200) {
      throw WeatherApiException(
        type: WeatherApiErrorType.server,
        message: 'Forecast API returned ${forecastResponse.statusCode}',
      );
    }

    return parseGridResponse(
      marineBody: marineResponse?.body,
      forecastBody: forecastResponse.body,
      grid: grid,
    );
  }

  /// Returns adaptive grid size based on map zoom level.
  static int _adaptiveGridSize(double? zoom) {
    if (zoom == null) return defaultGridSize;
    if (zoom >= 10) return maxGridSize;
    if (zoom >= 7) return 6;
    return defaultGridSize;
  }

  /// Builds an n×n list of (lat, lng) pairs across the viewport.
  static List<(double, double)> _buildGrid(
    double south,
    double north,
    double west,
    double east,
    int size,
  ) {
    final points = <(double, double)>[];
    final latStep = (north - south) / (size - 1);
    final lngStep = (east - west) / (size - 1);
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        points.add((south + row * latStep, west + col * lngStep));
      }
    }
    return points;
  }

  /// Builds the Marine API URI with multi-coordinate lat/lng (wave data).
  Uri _buildMarineUri(String lats, String lngs) {
    return Uri.parse(marineUrl).replace(
      queryParameters: {
        'latitude': lats,
        'longitude': lngs,
        'current': 'wave_height,wave_direction,wave_period',
        'hourly': 'wave_height,wave_direction,wave_period',
        'forecast_days': '$forecastDays',
      },
    );
  }

  /// Builds the Forecast API URI — wind + atmospheric data.
  Uri _buildForecastUri(String lats, String lngs) {
    return Uri.parse(forecastUrl).replace(
      queryParameters: {
        'latitude': lats,
        'longitude': lngs,
        'current': 'wind_speed_10m,wind_direction_10m,wind_gusts_10m,'
            'precipitation,cloud_cover,visibility,'
            'pressure_msl,temperature_2m,apparent_temperature,'
            'relative_humidity_2m',
        'hourly': 'wind_speed_10m,wind_direction_10m,wind_gusts_10m,'
            'precipitation,cloud_cover,visibility,'
            'pressure_msl,temperature_2m',
        'wind_speed_unit': 'kn',
        'forecast_days': '$forecastDays',
      },
    );
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
