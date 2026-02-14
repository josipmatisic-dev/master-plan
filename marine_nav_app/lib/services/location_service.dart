/// Location Service — phone GPS wrapper.
///
/// Provides a stream of device GPS positions via the Geolocator package.
/// Used as fallback when NMEA is not connected.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Phone GPS position source status.
enum LocationStatus {
  /// Not started.
  idle,

  /// Waiting for permissions / initialization.
  initializing,

  /// Actively receiving positions.
  active,

  /// Permission denied or service disabled.
  unavailable,
}

/// Wraps device GPS via Geolocator for fallback positioning.
class LocationService {
  StreamSubscription<Position>? _positionSub;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();
  final StreamController<LocationStatus> _statusController =
      StreamController<LocationStatus>.broadcast();

  LocationStatus _status = LocationStatus.idle;

  /// Stream of GPS positions from the device.
  Stream<Position> get positionStream => _positionController.stream;

  /// Stream of service status changes.
  Stream<LocationStatus> get statusStream => _statusController.stream;

  /// Current status.
  LocationStatus get status => _status;

  /// Whether actively receiving positions.
  bool get isActive => _status == LocationStatus.active;

  /// Start listening to device GPS.
  Future<void> start() async {
    if (_status == LocationStatus.active) return;

    _setStatus(LocationStatus.initializing);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setStatus(LocationStatus.unavailable);
        debugPrint('LocationService: Location services disabled');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setStatus(LocationStatus.unavailable);
        debugPrint('LocationService: Permission denied');
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // min meters between updates
        ),
      ).listen(
        (position) {
          _setStatus(LocationStatus.active);
          _positionController.add(position);
        },
        onError: (Object error) {
          debugPrint('LocationService: Stream error - $error');
          _setStatus(LocationStatus.unavailable);
        },
      );
    } catch (e) {
      debugPrint('LocationService: Failed to start - $e');
      _setStatus(LocationStatus.unavailable);
    }
  }

  /// Stop listening to device GPS.
  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _setStatus(LocationStatus.idle);
  }

  void _setStatus(LocationStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Release all resources.
  void dispose() {
    stop();
    _positionController.close();
    _statusController.close();
  }
}
