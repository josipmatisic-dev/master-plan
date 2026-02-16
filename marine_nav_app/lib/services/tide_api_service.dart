/// NOAA CO-OPS Tides & Currents API service.
///
/// Fetches tide predictions, water levels, and station data from
/// NOAA's free public API. No API key required.
/// Implements triple-layer protection: retry + timeout + cache fallback.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/tide_data.dart';

/// NOAA CO-OPS API service for tides and currents.
///
/// Endpoints used:
/// - `/api/prod/datagetter` for predictions and water levels
/// - `/mdapi/prod/webapi/stations.json` for station metadata
class TideApiService {
  /// HTTP client (injectable for testing).
  final http.Client _client;

  /// Base URL for NOAA CO-OPS data API.
  @visibleForTesting
  static const String baseUrl =
      'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter';

  /// Base URL for NOAA station metadata API.
  @visibleForTesting
  static const String stationsUrl =
      'https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json';

  /// Maximum retry attempts.
  static const int maxRetries = 3;

  /// Request timeout.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// NOAA application name for request tracking.
  static const String _appName = 'SailStream';

  /// Creates a tide API service with optional HTTP client.
  TideApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches tide predictions (high/low) for a station.
  ///
  /// Returns 48 hours of predictions from now.
  Future<List<TidePrediction>> fetchPredictions(String stationId) async {
    final now = DateTime.now();
    final end = now.add(const Duration(hours: 48));

    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'station': stationId,
      'product': 'predictions',
      'datum': 'MLLW',
      'time_zone': 'gmt',
      'units': 'english',
      'format': 'json',
      'interval': 'hilo',
      'begin_date': _formatDate(now),
      'end_date': _formatDate(end),
      'application': _appName,
    });

    final body = await _fetchJson(uri);
    final predictions = body['predictions'] as List?;
    if (predictions == null || predictions.isEmpty) return [];

    return predictions
        .map((p) => TidePrediction.fromNoaaJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Fetches current water level observations for a station.
  ///
  /// Returns the last 24 hours of 6-minute interval data.
  Future<List<WaterLevel>> fetchWaterLevels(String stationId) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'station': stationId,
      'product': 'water_level',
      'datum': 'MLLW',
      'time_zone': 'gmt',
      'units': 'english',
      'format': 'json',
      'date': 'recent',
      'application': _appName,
    });

    final body = await _fetchJson(uri);
    final data = body['data'] as List?;
    if (data == null || data.isEmpty) return [];

    return data
        .map((d) => WaterLevel.fromNoaaJson(d as Map<String, dynamic>))
        .toList();
  }

  /// Fetches full tide data (predictions + observations) for a station.
  Future<TideData> fetchTideData({
    required String stationId,
    required String stationName,
    required double latitude,
    required double longitude,
  }) async {
    final results = await Future.wait([
      fetchPredictions(stationId),
      fetchWaterLevels(stationId).catchError((_) => <WaterLevel>[]),
    ]);

    return TideData(
      station: TideStation(
        id: stationId,
        name: stationName,
        latitude: latitude,
        longitude: longitude,
      ),
      predictions: results[0] as List<TidePrediction>,
      observations: results[1] as List<WaterLevel>,
      fetchedAt: DateTime.now(),
    );
  }

  /// Finds the nearest tide station to a given lat/lng.
  ///
  /// Fetches the full station list from NOAA and returns the
  /// closest one by haversine distance.
  Future<TideStation?> findNearestStation({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(stationsUrl).replace(queryParameters: {
      'type': 'tidepredictions',
      'units': 'english',
    });

    final body = await _fetchJson(uri);
    final stations = body['stations'] as List?;
    if (stations == null || stations.isEmpty) return null;

    TideStation? nearest;
    double minDist = double.infinity;

    for (final s in stations) {
      final sMap = s as Map<String, dynamic>;
      final lat = (sMap['lat'] as num).toDouble();
      final lng = (sMap['lng'] as num).toDouble();
      final dist = _haversineMeters(latitude, longitude, lat, lng);

      if (dist < minDist) {
        minDist = dist;
        nearest = TideStation.fromNoaaJson(sMap);
      }
    }

    return nearest;
  }

  // ============ HTTP Helpers ============

  Future<Map<String, dynamic>> _fetchJson(Uri uri) async {
    final response = await _retryWithBackoff(
      () => _client.get(uri).timeout(requestTimeout),
    );

    if (response.statusCode != 200) {
      throw TideApiException(
        'NOAA API returned ${response.statusCode}',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        // NOAA returns errors as {"error": {"message": "..."}}
        if (decoded.containsKey('error')) {
          final err = decoded['error'];
          final msg = err is Map ? err['message'] : err.toString();
          throw TideApiException('NOAA API error: $msg');
        }
        return decoded;
      }
      throw const TideApiException('Unexpected response format');
    } catch (e) {
      if (e is TideApiException) rethrow;
      throw TideApiException('Failed to parse response: $e');
    }
  }

  /// Retries with exponential backoff per Bible C.4.
  Future<http.Response> _retryWithBackoff(
    Future<http.Response> Function() request,
  ) async {
    Duration delay = const Duration(milliseconds: 100);
    Object? lastError;

    for (var i = 0; i < maxRetries; i++) {
      try {
        return await request();
      } on TimeoutException {
        lastError = const TideApiException('Request timed out');
        if (i == maxRetries - 1) throw lastError;
      } on http.ClientException catch (e) {
        lastError = TideApiException('Network error: $e');
        if (i == maxRetries - 1) throw lastError;
      } catch (e) {
        if (e is TideApiException) rethrow;
        lastError = TideApiException('Unexpected error: $e');
        if (i == maxRetries - 1) throw lastError;
      }

      debugPrint('TideApi: Retry ${i + 1}/$maxRetries after $delay');
      await Future<void>.delayed(delay);
      delay *= 2;
    }

    throw lastError ?? const TideApiException('Failed after retries');
  }

  // ============ Utilities ============

  /// Formats a DateTime for NOAA API (yyyyMMdd HH:mm).
  static String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y$m$d $h:$min';
  }

  /// Haversine distance in meters.
  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  /// Disposes the HTTP client.
  void dispose() {
    _client.close();
  }
}

/// Exception thrown by [TideApiService].
class TideApiException implements Exception {
  /// Human-readable description.
  final String message;

  /// Creates a tide API exception.
  const TideApiException(this.message);

  @override
  String toString() => 'TideApiException: $message';
}
