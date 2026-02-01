# Phase 0 Architecture - Provider Hierarchy and Data Flow

**Version:** 1.0  
**Date:** 2026-02-01  
**Status:** Design Complete - Awaiting Implementation

---

## Table of Contents

1. [Provider Dependency Graph](#provider-dependency-graph)
2. [Data Flow Architecture](#data-flow-architecture)
3. [Service Layer Architecture](#service-layer-architecture)
4. [Coordinate Projection Pipeline](#coordinate-projection-pipeline)
5. [Caching Strategy](#caching-strategy)
6. [Error Handling Strategy](#error-handling-strategy)
7. [Testing Strategy](#testing-strategy)

---

## Provider Dependency Graph

### Layer Architecture (Acyclic)

Following **CON-004** from `MASTER_DEVELOPMENT_BIBLE.md`, all providers are organized in strict layers with one-directional dependencies:

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

### Provider Specifications

#### Layer 0: SettingsProvider

**File:** `lib/providers/settings_provider.dart`

**Responsibilities:**
- User preferences (units, language)
- App configuration
- Persist settings to disk

**Dependencies:** None

**API:**
```dart
class SettingsProvider extends ChangeNotifier {
  SpeedUnit get speedUnit;
  void setSpeedUnit(SpeedUnit unit);
  
  DistanceUnit get distanceUnit;
  void setDistanceUnit(DistanceUnit unit);
  
  String get language;
  void setLanguage(String lang);
  
  Future<void> loadSettings();
  Future<void> saveSettings();
}
```

**No Circular Dependencies:** This is Layer 0, bottom of the hierarchy.

---

#### Layer 1: ThemeProvider

**File:** `lib/providers/theme_provider.dart`

**Responsibilities:**
- Theme mode management (light/dark/system)
- Provide ThemeData to MaterialApp
- Persist theme preference

**Dependencies:**
- ✅ SettingsProvider (Layer 0)

**API:**
```dart
class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._settingsProvider);
  
  final SettingsProvider _settingsProvider;
  
  ThemeMode get themeMode;
  void setThemeMode(ThemeMode mode);
  void toggleDarkMode();
  
  ThemeData get lightTheme;
  ThemeData get darkTheme;
}
```

**Dependency Justification:** ThemeProvider needs to persist theme choice through SettingsProvider.

---

#### Layer 1: CacheProvider

**File:** `lib/providers/cache_provider.dart`

**Responsibilities:**
- Coordinate CacheService lifecycle
- Provide cache statistics to UI
- Handle cache clearing

**Dependencies:**
- ✅ SettingsProvider (Layer 0)

**API:**
```dart
class CacheProvider extends ChangeNotifier {
  CacheProvider(this._settingsProvider, this._cacheService);
  
  final SettingsProvider _settingsProvider;
  final CacheService _cacheService;
  
  Future<void> init();
  Future<void> clearCache();
  int get cacheSize;
  String get cacheSizeFormatted;
}
```

**Dependency Justification:** CacheProvider may need to respect user-configured cache limits from SettingsProvider.

---

#### Layer 2: MapProvider (Future - Phase 1)

**File:** `lib/providers/map_provider.dart`

**Responsibilities:**
- Map viewport state
- Coordinate WebView communication
- Handle map interactions

**Dependencies:**
- ✅ CacheProvider (Layer 1)
- ✅ SettingsProvider (Layer 0)

**NOT IMPLEMENTED IN PHASE 0**

---

#### Layer 2: WeatherProvider (Future - Phase 2)

**File:** `lib/providers/weather_provider.dart`

**Responsibilities:**
- Weather data fetching
- Weather cache management
- Overlay data for map

**Dependencies:**
- ✅ CacheProvider (Layer 1)
- ✅ SettingsProvider (Layer 0)

**NOT IMPLEMENTED IN PHASE 0**

---

### Main.dart Provider Setup

**File:** `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services (no Provider needed for stateless services)
  final cacheService = CacheService();
  await cacheService.init();
  
  final httpClient = HttpClient();
  final projectionService = ProjectionService();
  final nmeaParser = NMEAParser();
  final databaseService = DatabaseService();
  await databaseService.init();
  
  runApp(
    MultiProvider(
      providers: [
        // Layer 0: No dependencies
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        
        // Layer 1: Depends on Layer 0
        ChangeNotifierProxyProvider<SettingsProvider, ThemeProvider>(
          create: (_) => ThemeProvider(
            Provider.of<SettingsProvider>(_, listen: false),
          ),
          update: (_, settings, themeProvider) => themeProvider!,
        ),
        
        ChangeNotifierProxyProvider<SettingsProvider, CacheProvider>(
          create: (_) => CacheProvider(
            Provider.of<SettingsProvider>(_, listen: false),
            cacheService,
          )..init(),
          update: (_, settings, cacheProvider) => cacheProvider!,
        ),
        
        // Services (not ChangeNotifiers, provided as values)
        Provider<CacheService>.value(value: cacheService),
        Provider<HttpClient>.value(value: httpClient),
        Provider<ProjectionService>.value(value: projectionService),
        Provider<NMEAParser>.value(value: nmeaParser),
        Provider<DatabaseService>.value(value: databaseService),
      ],
      child: const MyApp(),
    ),
  );
}
```

**Key Rules:**
1. All providers created at app root (never in widget build methods)
2. ProxyProvider used for dependencies
3. Services provided as values (stateless)
4. Initialization happens before runApp

---

## Data Flow Architecture

### Single Source of Truth (CON-002)

```
┌────────────────────────────────────────────────────────┐
│                  USER INTERFACE                        │
│  (Widgets read from Providers, never write directly)  │
└────────────────┬───────────────────────────────────────┘
                 │ Read Only (Consumer/Provider.of)
┌────────────────▼───────────────────────────────────────┐
│                  PROVIDERS                             │
│  (Single Source of Truth, notifyListeners on change)  │
│                                                        │
│  SettingsProvider → ThemeProvider → UI Theme          │
│  CacheProvider → Cache Stats → UI Display             │
└────────────────┬───────────────────────────────────────┘
                 │ Service Calls
┌────────────────▼───────────────────────────────────────┐
│                  SERVICES                              │
│  (Stateless logic, no ChangeNotifier)                 │
│                                                        │
│  CacheService → Disk I/O                              │
│  HttpClient → Network Requests                        │
│  ProjectionService → Math/Transforms                  │
│  NMEAParser → String Processing                       │
│  DatabaseService → SQLite Operations                  │
└────────────────┬───────────────────────────────────────┘
                 │ External I/O
┌────────────────▼───────────────────────────────────────┐
│              EXTERNAL SYSTEMS                          │
│                                                        │
│  Disk (SharedPreferences, File System, SQLite)        │
│  Network (APIs, Servers)                              │
│  GPS/Sensors (NMEA Data)                              │
└────────────────────────────────────────────────────────┘
```

### Data Flow Rules

1. **UI → Provider**: UI triggers actions via provider methods
2. **Provider → Service**: Provider calls services to fetch/persist data
3. **Service → External**: Services handle all I/O
4. **External → Service → Provider → UI**: Data flows back up with notifyListeners

**Example Flow: User Changes Speed Unit**

```
1. UI: User taps "Knots" button
   └─> SpeedUnitPicker.onTap(SpeedUnit.knots)

2. Provider: SettingsProvider receives event
   └─> settingsProvider.setSpeedUnit(SpeedUnit.knots)
   └─> notifyListeners()
   └─> _saveSettings() // Persist to disk

3. Service: SharedPreferences saves data
   └─> prefs.setString('speed_unit', 'knots')

4. UI: Consumer rebuilds
   └─> Consumer<SettingsProvider>(
         builder: (context, settings, child) {
           return Text(settings.speedUnit.displayName);
         }
       )
```

**No Duplicate State:** Speed unit exists ONLY in SettingsProvider, nowhere else.

---

## Service Layer Architecture

### Stateless Services (No Provider Needed)

All services in Phase 0 are stateless and provided as simple values, not ChangeNotifiers:

```dart
Provider<CacheService>.value(value: cacheService)
Provider<HttpClient>.value(value: httpClient)
Provider<ProjectionService>.value(value: projectionService)
Provider<NMEAParser>.value(value: nmeaParser)
Provider<DatabaseService>.value(value: databaseService)
```

### Service Usage Pattern

**Access in Providers:**
```dart
class CacheProvider extends ChangeNotifier {
  final CacheService _cacheService;
  
  CacheProvider(this._settingsProvider, this._cacheService);
  
  Future<void> clearCache() async {
    await _cacheService.clear();
    notifyListeners(); // Update UI with new cache size
  }
}
```

**Access in Widgets (Rare):**
```dart
class SomeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final projectionService = Provider.of<ProjectionService>(context, listen: false);
    
    // Use service directly for one-time calculation
    final screenPoint = projectionService.latLngToScreen(...);
    
    return CustomPaint(painter: MyPainter(screenPoint));
  }
}
```

**Never:**
- ❌ Create services inside widgets
- ❌ Make services ChangeNotifiers
- ❌ Store state in services

---

## Coordinate Projection Pipeline

### CON-003: All Coordinate Transforms Through ProjectionService

**Problem Solved:** Prevents projection mismatches that caused overlay rendering failures in Attempts 2 and 4.

```
┌──────────────────────────────────────────────────────┐
│          DATA SOURCE (Always WGS84)                  │
│                                                      │
│  GPS Sensor → LatLng(48.1173, 11.5167)              │
│  API Response → {"lat": 48.1173, "lng": 11.5167}    │
│  User Input → "48.1173, 11.5167"                    │
└──────────────────┬───────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────┐
│       ProjectionService.wgs84ToWebMercator()        │
│                                                      │
│  LatLng(48.1173, 11.5167) → Point(x, y)             │
└──────────────────┬───────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────┐
│       ProjectionService.latLngToScreen()            │
│                                                      │
│  Point(x, y) + Viewport → Offset(screenX, screenY)  │
└──────────────────┬───────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────┐
│              RENDER TO SCREEN                        │
│                                                      │
│  Canvas.drawCircle(Offset(screenX, screenY), ...)   │
└──────────────────────────────────────────────────────┘
```

### Viewport Synchronization

**Problem Solved:** Map in WebView and Flutter overlay must use same viewport state.

```dart
// MapProvider holds viewport state (Phase 1)
class MapProvider extends ChangeNotifier {
  Viewport _viewport = Viewport(
    center: LatLng(0, 0),
    zoom: 10,
    bearing: 0,
    pitch: 0,
  );
  
  void updateViewport(Viewport newViewport) {
    _viewport = newViewport;
    notifyListeners(); // Overlay rebuilds with new viewport
  }
}

// Overlay widget uses same viewport
class WeatherOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final projectionService = Provider.of<ProjectionService>(context, listen: false);
    
    return CustomPaint(
      painter: WeatherPainter(
        viewport: mapProvider.viewport,
        projectionService: projectionService,
      ),
    );
  }
}
```

---

## Caching Strategy

### Cache Layers

Following lessons from **A.4: Cache Invalidation Race Conditions**, we use a SINGLE cache layer:

```
┌──────────────────────────────────────────────────────┐
│                    REQUEST                           │
│  "Fetch weather for bounds (45.5, -122.7, 45.6, -122.6)" │
└──────────────────┬───────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────┐
│            1. CHECK CACHE FIRST                      │
│                                                      │
│  CacheService.get('weather_45.5_-122.7_...')        │
│  ├─ Hit: Return cached data immediately             │
│  └─ Miss: Continue to step 2                        │
└──────────────────┬───────────────────────────────────┘
                   │ Cache Miss
┌──────────────────▼───────────────────────────────────┐
│            2. FETCH FROM NETWORK                     │
│                                                      │
│  HttpClient.getJson('https://api.open-meteo.com/...')│
└──────────────────┬───────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────┐
│            3. UPDATE CACHE                           │
│                                                      │
│  CacheService.put('weather_45.5_-122.7_...', data,  │
│                   ttl: Duration(hours: 1))           │
└──────────────────┬───────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────┐
│            4. RETURN TO CALLER                       │
└──────────────────────────────────────────────────────┘
```

### Cache Key Strategy

**Weather Data:**
```dart
String getCacheKey(Bounds bounds, String dataType) {
  // Round to 2 decimal places to increase cache hits
  double lat1 = (bounds.southwest.latitude * 100).round() / 100;
  double lng1 = (bounds.southwest.longitude * 100).round() / 100;
  double lat2 = (bounds.northeast.latitude * 100).round() / 100;
  double lng2 = (bounds.northeast.longitude * 100).round() / 100;
  
  return 'weather_${dataType}_${lat1}_${lng1}_${lat2}_${lng2}';
}
```

**Map Tiles:**
```dart
String getTileCacheKey(int x, int y, int z) {
  return 'tile_${z}_${x}_${y}';
}
```

### Cache Invalidation

**Time-based (TTL):**
- Weather data: 1 hour
- Map tiles: 7 days
- API responses: 5 minutes

**Manual:**
```dart
// User triggers refresh
await cacheProvider.clearCache();

// Or specific type
await cacheService.delete('weather_*'); // Clear all weather data
```

**Event-based (Future):**
- When user changes location significantly
- When app comes to foreground after 1+ hour
- When network reconnects after offline

---

## Error Handling Strategy

### Error Hierarchy

```
Exception
├── NetworkException
│   ├── TimeoutException
│   ├── NoConnectionException
│   └── ServerException
├── CacheException
│   ├── CacheFullException
│   └── CacheCorruptException
├── ParsingException
│   ├── NMEAChecksumException
│   └── JSONParseException
└── ValidationException
    ├── InvalidCoordinateException
    └── InvalidBoundsException
```

### Error Handling Pattern

**Services throw exceptions, Providers handle them:**

```dart
// Service throws
class HttpClient {
  Future<Response> get(String url) async {
    try {
      return await _client.get(url).timeout(Duration(seconds: 30));
    } on TimeoutException {
      throw NetworkException('Request timeout');
    } on SocketException {
      throw NetworkException('No connection');
    }
  }
}

// Provider catches and recovers
class WeatherProvider extends ChangeNotifier {
  Future<void> fetchWeather(Bounds bounds) async {
    try {
      // Try cache first
      final cached = await _cacheService.get(getCacheKey(bounds));
      if (cached != null) {
        _weatherData = cached;
        notifyListeners();
        return;
      }
      
      // Fetch from network
      final data = await _httpClient.getJson(...);
      _weatherData = data;
      await _cacheService.put(getCacheKey(bounds), data);
      notifyListeners();
      
    } on NetworkException catch (e) {
      // Use stale cache if available
      final stale = await _cacheService.get(getCacheKey(bounds), ignoreExpiry: true);
      if (stale != null) {
        _weatherData = stale;
        _showStaleDataWarning = true;
        notifyListeners();
      } else {
        _error = 'No connection and no cached data';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Unexpected error: ${e.toString()}';
      notifyListeners();
    }
  }
}
```

### UI Error Display

```dart
Consumer<WeatherProvider>(
  builder: (context, provider, child) {
    if (provider.error != null) {
      return ErrorWidget(message: provider.error);
    }
    
    if (provider.showStaleDataWarning) {
      return Column(
        children: [
          WarningBanner('Showing cached data - no connection'),
          WeatherDisplay(data: provider.weatherData),
        ],
      );
    }
    
    return WeatherDisplay(data: provider.weatherData);
  },
)
```

---

## Testing Strategy

### Unit Test Pyramid

```
         ┌──────────┐
         │Integration│ (10% - Phase 1+)
         │  Tests    │
         └──────────┘
      ┌──────────────────┐
      │  Widget Tests    │ (20% - Phase 1+)
      │                  │
      └──────────────────┘
   ┌────────────────────────┐
   │    Unit Tests          │ (70% - Phase 0)
   │                        │
   │  Services, Models,     │
   │  Providers, Utils      │
   └────────────────────────┘
```

### Phase 0 Testing Focus

**Services (85% coverage):**
- ✅ CacheService: LRU eviction, TTL expiry, size limits
- ✅ HttpClient: Retry logic, timeouts, error handling
- ✅ ProjectionService: Coordinate accuracy, edge cases
- ✅ NMEAParser: Valid/invalid sentences, checksums
- ✅ DatabaseService: CRUD operations

**Models (80% coverage):**
- ✅ LatLng: Validation, equality, serialization
- ✅ Bounds: Contains, intersects, getters
- ✅ Viewport: Validation, copyWith
- ✅ BoatPosition: Factory methods
- ✅ CacheEntry: Expiry logic
- ✅ NMEAMessage: Subclass integrity

**Providers (70% coverage):**
- ✅ SettingsProvider: Load/save, updates
- ✅ ThemeProvider: Theme switching
- ✅ CacheProvider: Stats, clearing

### Mocking Strategy

```dart
// Mock services in provider tests
class MockCacheService extends Mock implements CacheService {}
class MockHttpClient extends Mock implements HttpClient {}

// Test provider with mocked dependencies
void main() {
  test('CacheProvider clears cache', () async {
    final mockCache = MockCacheService();
    final provider = CacheProvider(mockSettings, mockCache);
    
    when(mockCache.clear()).thenAnswer((_) async => {});
    
    await provider.clearCache();
    
    verify(mockCache.clear()).called(1);
  });
}
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Check coverage
        run: |
          lcov --summary coverage/lcov.info
          # Fail if coverage < 80%
          coverage=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
          if [ $(echo "$coverage < 80" | bc) -eq 1 ]; then
            echo "Coverage $coverage% is below 80%"
            exit 1
          fi
```

---

## Architecture Compliance Checklist

### CON-001: Maximum 300 Lines Per File
- [ ] All services under 300 lines
- [ ] All providers under 300 lines
- [ ] All models under 300 lines
- [ ] Automated check in CI/CD

### CON-002: Single Source of Truth
- [x] Each data element has ONE authoritative source
- [x] No duplicate state across providers
- [x] Documented in this architecture file

### CON-003: All Coordinate Conversions Through ProjectionService
- [x] ProjectionService is only place for WGS84 ↔ Web Mercator
- [x] All overlays must use ProjectionService
- [x] No manual lat/lng to pixel math anywhere

### CON-004: Provider Hierarchy Documented and Acyclic
- [x] Provider dependency graph documented
- [x] No circular dependencies
- [x] Maximum 3 layers (actually 2 in Phase 0)
- [x] Verified in this document

### CON-005: Network Requests Require Retry + Timeout + Cache Fallback
- [x] HttpClient has 3 retry attempts
- [x] 30 second timeout enforced
- [x] Services check cache before network
- [x] Stale cache used if network fails

### CON-006: All Resources Disposed
- [x] All providers have dispose() methods
- [x] All services have dispose() or close() methods
- [x] dispose() documented in API specs
- [x] Tested in unit tests

---

## Next Steps (After Flutter SDK Available)

1. **Implement Services** (1-2 days)
   - CacheService
   - HttpClient
   - ProjectionService
   - NMEAParser
   - DatabaseService

2. **Implement Models** (0.5 days)
   - All 6 data models

3. **Implement Providers** (1 day)
   - SettingsProvider
   - ThemeProvider
   - CacheProvider

4. **Write Tests** (2 days)
   - Unit tests for all components
   - Achieve 80%+ coverage

5. **Set Up CI/CD** (0.5 days)
   - GitHub Actions workflows
   - Coverage reporting

**Total Estimated Time:** 5 days

---

## Document End

This architecture is designed to prevent ALL failures from previous attempts while maintaining clean, testable, and maintainable code. Every decision is grounded in lessons learned from `MASTER_DEVELOPMENT_BIBLE.md`.
