/// Map WebView placeholder widget.
library;

import 'dart:convert';
import 'package:flutter/material.dart' hide Viewport;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/map_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/route_map_bridge.dart';
import '../../services/wind_texture_generator.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive_utils.dart';

/// WebView container for the MapTiler integration.
class MapWebView extends StatefulWidget {
  /// Height of the map container. Null means fill parent.
  final double? height;

  /// Optional controller for testing.
  @visibleForTesting
  final WebViewController? testController;

  /// Creates the MapWebView widget.
  const MapWebView({
    super.key,
    this.height = 280,
    this.testController,
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
    
    // Allow proceeding if testController is provided even if platform is null
    if (WebViewPlatform.instance == null && widget.testController == null) {
      _webViewAvailable = false;
      return;
    }

    _mapProvider = context.read<MapProvider>();
    _mapProvider!.addListener(_onViewportChanged);

    _weatherProvider = context.read<WeatherProvider>();
    _weatherProvider!.addListener(_onWeatherChanged);

    _routeProvider = context.read<RouteProvider>();
    _routeProvider!.addListener(_onRouteChanged);

    if (widget.testController != null) {
      _controller = widget.testController;
    } else {
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
  Future<void> _onWeatherChanged() async {
    await _pushWeatherToJs();
  }

  /// Send current weather data to the WebGL layers in map.html.
  Future<void> _pushWeatherToJs() async {
    final weather = _weatherProvider;
    if (weather == null || _controller == null) return;
    if (!weather.hasData) return;

    final vp = _mapProvider?.viewport;
    if (vp == null || vp.size.isEmpty) return;
    final b = vp.bounds;

    // Toggle visibility
    await _controller!.runJavaScript(
      'window.mapBridge.setWindLayerVisible(${weather.isWindVisible});',
    );
    await _controller!.runJavaScript(
      'window.mapBridge.setWaveLayerVisible(${weather.isWaveVisible});',
    );

    // Send wind data using server-side texture generation
    // Use pre-generated texture from provider if available
    if (weather.isWindVisible) {
      final textureData = weather.windTexture;
      if (textureData != null) {
        try {
          await _controller!.runJavaScript(
            'window.mapBridge.setWindTexture('
            '"${textureData.base64Png}", '
            '${textureData.uMin}, ${textureData.uMax}, '
            '${textureData.vMin}, ${textureData.vMax}'
            ');',
          );
        } catch (e) {
          debugPrint('setWindTexture failed: $e');
        }
      } else if (weather.data.windPoints.isNotEmpty) {
         // Fallback? Or just wait for provider to generate it?
         // Provider generates it async and notifies.
         // So we just wait.
      }
    }

    // Send wave data as GeoJSON-like points (using generator if available or raw)
    // WindTextureGenerator also supports wave GeoJSON generation
    if (weather.isWaveVisible && weather.data.wavePoints.isNotEmpty) {
      final waveData = WindTextureGenerator.generateWaveGeoJson(
        weather.data.wavePoints,
      );

      if (waveData != null) {
        // We pass raw points + max height to JS, or just the points?
        // map.html setWaveData expects { points: [...], bounds: ... }
        // But generateWaveGeoJson returns a GeoJSON string.
        // Let's see map.html setWaveData again.
        // It iterates points. So generateWaveGeoJson is for MapLibre Heatmap layer?
        // map.html setWaveData logic:
        // data = { points: [{lat, lng, height, dir}], bounds: ... }
        // So we should stick to the manual point construction for now unless map.html updated.
        // Wait, map.html setWaveData takes { points: ... }.
        // WindTextureGenerator.generateWaveGeoJson returns a FeatureCollection string.
        // It seems map.html implements a custom canvas renderer for waves ("_animateWaves"), not a MapLibre layer.
        // So we should KEEP the old wave implementation for now.

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
        await _controller!.runJavaScript(
          'window.mapBridge.setWaveData($waveJson);',
        );
      }
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
                    if (_webViewAvailable && _controller != null && widget.testController == null)
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
