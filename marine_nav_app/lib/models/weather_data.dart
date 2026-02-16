/// Weather data models for marine weather overlays.
library;

import 'package:flutter/foundation.dart';

import 'atmospheric_data.dart';
import 'lat_lng.dart';

/// A single wind measurement at a grid point.
@immutable
class WindDataPoint {
  /// Geographic position of this measurement.
  final LatLng position;

  /// Wind speed at 10m above ground in knots.
  final double speedKnots;

  /// Wind direction in degrees (0-360, meteorological convention).
  final double directionDegrees;

  /// Wind gust speed in knots. Null if unavailable.
  final double? gustKnots;

  /// Creates a wind data point.
  const WindDataPoint({
    required this.position,
    required this.speedKnots,
    required this.directionDegrees,
    this.gustKnots,
  });

  /// Creates from JSON.
  factory WindDataPoint.fromJson(Map<String, dynamic> json) {
    return WindDataPoint(
      position: LatLng.fromJson(json['pos']),
      speedKnots: (json['spd'] as num).toDouble(),
      directionDegrees: (json['dir'] as num).toDouble(),
      gustKnots: (json['gust'] as num?)?.toDouble(),
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'pos': position.toJson(),
        'spd': speedKnots,
        'dir': directionDegrees,
        if (gustKnots != null) 'gust': gustKnots,
      };

  /// Beaufort scale number (0-12) based on wind speed.
  int get beaufortScale {
    const thresholds = [1, 4, 7, 11, 17, 22, 28, 34, 41, 48, 56, 64];
    for (var i = 0; i < thresholds.length; i++) {
      if (speedKnots < thresholds[i]) return i;
    }
    return 12;
  }

  @override
  String toString() => 'Wind(${position.latitude.toStringAsFixed(2)}, '
      '${speedKnots.toStringAsFixed(1)} kts)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindDataPoint &&
        other.position == position &&
        other.speedKnots == speedKnots &&
        other.directionDegrees == directionDegrees &&
        other.gustKnots == gustKnots;
  }

  @override
  int get hashCode =>
      Object.hash(position, speedKnots, directionDegrees, gustKnots);
}

/// A single wave measurement at a grid point.
@immutable
class WaveDataPoint {
  /// Geographic position.
  final LatLng position;

  /// Significant wave height in meters.
  final double heightMeters;

  /// Wave direction in degrees (coming FROM).
  final double directionDegrees;

  /// Wave period in seconds.
  final double? periodSeconds;

  /// Creates a wave data point.
  const WaveDataPoint({
    required this.position,
    required this.heightMeters,
    required this.directionDegrees,
    this.periodSeconds,
  });

