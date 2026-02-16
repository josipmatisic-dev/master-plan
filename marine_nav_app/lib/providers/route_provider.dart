import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/route.dart';
import '../services/geo_utils.dart';

/// Manages active route state, saved routes, and navigation progress.
///
/// Layer 2 Provider: Depends on GeoUtils service for calculations.
/// Tracks current route, active waypoint, and computed navigation metrics.
/// Persists saved routes to SharedPreferences.
class RouteProvider extends ChangeNotifier {
  Route? _activeRoute;
  int _currentWaypointIndex = 0;
  LatLng? _currentPosition;
  List<Route> _savedRoutes = [];
  Future<void>? _pendingPersist;

  /// Creates a new RouteProvider instance.
  RouteProvider();

  /// Currently active route, or null if no route is active.
  Route? get activeRoute => _activeRoute;

  /// List of saved routes.
  List<Route> get savedRoutes => List.unmodifiable(_savedRoutes);

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

  /// Cross-track error in nautical miles (signed: + right, − left of track).
  /// Returns 0 if no active route or position.
  double get crossTrackError {
    if (_activeRoute == null || _currentPosition == null) return 0.0;
    if (_currentWaypointIndex >= _activeRoute!.waypoints.length - 1) {
      return 0.0;
    }
    final from = _activeRoute!.waypoints[_currentWaypointIndex].position;
    final to = _activeRoute!.waypoints[_currentWaypointIndex + 1].position;
    return GeoUtils.crossTrackDistance(from, to, _currentPosition!);
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

  // ============ Route CRUD ============

  /// Add a route to saved routes and persist.
  Future<void> saveRoute(Route route) async {
    final idx = _savedRoutes.indexWhere((r) => r.id == route.id);
    if (idx >= 0) {
      _savedRoutes[idx] = route.copyWith(updatedAt: DateTime.now());
    } else {
      _savedRoutes.add(route);
    }
    notifyListeners();
    await _persistRoutes();
  }

  /// Delete a saved route by ID.
  Future<void> deleteRoute(String routeId) async {
    _savedRoutes.removeWhere((r) => r.id == routeId);
    if (_activeRoute?.id == routeId) deactivateRoute();
    notifyListeners();
    await _persistRoutes();
  }

  /// Create a new route with given waypoints and save it.
  Future<Route> createRoute({
    required String name,
    required List<Waypoint> waypoints,
    String? description,
  }) async {
    final now = DateTime.now();
    final route = Route(
      id: 'route_${now.millisecondsSinceEpoch}',
      name: name,
      waypoints: waypoints,
      createdAt: now,
      updatedAt: now,
      description: description,
    );
    await saveRoute(route);
    return route;
  }

  /// Load saved routes from SharedPreferences.
  Future<void> loadSavedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('saved_routes');
      if (json == null) return;
      final list = jsonDecode(json) as List<dynamic>;
      _savedRoutes =
          list.map((e) => _routeFromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('RouteProvider: Failed to load routes - $e');
    }
  }

  Future<void> _persistRoutes() async {
    // Serialize writes to prevent race conditions
    final prev = _pendingPersist;
    _pendingPersist = _doPersist(prev);
    await _pendingPersist;
  }

  Future<void> _doPersist(Future<void>? previous) async {
    await previous;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_savedRoutes.map(_routeToJson).toList());
      await prefs.setString('saved_routes', json);
    } catch (e) {
      debugPrint('RouteProvider: Failed to persist routes - $e');
    }
  }

  static Map<String, dynamic> _routeToJson(Route r) => r.toJson();

  static Route _routeFromJson(Map<String, dynamic> j) => Route.fromJson(j);
}
