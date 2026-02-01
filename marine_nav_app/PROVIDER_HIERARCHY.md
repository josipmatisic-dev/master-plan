# Provider Dependency Graph - Phase 0

**Version:** 1.0  
**Date:** 2026-02-01  
**Status:** Implemented

---

## Provider Hierarchy

Following **CON-004** from MASTER_DEVELOPMENT_BIBLE.md, all providers are organized in strict acyclic layers with one-directional dependencies:

```
┌─────────────────────────────────────────────────────┐
│                  Layer 2 (Future)                   │
│                                                     │
│  ┌──────────────┐         ┌──────────────┐        │
│  │ MapProvider  │         │WeatherProvider│        │
│  └──────┬───────┘         └──────┬────────┘        │
│         │                         │                 │
│         └─────────┬───────────────┘                 │
└───────────────────┼─────────────────────────────────┘
                    │
┌───────────────────┼─────────────────────────────────┐
│                   │      Layer 1                    │
│         ┌─────────▼─────────┐  ┌──────────────┐    │
│         │  CacheProvider    │  │ThemeProvider │    │
│         └─────────┬─────────┘  └──────┬───────┘    │
│                   │                    │             │
│                   └──────────┬─────────┘             │
└──────────────────────────────┼──────────────────────┘
                               │
┌──────────────────────────────┼──────────────────────┐
│                              │  Layer 0             │
│                    ┌─────────▼─────────┐            │
│                    │ SettingsProvider  │            │
│                    │  (No Dependencies) │            │
│                    └───────────────────┘            │
└─────────────────────────────────────────────────────┘
```

## Implementation Status

### ✅ Layer 0: Foundation (Complete)

**SettingsProvider**
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

**ThemeProvider**
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

**CacheProvider**
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

### ⏳ Layer 2: Feature Providers (Future Phase)

**MapProvider** (Not yet implemented)
- Will manage map viewport state
- Dependencies: SettingsProvider, CacheProvider
- Coordinates with ProjectionService

**WeatherProvider** (Not yet implemented)
- Will manage weather data
- Dependencies: SettingsProvider, CacheProvider
- Coordinates with WeatherService

## Provider Initialization Order

In `main.dart`, providers are initialized in dependency order:

```dart
void main() async {
  // 1. Create providers
  final settingsProvider = SettingsProvider();
  final themeProvider = ThemeProvider();
  final cacheProvider = CacheProvider();
  
  // 2. Initialize all (Layer 0 first, then Layer 1)
  await Future.wait([
    settingsProvider.init(),
    themeProvider.init(),
    cacheProvider.init(),
  ]);
  
  // 3. Provide to app
  runApp(MarineNavigationApp(
    settingsProvider: settingsProvider,
    themeProvider: themeProvider,
    cacheProvider: cacheProvider,
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
    
    // Layer 2 (Future): MapProvider, WeatherProvider
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

✅ **CON-002**: Single Source of Truth
- Each provider manages distinct state
- No duplicate state across providers
- Clear ownership of data

✅ **CON-006**: Proper disposal
- All providers implement dispose()
- Resources cleaned up properly

## Testing Strategy

Each provider will have unit tests covering:

1. **SettingsProvider**
   - Default values
   - Setting persistence
   - Validation
   - Reset functionality

2. **ThemeProvider**
   - Theme mode switching
   - Persistence
   - Red light mode
   - System theme following

3. **CacheProvider**
   - Statistics tracking
   - Cache clearing
   - Invalidation
   - Integration with CacheService (when available)

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
**Last Updated:** 2026-02-01  
**Status:** Phase 0 Complete ✅
