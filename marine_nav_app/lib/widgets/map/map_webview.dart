/// Map WebView placeholder widget.
library;

import 'dart:convert';
import 'package:flutter/material.dart' hide Viewport;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/weather_data.dart';
import '../../providers/map_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/timeline_provider.dart';
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
  TimelineProvider? _timelineProvider;
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

    _timelineProvider = context.read<TimelineProvider>();
    _timelineProvider!.addListener(_onTimelineChanged);

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

  /// Handle timeline frame changes: regenerate wind texture for active frame.
  Future<void> _onTimelineChanged() async {
    final timeline = _timelineProvider;
    if (timeline == null || _weatherProvider == null) return;

    if (timeline.hasFrames) {
      await _pushWeatherToJs(useTimelineData: true);
    }
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
  ///
  /// If [useTimelineData] is true, uses wave/wind points from the active
  /// timeline frame. Otherwise uses current weather data.
  Future<void> _pushWeatherToJs({
    bool useTimelineData = false,
  }) async {
    final weather = _weatherProvider;
    if (weather == null || _controller == null) return;
    if (!weather.hasData) return;

    final vp = _mapProvider?.viewport;
    if (vp == null || vp.size.isEmpty) return;
    final b = vp.bounds;

    // Determine which wave data to use
    List<WaveDataPoint> wavePointsToUse;
    if (useTimelineData &&
        _timelineProvider != null &&
        _timelineProvider!.hasFrames) {
      wavePointsToUse = _timelineProvider!.activeWavePoints;
    } else {
      wavePointsToUse = weather.data.wavePoints;
    }

    // Toggle visibility
    await _controller!.runJavaScript(
      'window.mapBridge.setWindLayerVisible(${weather.isWindVisible});',
    );
    await _controller!.runJavaScript(
      'window.mapBridge.setWaveLayerVisible(${weather.isWaveVisible});',
    );

    // Wind data is now rendered via native overlays (WindParticleOverlay),
    // but legacy WebView path kept for fallback compatibility.
    if (weather.isWindVisible) {
      // Legacy texture pipeline removed — wind rendered natively
    }

    // Send wave data as points (map.html uses custom canvas renderer)
    if (weather.isWaveVisible && wavePointsToUse.isNotEmpty) {
      final points = <Map<String, double>>[];
      for (final p in wavePointsToUse) {
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

  @override
  void dispose() {
    _mapProvider?.removeListener(_onViewportChanged);
    _weatherProvider?.removeListener(_onWeatherChanged);
    _timelineProvider?.removeListener(_onTimelineChanged);
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
                    if (_webViewAvailable &&
                        _controller != null &&
                        widget.testController == null)
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
