/// Map WebView placeholder widget.
library;

import 'package:flutter/material.dart' hide Viewport;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/map_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/timeline_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/route_map_bridge.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive_utils.dart';
import '../overlays/wave_overlay.dart';
import '../overlays/wind_overlay.dart';

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

  @override
  void dispose() {
    _mapProvider?.removeListener(_onViewportChanged);
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
                    // Weather overlays — use timeline frame if available
                    Consumer2<WeatherProvider, TimelineProvider>(
                      builder: (context, weather, timeline, _) {
                        if (!weather.hasData) {
                          return const SizedBox.shrink();
                        }
                        // Use timeline's active frame data when available.
                        final windPts = timeline.hasFrames
                            ? timeline.activeWindPoints
                            : weather.data.windPoints;
                        final wavePts = timeline.hasFrames
                            ? timeline.activeWavePoints
                            : weather.data.wavePoints;
                        return Positioned.fill(
                          child: Stack(children: [
                            if (weather.isWindVisible && windPts.isNotEmpty)
                              WindOverlay(
                                windPoints: windPts,
                                viewport: mapProvider.viewport,
                              ),
                            if (weather.isWaveVisible && wavePts.isNotEmpty)
                              WaveOverlay(
                                wavePoints: wavePts,
                                viewport: mapProvider.viewport,
                              ),
                          ]),
                        );
                      },
                    ),
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
