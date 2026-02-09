/// Boat position model for vessel tracking.
library;

import 'package:flutter/foundation.dart';

import 'lat_lng.dart';

/// Immutable snapshot of the vessel's position and motion at a point in time.
///
/// Created from NMEA GPGGA/GPRMC data by [BoatProvider].
/// Used for rendering the boat marker, track overlay, and MOB positions.
///
/// Usage:
/// ```dart
/// final pos = BoatPosition(
///   position: LatLng(latitude: 59.91, longitude: 10.75),
///   timestamp: DateTime.now(),
///   accuracy: 5.0,
/// );
/// ```
@immutable
class BoatPosition {
  /// Geographic position in WGS84 (latitude/longitude).
  final LatLng position;

  /// Speed over ground in knots (null if unavailable).
  final double? speedKnots;

  /// Course over ground (true heading) in degrees 0–359 (null if unavailable).
  final double? courseTrue;

  /// Magnetic heading in degrees 0–359 (null if unavailable).
  final double? heading;

  /// UTC timestamp when this position was recorded.
  final DateTime timestamp;

  /// Horizontal accuracy estimate in meters.
  ///
  /// Derived from HDOP × baseline. Used for ISS-018 filtering:
  /// positions with accuracy >50 m are candidates for jump rejection.
  final double accuracy;

  /// GPS fix quality indicator (0 = invalid, 1 = GPS, 2 = DGPS, etc.).
  final int fixQuality;

  /// Number of satellites used in fix.
  final int satellites;

  /// Altitude above mean sea level in meters (null if unavailable).
  final double? altitudeMeters;

  /// Creates an immutable [BoatPosition] snapshot.
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

  /// Whether this fix is considered valid (fix quality > 0).
  bool get isValid => fixQuality > 0;

  /// Whether accuracy is within acceptable threshold (<= 50 m).
  bool get isAccurate => accuracy <= 50.0;

  /// Convenience getter for latitude.
  double get latitude => position.latitude;

  /// Convenience getter for longitude.
  double get longitude => position.longitude;

  /// Returns a copy with updated fields.
  BoatPosition copyWith({
    LatLng? position,
    double? speedKnots,
    double? courseTrue,
    double? heading,
    DateTime? timestamp,
    double? accuracy,
    int? fixQuality,
    int? satellites,
    double? altitudeMeters,
  }) {
    return BoatPosition(
      position: position ?? this.position,
      speedKnots: speedKnots ?? this.speedKnots,
      courseTrue: courseTrue ?? this.courseTrue,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
      fixQuality: fixQuality ?? this.fixQuality,
      satellites: satellites ?? this.satellites,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
    );
  }

  @override
  String toString() =>
      'BoatPosition(${position.latitude}, ${position.longitude}, '
      'SOG: ${speedKnots ?? "n/a"} kts, COG: ${courseTrue ?? "n/a"}°)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoatPosition &&
        other.position == position &&
        other.timestamp == timestamp &&
        other.speedKnots == speedKnots &&
        other.courseTrue == courseTrue &&
        other.heading == heading &&
        other.accuracy == accuracy &&
        other.fixQuality == fixQuality &&
        other.satellites == satellites &&
        other.altitudeMeters == altitudeMeters;
  }

  @override
  int get hashCode => Object.hash(
        position,
        timestamp,
        speedKnots,
        courseTrue,
        heading,
        accuracy,
        fixQuality,
        satellites,
        altitudeMeters,
      );
}

/// Maximum speed threshold in meters per second for ISS-018 filtering.
///
/// 50 m/s ≈ 97 knots — unrealistic for most vessels.
/// Used by [BoatProvider] to reject position jumps on GPS reconnect.
const double maxRealisticSpeedMps = 50.0;

/// Maximum accuracy threshold in meters for ISS-018 filtering.
///
/// Positions with accuracy worse than this are candidates for rejection
/// when combined with unrealistic speed.
const double maxAccuracyThresholdMeters = 50.0;

/// Maximum number of track history points before LRU eviction.
const int maxTrackHistoryPoints = 1000;
