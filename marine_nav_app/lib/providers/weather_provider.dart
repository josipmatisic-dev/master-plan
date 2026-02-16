/// Weather Provider - Layer 2
///
/// Manages weather overlay state by fetching data from Open-Meteo
/// Marine API via [WeatherApiService]. Implements cache-first strategy
/// with 1-hour TTL and debounced viewport-based fetching.
///
/// Dependencies:
/// - Layer 0: SettingsProvider (units/preferences)
/// - Layer 1: CacheProvider (cache coordination)
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/weather_data.dart';
import '../services/weather_api.dart';
import '../services/wind_texture_generator.dart';
import 'cache_provider.dart';
import 'settings_provider.dart';

/// Overlay layer toggle state.
enum WeatherLayer {
  /// Wind barbs/arrows overlay.
  wind,

  /// Wave height contours overlay.
  wave,
}

/// Weather Provider - manages marine weather overlay data.
///
/// Fetches weather data for the current viewport, caches results,
/// and exposes layer visibility toggles for UI.
///
/// Usage:
/// ```dart
/// final weather = context.watch<WeatherProvider>();
/// if (weather.hasData) {
///   final wind = weather.data.windPoints;
/// }
/// ```
class WeatherProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final CacheProvider _cache;
  final WeatherApiService _api;

  WeatherData _data = WeatherData.empty;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  /// Latest generated wind texture for WebGL rendering.
  WindTextureData? _windTexture;

  /// Latest generated wave GeoJSON for WebGL heatmap.
  WaveTextureData? _waveTexture;

  /// Active overlay layers (all enabled by default).
  final Set<WeatherLayer> _activeLayers = {
    WeatherLayer.wind,
    WeatherLayer.wave,
  };

  /// Last fetched bounding box to avoid redundant calls.
  _BoundingBox? _lastFetchedBounds;

  /// Debounce duration for viewport changes.
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  /// Creates a WeatherProvider with required dependencies.
  WeatherProvider({
    required SettingsProvider settingsProvider,
    required CacheProvider cacheProvider,
    WeatherApiService? api,
  })  : _settings = settingsProvider,
        _cache = cacheProvider,
        _api = api ?? WeatherApiService();

  // ============ Public Getters ============

  /// Current weather data snapshot.
  WeatherData get data => _data;

  /// Whether weather data has been loaded.
  bool get hasData => !_data.isEmpty;

  /// Whether a fetch is in progress.
  bool get isLoading => _isLoading;

  /// Last error message (null if no error).
  String? get errorMessage => _errorMessage;

  /// Whether a layer is currently visible.
  bool isLayerActive(WeatherLayer layer) => _activeLayers.contains(layer);

  /// Whether wind overlay is visible.
  bool get isWindVisible => _activeLayers.contains(WeatherLayer.wind);

  /// Whether wave overlay is visible.
  bool get isWaveVisible => _activeLayers.contains(WeatherLayer.wave);

  /// Whether data is stale (older than 1 hour).
  bool get isStale => _data.isStale;

  /// Latest wind texture for WebGL layer (null if not yet generated).
  WindTextureData? get windTexture => _windTexture;

  /// Latest wave GeoJSON for WebGL heatmap (null if not yet generated).
  WaveTextureData? get waveTexture => _waveTexture;

  /// Settings provider (read-only access for unit conversions).
  SettingsProvider get settings => _settings;

  /// Cache provider (read-only access).
  CacheProvider get cache => _cache;

  // ============ Layer Toggle ============

  /// Toggles visibility of a weather overlay layer.
  void toggleLayer(WeatherLayer layer) {
    if (_activeLayers.contains(layer)) {
      _activeLayers.remove(layer);
    } else {
      _activeLayers.add(layer);
    }
    notifyListeners();
  }

  /// Sets a specific layer's visibility.
  void setLayerActive(WeatherLayer layer, {required bool active}) {
    final changed =
        active ? _activeLayers.add(layer) : _activeLayers.remove(layer);
    if (changed) {
      notifyListeners();
    }
  }

  // ============ Data Fetching ============

  /// Fetches weather data for a viewport bounding box (debounced).
  ///
  /// Call this when the map viewport changes. Debounces to avoid
  /// excessive API calls during rapid panning/zooming.
  void fetchForViewport({
    required double south,
    required double north,
    required double west,
    required double east,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _fetchData(south: south, north: north, west: west, east: east);
    });
  }

  /// Fetches weather data immediately (bypasses debounce).
  ///
  /// Use for explicit refresh actions.
  Future<void> refresh({
    required double south,
    required double north,
    required double west,
    required double east,
    bool force = true,
  }) async {
    _debounceTimer?.cancel();
    await _fetchData(
      south: south,
      north: north,
      west: west,
      east: east,
      force: force,
    );
  }

  /// Internal fetch with cache-first strategy and retry.
  Future<void> _fetchData({
    required double south,
    required double north,
    required double west,
    required double east,
    bool force = false,
  }) async {
    // Round coordinates to generate consistent cache keys
    // Round to 1 decimal place (approx 11km) for cache bucket
    final rSouth = double.parse(south.toStringAsFixed(1));
    final rNorth = double.parse(north.toStringAsFixed(1));
    final rWest = double.parse(west.toStringAsFixed(1));
    final rEast = double.parse(east.toStringAsFixed(1));

    final cacheKey = 'weather_${rSouth}_${rNorth}_${rWest}_$rEast';

    // 1. Try cache first (unless forced)
    if (!force) {
      final cachedJson = _cache.getString(cacheKey);
      if (cachedJson != null) {
        try {
          final data = WeatherData.fromJson(jsonDecode(cachedJson));
          if (!data.isStale) {
            debugPrint('WeatherProvider: Cache HIT for $cacheKey');
            _data = data;
            _errorMessage = null;

            // Generate textures from cached data
            _generateTextures(
              windPoints: _data.windPoints,
              wavePoints: _data.wavePoints,
              south: south,
              north: north,
              west: west,
              east: east,
            );

            notifyListeners();
            return;
          }
        } catch (e) {
          debugPrint('WeatherProvider: Cache parse failed - $e');
          _cache.invalidate(cacheKey);
        }
      }

      // Skip if same bounding box and data is fresh (in-memory check)
      final bounds = _BoundingBox(
        south: south,
        north: north,
        west: west,
        east: east,
      );
      if (_lastFetchedBounds == bounds && !_data.isStale && hasData) {
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.fetchWeatherData(
        south: south,
        north: north,
        west: west,
        east: east,
      );

      _data = result;
      _lastFetchedBounds = _BoundingBox(
        south: south,
        north: north,
        west: west,
        east: east,
      );
      _errorMessage = null;

      // 2. Write to cache
      try {
        await _cache.put(
          cacheKey,
          jsonEncode(_data.toJson()),
          ttl: const Duration(hours: 1),
        );
      } catch (e) {
        debugPrint('WeatherProvider: Cache write failed - $e');
      }

      debugPrint(
        'WeatherProvider: Fetched ${result.windPoints.length} wind, '
        '${result.wavePoints.length} wave points',
      );

      // Generate WebGL textures in background
      _generateTextures(
        windPoints: result.windPoints,
        wavePoints: result.wavePoints,
        south: south,
        north: north,
        west: west,
        east: east,
      );
    } on WeatherApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('WeatherProvider: API error - ${e.message}');

      // Cache fallback: keep stale data if available
      if (hasData) {
        debugPrint('WeatherProvider: Using cached data (age: '
            '${_data.age.inMinutes} min)');
      }
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      debugPrint('WeatherProvider: Unexpected error - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates wind texture from wind data points.
  ///
  /// If [windPoints] is provided, generates texture from those points.
  /// Otherwise, uses current weather data ([_data.windPoints]).
  /// Updates [_windTexture] and notifies listeners.
  ///
  /// Useful for timeline playback: call with [TimelineProvider.activeWindPoints]
  /// to render forecast frames without mutating fetched data.
  Future<void> generateWindTexture({
    List<WindDataPoint>? windPoints,
    double? south,
    double? north,
    double? west,
    double? east,
  }) async {
    // If explicit bounds not provided, use stored bounds from last fetch
    // If those don't exist either, we can't generate (need bounds for texture)
    final actualSouth = south ?? _lastFetchedBounds?.south;
    final actualNorth = north ?? _lastFetchedBounds?.north;
    final actualWest = west ?? _lastFetchedBounds?.west;
    final actualEast = east ?? _lastFetchedBounds?.east;

    if (actualSouth == null ||
        actualNorth == null ||
        actualWest == null ||
        actualEast == null) {
      debugPrint(
        'WeatherProvider.generateWindTexture: '
        'Cannot generate texture without bounds. '
        'Either pass bounds or fetch data first.',
      );
      return;
    }

    final pointsToUse = windPoints ?? _data.windPoints;

    try {
      _windTexture = await WindTextureGenerator.generate(
        windPoints: pointsToUse,
        south: actualSouth,
        north: actualNorth,
        west: actualWest,
        east: actualEast,
      );

      if (_windTexture != null) {
        debugPrint('WeatherProvider: Wind texture generated');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('WeatherProvider: Wind texture generation failed - $e');
    }
  }

  /// Generates WebGL textures from fetched weather data.
  /// Internal method used during data fetching.
  Future<void> _generateTextures({
    required List<WindDataPoint> windPoints,
    required List<WaveDataPoint> wavePoints,
    required double south,
    required double north,
    required double west,
    required double east,
  }) async {
    try {
      _windTexture = await WindTextureGenerator.generate(
        windPoints: windPoints,
        south: south,
        north: north,
        west: west,
        east: east,
      );
      _waveTexture = WindTextureGenerator.generateWaveGeoJson(wavePoints);

      if (_windTexture != null || _waveTexture != null) {
        debugPrint(
          'WeatherProvider: Textures ready '
          '(wind: ${_windTexture != null}, wave: ${_waveTexture != null})',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('WeatherProvider: Texture generation failed - $e');
    }
  }

  /// Clears all cached weather data.
  void clearData() {
    _data = WeatherData.empty;
    _lastFetchedBounds = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _api.dispose();
    super.dispose();
  }
}

/// Internal bounding box for deduplication.
class _BoundingBox {
  final double south;
  final double north;
  final double west;
  final double east;

  const _BoundingBox({
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _BoundingBox &&
        other.south == south &&
        other.north == north &&
        other.west == west &&
        other.east == east;
  }

  @override
  int get hashCode => Object.hash(south, north, west, east);
}
