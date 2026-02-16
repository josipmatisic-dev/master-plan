# Provider Dependency Graph - Phase 3

**Version:** 5.0  
**Date:** 2026-02-17  
**Status:** Implemented (AnchorAlarmService added)

---

## Provider Hierarchy

Following **CON-004** from MASTER_DEVELOPMENT_BIBLE.md, all providers are organized in strict acyclic layers with one-directional dependencies:

```text
┌──────────────────────────────────────────────────────────────────────────┐
│                          Layer 2 (Navigation)                           │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │ MapProvider  │  │NMEAProvider  │  │RouteProvider │  │WeatherProv. │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘  │
│         │                  │                 │                  │         │
│         │          ┌───────┘                 │                  │         │
│         │          ▼                         │                  │         │
│         │   ┌──────────────┐                 │      ┌──────────┘         │
│         │   │BoatProvider  │                 │      ▼                    │
│         │   │(←NMEA,Map,Rt)│                 │  ┌──────────────┐        │
│         │   └──────────────┘                 │  │TimelineProv. │        │
│         │                                    │  └──────────────┘        │
│         │   ┌──────────────┐                 │                          │
│         │   │ AisProvider  │                 │                          │
│         │   │(←Settings)   │                 │                          │
│         │   └──────────────┘                 │                          │
│         └──────────┬───────┴─────────────────┴──────────────────┘        │
└────────────────────┼────────────────────────────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────────────┐
│                    │      Layer 1                       │
│         ┌──────────▼──────────┐  ┌──────────────┐       │
│         │  CacheProvider      │  │ThemeProvider │       │
│         └──────────┬──────────┘  └──────┬───────┘       │
│                    │                     │               │
│                    └──────────┬──────────┘               │
└───────────────────────────────┼───────────────────────┘
                                │
┌───────────────────────────────┼───────────────────────┐
│                               │  Layer 0              │
│                    ┌──────────▼──────────┐            │
│                    │ SettingsProvider    │            │
│                    │  (No Dependencies)  │            │
│                    └─────────────────────┘            │
└────────────────────────────────────────────────────────┘
```

## Implementation Status

### ✅ Layer 0: Foundation (Complete)

#### SettingsProvider

- File: `lib/providers/settings_provider.dart`
- Lines: ~130 (under 300 limit ✅)
- Dependencies: None
- Responsibilities:
  - User preferences (units, language)
  - App configuration
  - Persist settings to SharedPreferences

**API:**

```dart
class SettingsProvider extends ChangeNotifier {
  SpeedUnit get speedUnit;
  DistanceUnit get distanceUnit;
  String get language;
  int get mapRefreshRate;
  
  Future<void> setSpeedUnit(SpeedUnit unit);
  Future<void> setDistanceUnit(DistanceUnit unit);
  Future<void> setLanguage(String lang);
  Future<void> setMapRefreshRate(int ms);
  Future<void> resetToDefaults();
}
```

### ✅ Layer 1: UI Coordination (Complete)

#### ThemeProvider

- File: `lib/providers/theme_provider.dart`
- Lines: ~115 (under 300 limit ✅)
- Dependencies: Can access SettingsProvider (Layer 0)
- Responsibilities:
  - Theme mode management (dark/light/system/red light)
  - Provide ThemeData to MaterialApp
  - Persist theme preference

**API:**

```dart
class ThemeProvider extends ChangeNotifier {
  AppThemeMode get themeMode;
  ThemeData getTheme(Brightness systemBrightness);
  bool isDark(Brightness systemBrightness);
  bool get isRedLightMode;
  
  Future<void> setThemeMode(AppThemeMode mode);
  Future<void> toggleTheme();
  Future<void> enableRedLightMode();
  Future<void> disableRedLightMode();
}
```

#### CacheProvider

- File: `lib/providers/cache_provider.dart`
- Lines: ~120 (under 300 limit ✅)
- Dependencies: Can access SettingsProvider (Layer 0)
- Responsibilities:
  - Coordinate cache operations
  - Expose cache statistics to UI
  - Cache invalidation controls

**API:**

