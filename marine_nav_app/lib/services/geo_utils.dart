// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/route.dart';

/// Geographic utility functions for distance and bearing calculations.
///
/// Provides haversine formula implementations for calculating distances
/// and bearings between geographic coordinates on Earth.
class GeoUtils {
  /// Earth's mean radius in meters.
  static const double earthRadiusMeters = 6371000.0;

  /// Converts degrees to radians.
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Converts radians to degrees.
  static double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  /// Converts meters to nautical miles.
  static double _metersToNauticalMiles(double meters) {
    return meters / 1852.0;
  }

  /// Calculates great-circle distance between two points using Haversine formula.
  ///
  /// Returns distance in meters.
  static double distanceBetweenMeters(LatLng from, LatLng to) {
    final lat1Rad = _degreesToRadians(from.latitude);
    final lat2Rad = _degreesToRadians(to.latitude);
    final deltaLatRad = _degreesToRadians(to.latitude - from.latitude);
    final deltaLngRad = _degreesToRadians(to.longitude - from.longitude);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Calculates great-circle distance between two points using Haversine formula.
  ///
  /// Returns distance in nautical miles.
  static double distanceBetween(LatLng from, LatLng to) {
    return _metersToNauticalMiles(distanceBetweenMeters(from, to));
  }

  /// Calculates initial bearing (true course) from one point to another.
  ///
  /// Returns bearing in degrees (0-360) where 0° is north, 90° is east, etc.
  static double bearingBetween(LatLng from, LatLng to) {
    final lat1Rad = _degreesToRadians(from.latitude);
    final lat2Rad = _degreesToRadians(to.latitude);
    final deltaLngRad = _degreesToRadians(to.longitude - from.longitude);

    final y = math.sin(deltaLngRad) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);

    var bearing = _radiansToDegrees(math.atan2(y, x));
    bearing = (bearing + 360) % 360; // Normalize to 0-360

    return bearing;
  }

  /// Calculates the total distance of a route in nautical miles.
  ///
  /// Sums great-circle distances between consecutive waypoints.
  /// Returns 0 if route has fewer than 2 waypoints.
  static double getTotalRouteDistance(Route route) {
    if (route.waypoints.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < route.waypoints.length - 1; i++) {
      total += distanceBetween(
        route.waypoints[i].position,
        route.waypoints[i + 1].position,
      );
    }
    return total;
  }

  /// Calculates distance from current position to next waypoint.
  ///
  /// Returns 0 if no next waypoint exists.
  static double getDistanceToNextWaypoint(
    Route route,
    LatLng currentPosition,
    int currentWaypointIndex,
  ) {
    if (currentWaypointIndex >= route.waypoints.length - 1) return 0.0;
    return distanceBetween(
      currentPosition,
      route.waypoints[currentWaypointIndex + 1].position,
    );
  }

  /// Calculates bearing from current position to next waypoint.
  ///
  /// Returns 0 if no next waypoint exists.
  static double getBearingToNextWaypoint(
    Route route,
    LatLng currentPosition,
    int currentWaypointIndex,
  ) {
    if (currentWaypointIndex >= route.waypoints.length - 1) return 0.0;
    return bearingBetween(
      currentPosition,
      route.waypoints[currentWaypointIndex + 1].position,
    );
  }
}
