# Provider Dependency Graph - Phase 1

**Version:** 2.0  
**Date:** 2026-02-03  
**Status:** Implemented (RouteProvider added)

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
│         └──────────┬───────┴─────────────────┘            │
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
```text

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
```text

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
```text

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
```text

### ⏳ Layer 2: Feature Providers (Partial)

#### MapProvider (Implemented)

- File: `lib/providers/map_provider.dart`
- Dependencies: SettingsProvider, CacheProvider
- Responsibilities:
  - Owns viewport state (center/zoom/size/rotation)
  - Emits map errors to UI
  - Coordinates with ProjectionService

#### NMEAProvider (Implemented)

- File: `lib/providers/nmea_provider.dart`
- Lines: ~216 (under 300 limit ✅)
- Dependencies: SettingsProvider, CacheProvider
- Responsibilities:
  - Manage NMEA data connection lifecycle (TCP/UDP)
  - Provide real-time marine navigation data (SOG, COG, depth, wind, GPS position)
  - Auto-reconnect with exponential backoff
  - Stream parsed NMEA sentences to UI
  
**API:**

```dart
class NMEAProvider extends ChangeNotifier {
  // Connection state
  ConnectionStatus get status;
  bool get isConnected;
  bool get isActive;
  int get reconnectAttempts;
  NMEAError? get lastError;
  
  // Data streams
  NMEAData? get currentData;
  DateTime? get lastUpdateTime;
  
  // Actions
  Future<void> connect();
  Future<void> disconnect();
  void clearError();
}
```text

#### RouteProvider (NEW - Phase 1)

- File: `lib/providers/route_provider.dart`
- Lines: ~168 (under 300 limit ✅)
- Dependencies: None (uses GeoUtils service)
- Responsibilities:
  - Manage active route state
  - Track current waypoint and position
  - Calculate navigation metrics (distance, bearing, ETA, progress)
  - Notify listeners of route changes

**API:**

```dart
class RouteProvider extends ChangeNotifier {
  // State getters
  Route? get activeRoute;
  int get currentWaypointIndex;
  LatLng? get currentPosition;
  Waypoint? get nextWaypoint;
  
  // Metrics
  double get distanceToNextWaypoint;
  double get bearingToNextWaypoint;
  double get totalRouteDistance;
  double get distanceRemaining;
  double get routeProgress;
  
  // ETA calculation
  double getETAToNextWaypoint(double speedKnots);
  
  // Actions
  void activateRoute(Route route);
  void updatePosition(LatLng position);
  void advanceWaypoint();
  void revertWaypoint();
  void deactivateRoute();
  void clearPosition();
}
```text

#### Weather Provider (Planned - Phase 2)

- File: `lib/providers/weather_provider.dart`
- Layer: 2
- Status: Scheduled for Phase 2

## Provider Initialization Order

In `main.dart`, providers are initialized in dependency order:

```dart
void main() async {
  // 1. Create Layer 0 providers (no dependencies)
  final settingsProvider = SettingsProvider();
  
  // 2. Create Layer 1 providers (depend on Layer 0)
  final themeProvider = ThemeProvider();
  final cacheProvider = CacheProvider();
  
  // 3. Create Layer 2 providers (depend on Layers 0+1, services)
  final mapProvider = MapProvider(...);
  final nmeaProvider = NMEAProvider(...);
  final routeProvider = RouteProvider();
  
  // 4. Initialize all providers
  await Future.wait([...]);
  
  // 5. Setup app with all providers
  runApp(MarineNavigationApp(...));
}
```text

## Constraint Compliance

✅ **CON-004**: Acyclic provider dependencies
✅ **CON-001**: All providers under 300 lines
✅ **CON-002**: Single Source of Truth
✅ **CON-006**: Proper disposal

## Phase 1 Test Coverage Summary

- **SettingsProvider**: 18 tests ✅
- **ThemeProvider**: 15 tests ✅
- **CacheProvider**: 12 tests ✅
- **MapProvider**: 20 tests ✅
- **NMEAProvider**: 27 tests ✅
- **RouteProvider**: 30 tests ✅ NEW

**Total:** 142/142 tests passing ✅

---

**Created:** 2026-02-01  
**Last Updated:** 2026-02-03  
**Status:** Phase 1 - Core Navigation (50% complete) - RouteProvider added ✅
