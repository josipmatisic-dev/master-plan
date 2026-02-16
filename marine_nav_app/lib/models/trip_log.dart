/// Trip log model for recording sailing trips.
///
/// Stores an ordered sequence of waypoints with timestamps and speed data.
/// Supports metadata like trip name and total distance.
library;

import 'package:flutter/foundation.dart';

import 'boat_position.dart';

/// A single waypoint recorded during a trip.
@immutable
class TripWaypoint {
  /// Latitude in degrees.
  final double lat;

  /// Longitude in degrees.
  final double lng;

  /// Speed over ground in knots at this waypoint.
  final double speedKnots;

  /// Course over ground in degrees at this waypoint.
  final double? cogDegrees;

  /// ISO 8601 timestamp string.
  final String timestamp;

  /// Creates a trip waypoint.
  const TripWaypoint({
    required this.lat,
    required this.lng,
    required this.speedKnots,
    required this.timestamp,
    this.cogDegrees,
  });

  /// Creates a waypoint from a BoatPosition.
  factory TripWaypoint.fromPosition(BoatPosition pos) {
    return TripWaypoint(
      lat: pos.latitude,
      lng: pos.longitude,
      speedKnots: pos.speedKnots ?? 0,
      cogDegrees: pos.courseTrue,
      timestamp: pos.timestamp.toUtc().toIso8601String(),
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'speedKnots': speedKnots,
        'timestamp': timestamp,
        if (cogDegrees != null) 'cogDegrees': cogDegrees,
      };

  /// Deserializes from JSON map.
  factory TripWaypoint.fromJson(Map<String, dynamic> json) {
    return TripWaypoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speedKnots: (json['speedKnots'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      cogDegrees: (json['cogDegrees'] as num?)?.toDouble(),
    );
  }
}

/// A recorded sailing trip with waypoints and metadata.
@immutable
class TripLog {
  /// Unique identifier for this trip.
  final String id;

  /// User-provided trip name.
  final String name;

  /// When the trip recording started.
  final DateTime startTime;

  /// When the trip recording ended. Null if still recording.
  final DateTime? endTime;

  /// Ordered list of recorded waypoints.
  final List<TripWaypoint> waypoints;

  /// Total distance traveled in nautical miles.
  final double distanceNm;

  /// Creates a trip log.
  const TripLog({
    required this.id,
    required this.name,
    required this.startTime,
    required this.waypoints,
    this.endTime,
    this.distanceNm = 0,
  });

  /// Whether this trip is currently being recorded.
  bool get isRecording => endTime == null;

  /// Duration of the trip.
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  /// Average speed in knots (0 if no waypoints).
  double get avgSpeedKnots {
    if (waypoints.isEmpty) return 0;
    final sum = waypoints.fold<double>(0, (s, w) => s + w.speedKnots);
    return sum / waypoints.length;
  }

  /// Maximum speed in knots recorded during the trip.
  double get maxSpeedKnots {
    if (waypoints.isEmpty) return 0;
    return waypoints.map((w) => w.speedKnots).reduce((a, b) => a > b ? a : b);
  }

  /// Creates a copy with replaced fields.
  TripLog copyWith({
    String? name,
    DateTime? endTime,
    List<TripWaypoint>? waypoints,
    double? distanceNm,
  }) {
    return TripLog(
      id: id,
      name: name ?? this.name,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      waypoints: waypoints ?? this.waypoints,
      distanceNm: distanceNm ?? this.distanceNm,
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startTime': startTime.toUtc().toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toUtc().toIso8601String(),
        'distanceNm': distanceNm,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
      };

  /// Deserializes from JSON map.
  factory TripLog.fromJson(Map<String, dynamic> json) {
    return TripLog(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      distanceNm: (json['distanceNm'] as num).toDouble(),
      waypoints: (json['waypoints'] as List)
          .map((w) => TripWaypoint.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}
