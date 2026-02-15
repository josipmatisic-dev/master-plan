/// Map WebView placeholder widget.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/map_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/route_map_bridge.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive_utils.dart';

/// WebView container for the MapTiler integration.
class MapWebView extends StatefulWidget {
  /// Height of the map container. Null means fill parent.
  final double? height;

  /// Creates the MapWebView widget.
  const MapWebView({
    super.key,
    this.height = 280,
  });

  @override
  State<MapWebView> createState() => _MapWebViewState();
}

class _MapWebViewState extends State<MapWebView> {
  WebViewController? _controller;
  bool _webViewAvailable = true;
  MapProvider? _mapProvider;
  WeatherProvider? _weatherProvider;
  RouteProvider? _routeProvider;
  RouteMapBridge? _routeBridge;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance == null) {
      _webViewAvailable = false;
      return;
    }

    _mapProvider = context.read<MapProvider>();
    _mapProvider!.addListener(_onViewportChanged);

    _weatherProvider = context.read<WeatherProvider>();
    _weatherProvider!.addListener(_onWeatherChanged);

    _routeProvider = context.read<RouteProvider>();
    _routeProvider!.addListener(_onRouteChanged);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'MapBridge',
        onMessageReceived: (message) {
          _mapProvider!.handleWebViewEvent(message.message);
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          _mapProvider!.attachWebView(_controller!);
          _routeBridge = RouteMapBridge(_controller);
          if (_mapProvider!.settingsProvider.hasMapTilerApiKey) {
            _mapProvider!.initializeMap(
              _mapProvider!.settingsProvider.mapTilerApiKey,
            );
          }
          // Render active route if present
          _onRouteChanged();
          // Trigger initial weather fetch for current viewport
          _onViewportChanged();
        },
      ))
      ..loadFlutterAsset('assets/map.html');
  }

  /// Trigger weather fetch when viewport changes.
  void _onViewportChanged() {
    final weather = _weatherProvider;
    if (weather == null) return;
    final vp = _mapProvider!.viewport;
    if (vp.size.isEmpty) return;
    final b = vp.bounds;
    weather.fetchForViewport(
      south: b.south,
      north: b.north,
      west: b.west,
      east: b.east,
    );
  }

  /// Render route on map when RouteProvider changes.
  void _onRouteChanged() {
    if (_routeBridge == null) return;
    final route = _routeProvider?.activeRoute;
    if (route != null) {
      _routeBridge!.renderRoute(route);
    } else {
      _routeBridge!.clearRoute();
    }
  }

  /// Push weather data to JS WebGL layers when data changes.
  void _onWeatherChanged() {
    _pushWeatherToJs();
  }

  /// Send current weather data to the WebGL layers in map.html.
  void _pushWeatherToJs() {
    final weather = _weatherProvider;
    if (weather == null || _controller == null) return;
    if (!weather.hasData) return;

    final vp = _mapProvider?.viewport;
    if (vp == null || vp.size.isEmpty) return;
    final b = vp.bounds;

    // Toggle visibility
    _controller!.runJavaScript(
      'window.mapBridge.setWindLayerVisible(${weather.isWindVisible});',
    );
    _controller!.runJavaScript(
      'window.mapBridge.setWaveLayerVisible(${weather.isWaveVisible});',
    );

    // Send wind data as sparse points with U/V components
    if (weather.isWindVisible && weather.data.windPoints.isNotEmpty) {
      final pts = weather.data.windPoints;
      // Convert speed+direction to U/V components
      var uMin = double.infinity, uMax = double.negativeInfinity;
      var vMin = double.infinity, vMax = double.negativeInfinity;
      final points = <Map<String, double>>[];
      for (final p in pts) {
        final rad = p.directionDegrees * math.pi / 180.0;
        final u = -p.speedKnots * math.sin(rad);
        final v = -p.speedKnots * math.cos(rad);
        if (u < uMin) uMin = u;
        if (u > uMax) uMax = u;
        if (v < vMin) vMin = v;
        if (v > vMax) vMax = v;
        points.add({
          'lat': p.position.latitude,
          'lng': p.position.longitude,
          'u': u,
          'v': v,
        });
      }
      final windJson = jsonEncode({
        'points': points,
        'bounds': {
          's': b.south,
          'n': b.north,
          'w': b.west,
          'e': b.east,
        },
        'uMin': uMin,
        'uMax': uMax,
        'vMin': vMin,
        'vMax': vMax,
      });
      _controller!.runJavaScript(
        'window.mapBridge.setWindData($windJson);',
      );
    }

    // Send wave data as GeoJSON-like points
    if (weather.isWaveVisible && weather.data.wavePoints.isNotEmpty) {
      final wavePts = weather.data.wavePoints;
      final points = <Map<String, double>>[];
      for (final p in wavePts) {
        points.add({
          'lat': p.position.latitude,
          'lng': p.position.longitude,
          'height': p.heightMeters,
          'dir': p.directionDegrees,
        });
      }
      final waveJson = jsonEncode({
        'points': points,
        'bounds': {
          's': b.south,
          'n': b.north,
          'w': b.west,
          'e': b.east,
        },
      });
      _controller!.runJavaScript(
        'window.mapBridge.setWaveData($waveJson);',
      );
    }
  }

  @override
  void dispose() {
    _mapProvider?.removeListener(_onViewportChanged);
    _weatherProvider?.removeListener(_onWeatherChanged);
    _routeProvider?.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, _) {
        final Widget layoutChild = LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            if (!size.isEmpty && size != mapProvider.viewport.size) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                mapProvider.setSize(size);
              });
            }

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: OceanColors.surface,
                borderRadius: BorderRadius.circular(OceanDimensions.radius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(OceanDimensions.radius),
                child: Stack(
                  children: [
                    if (_webViewAvailable && _controller != null)
                      WebViewWidget(controller: _controller!)
                    else
                      _buildFallback(),
                    // Weather overlays now rendered via WebGL in map.html
                  ],
                ),
              ),
            );
          },
        );
        if (widget.height != null) {
          return SizedBox(height: widget.height, child: layoutChild);
        }
        return layoutChild;
      },
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map,
            size: OceanDimensions.iconXL,
            color: OceanColors.seafoamGreen,
          ),
          OceanDimensions.spacingS.verticalSpace,
          Text(
            'Map View (WebView pending)',
            style: OceanTextStyles.body.copyWith(
              color: OceanColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
