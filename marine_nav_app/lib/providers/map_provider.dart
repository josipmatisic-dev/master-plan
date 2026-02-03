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

/// Map Provider - manages viewport state.
class MapProvider extends ChangeNotifier {
  /// Settings provider dependency (Layer 0).
  final SettingsProvider settingsProvider;

  /// Cache provider dependency (Layer 1).
  final CacheProvider cacheProvider;

  final StreamController<MapError> _errorController =
      StreamController<MapError>.broadcast();

  Viewport _viewport;
  bool _isInitialized = false;

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

  /// Initialize provider state.
  Future<void> init() async {
    _isInitialized = true;
  }

  /// Update the full viewport state.
  void updateViewport(Viewport next) {
    _viewport = next;
    notifyListeners();
  }

  /// Update viewport center.
  void setCenter(LatLng center) {
    _viewport = _viewport.copyWith(center: center);
    notifyListeners();
  }

  /// Update viewport zoom (clamped 1-20).
  void setZoom(double zoom) {
    final clampedZoom = zoom.clamp(1.0, 20.0);
    _viewport = _viewport.copyWith(zoom: clampedZoom);
    notifyListeners();
  }

  /// Update viewport rotation.
  void setRotation(double rotation) {
    _viewport = _viewport.copyWith(rotation: rotation);
    notifyListeners();
  }

  /// Update viewport size.
  void setSize(Size size) {
    _viewport = _viewport.copyWith(size: size);
    notifyListeners();
  }

  /// Emit a map error.
  void reportError(MapError error) {
    _errorController.add(error);
  }

  @override
  void dispose() {
    _errorController.close();
    super.dispose();
  }
}
