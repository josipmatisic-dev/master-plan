# Provider Dependency Graph - Phase 2

**Version:** 3.0  
**Date:** 2026-02-09  
**Status:** Implemented (BoatProvider, NMEAProvider, RouteProvider added)

---

## Provider Hierarchy

Following **CON-004** from MASTER_DEVELOPMENT_BIBLE.md, all providers are organized in strict acyclic layers with one-directional dependencies:

```text
┌──────────────────────────────────────────────────────────┐
│                   Layer 2 (Navigation)                   │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ MapProvider  │  │NMEAProvider  │  │RouteProvider │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                  │                 │            │
│         │          ┌───────┘                 │            │
│         │          ▼                         │            │
│         │   ┌──────────────┐                 │            │
│         │   │BoatProvider  │                 │            │
│         │   │ (← NMEA)     │                 │            │
│         │   └──────────────┘                 │            │
│         │                                    │            │
│         └──────────┬─────────────────────────┘            │
└────────────────────┼────────────────────────────────────┘
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

#### BoatProvider (NEW - Phase 2)

- File: `lib/providers/boat_provider.dart`
- Lines: ~230 (under 300 limit ✅)
- Dependencies: NMEAProvider (Layer 2 peer, listens via ChangeNotifier)
- Responsibilities:
  - Consume NMEAProvider position data
  - Maintain current vessel position state
  - Track history with LRU eviction (max 1000 points)
  - ISS-018 position jump filtering (reject speed >50 m/s + accuracy >50 m)
  - Man Overboard (MOB) marker capability

**API:**

```dart
class BoatProvider extends ChangeNotifier {
  BoatPosition? get currentPosition;
  List<BoatPosition> get trackHistory;
  int get trackHistoryLength;
  BoatPosition? get mobPosition;
  bool get hasMob;
  bool get isTracking;
  bool get hasPosition;
  
  void updateFromNMEA(NMEAData? data);
  void markMOB();
  void clearMOB();
  void clearTrack();
  void setTracking({required bool enabled});
}
```

#### Weather Provider (Planned - Phase 3)

- File: `lib/providers/weather_provider.dart`
- Layer: 2
- Status: Scheduled for Phase 3

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
  final boatProvider = BoatProvider(nmeaProvider: nmeaProvider);

  // 4. Initialize async providers (Layer 0 first, then Layer 1)
  await Future.wait([
    settingsProvider.init(),
    themeProvider.init(),
    cacheProvider.init(),
    mapProvider.init(),
  ]);

  // 5. Provide to app
  runApp(MarineNavigationApp(
    settingsProvider: settingsProvider,
    themeProvider: themeProvider,
    cacheProvider: cacheProvider,
    mapProvider: mapProvider,
    nmeaProvider: nmeaProvider,
    routeProvider: routeProvider,
    boatProvider: boatProvider,
  ));
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

- SettingsProvider: ~130 lines
- ThemeProvider: ~115 lines
- CacheProvider: ~120 lines
- MapProvider: ~100 lines
- NMEAProvider: ~231 lines
- RouteProvider: ~175 lines
- BoatProvider: ~230 lines

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
| BoatPosition (model) | 14 | ✅ |
| **Total** | **148+** | **185 including widget/integration** |

Key test areas per provider:

1. **SettingsProvider** — Default values, persistence, validation, reset
2. **ThemeProvider** — Mode switching, persistence, red light mode, system theme
3. **CacheProvider** — Statistics tracking, clearing, invalidation
4. **MapProvider** — Viewport state, errors, projection coordination
5. **NMEAProvider** — Connection lifecycle, data parsing, reconnection, errors
6. **RouteProvider** — Route activation, waypoint navigation, metrics, progress
7. **BoatProvider** — NMEA consumption, ISS-018 filtering, track history LRU, MOB, dispose

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
**Last Updated:** 2026-02-09
**Status:** Phase 2 — Boat Position Tracking ✅
