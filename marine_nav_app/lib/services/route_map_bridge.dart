/// Route map bridge — JS call helpers for route visualization.
///
/// Separated from [MapProvider] to keep it under 300 lines.
/// Provides methods to render route lines and waypoint markers
/// on the MapLibre GL JS map via WebView.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/route.dart';

/// Renders route lines and waypoint markers on the JS map.
///
/// Usage:
/// ```dart
/// final bridge = RouteMapBridge(controller);
/// bridge.renderRoute(route);
/// ```
class RouteMapBridge {
  final WebViewController? _controller;

  /// Creates a route bridge with a WebViewController.
  const RouteMapBridge(this._controller);

  /// Render a route line and waypoint markers on the map.
  Future<void> renderRoute(Route route) async {
    if (route.waypoints.isEmpty) {
      await clearRoute();
      return;
    }

    // Build coordinate array for line: [[lng, lat], ...]
    final coords = route.waypoints
        .map((wp) => '[${wp.position.longitude},${wp.position.latitude}]')
        .join(',');
    await _runJs('window.mapBridge.updateRouteLine([$coords])');

    // Build waypoint objects for markers (JSON-encoded to prevent injection)
    final wps = jsonEncode(route.waypoints.map((wp) => {
      'lat': wp.position.latitude,
      'lng': wp.position.longitude,
      'name': wp.name,
    }).toList());
    await _runJs('window.mapBridge.updateWaypointMarkers($wps)');
  }

  /// Remove route line and waypoint markers from the map.
  Future<void> clearRoute() async {
    await _runJs('window.mapBridge.clearRoute()');
  }

  Future<void> _runJs(String js) async {
    try {
      await _controller?.runJavaScript(js);
    } catch (e) {
      debugPrint('RouteMapBridge: JS call failed - $e');
    }
  }
}
