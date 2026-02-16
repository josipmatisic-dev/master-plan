/// Tide data models for NOAA CO-OPS tides and currents API.
///
/// Supports tide predictions (high/low), water level observations,
/// and station metadata. Used by [TideApiService].
library;

import 'package:flutter/foundation.dart';

/// Type of tide event.
enum TideType {
  /// High tide.
  high,

  /// Low tide.
  low,
}

/// A single tide prediction (high or low water).
@immutable
class TidePrediction {
  /// Timestamp of the tide event.
  final DateTime time;

  /// Water level in meters relative to datum.
  final double heightMeters;

  /// Whether this is a high or low tide.
  final TideType type;

  /// Creates a tide prediction.
  const TidePrediction({
    required this.time,
    required this.heightMeters,
    required this.type,
  });

  /// Parses from NOAA JSON prediction entry.
  factory TidePrediction.fromNoaaJson(Map<String, dynamic> json) {
    return TidePrediction(
      time: DateTime.parse(json['t'] as String),
      heightMeters: double.parse(json['v'] as String) * 0.3048,
      type: (json['type'] as String) == 'H' ? TideType.high : TideType.low,
    );
  }

  @override
  String toString() =>
      'TidePrediction(${type.name}, ${heightMeters.toStringAsFixed(2)}m, $time)';
}

/// Current water level observation.
@immutable
class WaterLevel {
  /// Timestamp of the observation.
  final DateTime time;

  /// Water level in meters relative to datum.
  final double heightMeters;

  /// Creates a water level observation.
  const WaterLevel({
    required this.time,
    required this.heightMeters,
  });

  /// Parses from NOAA JSON observation entry.
  factory WaterLevel.fromNoaaJson(Map<String, dynamic> json) {
    return WaterLevel(
      time: DateTime.parse(json['t'] as String),
      heightMeters: double.parse(json['v'] as String) * 0.3048,
    );
  }
}

/// A NOAA tide station with metadata.
@immutable
class TideStation {
  /// NOAA station ID (e.g., "9414290").
  final String id;

  /// Station name (e.g., "San Francisco, CA").
  final String name;

  /// Station latitude.
  final double latitude;

  /// Station longitude.
  final double longitude;

  /// Creates a tide station.
  const TideStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Parses from NOAA station metadata JSON.
  factory TideStation.fromNoaaJson(Map<String, dynamic> json) {
    return TideStation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'TideStation($id: $name)';
}

/// Aggregated tide data for a station.
@immutable
class TideData {
  /// The station this data belongs to.
  final TideStation station;

  /// Tide predictions (high/low) for the forecast period.
  final List<TidePrediction> predictions;

  /// Current water level observations (if available).
  final List<WaterLevel> observations;

  /// When this data was fetched.
  final DateTime fetchedAt;

  /// Creates a tide data bundle.
  const TideData({
    required this.station,
    required this.predictions,
    this.observations = const [],
    required this.fetchedAt,
  });

  /// Next upcoming tide event (or null if none).
  TidePrediction? get nextTide {
    final now = DateTime.now();
    for (final p in predictions) {
      if (p.time.isAfter(now)) return p;
    }
    return null;
  }

  /// Next high tide (or null if none).
  TidePrediction? get nextHighTide {
    final now = DateTime.now();
    for (final p in predictions) {
      if (p.time.isAfter(now) && p.type == TideType.high) return p;
    }
    return null;
  }

  /// Next low tide (or null if none).
  TidePrediction? get nextLowTide {
    final now = DateTime.now();
    for (final p in predictions) {
      if (p.time.isAfter(now) && p.type == TideType.low) return p;
    }
    return null;
  }

  /// Latest water level observation (or null).
  WaterLevel? get latestObservation =>
      observations.isNotEmpty ? observations.last : null;

  /// Serializes to JSON for caching.
  Map<String, dynamic> toJson() => {
        'station': {
          'id': station.id,
          'name': station.name,
          'lat': station.latitude,
          'lng': station.longitude,
        },
        'predictions': predictions
            .map((p) => {
                  't': p.time.toUtc().toIso8601String(),
                  'v': (p.heightMeters / 0.3048).toStringAsFixed(3),
                  'type': p.type == TideType.high ? 'H' : 'L',
                })
            .toList(),
        'observations': observations
            .map((o) => {
                  't': o.time.toUtc().toIso8601String(),
                  'v': (o.heightMeters / 0.3048).toStringAsFixed(3),
                })
            .toList(),
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      };

  /// Deserializes from cached JSON.
  factory TideData.fromJson(Map<String, dynamic> json) {
    final stationJson = json['station'] as Map<String, dynamic>;
    return TideData(
      station: TideStation(
        id: stationJson['id'] as String,
        name: stationJson['name'] as String,
        latitude: (stationJson['lat'] as num).toDouble(),
        longitude: (stationJson['lng'] as num).toDouble(),
      ),
      predictions: (json['predictions'] as List)
          .map((p) => TidePrediction.fromNoaaJson(p as Map<String, dynamic>))
          .toList(),
      observations: (json['observations'] as List?)
              ?.map((o) => WaterLevel.fromNoaaJson(o as Map<String, dynamic>))
              .toList() ??
          const [],
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }
}
