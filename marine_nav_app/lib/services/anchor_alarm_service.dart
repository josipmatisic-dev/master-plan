/// Anchor alarm service — monitors boat position against a geofence.
///
/// Uses [GeoUtils] haversine distance to detect drift beyond the anchor
/// radius. Emits alarm state changes via a stream.
/// Persists anchor state to SharedPreferences for app restart recovery.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/anchor_alarm.dart';
import '../models/boat_position.dart';
import '../models/lat_lng.dart';
import '../services/geo_utils.dart';

/// Default anchor radius in meters.
const double defaultAnchorRadiusMeters = 50.0;

/// Minimum allowed radius in meters.
const double minAnchorRadiusMeters = 10.0;

/// Maximum allowed radius in meters.
const double maxAnchorRadiusMeters = 500.0;

/// Manages anchor alarm state and geofence monitoring.
///
/// Integrates with [BoatProvider] by accepting position updates via
/// [updatePosition]. When drift exceeds the configured radius, the
/// alarm state transitions to [AnchorAlarmState.triggered].
class AnchorAlarmService extends ChangeNotifier {
  AnchorAlarm? _alarm;

  /// The current anchor alarm (null if not set).
  AnchorAlarm? get alarm => _alarm;

  /// Whether an anchor alarm is currently active.
  bool get isActive => _alarm != null;

  /// Whether the alarm is currently triggered (boat outside radius).
  bool get isTriggered => _alarm?.isTriggered ?? false;

  /// Whether the boat is in the warning zone (>80% of radius).
  bool get isWarning =>
      _alarm?.state == AnchorAlarmState.warning || isTriggered;

  /// Set the anchor at a given position with optional radius.
  ///
  /// The [position] is the anchor drop point (geofence center).
  /// The [radiusMeters] defaults to 50m and is clamped to [10, 500].
  void setAnchor({
    required LatLng position,
    double radiusMeters = defaultAnchorRadiusMeters,
  }) {
    final clampedRadius = radiusMeters.clamp(
      minAnchorRadiusMeters,
      maxAnchorRadiusMeters,
    );

    _alarm = AnchorAlarm(
      anchorPosition: position,
      radiusMeters: clampedRadius,
      setAt: DateTime.now(),
    );

    debugPrint(
      'AnchorAlarm: ⚓ Set at ${position.latitude.toStringAsFixed(5)}, '
      '${position.longitude.toStringAsFixed(5)} '
      'radius=${clampedRadius.toStringAsFixed(0)}m',
    );
    notifyListeners();
    _persist();
  }

  /// Set anchor at current boat position.
  void setAnchorAtPosition(
    BoatPosition boatPosition, {
    double radiusMeters = defaultAnchorRadiusMeters,
  }) {
    setAnchor(
      position: boatPosition.position,
      radiusMeters: radiusMeters,
    );
  }

  /// Clear the anchor alarm.
  void clearAnchor() {
    if (_alarm == null) return;
    debugPrint('AnchorAlarm: 🔓 Cleared');
    _alarm = null;
    notifyListeners();
    _persist();
  }

  /// Loads persisted anchor alarm state from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefsKey);
      if (json == null) return;
      _alarm = AnchorAlarm.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      debugPrint('AnchorAlarm: 📦 Restored from storage');
      notifyListeners();
    } catch (e) {
      debugPrint('AnchorAlarm: Failed to load persisted state - $e');
    }
  }

  static const String _prefsKey = 'anchor_alarm';

  /// Update the geofence radius while anchor is active.
  void updateRadius(double radiusMeters) {
    if (_alarm == null) return;
    final clamped = radiusMeters.clamp(
      minAnchorRadiusMeters,
      maxAnchorRadiusMeters,
    );

    _alarm = AnchorAlarm(
      anchorPosition: _alarm!.anchorPosition,
      radiusMeters: clamped,
      setAt: _alarm!.setAt,
      currentDistanceMeters: _alarm!.currentDistanceMeters,
      maxDriftMeters: _alarm!.maxDriftMeters,
    );

    // Recompute state with current distance.
    _alarm = _alarm!.withDistance(_alarm!.currentDistanceMeters);
    debugPrint(
        'AnchorAlarm: 📏 Radius updated to ${clamped.toStringAsFixed(0)}m');
    notifyListeners();
  }

  /// Process a new boat position — called from BoatProvider on each fix.
  ///
  /// Computes distance from anchor and updates alarm state.
  void updatePosition(BoatPosition position) {
    if (_alarm == null) return;

    final distanceNm = GeoUtils.distanceBetween(
      _toLatLng2(_alarm!.anchorPosition),
      _toLatLng2(position.position),
    );
    final distanceMeters = distanceNm * 1852.0;

    final prev = _alarm!.state;
    _alarm = _alarm!.withDistance(distanceMeters);

    if (_alarm!.state != prev) {
      _logStateChange(prev, _alarm!.state, distanceMeters);
      notifyListeners();
    } else if ((distanceMeters - _alarm!.currentDistanceMeters).abs() > 1.0) {
      // Notify on significant distance change (>1m) even if state unchanged.
      notifyListeners();
    }
  }

  void _logStateChange(
    AnchorAlarmState prev,
    AnchorAlarmState next,
    double distM,
  ) {
    final emoji = switch (next) {
      AnchorAlarmState.safe => '✅',
      AnchorAlarmState.warning => '⚠️',
      AnchorAlarmState.triggered => '🚨',
      AnchorAlarmState.inactive => '⏸️',
    };
    debugPrint(
      'AnchorAlarm: $emoji $prev → $next '
      '(drift=${distM.toStringAsFixed(1)}m / '
      '${_alarm!.radiusMeters.toStringAsFixed(0)}m)',
    );
  }

  static latlong2.LatLng _toLatLng2(LatLng pos) {
    return latlong2.LatLng(pos.latitude, pos.longitude);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_alarm == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, jsonEncode(_alarm!.toJson()));
      }
    } catch (e) {
      debugPrint('AnchorAlarm: Failed to persist state - $e');
    }
  }
}
