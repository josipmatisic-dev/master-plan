/// Atmospheric data models for weather overlays.
library;

import 'package:flutter/foundation.dart';

import 'lat_lng.dart';

/// Real atmospheric conditions at a grid point.
@immutable
class AtmosphericDataPoint {
  /// Geographic position.
  final LatLng position;

  /// Precipitation rate in mm/h.
  final double precipitationMmH;

  /// Cloud cover percentage (0-100).
  final double cloudCoverPercent;

  /// Visibility in meters.
  final double? visibilityMeters;

  /// Sea level pressure in hPa.
  final double? pressureHpa;

  /// Temperature at 2m in Celsius.
  final double? temperatureCelsius;

  /// Apparent temperature in Celsius.
  final double? apparentTempCelsius;

  /// Relative humidity percentage (0-100).
  final double? humidityPercent;

  /// Creates an atmospheric data point.
  const AtmosphericDataPoint({
    required this.position,
    required this.precipitationMmH,
    required this.cloudCoverPercent,
    this.visibilityMeters,
    this.pressureHpa,
    this.temperatureCelsius,
    this.apparentTempCelsius,
    this.humidityPercent,
  });

  /// Whether it's raining (>0.1 mm/h).
  bool get isRaining => precipitationMmH > 0.1;

  /// Whether visibility is reduced (<5000m).
  bool get isLowVisibility =>
      visibilityMeters != null && visibilityMeters! < 5000;

  /// Whether it's foggy (<1000m visibility).
  bool get isFoggy => visibilityMeters != null && visibilityMeters! < 1000;

  /// Whether it's overcast (>80% cloud).
  bool get isOvercast => cloudCoverPercent > 80;

  /// Rain intensity 0.0-1.0 for overlay rendering.
  double get rainIntensity {
    if (precipitationMmH <= 0.1) return 0.0;
    if (precipitationMmH <= 1.0) return 0.2;
    if (precipitationMmH <= 4.0) return 0.5;
    if (precipitationMmH <= 10.0) return 0.8;
    return 1.0;
  }

  /// Fog density 0.0-1.0 based on actual visibility.
  double get fogDensity {
    if (visibilityMeters == null || visibilityMeters! >= 10000) return 0.0;
    if (visibilityMeters! >= 5000) return 0.1;
    if (visibilityMeters! >= 2000) return 0.3;
    if (visibilityMeters! >= 1000) return 0.5;
    if (visibilityMeters! >= 500) return 0.7;
    return 0.9;
  }

  /// Creates from JSON.
  factory AtmosphericDataPoint.fromJson(Map<String, dynamic> json) {
    return AtmosphericDataPoint(
      position: LatLng.fromJson(json['pos']),
      precipitationMmH: (json['precip'] as num).toDouble(),
      cloudCoverPercent: (json['cloud'] as num).toDouble(),
      visibilityMeters: (json['vis'] as num?)?.toDouble(),
      pressureHpa: (json['pres'] as num?)?.toDouble(),
      temperatureCelsius: (json['temp'] as num?)?.toDouble(),
      apparentTempCelsius: (json['appTemp'] as num?)?.toDouble(),
      humidityPercent: (json['hum'] as num?)?.toDouble(),
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'pos': position.toJson(),
        'precip': precipitationMmH,
        'cloud': cloudCoverPercent,
        if (visibilityMeters != null) 'vis': visibilityMeters,
        if (pressureHpa != null) 'pres': pressureHpa,
        if (temperatureCelsius != null) 'temp': temperatureCelsius,
        if (apparentTempCelsius != null) 'appTemp': apparentTempCelsius,
        if (humidityPercent != null) 'hum': humidityPercent,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AtmosphericDataPoint &&
        other.position == position &&
        other.precipitationMmH == precipitationMmH;
  }

  @override
  int get hashCode => Object.hash(position, precipitationMmH);
}
