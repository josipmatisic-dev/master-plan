/// Native MapLibre GL map widget replacing WebView-based map.
library;

import 'dart:math' show Point;

import 'package:flutter/material.dart' hide Viewport;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:provider/provider.dart';

import '../../models/lat_lng.dart' as app;
import '../../models/viewport.dart';
import '../../providers/map_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weather_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';

/// Native map widget using MapLibre GL for vector tile rendering.
class MapLibreMapWidget extends StatefulWidget {
  /// Height constraint. Null means fill parent.
  final double? height;

  /// Creates a native MapLibre GL map widget.
  const MapLibreMapWidget({super.key, this.height});

  @override
  State<MapLibreMapWidget> createState() => _MapLibreMapWidgetState();
}

class _MapLibreMapWidgetState extends State<MapLibreMapWidget> {
  ml.MapLibreMapController? _controller;
  MapProvider? _mapProvider;
  WeatherProvider? _weatherProvider;
  RouteProvider? _routeProvider;

  ml.Line? _routeLine;
  final List<ml.Symbol> _waypointSymbols = [];

  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapProvider = context.read<MapProvider>();
    _mapProvider!.addListener(_onViewportChanged);
    _weatherProvider = context.read<WeatherProvider>();
    _weatherProvider!.addListener(_onWeatherChanged);
    _routeProvider = context.read<RouteProvider>();
    _routeProvider!.addListener(_onRouteChanged);
  }

  /// MapTiler style URL based on theme.
  String _styleUrl(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final apiKey = settings.mapTilerApiKey;
    if (apiKey.isEmpty) {
      return 'https://demotiles.maplibre.org/style.json';
    }
    return 'https://api.maptiler.com/maps/ocean/style.json?key=$apiKey';
  }

  // ignore: use_setters_to_change_properties
  void _onMapCreated(ml.MapLibreMapController controller) {
    _controller = controller;
  }

  void _onStyleLoaded() {
    setState(() => _mapReady = true);
    // Notify MapProvider that map is ready
    _mapProvider?.handleMapReady(_controller);
    // Render existing route if any
    _onRouteChanged();
    // Trigger initial weather fetch
    _onViewportChanged();
  }

  void _onCameraIdle() {
    if (_controller == null || _mapProvider == null) return;
    final camera = _controller!.cameraPosition;
    if (camera != null) {
      _mapProvider!.updateViewport(Viewport(
        center: app.LatLng(
          latitude: camera.target.latitude,
          longitude: camera.target.longitude,
        ),
        zoom: camera.zoom,
        rotation: camera.bearing,
        size: _mapProvider!.viewport.size,
      ));
    }
  }

  /// Trigger weather fetch when viewport changes from MapProvider.
  void _onViewportChanged() {
    if (_weatherProvider == null) return;
    final vp = _mapProvider!.viewport;
    if (vp.size.isEmpty) return;
    final b = vp.bounds;
    _weatherProvider!.fetchForViewport(
      south: b.south,
      north: b.north,
      west: b.west,
      east: b.east,
    );
  }

  void _onWeatherChanged() {
    // Weather data changed — overlay painters will rebuild automatically
    // via their own provider listeners
  }

  void _onRouteChanged() {
    if (_controller == null || !_mapReady) return;
    final route = _routeProvider?.activeRoute;
    if (route != null) {
      _renderRoute(route);
    } else {
      _clearRoute();
    }
  }

  Future<void> _renderRoute(dynamic route) async {
    await _clearRoute();
    if (_controller == null) return;

    final waypoints = route.waypoints as List;
    if (waypoints.length < 2) return;

    // Draw route line
    final coords =
        waypoints.map((wp) => ml.LatLng(wp.latitude, wp.longitude)).toList();

    _routeLine = await _controller!.addLine(ml.LineOptions(
      geometry: coords,
      lineColor: '#FF00FF',
      lineWidth: 3.0,
      lineOpacity: 0.8,
    ));

    // Draw waypoint markers
    for (int i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final isLast = i == waypoints.length - 1;
      final symbol = await _controller!.addSymbol(ml.SymbolOptions(
        geometry: ml.LatLng(wp.latitude, wp.longitude),
        iconSize: 0.8,
        iconColor: isLast ? '#00FF88' : '#FF00FF',
      ));
      _waypointSymbols.add(symbol);
    }
  }

  Future<void> _clearRoute() async {
    if (_controller == null) return;
    if (_routeLine != null) {
      await _controller!.removeLine(_routeLine!);
      _routeLine = null;
    }
    for (final s in _waypointSymbols) {
      await _controller!.removeSymbol(s);
    }
    _waypointSymbols.clear();
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
                child: _buildMap(context, mapProvider),
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

  Widget _buildMap(BuildContext context, MapProvider mapProvider) {
    final settings = context.read<SettingsProvider>();
    if (!settings.hasMapTilerApiKey) {
      return _buildFallback('Map API key not configured');
    }

    final vp = mapProvider.viewport;
    return ml.MapLibreMap(
      styleString: _styleUrl(context),
      initialCameraPosition: ml.CameraPosition(
        target: ml.LatLng(vp.center.latitude, vp.center.longitude),
        zoom: vp.zoom,
        bearing: vp.rotation,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onCameraIdle: _onCameraIdle,
      compassEnabled: false,
      myLocationEnabled: false,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      trackCameraPosition: true,
      attributionButtonMargins: const Point<num>(-100, -100),
    );
  }

  Widget _buildFallback(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map,
            size: OceanDimensions.iconXL,
            color: OceanColors.seafoamGreen,
          ),
          const SizedBox(height: OceanDimensions.spacingS),
          Text(
            message,
            style: OceanTextStyles.body.copyWith(
              color: OceanColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
