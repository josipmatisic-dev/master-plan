/// Tide Provider - Layer 2
///
/// Manages tide data for the nearest NOAA station. Depends on
/// SettingsProvider (L0) and CacheProvider (L1). Fetches predictions
/// and water levels, caching results with 1-hour TTL.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/tide_data.dart';
import '../providers/cache_provider.dart';
import '../providers/settings_provider.dart';
import '../services/tide_api_service.dart';

/// Tide data provider for nearest station lookup and forecasts.
class TideProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final CacheProvider _cache;
  final TideApiService _api;

  TideData? _tideData;
  TideStation? _nearestStation;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;

  /// Cache TTL for tide data (1 hour).
  static const Duration cacheTtl = Duration(hours: 1);

  /// Cache key prefix.
  static const String _cacheKey = 'tide_data';

  /// Creates a tide provider.
  TideProvider({
    required SettingsProvider settingsProvider,
    required CacheProvider cacheProvider,
    TideApiService? apiService,
  })  : _settings = settingsProvider,
        _cache = cacheProvider,
        _api = apiService ?? TideApiService();

  /// Current tide data (null if not loaded).
  TideData? get tideData => _tideData;

  /// The nearest tide station (null if not looked up).
  TideStation? get nearestStation => _nearestStation;

  /// Whether data is currently being fetched.
  bool get isLoading => _isLoading;

  /// Last error message (null if no error).
  String? get error => _error;

  /// When data was last fetched.
  DateTime? get lastFetch => _lastFetch;

  /// Next upcoming tide event.
  TidePrediction? get nextTide => _tideData?.nextTide;

  /// Next high tide.
  TidePrediction? get nextHighTide => _tideData?.nextHighTide;

  /// Next low tide.
  TidePrediction? get nextLowTide => _tideData?.nextLowTide;

  /// Initialize — load cached data if available.
  Future<void> init() async {
    _loadFromCache();
    // Settings not currently used but reserved for units preference
    _settings.addListener(_onSettingsChanged);
  }

  /// Fetch tide data for the nearest station to the given position.
  Future<void> fetchForPosition({
    required double latitude,
    required double longitude,
  }) async {
    if (_isLoading) return;

    // Check cache freshness
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < cacheTtl) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Find nearest station
      final station = await _api.findNearestStation(
        latitude: latitude,
        longitude: longitude,
      );

      if (station == null) {
        _error = 'No tide stations found nearby';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _nearestStation = station;

      // Fetch tide data
      final data = await _api.fetchTideData(
        stationId: station.id,
        stationName: station.name,
        latitude: station.latitude,
        longitude: station.longitude,
      );

      _tideData = data;
      _lastFetch = DateTime.now();
      _error = null;

      // Persist to cache
      _saveToCache(data);

      debugPrint(
        'TideProvider: Fetched ${data.predictions.length} predictions '
        'from ${station.name}',
      );
    } on TideApiException catch (e) {
      _error = e.message;
      debugPrint('TideProvider: API error — $e');
      // Fall back to cache
      _loadFromCache();
    } catch (e) {
      _error = 'Failed to fetch tide data: $e';
      debugPrint('TideProvider: Error — $e');
      _loadFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch for a known station ID directly.
  Future<void> fetchForStation(TideStation station) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _nearestStation = station;
    notifyListeners();

    try {
      final data = await _api.fetchTideData(
        stationId: station.id,
        stationName: station.name,
        latitude: station.latitude,
        longitude: station.longitude,
      );

      _tideData = data;
      _lastFetch = DateTime.now();
      _error = null;
      _saveToCache(data);
    } on TideApiException catch (e) {
      _error = e.message;
      _loadFromCache();
    } catch (e) {
      _error = 'Failed to fetch tide data: $e';
      _loadFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ Cache ============

  void _loadFromCache() {
    final cached = _cache.getJson(_cacheKey);
    if (cached != null) {
      try {
        _tideData = TideData.fromJson(cached);
        _nearestStation = _tideData!.station;
        _lastFetch = _tideData!.fetchedAt;
        debugPrint('TideProvider: Loaded from cache');
      } catch (e) {
        debugPrint('TideProvider: Cache parse error — $e');
      }
    }
  }

  void _saveToCache(TideData data) {
    _cache.putJson(_cacheKey, data.toJson(), ttl: cacheTtl);
  }

  void _onSettingsChanged() {
    // Reserved for unit conversion preference changes
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _api.dispose();
    super.dispose();
  }
}
