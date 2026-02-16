/// Weather data models for marine weather overlays.
library;

import 'package:flutter/foundation.dart';

import 'atmospheric_data.dart';
import 'weather_data_points.dart';

export 'weather_data_points.dart';

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

  /// Optimized spatial index for O(1) lookup.
  /// Key: "latIdx_lngIdx"
  final Map<String, WindDataPoint> _gridIndex = {};

  /// Creates a weather data snapshot.
  WeatherData({
    required this.windPoints,
    required this.wavePoints,
    required this.fetchedAt,
    this.atmosphericPoints = const [],
    this.frames = const [],
    this.gridResolution = 0.25,
  }) {
    _buildGridIndex();
  }

  void _buildGridIndex() {
    _gridIndex.clear();
    for (final p in windPoints) {
      final latKey = (p.position.latitude / gridResolution).floor();
      final lngKey = (p.position.longitude / gridResolution).floor();
      _gridIndex['${latKey}_$lngKey'] = p;
    }
  }

  /// Bilinear interpolation of wind vector at (lat, lng).
  /// Returns a simple record with (u, v) components.
  ({double u, double v}) getInterpolatedWind(double lat, double lng) {
    // 1. Find grid cell indices (floor to get South-West corner)
    final latIdx = (lat / gridResolution).floor();
    final lngIdx = (lng / gridResolution).floor();

    // 2. Get the four corner points
    // P00 (South-West)
    final p00 = _gridIndex['${latIdx}_$lngIdx'];

    // If we have no data at the base point, return zero wind
    if (p00 == null) {
      return (u: 0.0, v: 0.0);
    }

    // P10 (South-East) - next longitude
    final p10 = _gridIndex['${latIdx}_${lngIdx + 1}'] ?? p00;

    // P01 (North-West) - next latitude
    final p01 = _gridIndex['${latIdx + 1}_$lngIdx'] ?? p00;

    // P11 (North-East) - next lat & lng
    final p11 = _gridIndex['${latIdx + 1}_${lngIdx + 1}'] ?? p00;

    // 3. Calculate fractional offsets (0.0 to 1.0) within the cell
    // latitude fraction (s)
    final s = (lat - latIdx * gridResolution) / gridResolution;
    // longitude fraction (t)
    final t = (lng - lngIdx * gridResolution) / gridResolution;

    // 4. Bilinear Interpolation
    // Pre-calculate weights for speed
    final w00 = (1 - t) * (1 - s);
    final w10 = t * (1 - s);
    final w01 = (1 - t) * s;
    final w11 = t * s;

    final u = (p00.u * w00) + (p10.u * w10) + (p01.u * w01) + (p11.u * w11);
    final v = (p00.v * w00) + (p10.v * w10) + (p01.v * w01) + (p11.v * w11);

    return (u: u, v: v);
  }

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
        listEquals(other.windPoints, windPoints) &&
        listEquals(other.wavePoints, wavePoints) &&
        listEquals(other.atmosphericPoints, atmosphericPoints);
  }

  @override
  int get hashCode => Object.hash(time, windPoints.length, wavePoints.length);
}

/// Default cache TTL for weather data (1 hour).
const Duration weatherCacheTtl = Duration(hours: 1);

/// Grid resolution for weather data in degrees (~25km).
const double weatherGridResolution = 0.25;
