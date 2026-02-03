import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/route.dart';
import '../services/geo_utils.dart';

/// Manages active route state and navigation progress.
///
/// Layer 2 Provider: Depends on GeoUtils service for calculations.
/// Tracks current route, active waypoint, and computed navigation metrics.
///
/// Usage:
/// ```dart
/// Consumer<RouteProvider>(
///   builder: (context, routeProvider, _) {
///     return Text('Distance: ${routeProvider.distanceToNextWaypoint}nm');
///   },
/// );
/// ```
class RouteProvider extends ChangeNotifier {
  Route? _activeRoute;
  int _currentWaypointIndex = 0;
  LatLng? _currentPosition;

  /// Creates a new RouteProvider instance.
  RouteProvider();

  /// Currently active route, or null if no route is active.
  Route? get activeRoute => _activeRoute;

  /// Index of the current waypoint in the active route.
  /// Returns -1 if no active route.
  int get currentWaypointIndex =>
      _activeRoute != null ? _currentWaypointIndex : -1;

  /// Current boat position, or null if not set.
  LatLng? get currentPosition => _currentPosition;

  /// Next waypoint in the route, or null if no next waypoint.
  Waypoint? get nextWaypoint {
    if (_activeRoute == null) return null;
    if (_currentWaypointIndex >= _activeRoute!.waypoints.length - 1) {
      return null;
    }
    return _activeRoute!.waypoints[_currentWaypointIndex + 1];
  }

  /// Distance to next waypoint in nautical miles, or 0 if no next waypoint.
  double get distanceToNextWaypoint {
    if (_activeRoute == null || _currentPosition == null) return 0.0;
    if (_currentWaypointIndex >= _activeRoute!.waypoints.length - 1) {
      return 0.0;
    }
    return GeoUtils.getDistanceToNextWaypoint(
      _activeRoute!,
      _currentPosition!,
      _currentWaypointIndex,
    );
  }

  /// Bearing to next waypoint in degrees (0-360), or 0 if no next waypoint.
  double get bearingToNextWaypoint {
    if (_activeRoute == null || _currentPosition == null) return 0.0;
    if (_currentWaypointIndex >= _activeRoute!.waypoints.length - 1) {
      return 0.0;
    }
    return GeoUtils.getBearingToNextWaypoint(
      _activeRoute!,
      _currentPosition!,
      _currentWaypointIndex,
    );
  }

  /// Total distance of active route in nautical miles, or 0 if no active route.
  double get totalRouteDistance {
    if (_activeRoute == null) return 0.0;
    return GeoUtils.getTotalRouteDistance(_activeRoute!);
  }

  /// Total distance remaining from current waypoint to route end (nm).
  double get distanceRemaining {
    if (_activeRoute == null || _currentPosition == null) return 0.0;

    // Distance from current position to next waypoint
    double remaining = distanceToNextWaypoint;

    // Add distances between remaining waypoints
    for (int i = _currentWaypointIndex + 1;
        i < _activeRoute!.waypoints.length - 1;
        i++) {
      remaining += GeoUtils.distanceBetween(
        _activeRoute!.waypoints[i].position,
        _activeRoute!.waypoints[i + 1].position,
      );
    }

    return remaining;
  }

  /// Percent of route completed (0.0 to 1.0), or 0 if no active route.
  double get routeProgress {
    if (_activeRoute == null) return 0.0;
    final total = totalRouteDistance;
    if (total == 0.0) return 0.0;
    return 1.0 - (distanceRemaining / total).clamp(0.0, 1.0);
  }

  /// ETA to next waypoint in minutes, based on current speed.
  /// Returns 0 if no next waypoint or speed is 0.
  double getETAToNextWaypoint(double speedKnots) {
    if (speedKnots <= 0 || distanceToNextWaypoint == 0) return 0.0;
    return (distanceToNextWaypoint / speedKnots) * 60;
  }

  /// Activates a route and resets to first waypoint.
  /// Notifies listeners of changes.
  void activateRoute(Route route) {
    _activeRoute = route.copyWith(isActive: true);
    _currentWaypointIndex = 0;
    _currentPosition = null;
    notifyListeners();
  }

  /// Updates current boat position and automatically advances waypoint if reached.
  /// Notifies listeners of changes.
  void updatePosition(LatLng position) {
    _currentPosition = position;

    // Check if next waypoint is reached (within 100m)
    if (_activeRoute != null &&
        nextWaypoint != null &&
        GeoUtils.distanceBetween(position, nextWaypoint!.position) < 0.054) {
      // 0.054 nm ≈ 100m
      _currentWaypointIndex++;
    }

    notifyListeners();
  }

  /// Manually advances to the next waypoint if available.
  /// Notifies listeners of changes.
  void advanceWaypoint() {
    if (_activeRoute == null) return;
    if (_currentWaypointIndex < _activeRoute!.waypoints.length - 1) {
      _currentWaypointIndex++;
      notifyListeners();
    }
  }

  /// Manually reverts to the previous waypoint if available.
  /// Notifies listeners of changes.
  void revertWaypoint() {
    if (_activeRoute == null) return;
    if (_currentWaypointIndex > 0) {
      _currentWaypointIndex--;
      notifyListeners();
    }
  }

  /// Deactivates the current route and clears navigation state.
  /// Notifies listeners of changes.
  void deactivateRoute() {
    _activeRoute = null;
    _currentWaypointIndex = 0;
    _currentPosition = null;
    notifyListeners();
  }

  /// Clears current position data but keeps active route.
  /// Notifies listeners of changes.
  void clearPosition() {
    _currentPosition = null;
    notifyListeners();
  }
}
