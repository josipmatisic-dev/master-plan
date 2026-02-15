/// Boat position model for GPS tracking and navigation display.
library;

import 'package:flutter/foundation.dart';

import 'lat_lng.dart';

/// ISS-018: Maximum realistic speed for position-jump filtering (m/s).
const double maxRealisticSpeedMps = 50.0;

/// Maximum GPS accuracy considered trustworthy (meters).
const double maxAccuracyThresholdMeters = 50.0;

/// Maximum number of track history points to retain.
const int maxTrackHistoryPoints = 1000;

/// A single recorded boat position with navigation metadata.
@immutable
class BoatPosition {
  /// Geographic position (WGS84).
  final LatLng position;

  /// Timestamp when this position was recorded.
  final DateTime timestamp;

  /// Speed over ground in knots. Null if unknown.
  final double? speedKnots;

  /// Course over ground in degrees (0-359) from GPS. Null if unknown.
  final double? courseTrue;

  /// Compass heading in degrees (0-359) from HDG/HDM sentence. Null if unknown.
  final double? heading;

  /// Horizontal accuracy estimate in meters. Defaults to 0.0.
  final double accuracy;

  /// GPS fix quality (0 = invalid, 1 = GPS, 2 = DGPS, etc.).
  final int fixQuality;

  /// Number of satellites used in fix.
  final int satellites;

  /// Altitude above mean sea level in meters. Null if unavailable.
  final double? altitudeMeters;

  /// Latitude in degrees.
  double get latitude => position.latitude;

  /// Longitude in degrees.
  double get longitude => position.longitude;

  /// Whether this position has a valid GPS fix.
  bool get isValid => fixQuality > 0;

  /// Whether this position is within the accuracy threshold.
  bool get isAccurate => accuracy <= maxAccuracyThresholdMeters;

  /// Best available heading: prefers courseTrue over compass heading.
  double? get bestHeading => courseTrue ?? heading;

  /// Creates an immutable boat position record.
  const BoatPosition({
    required this.position,
    required this.timestamp,
    this.speedKnots,
    this.courseTrue,
    this.heading,
    this.accuracy = 0.0,
    this.fixQuality = 0,
    this.satellites = 0,
    this.altitudeMeters,
  });

  /// Creates a copy with the given fields replaced.
  BoatPosition copyWith({
    LatLng? position,
    DateTime? timestamp,
    double? speedKnots,
    double? courseTrue,
    double? heading,
    double? accuracy,
    int? fixQuality,
    int? satellites,
    double? altitudeMeters,
  }) {
    return BoatPosition(
      position: position ?? this.position,
      timestamp: timestamp ?? this.timestamp,
      speedKnots: speedKnots ?? this.speedKnots,
      courseTrue: courseTrue ?? this.courseTrue,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      fixQuality: fixQuality ?? this.fixQuality,
      satellites: satellites ?? this.satellites,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoatPosition &&
        other.position == position &&
        other.timestamp == timestamp &&
        other.speedKnots == speedKnots &&
        other.courseTrue == courseTrue;
  }

  @override
  int get hashCode => Object.hash(position, timestamp, speedKnots, courseTrue);

  @override
  String toString() => 'BoatPosition(${position.latitude.toStringAsFixed(5)}, '
      '${position.longitude.toStringAsFixed(5)}, '
      'SOG: ${speedKnots?.toStringAsFixed(1) ?? "n/a"} kn, '
      'COG: ${courseTrue?.toStringAsFixed(1) ?? "n/a"}°)';
}

/// Lightweight track point for breadcrumb trail rendering.
@immutable
class TrackPoint {
  /// Latitude in degrees.
  final double lat;

  /// Longitude in degrees.
  final double lng;

  /// Speed in knots at this point (for coloring).
  final double speedKnots;

  /// Milliseconds since epoch.
  final int timestampMs;

  /// Creates a compact track point.
  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.speedKnots,
    required this.timestampMs,
  });

  /// Create from a full BoatPosition.
  factory TrackPoint.fromPosition(BoatPosition pos) {
    return TrackPoint(
      lat: pos.position.latitude,
      lng: pos.position.longitude,
      speedKnots: pos.speedKnots ?? 0,
      timestampMs: pos.timestamp.millisecondsSinceEpoch,
    );
  }
}
