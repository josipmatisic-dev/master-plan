/// Boat Provider - Layer 2
///
/// Consumes NMEAProvider data when connected, falls back to phone GPS
/// via LocationService when NMEA is unavailable. Filters unrealistic
/// positions (ISS-018) and maintains track history.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';

import '../models/boat_position.dart';
import '../models/lat_lng.dart' as app;
import '../services/location_service.dart';
import 'map_provider.dart';
import 'nmea_provider.dart';

/// Active position data source.
enum PositionSource {
  /// No position data available.
  none,

  /// NMEA instrument feed (primary).
  nmea,

  /// Phone built-in GPS (fallback).
  phoneGps,
}

/// Boat Provider - manages live position and track history.
class BoatProvider extends ChangeNotifier {
  final NMEAProvider _nmeaProvider;
  final MapProvider _mapProvider;
  final LocationService _locationService;

  BoatPosition? _currentPosition;
  PositionSource _source = PositionSource.none;
  final Queue<TrackPoint> _trackHistory = Queue<TrackPoint>();

  bool _followBoat = true;
  bool _showTrack = true;

  StreamSubscription<geo.Position>? _gpsSub;
  StreamSubscription<LocationStatus>? _gpsStatusSub;

  /// Max track history points (LRU eviction).
  static const int maxTrackPoints = 1000;

  /// Max realistic speed in m/s (~97 kn). ISS-018 filter.
  static const double maxRealisticSpeedMs = 50.0;

  /// Max acceptable accuracy in meters. ISS-018 filter.
  static const double maxAccuracyMeters = 50.0;

  /// Min distance between track points (meters).
  static const double minTrackDistanceM = 5.0;

  /// Creates a BoatProvider consuming NMEA, map, and location services.
  BoatProvider({
    required NMEAProvider nmeaProvider,
    required MapProvider mapProvider,
    LocationService? locationService,
  })  : _nmeaProvider = nmeaProvider,
        _mapProvider = mapProvider,
        _locationService = locationService ?? LocationService() {
    _nmeaProvider.addListener(_onNmeaUpdate);
    _startPhoneGps();
  }

  // ============ Public API ============

  /// Current boat position (null if no valid fix).
  BoatPosition? get currentPosition => _currentPosition;

  /// Active data source.
  PositionSource get source => _source;

  /// Unmodifiable track history.
  List<TrackPoint> get trackHistory => List.unmodifiable(_trackHistory);

  /// Track point count.
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

  // ============ NMEA Source (Primary) ============

  void _onNmeaUpdate() {
    if (!_nmeaProvider.isConnected) {
      // NMEA disconnected — phone GPS takes over automatically
      if (_source == PositionSource.nmea) {
        _source = PositionSource.phoneGps;
        notifyListeners();
      }
      return;
    }

    final data = _nmeaProvider.currentData;
    if (data == null) return;

    final position = data.position;
    if (position == null) return;

    final newPos = BoatPosition(
      position: position,
      timestamp: data.timestamp,
      headingDegrees: data.courseOverGroundDegrees,
      speedKnots: data.speedOverGroundKnots,
      accuracyMeters: _hdopToMeters(data.gpgga?.hdop),
    );

    _processPosition(newPos, PositionSource.nmea);
  }

  // ============ Phone GPS Source (Fallback) ============

  void _startPhoneGps() {
    _gpsSub = _locationService.positionStream.listen(_onPhoneGpsUpdate);
    _gpsStatusSub = _locationService.statusStream.listen((_) {
      notifyListeners();
    });
    _locationService.start();
  }

  void _onPhoneGpsUpdate(geo.Position geoPos) {
    // Skip phone GPS when NMEA is active
    if (_nmeaProvider.isConnected) return;

    final newPos = BoatPosition(
      position: LatLng(geoPos.latitude, geoPos.longitude),
      timestamp: geoPos.timestamp,
      headingDegrees: geoPos.heading != 0 ? geoPos.heading : null,
      speedKnots: geoPos.speed > 0 ? geoPos.speed * 1.94384 : null,
      accuracyMeters: geoPos.accuracy,
    );

    _processPosition(newPos, PositionSource.phoneGps);
  }

  // ============ Shared Position Processing ============

  void _processPosition(BoatPosition newPos, PositionSource src) {
    if (!_isPositionValid(newPos)) return;

    _currentPosition = newPos;
    _source = src;
    _addTrackPoint(newPos);
    _syncBoatToMap();

    if (_followBoat) {
      _mapProvider.setCenter(app.LatLng(
        latitude: newPos.position.latitude,
        longitude: newPos.position.longitude,
      ));
    }

    notifyListeners();
  }

  // ============ ISS-018 Position Filtering ============

  bool _isPositionValid(BoatPosition newPos) {
    if (newPos.accuracyMeters != null &&
        newPos.accuracyMeters! > maxAccuracyMeters) {
      return false;
    }

    final prev = _currentPosition;
    if (prev != null) {
      final distM = _haversine(
        prev.position.latitude, prev.position.longitude,
        newPos.position.latitude, newPos.position.longitude,
      );
      final dtS =
          newPos.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
      if (dtS > 0 && (distM / dtS) > maxRealisticSpeedMs) return false;
    }

    return true;
  }

  // ============ Track History ============

  void _addTrackPoint(BoatPosition pos) {
    if (_trackHistory.isNotEmpty) {
      final last = _trackHistory.last;
      final dist = _haversine(
        last.lat, last.lng,
        pos.position.latitude, pos.position.longitude,
      );
      if (dist < minTrackDistanceM) return;
    }

    _trackHistory.addLast(TrackPoint.fromPosition(pos));
    while (_trackHistory.length > maxTrackPoints) {
      _trackHistory.removeFirst();
    }
  }

  // ============ Map Sync ============

  void _syncBoatToMap() {
    final pos = _currentPosition;
    if (pos == null) return;
    _mapProvider.updateBoatMarker(
      pos.position.latitude,
      pos.position.longitude,
      pos.headingDegrees ?? 0,
    );
  }

  void _syncTrackToMap() {
    if (!_showTrack || _trackHistory.isEmpty) {
      _mapProvider.clearTrackLine();
      return;
    }
    _mapProvider.updateTrackLine(
      _trackHistory.map((p) => [p.lng, p.lat]).toList(),
    );
  }

  // ============ Utilities ============

  static double? _hdopToMeters(double? hdop) =>
      hdop != null ? hdop * 5.0 : null;

  static double _haversine(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  @override
  void dispose() {
    _nmeaProvider.removeListener(_onNmeaUpdate);
    _gpsSub?.cancel();
    _gpsStatusSub?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
