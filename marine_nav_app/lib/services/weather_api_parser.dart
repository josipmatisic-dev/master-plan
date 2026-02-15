/// Weather API response parser.
///
/// Parses separate Marine API (waves) and Forecast API (wind) responses
/// from multi-coordinate grid requests. Each response contains an array
/// of results, one per grid point.
library;

import 'dart:convert';

import '../models/lat_lng.dart';
import '../models/weather_data.dart';
import 'weather_api.dart';

/// Parses multi-coordinate API responses into weather data.
///
/// Open-Meteo returns an array of results when given comma-separated
/// lat/lng values. Each array element corresponds to one grid point.
WeatherData parseGridResponse({
  required String marineBody,
  required String forecastBody,
  required List<(double, double)> grid,
}) {
  try {
    final forecastJson = jsonDecode(forecastBody);
    final marineJson = jsonDecode(marineBody);

    final windPoints = <WindDataPoint>[];
    final wavePoints = <WaveDataPoint>[];

    // Multi-point response: array of result objects
    final forecastList = forecastJson is List ? forecastJson : [forecastJson];
    final marineList = marineJson is List ? marineJson : [marineJson];

    for (var i = 0; i < grid.length; i++) {
      final pos = LatLng(latitude: grid[i].$1, longitude: grid[i].$2);

      // Parse wind for this grid point
      if (i < forecastList.length) {
        final fc = forecastList[i] as Map<String, dynamic>;
        final current = fc['current'] as Map<String, dynamic>?;
        if (current != null) {
          final speed = (current['wind_speed_10m'] as num?)?.toDouble();
          final dir = (current['wind_direction_10m'] as num?)?.toDouble();
          if (speed != null && dir != null) {
            windPoints.add(WindDataPoint(
              position: pos,
              speedKnots: speed,
              directionDegrees: dir,
            ));
          }
        }
      }

      // Parse waves for this grid point
      if (i < marineList.length) {
        final mc = marineList[i] as Map<String, dynamic>;
        final current = mc['current'] as Map<String, dynamic>?;
        if (current != null) {
          final height = (current['wave_height'] as num?)?.toDouble();
          final dir = (current['wave_direction'] as num?)?.toDouble();
          final period = (current['wave_period'] as num?)?.toDouble();
          if (height != null && dir != null) {
            wavePoints.add(WaveDataPoint(
              position: pos,
              heightMeters: height,
              directionDegrees: dir,
              periodSeconds: period,
            ));
          }
        }
      }
    }

    // Parse hourly frames from the first grid point (representative)
    final firstForecast = forecastList.isNotEmpty
        ? forecastList[0] as Map<String, dynamic>
        : null;
    final firstMarine =
        marineList.isNotEmpty ? marineList[0] as Map<String, dynamic> : null;
    final frames = _parseHourlyFrames(
      firstForecast?['hourly'] as Map<String, dynamic>?,
      firstMarine?['hourly'] as Map<String, dynamic>?,
      firstForecast?['hourly']?['time'] as List<dynamic>?,
    );

    return WeatherData(
      windPoints: windPoints,
      wavePoints: wavePoints,
      frames: frames,
      fetchedAt: DateTime.now(),
    );
  } catch (e) {
    if (e is WeatherApiException) rethrow;
    throw WeatherApiException(
      type: WeatherApiErrorType.parsing,
      message: 'Failed to parse grid response: $e',
    );
  }
}

/// Legacy single-point parser (kept for backward compatibility with tests).
WeatherData parseDualResponse({
  required String marineBody,
  required String forecastBody,
  required double south,
  required double north,
  required double west,
  required double east,
}) {
  return parseGridResponse(
    marineBody: marineBody,
    forecastBody: forecastBody,
    grid: [(south, west)],
  );
}

/// Parses hourly forecast frames by merging wind + wave hourly data.
List<WeatherFrame> _parseHourlyFrames(
  Map<String, dynamic>? forecastHourly,
  Map<String, dynamic>? marineHourly,
  List<dynamic>? times,
) {
  if (times == null) return [];
  final frames = <WeatherFrame>[];

  final windSpeeds = forecastHourly?['wind_speed_10m'] as List<dynamic>?;
  final windDirs = forecastHourly?['wind_direction_10m'] as List<dynamic>?;
  final waveHeights = marineHourly?['wave_height'] as List<dynamic>?;
  final waveDirs = marineHourly?['wave_direction'] as List<dynamic>?;
  final wavePeriods = marineHourly?['wave_period'] as List<dynamic>?;

  const pos = LatLng(latitude: 0, longitude: 0);

  for (var i = 0; i < times.length; i++) {
    final timeStr = times[i] as String?;
    if (timeStr == null) continue;
    final time = DateTime.tryParse(timeStr);
    if (time == null) continue;

    WindDataPoint? wind;
    if (windSpeeds != null &&
        windDirs != null &&
        i < windSpeeds.length &&
        i < windDirs.length) {
      final speed = (windSpeeds[i] as num?)?.toDouble();
      final dir = (windDirs[i] as num?)?.toDouble();
      if (speed != null && dir != null) {
        wind = WindDataPoint(
            position: pos, speedKnots: speed, directionDegrees: dir);
      }
    }

    WaveDataPoint? wave;
    if (waveHeights != null &&
        waveDirs != null &&
        i < waveHeights.length &&
        i < waveDirs.length) {
      final height = (waveHeights[i] as num?)?.toDouble();
      final wDir = (waveDirs[i] as num?)?.toDouble();
      final period = wavePeriods != null && i < wavePeriods.length
          ? (wavePeriods[i] as num?)?.toDouble()
          : null;
      if (height != null && wDir != null) {
        wave = WaveDataPoint(
          position: pos,
          heightMeters: height,
          directionDegrees: wDir,
          periodSeconds: period,
        );
      }
    }

    if (wind != null || wave != null) {
      frames.add(WeatherFrame(time: time, wind: wind, wave: wave));
    }
  }
  return frames;
}
