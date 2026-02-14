/// Weather API response parser.
///
/// Parses separate Marine API (waves) and Forecast API (wind) responses,
/// then generates a 5×5 grid of data points covering the viewport.
library;

import 'dart:convert';
import 'dart:math';

import '../models/lat_lng.dart';
import '../models/weather_data.dart';
import 'weather_api.dart';

/// Grid size for viewport coverage (5×5 = 25 points).
const int _gridSize = 5;

/// Parses dual API responses and expands into a viewport grid.
WeatherData parseDualResponse({
  required String marineBody,
  required String forecastBody,
  required double south,
  required double north,
  required double west,
  required double east,
}) {
  try {
    final windBase = _parseWindResponse(forecastBody);
    final waveBase = _parseWaveResponse(marineBody);

    // Extract hourly frames from both responses.
    final forecastJson = jsonDecode(forecastBody) as Map<String, dynamic>;
    final marineJson = jsonDecode(marineBody) as Map<String, dynamic>;
    final frames = _parseHourlyFrames(
      forecastJson['hourly'] as Map<String, dynamic>?,
      marineJson['hourly'] as Map<String, dynamic>?,
      forecastJson['hourly']?['time'] as List<dynamic>?,
    );

    // Expand single-point data into a 5×5 grid with ±10% variation.
    final rng = Random(42);
    final windPoints = _expandToGrid(
      south: south, north: north, west: west, east: east,
      base: windBase,
      rng: rng,
      builder: (pos, w, r) => WindDataPoint(
        position: pos,
        speedKnots: _vary(w.speedKnots, r),
        directionDegrees: _vary(w.directionDegrees, r) % 360,
      ),
    );
    final wavePoints = _expandToGrid(
      south: south, north: north, west: west, east: east,
      base: waveBase,
      rng: rng,
      builder: (pos, w, r) => WaveDataPoint(
        position: pos,
        heightMeters: _vary(w.heightMeters, r),
        directionDegrees: _vary(w.directionDegrees, r) % 360,
        periodSeconds:
            w.periodSeconds != null ? _vary(w.periodSeconds!, r) : null,
      ),
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
      message: 'Failed to parse response: $e',
    );
  }
}

/// Parses wind data from the Forecast API response.
WindDataPoint? _parseWindResponse(String body) {
  final json = jsonDecode(body) as Map<String, dynamic>;
  final current = json['current'] as Map<String, dynamic>?;
  if (current == null) return null;
  final speed = (current['wind_speed_10m'] as num?)?.toDouble();
  final dir = (current['wind_direction_10m'] as num?)?.toDouble();
  if (speed == null || dir == null) return null;
  final lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
  final lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
  return WindDataPoint(
    position: LatLng(latitude: lat, longitude: lng),
    speedKnots: speed,
    directionDegrees: dir,
  );
}

/// Parses wave data from the Marine API response.
WaveDataPoint? _parseWaveResponse(String body) {
  final json = jsonDecode(body) as Map<String, dynamic>;
  final current = json['current'] as Map<String, dynamic>?;
  if (current == null) return null;
  final height = (current['wave_height'] as num?)?.toDouble();
  final dir = (current['wave_direction'] as num?)?.toDouble();
  final period = (current['wave_period'] as num?)?.toDouble();
  if (height == null || dir == null) return null;
  final lat = (json['latitude'] as num?)?.toDouble() ?? 0.0;
  final lng = (json['longitude'] as num?)?.toDouble() ?? 0.0;
  return WaveDataPoint(
    position: LatLng(latitude: lat, longitude: lng),
    heightMeters: height,
    directionDegrees: dir,
    periodSeconds: period,
  );
}

/// Expands a single base data point into a 5×5 grid with ±10% variation.
List<T> _expandToGrid<T>({
  required double south,
  required double north,
  required double west,
  required double east,
  required dynamic base,
  required Random rng,
  required T Function(LatLng position, dynamic base, Random rng) builder,
}) {
  if (base == null) return [];
  final points = <T>[];
  final latStep = (north - south) / (_gridSize - 1);
  final lngStep = (east - west) / (_gridSize - 1);
  for (var row = 0; row < _gridSize; row++) {
    for (var col = 0; col < _gridSize; col++) {
      final pos = LatLng(
        latitude: south + row * latStep,
        longitude: west + col * lngStep,
      );
      points.add(builder(pos, base, rng));
    }
  }
  return points;
}

/// Applies ±10% random variation to a value.
double _vary(double value, Random rng) {
  final factor = 0.9 + rng.nextDouble() * 0.2; // 0.9 – 1.1
  return value * factor;
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

  final pos = const LatLng(latitude: 0, longitude: 0);

  for (var i = 0; i < times.length; i++) {
    final timeStr = times[i] as String?;
    if (timeStr == null) continue;
    final time = DateTime.tryParse(timeStr);
    if (time == null) continue;

    WindDataPoint? wind;
    if (windSpeeds != null && windDirs != null &&
        i < windSpeeds.length && i < windDirs.length) {
      final speed = (windSpeeds[i] as num?)?.toDouble();
      final dir = (windDirs[i] as num?)?.toDouble();
      if (speed != null && dir != null) {
        wind = WindDataPoint(
            position: pos, speedKnots: speed, directionDegrees: dir);
      }
    }

    WaveDataPoint? wave;
    if (waveHeights != null && waveDirs != null &&
        i < waveHeights.length && i < waveDirs.length) {
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