```dart
class CacheProvider extends ChangeNotifier {
  CacheStats get stats;
  bool get isInitialized;
  double get cacheSizeMB;
  
  Future<void> refreshStats();
  Future<void> clearCache();
  Future<void> invalidate(String key);
  Future<T?> get<T>(String key);
}
```

### ✅ Layer 2: Feature Providers (Implemented)

#### MapProvider

- File: `lib/providers/map_provider.dart`
- Lines: ~100 (under 300 limit ✅)
- Dependencies: SettingsProvider, CacheProvider
- Responsibilities:
  - Owns viewport state (center/zoom/size/rotation)
  - Emits map errors to UI
  - Coordinates with ProjectionService

#### NMEAProvider

- File: `lib/providers/nmea_provider.dart`
- Lines: ~231 (under 300 limit ✅)
- Dependencies: SettingsProvider, CacheProvider
- Responsibilities:
  - Manage NMEA data connection lifecycle (TCP/UDP)
  - Provide real-time marine navigation data (SOG, COG, depth, wind, GPS position)
  - Auto-reconnect with exponential backoff
  - Stream parsed NMEA sentences to UI

**API:**

```dart
class NMEAProvider extends ChangeNotifier {
  ConnectionStatus get status;
  bool get isConnected;
  bool get isActive;
  int get reconnectAttempts;
  NMEAError? get lastError;
  NMEAData? get currentData;
  DateTime? get lastUpdateTime;
  
  Future<void> connect();
  Future<void> disconnect();
  void clearError();
}
```

#### RouteProvider

- File: `lib/providers/route_provider.dart`
- Lines: ~175 (under 300 limit ✅)
- Dependencies: None (uses GeoUtils service)
- Responsibilities:
  - Manage active route state
  - Track current waypoint and position
  - Calculate navigation metrics (distance, bearing, ETA, progress)
  - Notify listeners of route changes

**API:**

```dart
class RouteProvider extends ChangeNotifier {
  Route? get activeRoute;
  int get currentWaypointIndex;
  LatLng? get currentPosition;
  Waypoint? get nextWaypoint;
  
  double get distanceToNextWaypoint;
  double get bearingToNextWaypoint;
  double get totalRouteDistance;
  double get distanceRemaining;
  double get routeProgress;
  
  double getETAToNextWaypoint(double speedKnots);
  
  void activateRoute(Route route);
  void updatePosition(LatLng position);
  void advanceWaypoint();
  void revertWaypoint();
  void deactivateRoute();
  void clearPosition();
}
```

#### Weather Provider (Implemented - FEAT-004)

- File: `lib/providers/weather_provider.dart`
- Lines: ~230 (under 300 limit ✅)
- Dependencies: SettingsProvider (Layer 0), CacheProvider (Layer 1)
- Responsibilities:
  - Fetch weather data from Open-Meteo Marine API
  - Cache-first strategy with 1-hour TTL
  - Debounced viewport-based fetching (500ms)
  - Toggle wind/wave overlay layers
  - Track loading, error, and staleness states

**API:**

```dart
class WeatherProvider extends ChangeNotifier {
  // State getters
  WeatherData? get weatherData;
  bool get isLoading;
  String? get error;
  bool get isLayerActive;
  WeatherLayer get activeLayer;
  bool get isStale;
  
  // Actions
  Future<void> refresh(LatLng southWest, LatLng northEast);
  void fetchForViewport(Viewport viewport);
  void toggleLayer();
  void setLayerActive(bool active);
  void clearData();
}
```

#### BoatProvider (NEW - Phase 2)

- File: `lib/providers/boat_provider.dart`
- Lines: ~263 (under 300 limit ✅)
- Dependencies: NMEAProvider (Layer 2 peer), MapProvider (Layer 2 peer), LocationService (optional, for phone GPS fallback), RouteProvider (optional, for XTE/nav sync), AnchorAlarmService (service, for geofence monitoring)
- Responsibilities:
  - Consume NMEAProvider position data via `addListener`
  - Maintain current vessel position state
  - Track history with LRU eviction (max 1000 points)
  - ISS-018 position jump filtering (reject speed >50 m/s + accuracy >50 m)
  - Follow-boat mode (auto-center map on vessel)
  - Anchor alarm geofence monitoring (set/clear anchor, drift detection)

