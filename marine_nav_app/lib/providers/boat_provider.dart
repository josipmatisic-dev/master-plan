/// Boat Provider - Layer 2 Provider
///
/// Manages vessel position state by consuming NMEAProvider data.
/// Maintains track history with LRU eviction and implements ISS-018
/// position jump filtering for GPS reconnect scenarios.
///
/// Dependencies:
/// - Layer 2: NMEAProvider (position data source)
library;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/boat_position.dart';
import '../models/lat_lng.dart';
import '../models/nmea_data.dart';
import 'nmea_provider.dart';

/// Provides vessel position tracking, track history, and MOB capability.
///
/// Listens to [NMEAProvider] for position updates, filters unrealistic
/// jumps per ISS-018, and maintains a bounded track history list.
///
/// Usage:
/// ```dart
/// final boat = context.watch<BoatProvider>();
/// if (boat.currentPosition != null) {
///   final sog = boat.currentPosition!.speedKnots;
/// }
/// ```
class BoatProvider extends ChangeNotifier {
  final NMEAProvider _nmeaProvider;

  BoatPosition? _currentPosition;
  final List<BoatPosition> _trackHistory = [];
  BoatPosition? _mobPosition;
  bool _isTracking = true;

  /// Earth radius in meters for haversine distance calculation.
  static const double _earthRadiusMeters = 6371000.0;

  /// Creates a BoatProvider that listens to [nmeaProvider] for updates.
  BoatProvider({
    required NMEAProvider nmeaProvider,
  }) : _nmeaProvider = nmeaProvider {
    _nmeaProvider.addListener(_onNmeaUpdate);
  }

  // ============ Public Getters ============

  /// Current vessel position (null if no valid position received yet).
  BoatPosition? get currentPosition => _currentPosition;

  /// Track history, oldest first. Max [maxTrackHistoryPoints] entries.
  List<BoatPosition> get trackHistory => List.unmodifiable(_trackHistory);

  /// Number of points in track history.
  int get trackHistoryLength => _trackHistory.length;

  /// MOB (Man Overboard) marker position (null if not set).
  BoatPosition? get mobPosition => _mobPosition;

  /// Whether MOB marker is active.
  bool get hasMob => _mobPosition != null;

  /// Whether position tracking is enabled.
  bool get isTracking => _isTracking;

  /// Whether a valid position has been received.
  bool get hasPosition => _currentPosition != null;

  // ============ Public Methods ============

  /// Marks current position as Man Overboard (MOB).
  ///
  /// Captures the current vessel position. If no current position
  /// is available, does nothing.
  void markMOB() {
    if (_currentPosition == null) return;
    _mobPosition = _currentPosition;
    notifyListeners();
  }

  /// Clears the MOB marker.
  void clearMOB() {
    if (_mobPosition == null) return;
    _mobPosition = null;
    notifyListeners();
  }

  /// Clears all track history points.
  void clearTrack() {
    if (_trackHistory.isEmpty) return;
    _trackHistory.clear();
    notifyListeners();
  }

  /// Enables or disables position tracking.
  ///
  /// When disabled, NMEA updates are ignored and no new positions
  /// are added to the track history.
  void setTracking({required bool enabled}) {
    if (_isTracking == enabled) return;
    _isTracking = enabled;
    notifyListeners();
  }

  /// Manually updates position from NMEA data.
  ///
  /// Called by the provider wiring or directly for testing.
  /// Delegates to [_processNmeaData] for filtering and history management.
  void updateFromNMEA(NMEAData? data) {
    if (data == null || !_isTracking) return;
    _processNmeaData(data);
  }

  // ============ Private Methods ============

  /// Listener callback for NMEAProvider changes.
  void _onNmeaUpdate() {
    updateFromNMEA(_nmeaProvider.currentData);
  }

  /// Processes NMEA data into a BoatPosition with ISS-018 filtering.
  void _processNmeaData(NMEAData data) {
    final position = data.position;
    if (position == null) return;

    // Extract accuracy from GPGGA HDOP (HDOP × 5m baseline estimate)
    final hdop = data.gpgga?.hdop ?? 99.0;
    final accuracy = hdop * 5.0;

    final newPosition = BoatPosition(
      position: LatLng(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      speedKnots: data.speedOverGroundKnots,
      courseTrue: data.courseOverGroundDegrees,
      heading: null, // Do not treat magnetic course over ground as vessel heading
      timestamp: data.timestamp,
      accuracy: accuracy,
      fixQuality: data.gpgga?.fixQuality ?? 0,
      satellites: data.gpgga?.satellites ?? 0,
      altitudeMeters: data.gpgga?.altitudeMeters,
    );

    // Apply ISS-018 filter: reject unrealistic position jumps
    if (!_passesPositionFilter(newPosition)) {
      debugPrint(
        'ISS-018: Filtered unrealistic position jump '
        '(accuracy: ${accuracy.toStringAsFixed(1)}m)',
      );
      return;
    }

    _currentPosition = newPosition;
    _addToTrackHistory(newPosition);
    notifyListeners();
  }

  /// ISS-018 filter: Rejects positions with unrealistic speed AND low accuracy.
  ///
  /// Returns true if position should be accepted, false if rejected.
  /// First position is always accepted.
  bool _passesPositionFilter(BoatPosition newPosition) {
    if (_currentPosition == null) return true;

    final previous = _currentPosition!;
    final timeDelta =
        newPosition.timestamp.difference(previous.timestamp).inMilliseconds;

    // Avoid division by zero; accept if timestamps are identical
    if (timeDelta <= 0) return true;

    final distanceMeters = _haversineDistance(
      previous.position,
      newPosition.position,
    );

    final speedMps = distanceMeters / (timeDelta / 1000.0);

    // Reject if both speed is unrealistic AND accuracy is poor
    if (speedMps > maxRealisticSpeedMps &&
        newPosition.accuracy > maxAccuracyThresholdMeters) {
      return false;
    }

    return true;
  }

  /// Adds position to track history with LRU eviction.
  void _addToTrackHistory(BoatPosition position) {
    _trackHistory.add(position);

    // Evict oldest points if over limit
    while (_trackHistory.length > maxTrackHistoryPoints) {
      _trackHistory.removeAt(0);
    }
  }

  /// Haversine distance calculation between two coordinates.
  ///
  /// Returns distance in meters. Used for ISS-018 speed calculation.
  static double _haversineDistance(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLat = _degToRad(to.latitude - from.latitude);
    final dLng = _degToRad(to.longitude - from.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  static double _degToRad(double deg) => deg * math.pi / 180.0;

  @override
  void dispose() {
    _nmeaProvider.removeListener(_onNmeaUpdate);
    super.dispose();
  }
}
