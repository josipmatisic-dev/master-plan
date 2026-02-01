# Codebase Map
## Marine Navigation App - Flutter Project Structure

**Version:** 2.0  
**Last Updated:** 2024-02-01  
**Purpose:** Complete map of codebase structure, dependencies, and data flow

---

## Table of Contents

1. [Directory Structure](#directory-structure)
2. [Provider Dependency Graph](#provider-dependency-graph)
3. [Data Flow Diagrams](#data-flow-diagrams)
4. [Key Files Reference](#key-files-reference)
5. [Service Layer Architecture](#service-layer-architecture)
6. [Widget Hierarchy](#widget-hierarchy)

---

## Directory Structure

```
lib/
├── main.dart                     # App entry, provider setup
├── models/                       # Data models
│   ├── boat_position.dart       # GPS position with heading/speed
│   ├── bounds.dart              # Geographic bounds (SW/NE corners)
│   ├── cache_entry.dart         # Cache metadata (TTL, LRU)
│   ├── forecast_data.dart       # Weather forecast time series
│   ├── lat_lng.dart             # WGS84 coordinate pair
│   ├── nmea_message.dart        # Parsed NMEA sentences
│   ├── viewport.dart            # Map viewport state
│   ├── weather_data.dart        # Current weather conditions
│   ├── wind_data.dart           # Wind speed/direction
│   ├── wave_data.dart           # Wave height/period/direction
│   └── ais_target.dart          # AIS vessel information
│
├── providers/                    # State management (Provider pattern)
│   ├── boat_provider.dart       # Boat position & tracking state
│   ├── cache_provider.dart      # Cache coordination
│   ├── map_provider.dart        # Map viewport & interaction state
│   ├── nmea_provider.dart       # NMEA data stream processing
│   ├── settings_provider.dart   # User preferences & configuration
│   ├── theme_provider.dart      # Theme & dark mode state
│   ├── timeline_provider.dart   # Forecast playback state
│   └── weather_provider.dart    # Weather data & overlays
│
├── services/                     # Business logic & data access
│   ├── cache_service.dart       # LRU disk cache with TTL
│   ├── http_client.dart         # HTTP with retry & backoff
│   ├── location_service.dart    # GPS/location wrapper
│   ├── nmea_parser.dart         # NMEA 0183 sentence parser
│   ├── projection_service.dart  # Coordinate transformations
│   ├── weather_api.dart         # Open-Meteo API client
│   ├── noaa_api.dart            # NOAA tides/buoys API
│   ├── ais_service.dart         # AIS data processing
│   └── database_service.dart    # SQLite local database
│
├── screens/                      # Full-screen pages
│   ├── home_screen.dart         # Main app screen
│   ├── map_screen.dart          # Primary map view
│   ├── forecast_screen.dart     # Weather forecast details
│   ├── timeline_screen.dart     # Forecast playback
│   ├── settings_screen.dart     # App configuration
│   ├── trip_log_screen.dart     # Trip history
│   └── about_screen.dart        # About & help
│
├── widgets/                      # Reusable UI components
│   ├── map_webview.dart         # MapTiler WebView container
│   ├── overlays/                # Map overlay widgets
│   │   ├── wind_overlay.dart   # Wind arrow rendering
│   │   ├── wave_overlay.dart   # Wave height visualization
│   │   ├── current_overlay.dart # Ocean current vectors
│   │   ├── boat_marker.dart    # Boat position indicator
│   │   ├── track_overlay.dart  # Breadcrumb trail
│   │   └── ais_overlay.dart    # AIS vessel markers
│   ├── controls/                # UI controls
│   │   ├── timeline_controls.dart # Play/pause/speed
│   │   ├── layer_toggle.dart   # Overlay enable/disable
│   │   ├── zoom_controls.dart  # +/- buttons
│   │   └── compass_widget.dart # Heading indicator
│   ├── cards/                   # Info display cards
│   │   ├── boat_info_card.dart # Speed/heading/position
│   │   ├── weather_card.dart   # Current conditions
│   │   ├── forecast_card.dart  # Daily forecast
│   │   └── tide_card.dart      # Tide predictions
│   └── common/                  # Shared widgets
│       ├── error_widget.dart   # Error display
│       ├── loading_widget.dart # Loading spinner
│       └── empty_state.dart    # No data state
│
├── utils/                        # Utility functions
│   ├── beaufort.dart            # Wind speed to Beaufort scale
│   ├── conversions.dart         # Unit conversions
│   ├── formatters.dart          # Date/number formatting
│   ├── validators.dart          # Input validation
│   ├── logger.dart              # Logging wrapper
│   └── constants.dart           # App-wide constants
│
├── theme/                        # Styling & theming
│   ├── app_theme.dart           # Light/dark themes
│   ├── colors.dart              # Marine color palette
│   ├── text_styles.dart         # Typography
│   └── dimensions.dart          # Spacing/sizing
│
└── l10n/                         # Localization
    ├── app_en.arb               # English strings
    ├── app_es.arb               # Spanish strings
    └── app_fr.arb               # French strings

assets/
├── map.html                      # MapTiler GL JS setup
├── images/                       # App images
│   ├── logo.png
│   ├── boat_icon.png
│   └── compass_rose.png
└── fonts/                        # Custom fonts
    └── RobotoMono-Regular.ttf

test/
├── unit/                         # Unit tests
│   ├── services/
│   │   ├── nmea_parser_test.dart
│   │   ├── projection_service_test.dart
│   │   └── cache_service_test.dart
│   └── utils/
│       ├── beaufort_test.dart
│       └── conversions_test.dart
├── widget/                       # Widget tests
│   ├── map_webview_test.dart
│   ├── timeline_controls_test.dart
│   └── weather_card_test.dart
└── integration/                  # Integration tests
    └── app_test.dart

---

## Provider Dependency Graph

```
Layer 0 (No Dependencies):
┌─────────────────────┐
│ SettingsProvider    │  ← User preferences, units, language
└─────────────────────┘

Layer 1 (Depends on Layer 0):
┌─────────────────────┐      ┌─────────────────────┐
│ CacheProvider       │      │ ThemeProvider       │
│ - Depends: Settings │      │ - Depends: Settings │
└─────────────────────┘      └─────────────────────┘

Layer 2 (Depends on Layer 0-1):
┌─────────────────────────────┐      ┌─────────────────────────────┐
│ WeatherProvider             │      │ MapProvider                 │
│ - Depends: Settings, Cache  │      │ - Depends: Settings         │
└─────────────────────────────┘      └─────────────────────────────┘
         ↓                                      ↓
┌─────────────────────────────┐      ┌─────────────────────────────┐
│ NMEAProvider                │      │ BoatProvider                │
│ - Depends: Settings         │      │ - Depends: Map, Settings    │
└─────────────────────────────┘      └─────────────────────────────┘

Layer 3 (Depends on Layer 0-2):
┌─────────────────────────────────────────────────┐
│ TimelineProvider                                │
│ - Depends: Weather, Map, Settings               │
└─────────────────────────────────────────────────┘

RULES:
- Maximum 3 layers
- No circular dependencies
- All created in main.dart
- Dependencies documented in code
```

---

## Data Flow Diagrams

### Weather Data Flow

```
User Pans Map
      ↓
MapProvider.updateViewport()
      ↓
WeatherProvider.fetchWeatherForBounds()
      ↓
1. Check CacheService (cache-first)
      ↓
2. If cached & valid → Return immediately
      ↓
3. Background: WeatherApi.fetchWeather()
      ↓
4. Parse response → WeatherData model
      ↓
5. CacheService.set() with TTL
      ↓
6. WeatherProvider.notifyListeners()
      ↓
Widget Rebuild:
  - MapScreen updates overlays
  - WeatherCard shows new data
  - ForecastScreen updates timeline
```

### NMEA Data Flow

```
GPS Device
      ↓
Socket Connection (TCP/UDP)
      ↓
Raw bytes → NMEAProvider
      ↓
Spawn Isolate for parsing
      ↓
NMEAParser.parse() in isolate
      ↓
Validate checksum
      ↓
Parse sentence type (GGA, RMC, AIVDM)
      ↓
Send parsed message to main isolate
      ↓
NMEAProvider receives message
      ↓
Update BoatProvider with position
      ↓
BoatProvider.notifyListeners()
      ↓
Widget Rebuild:
  - BoatMarker moves on map
  - BoatInfoCard updates speed/heading
  - TrackOverlay adds breadcrumb
```

### Overlay Rendering Flow

```
WeatherProvider has new data
      ↓
MapScreen receives notification
      ↓
CustomPaint widget rebuilds
      ↓
WindOverlayPainter.paint() called
      ↓
For each wind data point:
  1. Get lat/lng (WGS84)
  2. ProjectionService.latLngToMeters() → Web Mercator
  3. ProjectionService.metersToPixels() → Screen coords
  4. Check if visible in viewport
  5. Draw wind arrow at calculated position
      ↓
Canvas rendered to screen
      ↓
60 FPS smooth animation
```

---

## Key Files Reference

### main.dart
**Purpose:** App entry point, provider initialization  
**Lines:** ~150  
**Key Responsibilities:**
- Create all providers in correct order
- Setup dependency injection
- Initialize services (cache, database, location)
- Configure app theme
- Run the app

**Critical Code:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await CacheService.instance.initialize();
  await DatabaseService.instance.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        // Layer 0
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        
        // Layer 1
        ChangeNotifierProxyProvider<SettingsProvider, CacheProvider>(
          create: (_) => CacheProvider(),
          update: (_, settings, cache) => cache!..updateSettings(settings),
        ),
        
        // Layer 2 & 3...
      ],
      child: MyApp(),
    ),
  );
}
```

---

### providers/weather_provider.dart
**Purpose:** Manages weather data fetching and caching  
**Lines:** ~250  
**Dependencies:** CacheService, WeatherApi, SettingsProvider  
**Used By:** MapScreen, ForecastScreen, TimelineScreen  

**Key Methods:**
- `fetchWeather(Bounds bounds)` - Get weather for map area
- `getForecast(LatLng location, int days)` - Get forecast
- `refreshWeather()` - Force refresh from network
- `_updateCache()` - Update cache with new data

**State:**
- `WeatherData? currentWeather` - Current conditions
- `List<ForecastData> forecast` - 7-day forecast
- `bool isLoading` - Network request in progress
- `DateTime? lastUpdated` - Last fetch timestamp

---

### services/projection_service.dart
**Purpose:** Coordinate system transformations  
**Lines:** ~180  
**Dependencies:** None (pure math)  
**Used By:** All overlay painters, MapProvider  

**Critical Methods:**
- `latLngToMeters(lat, lng)` - WGS84 → Web Mercator
- `metersToLatLng(x, y)` - Web Mercator → WGS84
- `latLngToPixels(lat, lng, viewport)` - WGS84 → Screen
- `pixelsToLatLng(offset, viewport)` - Screen → WGS84

**Constants:**
- `EARTH_RADIUS = 6378137.0` meters
- `MAX_LATITUDE = 85.05112878` degrees

---

### widgets/map_webview.dart
**Purpose:** WebView container for MapTiler GL JS  
**Lines:** ~200  
**Dependencies:** InAppWebView, MapProvider  
**Used By:** MapScreen  

**Key Features:**
- JavaScript bridge for bi-directional communication
- Debounced viewport sync (200ms)
- Map control methods (setCenter, setZoom, flyTo)
- Layer visibility toggles

**JavaScript Handlers:**
- `onMapMove` - Called when map viewport changes
- `onMapClick` - Called when user taps map
- `onMapLoad` - Called when map finishes loading

---

### widgets/overlays/wind_overlay.dart
**Purpose:** Renders wind arrows on map  
**Lines:** ~180  
**Dependencies:** ProjectionService, WeatherProvider, Viewport  
**Used By:** MapScreen  

**Rendering Pipeline:**
1. Receive WeatherData with wind points
2. For each point: WGS84 → Screen coordinates
3. Cull points outside viewport
4. Draw wind arrow (Beaufort scale determines size/color)
5. shouldRepaint only on data or viewport change

---

## Service Layer Architecture

### Core Services

**CacheService**
- **Type:** Singleton
- **Storage:** Disk (application documents directory)
- **Strategy:** LRU eviction, TTL-based expiry
- **Size Limit:** 100MB default
- **Index:** In-memory Map for fast lookups

**WeatherApi**
- **Provider:** Open-Meteo
- **Endpoints:** `/v1/marine`, `/v1/forecast`
- **Rate Limit:** None (free tier)
- **Retry:** 3 attempts with exponential backoff
- **Timeout:** 10 seconds

**NMEAParser**
- **Format:** NMEA 0183
- **Sentences:** GGA, RMC, AIVDM, VTG, DPT, MWV
- **Validation:** Checksum required
- **Performance:** Runs in isolate

**DatabaseService**
- **Engine:** SQLite (sqflite package)
- **Tables:** trips, waypoints, tracks, settings_backup
- **Migrations:** Version-based schema updates
- **Indexes:** lat/lng for spatial queries

---

## Widget Hierarchy

### MapScreen Widget Tree

```
MapScreen (StatefulWidget)
├── Scaffold
│   ├── AppBar
│   │   ├── Title
│   │   ├── ConnectionStatus
│   │   └── SettingsButton
│   │
│   └── Body
│       └── Stack (layers from bottom to top)
│           ├── MapWebView (base map layer)
│           │
│           ├── Consumer<WeatherProvider>
│           │   ├── WindOverlay (CustomPaint)
│           │   ├── WaveOverlay (CustomPaint)
│           │   └── CurrentOverlay (CustomPaint)
│           │
│           ├── Consumer<BoatProvider>
│           │   ├── BoatMarker (Positioned)
│           │   └── TrackOverlay (CustomPaint)
│           │
│           ├── Consumer<NMEAProvider>
│           │   └── AISOverlay (CustomPaint)
│           │
│           └── UI Controls (top layer)
│               ├── Positioned(top-right)
│               │   └── LayerTogglePanel
│               │
│               ├── Positioned(bottom-right)
│               │   └── ZoomControls
│               │
│               ├── Positioned(bottom-left)
│               │   └── CompassWidget
│               │
│               └── Positioned(bottom-center)
│                   └── BoatInfoCard
```

---

## Module Ownership

| Module | Primary Owner | Lines | Tests | Coverage |
|--------|---------------|-------|-------|----------|
| `services/nmea_parser.dart` | NMEAProvider | 280 | 47 | 94% |
| `services/projection_service.dart` | MapProvider | 180 | 38 | 100% |
| `services/cache_service.dart` | CacheProvider | 250 | 31 | 87% |
| `services/weather_api.dart` | WeatherProvider | 220 | 28 | 82% |
| `providers/weather_provider.dart` | WeatherProvider | 250 | 22 | 78% |
| `providers/boat_provider.dart` | BoatProvider | 190 | 18 | 81% |
| `widgets/map_webview.dart` | MapProvider | 200 | 12 | 65% |
| `widgets/overlays/wind_overlay.dart` | WeatherProvider | 180 | 15 | 73% |

---

## Communication Patterns

### Provider → Provider
**FORBIDDEN:** Direct method calls between providers  
**ALLOWED:** ProxyProvider with update() method

### Provider → Service
**PATTERN:** Provider owns service instance, calls methods, handles async

### Widget → Provider
**READ:** `context.read<Provider>()` for one-time access  
**WATCH:** `context.watch<Provider>()` for reactive updates  
**CONSUMER:** `Consumer<Provider>` widget for scoped rebuilds

### Service → Service
**PATTERN:** Dependency injection in constructor, no singletons except Cache/Database

---

## File Size Compliance

| Category | Max Lines | Current Max | Compliant |
|----------|-----------|-------------|-----------|
| Providers | 300 | 250 | ✅ |
| Services | 300 | 280 | ✅ |
| Screens | 300 | 285 | ✅ |
| Widgets | 200 | 190 | ✅ |
| Models | 150 | 120 | ✅ |

---

**Document End**