**API:**

```dart
class BoatProvider extends ChangeNotifier {
  BoatPosition? get currentPosition;
  PositionSource get source;           // none, nmea, phoneGps
  bool get followBoat;
  Queue<TrackPoint> get trackHistory;  // LRU queue, max 1000 points
  AnchorAlarmService get anchorAlarm;  // geofence monitoring
  
  void toggleFollowBoat();
  void dispose();
}
```

#### TimelineProvider (NEW - Phase 2)

- File: `lib/providers/timeline_provider.dart`
- Lines: ~208 (under 300 limit ✅)
- Dependencies: WeatherProvider (Layer 2 peer)
- Responsibilities:
  - Manage forecast timeline scrubber position (0.0–1.0)
  - Playback controls (play/pause/speed)
  - Map scrubber position to WeatherFrame index
  - Auto-advance during playback

**API:**

```dart
class TimelineProvider extends ChangeNotifier {
  double get scrubberPosition;        // 0.0 to 1.0
  bool get isPlaying;
  double get playbackSpeed;           // 1.0x, 2.0x, 4.0x
  int get currentFrameIndex;
  int get totalFrames;
  WeatherFrame? get currentFrame;
  
  void setScrubberPosition(double position);
  void play();
  void pause();
  void togglePlayback();
  void setPlaybackSpeed(double speed);
  void stepForward();
  void stepBackward();
}
```

#### AisProvider (NEW - Phase 3)

- File: `lib/providers/ais_provider.dart`
- Lines: ~225 (under 300 limit ✅)
- Dependencies: SettingsProvider (Layer 0)
- Services: AisService (WebSocket), AisCollisionCalculator
- Responsibilities:
  - Connect to aisstream.io WebSocket for real-time AIS data
  - Maintain vessel target map (max 500 targets)
  - 500ms batched updates to prevent UI thrashing
  - CPA/TCPA collision warning computation
  - Stale target cleanup (>5 min)
  - Viewport-based bounding box filtering

**API:**

```dart
class AisProvider extends ChangeNotifier {
  Map<int, AisTarget> get targets;
  List<AisTarget> get warnings;        // CPA-sorted collision warnings
  AisConnectionState get connectionState;
  int get targetCount;
  bool get isConnected;
  
  Future<void> connect({swLat, swLng, neLat, neLng});
  Future<void> updateViewport({swLat, swLng, neLat, neLng});
  void updateOwnVessel({position, sogKnots, cogDegrees});
  Future<void> disconnect();
}
```

## Provider Initialization Order

In `main.dart`, providers are initialized in dependency order:

```dart
void main() async {
  // 1. Layer 0: Foundation (no dependencies)
  final settingsProvider = SettingsProvider();

  // 2. Layer 1: UI coordination (depends on Layer 0)
  final themeProvider = ThemeProvider();
  final cacheProvider = CacheProvider();

  // 3. Layer 2: Domain / feature providers
  final mapProvider = MapProvider(
    settingsProvider: settingsProvider,
    cacheProvider: cacheProvider,
  );
  final nmeaProvider = NMEAProvider(
    settingsProvider: settingsProvider,
    cacheProvider: cacheProvider,
  );
  final routeProvider = RouteProvider();
  final weatherProvider = WeatherProvider(
    settingsProvider: settingsProvider,
    cacheProvider: cacheProvider,
  );
  final boatProvider = BoatProvider(
    nmeaProvider: nmeaProvider,
    mapProvider: mapProvider,
    routeProvider: routeProvider,
  );
  final timelineProvider = TimelineProvider(
    weatherProvider: weatherProvider,
  );
  final aisProvider = AisProvider(
    settingsProvider: settingsProvider,
  );
  
  // 4. Initialize all providers
  await Future.wait([
    settingsProvider.init(),
    themeProvider.init(),
    cacheProvider.init(),
    mapProvider.init(),
    aisProvider.init(),
  ]);
  
  // 5. Setup app with all providers
  runApp(MarineNavigationApp(...));
}
```

