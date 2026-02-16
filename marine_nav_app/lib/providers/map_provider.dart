/// Map Provider - Layer 2
///
/// Owns map viewport state and exposes updates for UI and services.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/lat_lng.dart';
import '../models/viewport.dart';
import 'cache_provider.dart';
import 'settings_provider.dart';

/// Typedef for native map controller to avoid hard dependency.
typedef NativeMapController = dynamic;

/// Map error types.
enum MapErrorType {
  /// Network request failed.
  network,

  /// Cache lookup failed.
  cache,

  /// Map rendering failed.
  render,
}

/// Map error event.
class MapError {
  /// Error category.
  final MapErrorType type;

  /// Human-readable message.
  final String message;

  /// Creates a map error event.
  const MapError({
    required this.type,
    required this.message,
  });
}

/// Map Provider - manages viewport state and WebView bridge.
class MapProvider extends ChangeNotifier {
  /// Settings provider dependency (Layer 0).
  final SettingsProvider settingsProvider;

  /// Cache provider dependency (Layer 1).
  final CacheProvider cacheProvider;

  final StreamController<MapError> _errorController =
      StreamController<MapError>.broadcast();

  Viewport _viewport;
  bool _isInitialized = false;
  bool _isMapReady = false;
  NativeMapController? _nativeMapController;

  /// Creates a MapProvider with dependencies.
  MapProvider({
    required this.settingsProvider,
    required this.cacheProvider,
    Viewport? initialViewport,
  }) : _viewport = initialViewport ??
            const Viewport(
              center: LatLng(latitude: 0, longitude: 0),
              zoom: 3,
              size: Size.zero,
              rotation: 0,
            );

  /// Current viewport state.
  Viewport get viewport => _viewport;

  /// Stream of map errors.
  Stream<MapError> get errors => _errorController.stream;

  /// True when provider initialization completed.
  bool get isInitialized => _isInitialized;

  /// True when the JS map has finished loading.
  bool get isMapReady => _isMapReady;

  /// Initialize provider state.
  Future<void> init() async {
    _isInitialized = true;
  }

  /// Signal that the native MapLibre map is ready.
  void handleMapReady(NativeMapController? controller) {
    _nativeMapController = controller;
    _isMapReady = true;
    debugPrint('MapProvider: ✅ Native map is READY');
    notifyListeners();
  }

  /// The native map controller (if using maplibre_gl).
  NativeMapController? get nativeMapController => _nativeMapController;

  // ============ Boat / Track Map Sync (stub for native migration) ============

  /// Update boat marker on the map. Called by BoatProvider.
  void updateBoatMarker(double lat, double lng, double heading) {
    // TODO(slavko): Implement via native MapLibre controller
    debugPrint('MapProvider: boat marker → $lat, $lng, $heading°');
  }

  /// Update track line on the map.
  void updateTrackLine(List<List<double>> points) {
    // TODO(slavko): Implement via native MapLibre controller
  }

  /// Clear track line from the map.
  void clearTrackLine() {
    // TODO(slavko): Implement via native MapLibre controller
  }

  // ============ Viewport Mutators ============

  /// Update the full viewport state.
  void updateViewport(Viewport next) {
    if (_isSameViewport(next, _viewport)) {
      return;
    }
    _viewport = next;
    notifyListeners();
    _syncToNativeMap();
  }

  /// Update viewport center.
  void setCenter(LatLng center) {
    if (center == _viewport.center) {
      return;
    }
    _viewport = _viewport.copyWith(center: center);
    notifyListeners();
    _syncToNativeMap();
  }

  /// Update viewport zoom (clamped 1-20).
  void setZoom(double zoom) {
    final clampedZoom = zoom.clamp(1.0, 20.0);
    if (clampedZoom == _viewport.zoom) {
      return;
    }
    _viewport = _viewport.copyWith(zoom: clampedZoom);
    notifyListeners();
    _syncToNativeMap();
  }

  /// Update viewport rotation.
  void setRotation(double rotation) {
    if (rotation == _viewport.rotation) {
      return;
    }
    _viewport = _viewport.copyWith(rotation: rotation);
    notifyListeners();
    _syncToNativeMap();
  }

  /// Update viewport size.
  void setSize(Size size) {
    if (size.isEmpty) {
      return;
    }
    if (size == _viewport.size) {
      return;
    }
    _viewport = _viewport.copyWith(size: size);
    notifyListeners();
  }

  /// Fly to a location with smooth animation.
  Future<void> flyTo(LatLng target, {double? zoom}) async {
    // Native implementation would go here
    // _nativeMapController?.animateCamera(...)
    // For now we just update state which triggers sync
    setCenter(target);
    if (zoom != null) setZoom(zoom);
  }

  /// Emit a map error.
  void reportError(MapError error) {
    _errorController.add(error);
  }

  bool _isSameViewport(Viewport next, Viewport current) {
    return next.center == current.center &&
        next.zoom == current.zoom &&
        next.size == current.size &&
        next.rotation == current.rotation;
  }

  void _syncToNativeMap() {
    // In a real implementation, we would call _nativeMapController?.moveCamera()
    // But since MapLibreMapWidget might rebuild or listen, we leave this hook.
    // Currently MapLibreMapWidget listens to this provider.
  }

  @override
  void dispose() {
    _errorController.close();
    super.dispose();
  }
}
