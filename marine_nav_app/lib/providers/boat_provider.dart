/// Boat Provider - Layer 2
///
/// Consumes NMEAProvider data, filters unrealistic positions (ISS-018),
/// maintains track history, and pushes boat marker to the map.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/boat_position.dart';
import '../models/nmea_data.dart';
import 'map_provider.dart';
import 'nmea_provider.dart';

/// Boat Provider - manages live position and track history.
class BoatProvider extends ChangeNotifier {
  final NMEAProvider _nmeaProvider;
  final MapProvider _mapProvider;

  BoatPosition? _currentPosition;
  final Queue<TrackPoint> _trackHistory = Queue<TrackPoint>();

  bool _followBoat = true;
  bool _showTrack = true;

  /// Maximum track history points (LRU eviction).
  static const int maxTrackPoints = 1000;

  /// Max realistic speed in m/s (~97 knots). ISS-018 filter.
  static const double maxRealisticSpeedMs = 50.0;

  /// Min accuracy to accept a position (meters). ISS-018 filter.
  static const double maxAccuracyMeters = 50.0;

  /// Minimum distance (meters) between track points to avoid clutter.
  static const double minTrackDistanceMeters = 5.0;

  /// Creates a BoatProvider consuming NMEA and map providers.
  BoatProvider({
    required NMEAProvider nmeaProvider,
    required MapProvider mapProvider,
  })  : _nmeaProvider = nmeaProvider,
        _mapProvider = mapProvider {
    _nmeaProvider.addListener(_onNmeaUpdate);
  }

  /// Current boat position (null if no valid fix).
  BoatPosition? get currentPosition => _currentPosition;

  /// Unmodifiable view of track history.
  List<TrackPoint> get trackHistory => List.unmodifiable(_trackHistory);

  /// Number of recorded track points.
  int get trackPointCount => _trackHistory.length;

  /// Whether the map auto-follows the boat.
  bool get followBoat => _followBoat;

  /// Whether the track trail is visible.
  bool get showTrack => _showTrack;

  /// Toggle map auto-follow.
  set followBoat(bool value) {
    if (_followBoat == value) return;
    _followBoat = value;
    notifyListeners();
  }

  /// Toggle track trail visibility.
  set showTrack(bool value) {
    if (_showTrack == value) return;
    _showTrack = value;
    _syncTrackToMap();
    notifyListeners();
  }

  /// Clear all track history.
  void clearTrack() {
    _trackHistory.clear();
    _syncTrackToMap();
    notifyListeners();
  }

  // ============ NMEA Data Handling ============

  void _onNmeaUpdate() {
    final data = _nmeaProvider.currentData;
    if (data == null) return;

    final position = data.position;
    if (position == null) return;

    final newPos = BoatPosition(
      position: position,
      timestamp: data.timestamp,
      headingDegrees: data.courseOverGroundDegrees,
      speedKnots: data.speedOverGroundKnots,
      accuracyMeters: data.gpgga?.hdop != null
          ? (data.gpgga!.hdop! * 5.0) // rough HDOP → meters
          : null,
    );

    if (!_isPositionValid(newPos)) return;

    _currentPosition = newPos;
    _addTrackPoint(newPos);
    _syncBoatToMap();

    if (_followBoat) {
      _mapProvider.setCenter(
        _mapProvider.viewport.center.latitude != position.latitude ||
                _mapProvider.viewport.center.longitude != position.longitude
            ? _toMapLatLng(position)
            : _mapProvider.viewport.center,
      );
    }

    notifyListeners();
  }

  // ============ ISS-018 Position Filtering ============

  bool _isPositionValid(BoatPosition newPos) {
    // Filter by accuracy if available
    if (newPos.accuracyMeters != null &&
        newPos.accuracyMeters! > maxAccuracyMeters) {
      debugPrint('BoatProvider: Rejected position - accuracy '
          '${newPos.accuracyMeters!.toStringAsFixed(0)}m > ${maxAccuracyMeters}m');
      return false;
    }

    // Filter unrealistic speed jumps against previous position
    final prev = _currentPosition;
    if (prev != null) {
      final distanceM = _haversineDistance(
        prev.position.latitude, prev.position.longitude,
        newPos.position.latitude, newPos.position.longitude,
      );
      final timeDeltaS = newPos.timestamp
              .difference(prev.timestamp)
              .inMilliseconds /
          1000.0;

      if (timeDeltaS > 0) {
        final speedMs = distanceM / timeDeltaS;
        if (speedMs > maxRealisticSpeedMs) {
          debugPrint('BoatProvider: Rejected jump - '
              '${speedMs.toStringAsFixed(1)} m/s > $maxRealisticSpeedMs m/s');
          return false;
        }
      }
    }

    return true;
  }

  // ============ Track History ============

  void _addTrackPoint(BoatPosition pos) {
    // Skip if too close to last point
    if (_trackHistory.isNotEmpty) {
      final last = _trackHistory.last;
      final dist = _haversineDistance(
        last.lat, last.lng,
        pos.position.latitude, pos.position.longitude,
      );
      if (dist < minTrackDistanceMeters) return;
    }

    _trackHistory.addLast(TrackPoint.fromPosition(pos));

    // LRU eviction
    while (_trackHistory.length > maxTrackPoints) {
      _trackHistory.removeFirst();
    }
  }

  // ============ Map Bridge Sync ============

  void _syncBoatToMap() {
    final pos = _currentPosition;
    if (pos == null) return;

    final heading = pos.headingDegrees ?? 0;
    _mapProvider.runBoatMarkerJs(
      pos.position.latitude,
      pos.position.longitude,
      heading,
    );
  }

  void _syncTrackToMap() {
    if (!_showTrack || _trackHistory.isEmpty) {
      _mapProvider.runTrackJs(null);
      return;
    }
    _mapProvider.runTrackJs(
      _trackHistory.map((p) => [p.lng, p.lat]).toList(),
    );
  }

  // ============ Utilities ============

  /// Convert latlong2.LatLng → app LatLng model.
  static _toMapLatLng(LatLng pos) {
    return __import_lat_lng(pos.latitude, pos.longitude);
  }

  /// Haversine distance in meters between two WGS84 points.
  static double _haversineDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  @override
  void dispose() {
    _nmeaProvider.removeListener(_onNmeaUpdate);
    super.dispose();
  }
}