## Provider Wiring in Widget Tree

```dart
MultiProvider(
  providers: [
    // Layer 0: No dependencies
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settingsProvider,
    ),

    // Layer 1: Can depend on Layer 0
    ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
    ),
    ChangeNotifierProvider<CacheProvider>.value(
      value: cacheProvider,
    ),

    // Layer 2: Feature providers
    ChangeNotifierProvider<MapProvider>.value(
      value: mapProvider,
    ),
    ChangeNotifierProvider<NMEAProvider>.value(
      value: nmeaProvider,
    ),
    ChangeNotifierProvider<RouteProvider>.value(
      value: routeProvider,
    ),
    ChangeNotifierProvider<BoatProvider>.value(
      value: boatProvider,
    ),
    ChangeNotifierProvider<WeatherProvider>.value(
      value: weatherProvider,
    ),
    ChangeNotifierProvider<TimelineProvider>.value(
      value: timelineProvider,
    ),
    ChangeNotifierProvider<AisProvider>.value(
      value: aisProvider,
    ),
  ],
  child: ...,
)
```

## Architecture Rules Compliance

✅ **CON-004**: Provider hierarchy is documented and acyclic

- Maximum 3 layers
- Dependencies only flow downward
- No circular references
- Clear documentation

✅ **CON-001**: All providers under 300 lines

- SettingsProvider: ~286 lines
- ThemeProvider: ~115 lines
- CacheProvider: ~120 lines
- MapProvider: ~100 lines
- NMEAProvider: ~231 lines
- RouteProvider: ~175 lines
- BoatProvider: ~230 lines
- WeatherProvider: ~230 lines
- TimelineProvider: ~208 lines
- AisProvider: ~225 lines

✅ **CON-002**: Single Source of Truth

- Each provider manages distinct state
- No duplicate state across providers
- Clear ownership of data

✅ **CON-006**: Proper disposal

- All providers implement dispose()
- Resources cleaned up properly
- BoatProvider removes NMEAProvider listener on dispose

## Testing Summary

| Provider | Tests | Coverage |
| ---------- | ------- | ---------- |
| SettingsProvider | 18 | ✅ |
| ThemeProvider | 15 | ✅ |
| CacheProvider | 12 | ✅ |
| MapProvider | 20 | ✅ |
| NMEAProvider | 14 | ✅ |
| RouteProvider | 30 | ✅ |
| BoatProvider | 25 | ✅ |
| WeatherProvider | 22 | ✅ |
| TimelineProvider | 12 | ✅ |
| BoatPosition (model) | 14 | ✅ |
| AIS (models + collision) | 22 | ✅ |
| AnchorAlarm (model + service) | 21 | ✅ |
| **Total** | **190+** | **419 including widget/integration** |

Key test areas per provider:

1. **SettingsProvider** — Default values, persistence, validation, reset
2. **ThemeProvider** — Mode switching, persistence, red light mode, system theme
3. **CacheProvider** — Statistics tracking, clearing, invalidation
4. **MapProvider** — Viewport state, errors, projection coordination
5. **NMEAProvider** — Connection lifecycle, data parsing, reconnection, errors
6. **RouteProvider** — Route activation, waypoint navigation, metrics, progress
7. **BoatProvider** — NMEA consumption, ISS-018 filtering, track history LRU, MOB, dispose
8. **WeatherProvider** — Data fetching, caching, layer toggling, staleness, viewport debounce
9. **TimelineProvider** — Scrubber position, playback controls, frame mapping, speed settings
10. **AisProvider** — AIS target tracking, CPA/TCPA warnings, WebSocket connection, batching

## Future Extensions

When adding new providers in Layer 2:

1. **Determine layer** based on dependencies
2. **Document** in this file
3. **Verify acyclic** - no circular dependencies
4. **Keep under 300 lines** (CON-001)
5. **Add to main.dart** in correct order
6. **Write tests** with 80%+ coverage

---

**Created:** 2026-02-01
**Last Updated:** 2026-02-17
**Status:** Phase 3 — AIS Vessel Tracking + Anchor Alarm ✅
