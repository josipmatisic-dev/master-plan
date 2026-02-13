/// Boat position model for GPS tracking.
library;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// A single recorded boat position with navigation metadata.
@immutable
class BoatPosition {
  /// Geographic position (WGS84).
  final LatLng position;

  /// Heading / course over ground in degrees (0-359). Null if unknown.
  final double? headingDegrees;

  /// Speed over ground in knots. Null if unknown.
  final double? speedKnots;

  /// Horizontal accuracy estimate in meters. Null if unavailable.
  final double? accuracyMeters;

  /// Timestamp when this position was recorded.
  final DateTime timestamp;

  /// Creates an immutable boat position record.
  const BoatPosition({
    required this.position,
    required this.timestamp,
    this.headingDegrees,
    this.speedKnots,
    this.accuracyMeters,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoatPosition &&
        other.position == position &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(position, timestamp);

  @override
  String toString() =>
      'BoatPosition(${position.latitude.toStringAsFixed(5)}, '
      '${position.longitude.toStringAsFixed(5)}, '
      '${speedKnots?.toStringAsFixed(1) ?? "?"}kn)';
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
