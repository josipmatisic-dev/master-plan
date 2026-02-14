/// Weather data models for marine weather overlays.
///
/// Contains grid-based wind, wave, current, and SST data
/// fetched from the Open-Meteo Marine API.
library;

import 'package:flutter/foundation.dart';

import 'lat_lng.dart';

/// A single wind measurement at a grid point.
@immutable
class WindDataPoint {
  /// Geographic position of this measurement.
  final LatLng position;

  /// Wind speed at 10m above ground in knots.
  final double speedKnots;

  /// Wind direction in degrees (0-360, meteorological convention).
  ///
  /// Direction the wind is coming FROM: 0 = North, 90 = East.
  final double directionDegrees;

  /// Creates a wind data point.
  const WindDataPoint({
    required this.position,
    required this.speedKnots,
    required this.directionDegrees,
  });

  /// Beaufort scale number (0-12) based on wind speed in knots.
  int get beaufortScale {
    if (speedKnots < 1) return 0;
    if (speedKnots < 4) return 1;
    if (speedKnots < 7) return 2;
    if (speedKnots < 11) return 3;
    if (speedKnots < 17) return 4;
    if (speedKnots < 22) return 5;
    if (speedKnots < 28) return 6;
    if (speedKnots < 34) return 7;
    if (speedKnots < 41) return 8;
    if (speedKnots < 48) return 9;
    if (speedKnots < 56) return 10;
    if (speedKnots < 64) return 11;
    return 12;
  }

  @override
  String toString() => 'WindDataPoint(${position.latitude.toStringAsFixed(2)}, '
      '${position.longitude.toStringAsFixed(2)}, '
      '${speedKnots.toStringAsFixed(1)} kts, '
      '${directionDegrees.toStringAsFixed(0)}°)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindDataPoint &&
        other.position == position &&
        other.speedKnots == speedKnots &&
        other.directionDegrees == directionDegrees;
  }

  @override
  int get hashCode => Object.hash(position, speedKnots, directionDegrees);
}

/// A single wave measurement at a grid point.
@immutable
class WaveDataPoint {
  /// Geographic position of this measurement.
  final LatLng position;

  /// Significant wave height in meters.
  final double heightMeters;

  /// Wave direction in degrees (0-360).
  ///
  /// Direction the waves are coming FROM.
  final double directionDegrees;

  /// Wave period in seconds (null if unavailable).
  final double? periodSeconds;

  /// Creates a wave data point.
  const WaveDataPoint({
    required this.position,
    required this.heightMeters,
    required this.directionDegrees,
    this.periodSeconds,
  });

  @override
  String toString() => 'WaveDataPoint(${position.latitude.toStringAsFixed(2)}, '
      '${position.longitude.toStringAsFixed(2)}, '
      '${heightMeters.toStringAsFixed(1)} m, '
      '${directionDegrees.toStringAsFixed(0)}°)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaveDataPoint &&
        other.position == position &&
        other.heightMeters == heightMeters &&
        other.directionDegrees == directionDegrees;
  }

  @override
  int get hashCode => Object.hash(position, heightMeters, directionDegrees);
}

/// Aggregated weather data for a viewport region.
///
/// Contains grid-based measurements fetched from the Open-Meteo API.
/// Used by [WeatherProvider] and consumed by overlay widgets.
@immutable
class WeatherData {
  /// Wind measurements at grid points.
  final List<WindDataPoint> windPoints;

  /// Wave measurements at grid points.
  final List<WaveDataPoint> wavePoints;

  /// Hourly forecast frames (time-indexed snapshots).
  final List<WeatherFrame> frames;

  /// Timestamp when data was fetched.
  final DateTime fetchedAt;

  /// Grid resolution in degrees (e.g., 0.25 for ~25km).
  final double gridResolution;

  /// Creates a weather data snapshot.
  const WeatherData({
    required this.windPoints,
    required this.wavePoints,
    required this.fetchedAt,
    this.frames = const [],
    this.gridResolution = 0.25,
  });

  /// Empty weather data.
  static final empty = WeatherData(
    windPoints: const [],
    wavePoints: const [],
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Whether this data is empty (no measurements).
  bool get isEmpty => windPoints.isEmpty && wavePoints.isEmpty;

  /// Whether this data has wind measurements.
  bool get hasWind => windPoints.isNotEmpty;

  /// Whether this data has wave measurements.
  bool get hasWaves => wavePoints.isNotEmpty;

  /// Whether this data has hourly forecast frames.
  bool get hasFrames => frames.isNotEmpty;

  /// Number of hourly forecast frames.
  int get frameCount => frames.length;

  /// Age of this data since it was fetched.
  Duration get age => DateTime.now().difference(fetchedAt);

  /// Whether this data is stale (older than 1 hour).
  bool get isStale => age > const Duration(hours: 1);

  @override
  String toString() => 'WeatherData(wind: ${windPoints.length} pts, '
      'wave: ${wavePoints.length} pts, '
      'frames: ${frames.length}, '
      'age: ${age.inMinutes} min)';
}

/// A single hourly forecast frame (time-indexed weather snapshot).
@immutable
class WeatherFrame {
  /// Forecast timestamp for this frame.
  final DateTime time;

  /// Wind data for this hour.
  final WindDataPoint? wind;

  /// Wave data for this hour.
  final WaveDataPoint? wave;

  /// Creates a forecast frame.
  const WeatherFrame({
    required this.time,
    this.wind,
    this.wave,
  });

  /// Whether this frame has wind data.
  bool get hasWind => wind != null;

  /// Whether this frame has wave data.
  bool get hasWave => wave != null;

  @override
  String toString() => 'WeatherFrame($time, '
      'wind: ${wind != null ? "${wind!.speedKnots.toStringAsFixed(1)} kts" : "n/a"}, '
      'wave: ${wave != null ? "${wave!.heightMeters.toStringAsFixed(1)} m" : "n/a"})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherFrame &&
        other.time == time &&
        other.wind == wind &&
        other.wave == wave;
  }

  @override
  int get hashCode => Object.hash(time, wind, wave);
}

/// Default cache TTL for weather data (1 hour).
const Duration weatherCacheTtl = Duration(hours: 1);

/// Grid resolution for weather data in degrees (~25km).
const double weatherGridResolution = 0.25;