  /// Creates from JSON.
  factory WaveDataPoint.fromJson(Map<String, dynamic> json) {
    return WaveDataPoint(
      position: LatLng.fromJson(json['pos']),
      heightMeters: (json['hgt'] as num).toDouble(),
      directionDegrees: (json['dir'] as num).toDouble(),
      periodSeconds: (json['per'] as num?)?.toDouble(),
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'pos': position.toJson(),
        'hgt': heightMeters,
        'dir': directionDegrees,
        if (periodSeconds != null) 'per': periodSeconds,
      };

  @override
  String toString() => 'Wave(${heightMeters.toStringAsFixed(1)}m)';

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
@immutable
class WeatherData {
  /// Wind measurements at grid points.
  final List<WindDataPoint> windPoints;

  /// Wave measurements at grid points.
  final List<WaveDataPoint> wavePoints;

  /// Atmospheric conditions at grid points.
  final List<AtmosphericDataPoint> atmosphericPoints;

  /// Hourly forecast frames.
  final List<WeatherFrame> frames;

  /// Timestamp when data was fetched.
  final DateTime fetchedAt;

  /// Grid resolution in degrees.
  final double gridResolution;

  /// Creates a weather data snapshot.
  const WeatherData({
    required this.windPoints,
    required this.wavePoints,
    required this.fetchedAt,
    this.atmosphericPoints = const [],
    this.frames = const [],
    this.gridResolution = 0.25,
  });

  /// Creates from JSON.
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      windPoints: (json['wind'] as List?)
              ?.map((e) => WindDataPoint.fromJson(e))
              .toList() ??
          const [],
      wavePoints: (json['wave'] as List?)
              ?.map((e) => WaveDataPoint.fromJson(e))
              .toList() ??
          const [],
      atmosphericPoints: (json['atmo'] as List?)
              ?.map((e) => AtmosphericDataPoint.fromJson(e))
              .toList() ??
          const [],
      frames: (json['frames'] as List?)
              ?.map((e) => WeatherFrame.fromJson(e))
              .toList() ??
          const [],
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      gridResolution: (json['res'] as num).toDouble(),
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'wind': windPoints.map((e) => e.toJson()).toList(),
        'wave': wavePoints.map((e) => e.toJson()).toList(),
        if (atmosphericPoints.isNotEmpty)
          'atmo': atmosphericPoints.map((e) => e.toJson()).toList(),
        'frames': frames.map((e) => e.toJson()).toList(),
        'ts': fetchedAt.millisecondsSinceEpoch,
        'res': gridResolution,
      };

  /// Empty weather data singleton.
  static final empty = WeatherData(
    windPoints: const [],
    wavePoints: const [],
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Whether this data is empty.
  bool get isEmpty =>
      windPoints.isEmpty && wavePoints.isEmpty && frames.isEmpty;

  /// Whether wind data is present.
  bool get hasWind => windPoints.isNotEmpty;

  /// Whether wave data is present.
  bool get hasWaves => wavePoints.isNotEmpty;

  /// Whether atmospheric data is present.
  bool get hasAtmospheric => atmosphericPoints.isNotEmpty;

  /// Whether forecast frames are present.
  bool get hasFrames => frames.isNotEmpty;

  /// Number of forecast frames.
  int get frameCount => frames.length;

  /// Age since data was fetched.
  Duration get age => DateTime.now().difference(fetchedAt);

  /// Whether data is stale (>1 hour old).
  bool get isStale => age > const Duration(hours: 1);

  @override
  String toString() => 'WeatherData(w:${windPoints.length} '
      'wv:${wavePoints.length} fr:${frames.length})';
}

/// A single hourly forecast frame.
@immutable
class WeatherFrame {
  /// Forecast timestamp.
  final DateTime time;

  /// Wind data points for this hour.
  final List<WindDataPoint> windPoints;

  /// Wave data points for this hour.
  final List<WaveDataPoint> wavePoints;

  /// Atmospheric data points for this hour.
  final List<AtmosphericDataPoint> atmosphericPoints;

  /// Creates a forecast frame.
  const WeatherFrame({
    required this.time,
    this.windPoints = const [],
    this.wavePoints = const [],
    this.atmosphericPoints = const [],
  });

  /// Creates from JSON.
  factory WeatherFrame.fromJson(Map<String, dynamic> json) {
    return WeatherFrame(
      time: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      windPoints: (json['wind'] as List?)
              ?.map((e) => WindDataPoint.fromJson(e))
              .toList() ??
          const [],
      wavePoints: (json['wave'] as List?)
              ?.map((e) => WaveDataPoint.fromJson(e))
              .toList() ??
          const [],
      atmosphericPoints: (json['atmo'] as List?)
              ?.map((e) => AtmosphericDataPoint.fromJson(e))
              .toList() ??
          const [],
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'ts': time.millisecondsSinceEpoch,
        if (windPoints.isNotEmpty)
          'wind': windPoints.map((e) => e.toJson()).toList(),
        if (wavePoints.isNotEmpty)
          'wave': wavePoints.map((e) => e.toJson()).toList(),
        if (atmosphericPoints.isNotEmpty)
          'atmo': atmosphericPoints.map((e) => e.toJson()).toList(),
      };

  /// Whether this frame has wind data.
  bool get hasWind => windPoints.isNotEmpty;

  /// Whether this frame has wave data.
  bool get hasWave => wavePoints.isNotEmpty;

  /// Whether this frame has atmospheric data.
  bool get hasAtmospheric => atmosphericPoints.isNotEmpty;

  @override
  String toString() => 'Frame($time, w:${windPoints.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherFrame &&
        other.time == time &&
        other.windPoints == windPoints &&
        other.wavePoints == wavePoints &&
        other.atmosphericPoints == atmosphericPoints;
  }

  @override
  int get hashCode => Object.hash(time, windPoints, wavePoints);
}

/// Default cache TTL for weather data (1 hour).
const Duration weatherCacheTtl = Duration(hours: 1);

/// Grid resolution for weather data in degrees (~25km).
const double weatherGridResolution = 0.25;
