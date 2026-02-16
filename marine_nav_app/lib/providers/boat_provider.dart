/// Boat Provider - Layer 2
///
/// Consumes NMEAProvider data when connected, falls back to phone GPS
/// via LocationService when NMEA is unavailable. Filters unrealistic
/// positions (ISS-018) and maintains track history.
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart' as latlong2;

import '../models/boat_position.dart';
import '../models/lat_lng.dart';
import '../services/anchor_alarm_service.dart';
import '../services/geo_utils.dart';
import '../services/location_service.dart';
import 'map_provider.dart';
import 'nmea_provider.dart';
import 'route_provider.dart';

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
  final RouteProvider? _routeProvider;

  BoatPosition? _currentPosition;
  PositionSource _source = PositionSource.none;
  final Queue<TrackPoint> _trackHistory = Queue<TrackPoint>();

  bool _followBoat = true;
  bool _showTrack = true;

  StreamSubscription<geo.Position>? _gpsSub;
  StreamSubscription<LocationStatus>? _gpsStatusSub;

  /// Creates a BoatProvider consuming NMEA, map, and location services.
  BoatProvider({
    required NMEAProvider nmeaProvider,
    required MapProvider mapProvider,
    LocationService? locationService,
    RouteProvider? routeProvider,
  })  : _nmeaProvider = nmeaProvider,
        _mapProvider = mapProvider,
        _locationService = locationService ?? LocationService(),
        _routeProvider = routeProvider {
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
    notifyListeners();
  }

  /// Clear all track history.
  void clearTrack() {
    _trackHistory.clear();
    notifyListeners();
  }

  // ============ NMEA Source (Primary) ============

  void _onNmeaUpdate() {
    if (!_nmeaProvider.isConnected) {
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
      position: LatLng(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      timestamp: data.timestamp,
      courseTrue: data.courseOverGroundDegrees,
      heading: data.headingTrue,
      speedKnots: data.speedOverGroundKnots,
      accuracy: _hdopToAccuracy(data.gpgga?.hdop),
      fixQuality: data.gpgga?.fixQuality ?? 0,
      satellites: data.gpgga?.satellites ?? 0,
      altitudeMeters: data.gpgga?.altitudeMeters,
    );

    _processPosition(newPos, PositionSource.nmea);
  }

  // ============ Phone GPS Source (Fallback) ============

  void _startPhoneGps() {
    _gpsSub = _locationService.positionStream.listen(_onPhoneGpsUpdate);
    _gpsStatusSub = _locationService.statusStream.listen((status) {
      debugPrint('BoatProvider: GPS status → $status');
      notifyListeners();
    });
    debugPrint('BoatProvider: Starting phone GPS...');
    _locationService.start();
  }

  void _onPhoneGpsUpdate(geo.Position geoPos) {
    debugPrint(
      'BoatProvider: 📍 GPS fix '
      '${geoPos.latitude},${geoPos.longitude} acc=${geoPos.accuracy}m',
    );
    if (_nmeaProvider.isConnected) return;

    final newPos = BoatPosition(
      position: LatLng(
        latitude: geoPos.latitude,
        longitude: geoPos.longitude,
      ),
      timestamp: geoPos.timestamp,
      courseTrue: geoPos.heading != 0 ? geoPos.heading : null,
      speedKnots: geoPos.speed > 0 ? geoPos.speed * 1.94384 : null,
      accuracy: geoPos.accuracy,
      fixQuality: 1,
    );

    _processPosition(newPos, PositionSource.phoneGps);
  }

  // ============ Shared Position Processing ============

  void _processPosition(BoatPosition newPos, PositionSource src) {
    if (!_isPositionValid(newPos)) return;

    _currentPosition = newPos;
    _source = src;
    _addTrackPoint(newPos);

    final latLng2Pos = _toLatLng2(newPos.position);
    _routeProvider?.updatePosition(latLng2Pos);

    if (_followBoat) {
      _mapProvider.setCenter(newPos.position);
    }

    notifyListeners();
  }

  // ============ ISS-018 Position Filtering ============

  bool _isPositionValid(BoatPosition newPos) {
    if (newPos.accuracy > maxAccuracyThresholdMeters) {
      return false;
    }

    final prev = _currentPosition;
    if (prev != null) {
      final distNm = GeoUtils.distanceBetween(
        _toLatLng2(prev.position),
        _toLatLng2(newPos.position),
      );
      final distM = distNm * 1852.0;
      final dtS =
          newPos.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
      if (dtS > 0 && (distM / dtS) > maxRealisticSpeedMps) return false;
    }

    return true;
  }

  // ============ Track History ============

  void _addTrackPoint(BoatPosition pos) {
    const minTrackDistanceM = 5.0;
    if (_trackHistory.isNotEmpty) {
      final last = _trackHistory.last;
      final lastLatLng2 = latlong2.LatLng(last.lat, last.lng);
      final distNm = GeoUtils.distanceBetween(
        lastLatLng2,
        _toLatLng2(pos.position),
      );
      final distM = distNm * 1852.0;
      if (distM < minTrackDistanceM) return;
    }

    _trackHistory.addLast(TrackPoint.fromPosition(pos));
    while (_trackHistory.length > maxTrackHistoryPoints) {
      _trackHistory.removeFirst();
    }
  }

  // ============ Utilities ============

  static double _hdopToAccuracy(double? hdop) => hdop != null ? hdop * 5.0 : 0;

  /// Convert app LatLng to latlong2 LatLng for RouteProvider compatibility.
  static latlong2.LatLng _toLatLng2(LatLng pos) {
    return latlong2.LatLng(pos.latitude, pos.longitude);
  }

  @override
  void dispose() {
    _nmeaProvider.removeListener(_onNmeaUpdate);
    _gpsSub?.cancel();
    _gpsStatusSub?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
