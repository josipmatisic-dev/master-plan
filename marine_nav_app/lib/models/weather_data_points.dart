/// Wind and wave data point models for weather overlays.
library;

import 'dart:math';

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
  final double directionDegrees;

  /// Wind gust speed in knots. Null if unavailable.
  final double? gustKnots;

  /// U component (zonal velocity) in knots.
  final double u;

  /// V component (meridional velocity) in knots.
  final double v;

  /// Creates a wind data point.
  WindDataPoint({
    required this.position,
    required this.speedKnots,
    required this.directionDegrees,
    this.gustKnots,
  })  : u = -speedKnots * sin(directionDegrees * pi / 180.0),
        v = -speedKnots * cos(directionDegrees * pi / 180.0);

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
