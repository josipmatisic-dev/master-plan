import 'package:latlong2/latlong.dart';

import '../services/geo_utils.dart';

/// Represents a single waypoint in a route.
class Waypoint {
  /// Unique identifier for this waypoint
  final String id;

  /// Position coordinates (latitude/longitude)
  final LatLng position;

  /// Human-readable waypoint name
  final String name;

  /// Optional description or notes about this waypoint
  final String? description;

  /// Timestamp when this waypoint was created
  final DateTime timestamp;

  /// Creates an immutable waypoint instance.
  const Waypoint({
    required this.id,
    required this.position,
    required this.name,
    this.description,
    required this.timestamp,
  });

  /// Returns a copy of this waypoint with specified fields replaced.
  Waypoint copyWith({
    String? id,
    LatLng? position,
    String? name,
    String? description,
    DateTime? timestamp,
  }) {
    return Waypoint(
      id: id ?? this.id,
      position: position ?? this.position,
      name: name ?? this.name,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() => 'Waypoint($id: $name at $position)';
}

/// Represents a complete navigation route with multiple waypoints.
class Route {
  /// Unique route identifier
  final String id;

  /// User-defined route name
  final String name;

  /// Ordered list of waypoints comprising this route
  final List<Waypoint> waypoints;

  /// Whether this route is currently active/being tracked
  final bool isActive;

  /// Route creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  final DateTime updatedAt;

  /// Optional route description or notes
  final String? description;

  /// Creates an immutable route instance.
  ///
  /// The [waypoints] list should contain at least 2 waypoints (start and end).
  /// For a single point, use the first waypoint as both start and destination.
  const Route({
    required this.id,
    required this.name,
    required this.waypoints,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  /// Returns the total distance of this route in nautical miles.
  ///
  /// Calculates great-circle distance between consecutive waypoints.
  /// Returns 0 if route has fewer than 2 waypoints.
  double getTotalDistance() {
    return GeoUtils.getTotalRouteDistance(this);
  }

  /// Returns the distance from current position to the next waypoint (nm).
  ///
  /// Calculates great-circle distance using Haversine formula.
  /// Returns 0 if no next waypoint exists.
  double distanceToNextWaypoint(LatLng currentPosition, int currentWaypointIndex) {
    return GeoUtils.getDistanceToNextWaypoint(
      this,
      currentPosition,
      currentWaypointIndex,
    );
  }

  /// Returns the bearing (true course) from current position to next waypoint.
  ///
  /// Calculates bearing in degrees (0-360) where 0° is north, 90° is east, etc.
  /// Returns 0 if no next waypoint exists.
  double bearingToNextWaypoint(LatLng currentPosition, int currentWaypointIndex) {
    return GeoUtils.getBearingToNextWaypoint(
      this,
      currentPosition,
      currentWaypointIndex,
    );
  }

  /// Returns a copy of this route with specified fields replaced.
  Route copyWith({
    String? id,
    String? name,
    List<Waypoint>? waypoints,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return Route(
      id: id ?? this.id,
      name: name ?? this.name,
      waypoints: waypoints ?? this.waypoints,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'Route($id: $name with ${waypoints.length} waypoints)';
}
