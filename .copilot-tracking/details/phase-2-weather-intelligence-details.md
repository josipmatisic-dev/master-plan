# Phase 2 Weather Intelligence - Detailed Specifications

**Phase:** 2 - Weather Intelligence  
**Purpose:** Weather API integration, forecasting, and timeline playback  
**References:** [Phase 2 Plan](../plans/phase-2-weather-intelligence-plan.md)

## Weather API Integration

### Open-Meteo API Specification

**Endpoint:** `https://marine-api.open-meteo.com/v1/marine`

**Parameters:**
```text
latitude=48.0&longitude=-123.0
&hourly=wave_height,wave_direction,wave_period,wind_wave_height,wind_wave_direction,wind_wave_period
&daily=wave_height_max,wave_period_max,wind_wave_height_max
&timezone=auto
```text

**Response Model:**
```dart
@freezed
class WeatherData with _$WeatherData {
  const factory WeatherData({
    required List<ForecastHour> hourly,
    required List<ForecastDay> daily,
    required DateTime fetchedAt,
  }) = _WeatherData;
}
```text

## Cache-First Architecture

**Critical:** Prevents ISS-004 (stale cache) and ISS-010 (offline errors)

```dart
class WeatherProvider extends ChangeNotifier {
  Future<WeatherData> getWeather(Bounds bounds) async {
    final cacheKey = 'weather_${bounds.hashCode}';
    
    // 1. Check cache FIRST
    final cached = await _cache.get<WeatherData>(cacheKey);
    if (cached != null && !_isExpired(cached)) {
      _currentWeather = cached;
      notifyListeners(); // Return immediately
      
      // 2. Refresh in background
      _refreshInBackground(bounds, cacheKey);
      return cached;
    }
    
    // 3. Fetch from network
    try {
      final data = await _api.fetchWeather(bounds).timeout(Duration(seconds: 10));
      await _cache.set(cacheKey, data, ttl: Duration(hours: 1));
      _currentWeather = data;
      notifyListeners();
      return data;
    } catch (e) {
      // 4. Return stale cache on error
      if (cached != null) return cached;
      rethrow;
    }
  }
}
```text

## Timeline Playback

**Critical:** Lazy loading prevents ISS-013 (OutOfMemory)

```dart
class TimelineProvider extends ChangeNotifier {
  final int _maxCachedFrames = 5;
  final Map<int, WeatherFrame> _frameCache = {};
  int _currentIndex = 0;
  
  Future<WeatherFrame> getCurrentFrame() async {
    return await _loadFrame(_currentIndex);
  }
  
  Future<WeatherFrame> _loadFrame(int index) async {
    // Check cache
    if (_frameCache.containsKey(index)) {
      return _frameCache[index]!;
    }
    
    // Evict furthest frame if full
    if (_frameCache.length >= _maxCachedFrames) {
      final furthest = _getFurthestFrame(_currentIndex);
      _frameCache.remove(furthest);
    }
    
    // Load frame
    final frame = await _api.getForecastFrame(index);
    _frameCache[index] = frame;
    
    // Preload next
    _preloadFrame(index + 1);
    
    return frame;
  }
}
```text

## Weather Overlay Rendering

### Precipitation Overlay

Color-coded by intensity:
- 0-1mm/h: Light blue (0x4080C0FF)
- 1-5mm/h: Blue (0x2060A0FF)
- 5-10mm/h: Dark blue (0x104080FF)
- >10mm/h: Navy (0x082040FF)

### Ocean Current Overlay

Vector arrows similar to wind, but:
- Color: Purple/magenta
- Length proportional to current speed (knots)

## Performance Targets

- Weather API response: <2s
- Timeline frame load: <500ms
- Cache retrieval: <50ms
- Playback FPS: 60 (smooth)
- Memory with 5 cached frames: <100MB

---

**For complete task breakdown, see:** [Phase 2 Plan](../plans/phase-2-weather-intelligence-plan.md)
