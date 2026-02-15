/// Map Provider - Layer 2
///
/// Owns map viewport state and exposes updates for UI and services.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebViewController? _webViewController;
  Timer? _syncDebounce;

  /// Debounce duration for viewport sync (ISS-008).
  static const syncDebounceMs = 200;

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

  // ============ WebView Bridge ============

  /// Attach a WebViewController for JS communication.
  // ignore: use_setters_to_change_properties
  void attachWebView(WebViewController controller) {
    _webViewController = controller;
  }

  /// Send the MapTiler API key to JS and trigger map init.
  Future<void> initializeMap(String apiKey) async {
    await _runJs('window.mapBridge.setApiKey("$apiKey")');
  }

  /// Handle a JSON message from the JS MapBridge channel.
  void handleWebViewEvent(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'mapReady':
          _isMapReady = true;
          debugPrint('MapProvider: ✅ Map is READY');
          notifyListeners();

        case 'viewportChanged':
          debugPrint(
              'MapProvider: viewport changed → zoom=${data['zoom']}, center=${data['latitude']},${data['longitude']}');
          _handleViewportFromJs(data);

        case 'error':
          reportError(MapError(
            type: MapErrorType.render,
            message: data['message'] as String? ?? 'Unknown map error',
          ));
      }
    } catch (e) {
      debugPrint('MapProvider: Failed to parse JS event - $e');
    }
  }

  void _handleViewportFromJs(Map<String, dynamic> data) {
    final center = data['center'] as List<dynamic>?;
    final zoom = (data['zoom'] as num?)?.toDouble();
    final rotation = (data['rotation'] as num?)?.toDouble();

    if (center == null || center.length < 2) return;

    final lat = (center[0] as num).toDouble();
    final lng = (center[1] as num).toDouble();

    _viewport = _viewport.copyWith(
      center: LatLng(latitude: lat, longitude: lng),
      zoom: zoom?.clamp(1.0, 20.0),
      rotation: rotation,
    );
    notifyListeners();
  }

  /// Push current viewport to the JS map with debounce (ISS-008).
  void syncToWebView() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(
      const Duration(milliseconds: syncDebounceMs),
      _pushViewportToJs,
    );
  }

  Future<void> _pushViewportToJs() async {
    if (!_isMapReady || _webViewController == null) return;
    final v = _viewport;
    await _runJs(
      'window.mapBridge.setViewport('
      '${v.center.latitude}, ${v.center.longitude}, '
      '${v.zoom}, ${v.rotation})',
    );
  }

  Future<void> _runJs(String js) async {
    try {
      await _webViewController?.runJavaScript(js);
    } catch (e) {
      debugPrint('MapProvider: JS call failed - $e');
    }
  }

  // ============ Viewport Mutators ============

  /// Update the full viewport state.
  void updateViewport(Viewport next) {
    if (_isSameViewport(next, _viewport)) {
      return;
    }
    _viewport = next;
    notifyListeners();
    syncToWebView();
  }

  /// Update viewport center.
  void setCenter(LatLng center) {
    if (center == _viewport.center) {
      return;
    }
    _viewport = _viewport.copyWith(center: center);
    notifyListeners();
    syncToWebView();
  }

  /// Update viewport zoom (clamped 1-20).
  void setZoom(double zoom) {
    final clampedZoom = zoom.clamp(1.0, 20.0);
    if (clampedZoom == _viewport.zoom) {
      return;
    }
    _viewport = _viewport.copyWith(zoom: clampedZoom);
    notifyListeners();
    syncToWebView();
  }

  /// Update viewport rotation.
  void setRotation(double rotation) {
    if (rotation == _viewport.rotation) {
      return;
    }
    _viewport = _viewport.copyWith(rotation: rotation);
    notifyListeners();
    syncToWebView();
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
    await _runJs(
      'window.mapBridge.flyTo('
      '${target.latitude}, ${target.longitude}, '
      '${zoom ?? _viewport.zoom})',
    );
  }

  // ============ Boat Marker & Track ============

  /// Update the boat marker position and heading on the JS map.
  Future<void> updateBoatMarker(
    double lat,
    double lng,
    double headingDeg,
  ) async {
    await _runJs(
      'window.mapBridge.updateBoatMarker($lat, $lng, $headingDeg)',
    );
  }

  /// Update the track line on the JS map.
  Future<void> updateTrackLine(List<List<num>> coords) async {
    final json = coords.map((c) => '[${c[0]},${c[1]}]').join(',');
    await _runJs('window.mapBridge.updateTrackLine([$json])');
  }

  /// Remove the track line from the JS map.
  Future<void> clearTrackLine() async {
    await _runJs('window.mapBridge.clearTrackLine()');
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

  @override
  void dispose() {
    _syncDebounce?.cancel();
    _errorController.close();
    super.dispose();
  }
}
