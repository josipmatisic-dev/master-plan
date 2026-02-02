/// LatLng model for WGS84 coordinates.
library;

import 'package:flutter/foundation.dart';

/// Immutable latitude/longitude pair in degrees.
@immutable
class LatLng {
  /// Latitude in degrees.
  final double latitude;

  /// Longitude in degrees.
  final double longitude;

  /// Creates a LatLng coordinate.
  const LatLng({
    required this.latitude,
    required this.longitude,
  });

  /// Returns a copy with updated fields.
  LatLng copyWith({
    double? latitude,
    double? longitude,
  }) {
    return LatLng(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
