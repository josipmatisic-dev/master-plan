/// Weather API response parser.
///
/// Parses separate Marine API (waves) and Forecast API (wind) responses
/// from multi-coordinate grid requests. Each response contains an array
/// of results, one per grid point.
library;

import 'dart:convert';

import '../models/atmospheric_data.dart';
import '../models/lat_lng.dart';
import '../models/weather_data.dart';
import 'weather_api.dart';

/// Parses multi-coordinate API responses into weather data.
///
/// Open-Meteo returns an array of results when given comma-separated
/// lat/lng values. Each array element corresponds to one grid point.
WeatherData parseGridResponse({
  String? marineBody,
  required String forecastBody,
  required List<(double, double)> grid,
}) {
  try {
    final forecastJson = jsonDecode(forecastBody);
    final marineJson = marineBody != null ? jsonDecode(marineBody) : null;

    final windPoints = <WindDataPoint>[];
    final wavePoints = <WaveDataPoint>[];
    final atmosphericPoints = <AtmosphericDataPoint>[];

    // Multi-point response: array of result objects
    final forecastList = forecastJson is List ? forecastJson : [forecastJson];
    final marineList =
        marineJson != null ? (marineJson is List ? marineJson : [marineJson]) : <dynamic>[];

    for (var i = 0; i < grid.length; i++) {
      final pos = LatLng(latitude: grid[i].$1, longitude: grid[i].$2);

      // Parse wind + atmospheric for this grid point
      if (i < forecastList.length) {
        final fc = forecastList[i] as Map<String, dynamic>;
        final current = fc['current'] as Map<String, dynamic>?;
        if (current != null) {
          final speed = (current['wind_speed_10m'] as num?)?.toDouble();
          final dir = (current['wind_direction_10m'] as num?)?.toDouble();
          final gusts = (current['wind_gusts_10m'] as num?)?.toDouble();
          if (speed != null && dir != null) {
            windPoints.add(WindDataPoint(
              position: pos,
              speedKnots: speed,
              directionDegrees: dir,
              gustKnots: gusts,
            ));
          }
          // Parse atmospheric data
          final precip = (current['precipitation'] as num?)?.toDouble();
          final cloud = (current['cloud_cover'] as num?)?.toDouble();
          if (precip != null && cloud != null) {
            atmosphericPoints.add(AtmosphericDataPoint(
              position: pos,
              precipitationMmH: precip,
              cloudCoverPercent: cloud,
              visibilityMeters: (current['visibility'] as num?)?.toDouble(),
              pressureHpa: (current['pressure_msl'] as num?)?.toDouble(),
              temperatureCelsius:
                  (current['temperature_2m'] as num?)?.toDouble(),
              apparentTempCelsius:
                  (current['apparent_temperature'] as num?)?.toDouble(),
              humidityPercent:
                  (current['relative_humidity_2m'] as num?)?.toDouble(),
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

    // Parse hourly frames: collect all grid points for each time step
    final frames = _parseHourlyFrames(
      forecastList: forecastList,
      marineList: marineList,
      grid: grid,
    );

    return WeatherData(
      windPoints: windPoints,
      wavePoints: wavePoints,
      atmosphericPoints: atmosphericPoints,
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

/// Parses hourly forecast frames by iterating time steps and collecting
/// all grid points' wind + wave data for each step.
List<WeatherFrame> _parseHourlyFrames({
  required List<dynamic> forecastList,
  required List<dynamic> marineList,
  required List<(double, double)> grid,
}) {
  if (forecastList.isEmpty && marineList.isEmpty) return [];

  final frames = <WeatherFrame>[];

  // Get the common time array from the first forecast
  final firstForecast =
      forecastList.isNotEmpty ? forecastList[0] as Map<String, dynamic> : null;
  final hourlyForecast = firstForecast?['hourly'] as Map<String, dynamic>?;
  final times = hourlyForecast?['time'] as List<dynamic>?;

  if (times == null || times.isEmpty) return [];

  // Iterate through each time step
  for (var timeIdx = 0; timeIdx < times.length; timeIdx++) {
    final timeStr = times[timeIdx] as String?;
    if (timeStr == null) continue;
    final time = DateTime.tryParse(timeStr);
    if (time == null) continue;

    final windPoints = <WindDataPoint>[];
    final wavePoints = <WaveDataPoint>[];

    // Collect wind data from all grid points at this time step
    for (var gridIdx = 0; gridIdx < forecastList.length; gridIdx++) {
      if (gridIdx >= grid.length) break;
      final pos =
          LatLng(latitude: grid[gridIdx].$1, longitude: grid[gridIdx].$2);
      final fc = forecastList[gridIdx] as Map<String, dynamic>;
      final hourly = fc['hourly'] as Map<String, dynamic>?;

      if (hourly != null) {
        final windSpeeds = hourly['wind_speed_10m'] as List<dynamic>?;
        final windDirs = hourly['wind_direction_10m'] as List<dynamic>?;
        final windGusts = hourly['wind_gusts_10m'] as List<dynamic>?;

        if (windSpeeds != null &&
            windDirs != null &&
            timeIdx < windSpeeds.length &&
            timeIdx < windDirs.length) {
          final speed = (windSpeeds[timeIdx] as num?)?.toDouble();
          final dir = (windDirs[timeIdx] as num?)?.toDouble();
          final gust = windGusts != null && timeIdx < windGusts.length
              ? (windGusts[timeIdx] as num?)?.toDouble()
              : null;
          if (speed != null && dir != null) {
            windPoints.add(WindDataPoint(
              position: pos,
              speedKnots: speed,
              directionDegrees: dir,
              gustKnots: gust,
            ));
          }
        }
      }
    }

    // Collect wave data from all grid points at this time step
    for (var gridIdx = 0; gridIdx < marineList.length; gridIdx++) {
      if (gridIdx >= grid.length) break;
      final pos =
          LatLng(latitude: grid[gridIdx].$1, longitude: grid[gridIdx].$2);
      final mc = marineList[gridIdx] as Map<String, dynamic>;
      final hourly = mc['hourly'] as Map<String, dynamic>?;

      if (hourly != null) {
        final waveHeights = hourly['wave_height'] as List<dynamic>?;
        final waveDirs = hourly['wave_direction'] as List<dynamic>?;
        final wavePeriods = hourly['wave_period'] as List<dynamic>?;

        if (waveHeights != null &&
            waveDirs != null &&
            timeIdx < waveHeights.length &&
            timeIdx < waveDirs.length) {
          final height = (waveHeights[timeIdx] as num?)?.toDouble();
          final wDir = (waveDirs[timeIdx] as num?)?.toDouble();
          final period = wavePeriods != null && timeIdx < wavePeriods.length
              ? (wavePeriods[timeIdx] as num?)?.toDouble()
              : null;
          if (height != null && wDir != null) {
            wavePoints.add(WaveDataPoint(
              position: pos,
              heightMeters: height,
              directionDegrees: wDir,
              periodSeconds: period,
            ));
          }
        }
      }
    }

    // Create frame for this time step
    if (windPoints.isNotEmpty || wavePoints.isNotEmpty) {
      frames.add(WeatherFrame(
        time: time,
        windPoints: windPoints,
        wavePoints: wavePoints,
      ));
    }
  }

  return frames;
}
