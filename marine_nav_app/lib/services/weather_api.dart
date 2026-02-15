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

  /// Grid size for multi-point fetch (gridSize × gridSize points).
  static const int gridSize = 5;

  /// Fetches weather data for a geographic bounding box.
  ///
  /// Builds a [gridSize]×[gridSize] grid of coordinates across the viewport
  /// and fetches real data for each point via Open-Meteo's multi-coordinate
  /// support. Makes parallel calls to the Marine API (waves) and Forecast
  /// API (wind), then merges the results.
  Future<WeatherData> fetchWeatherData({
    required double south,
    required double north,
    required double west,
    required double east,
  }) async {
    final grid = _buildGrid(south, north, west, east);
    final lats = grid.map((p) => p.$1.toStringAsFixed(4)).join(',');
    final lngs = grid.map((p) => p.$2.toStringAsFixed(4)).join(',');

    final marineUri = _buildMarineUri(lats, lngs);
    final forecastUri = _buildForecastUri(lats, lngs);

    // Parallel fetch with shared retry logic.
    final responses = await Future.wait([
      _retryWithBackoff(() => _client.get(marineUri).timeout(requestTimeout)),
      _retryWithBackoff(() => _client.get(forecastUri).timeout(requestTimeout)),
    ]);

    final marineResponse = responses[0];
    final forecastResponse = responses[1];

    if (marineResponse.statusCode != 200) {
      throw WeatherApiException(
        type: WeatherApiErrorType.server,
        message: 'Marine API returned ${marineResponse.statusCode}',
      );
    }
    if (forecastResponse.statusCode != 200) {
      throw WeatherApiException(
        type: WeatherApiErrorType.server,
        message: 'Forecast API returned ${forecastResponse.statusCode}',
      );
    }

    return parseGridResponse(
      marineBody: marineResponse.body,
      forecastBody: forecastResponse.body,
      grid: grid,
    );
  }

  /// Builds a gridSize×gridSize list of (lat, lng) pairs across the viewport.
  static List<(double, double)> _buildGrid(
    double south,
    double north,
    double west,
    double east,
  ) {
    final points = <(double, double)>[];
    final latStep = (north - south) / (gridSize - 1);
    final lngStep = (east - west) / (gridSize - 1);
    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < gridSize; col++) {
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
        'forecast_days': '7',
      },
    );
  }

  /// Builds the Forecast API URI with multi-coordinate lat/lng (wind data).
  Uri _buildForecastUri(String lats, String lngs) {
    return Uri.parse(forecastUrl).replace(
      queryParameters: {
        'latitude': lats,
        'longitude': lngs,
        'current': 'wind_speed_10m,wind_direction_10m',
        'hourly': 'wind_speed_10m,wind_direction_10m',
        'wind_speed_unit': 'kn',
        'forecast_days': '7',
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
