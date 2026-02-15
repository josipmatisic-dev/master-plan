# Codebase Map
<!-- markdownlint-disable MD022 MD031 MD032 MD036 MD040 MD046 MD051 MD060 -->

## Marine Navigation App - Flutter Project Structure

**Version:** 4.0
**Last Updated:** 2026-02-15
**Purpose:** Complete map of codebase structure, dependencies, and data flow (includes SailStream UI)

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

The Flutter scaffold includes Android and iOS native folders under `marine_nav_app/android` and `marine_nav_app/ios` for parallel platform work.

```text
lib/
├── config/
│   ├── env.dart                  # Environment configuration
│   └── env.example.dart          # Example env template
├── main.dart                     # App entry, provider setup (~222 lines)
├── models/
│   ├── boat_position.dart        # Unified GPS model: courseTrue, heading, accuracy, fixQuality, satellites, altitudeMeters, isValid, isAccurate, copyWith, TrackPoint, ISS-018 constants
│   ├── lat_lng.dart              # WGS84 coordinate pair (app's LatLng, used by ProjectionService)
│   ├── nmea_data.dart            # NMEA sentence data (GPGGA, GPRMC, GPVTG, MWV, DPT, HDG, MTW)
│   ├── nmea_error.dart           # NMEA error types & connection config
│   ├── nmea_instrument_data.dart # Individual NMEA instrument data classes (MWV, DPT, HDG, MTW)
│   ├── route.dart                # Route & Waypoint models with navigation metrics
│   ├── viewport.dart             # Map viewport state (center, zoom, rotation, size, bounds)
│   └── weather_data.dart         # Weather data + WeatherFrame for timeline
│
├── providers/
│   ├── boat_provider.dart        # Boat position tracking (NMEA + phone GPS fallback, ISS-018 filter, track history)
│   ├── cache_provider.dart       # Cache coordination & statistics
│   ├── map_provider.dart         # Map viewport & interaction state
│   ├── nmea_provider.dart        # NMEA data stream processing & connection lifecycle
│   ├── route_provider.dart       # Route management & navigation metrics (distance, bearing, ETA, XTE)
│   ├── settings_provider.dart    # User preferences & configuration
│   ├── theme_provider.dart       # Theme mode + theme variant (Ocean Glass / Holographic)
│   ├── timeline_provider.dart    # Forecast playback state (play/pause/speed/frame selection)
│   └── weather_provider.dart     # Weather data fetching, caching, overlay layer toggles
│
├── services/
│   ├── cache_service.dart        # Disk-backed KV cache (SharedPreferences, TTL, LRU eviction)
│   ├── geo_utils.dart            # Geographic calculations (haversine distance, bearing, XTE)
│   ├── location_service.dart     # Phone GPS wrapper (geolocator package)
│   ├── nmea_isolate_messages.dart # Messages for NMEA parser isolate communication
│   ├── nmea_parser.dart          # NMEA 0183 sentence parser (checksum, coordinate conversion)
│   ├── nmea_parser_instruments.dart # Instrument-specific NMEA parsers (MWV, DPT, HDG, MTW)
│   ├── nmea_service.dart         # NMEA TCP/UDP connection service with auto-reconnect
│   ├── projection_service.dart   # Coordinate transforms (WGS84 ↔ Web Mercator ↔ Screen)
│   ├── route_map_bridge.dart     # Route visualization on WebView map
│   ├── weather_api.dart          # Open-Meteo Marine API client with retry/backoff
│   ├── weather_api_parser.dart   # Weather API response parser
│   └── wind_texture_generator.dart # WebGL texture generation for wind particle rendering
│
├── screens/
│   ├── dashboard_screen.dart     # Dashboard overview
│   ├── home_screen.dart          # Main app entry screen
│   ├── map_screen.dart           # Primary map view with draggable overlays
│   ├── navigation_mode_screen.dart # Navigation mode (SOG/COG/DEPTH orbs + route)
│   ├── profile_screen.dart       # User profile
│   ├── settings_screen.dart      # App configuration
│   ├── vessel_screen.dart        # Vessel information
│   └── weather_screen.dart       # Fullscreen weather with draggable bottom sheet
│
├── widgets/
│   ├── common/
│   │   ├── animated_press_button.dart # Animated button with press feedback
│   │   ├── draggable_overlay.dart     # Drag + resize wrapper with persistence
│   │   ├── glow_text.dart             # Multi-layer shadow text for bloom effect
│   │   └── setting_row.dart           # Reusable settings row widget
│   ├── controls/
│   │   └── layer_toggle.dart          # Overlay enable/disable control
│   ├── data_displays/
│   │   ├── data_orb.dart              # Circular data display (3 sizes, 4 states, hero animation)
│   │   ├── neon_data_orb.dart         # Rotating neon orb for holographic theme
│   │   └── wind_widget.dart           # Draggable true wind indicator (140×140)
│   ├── effects/
│   │   ├── holographic_shimmer.dart   # Cyberpunk shimmer effect
│   │   ├── particle_background.dart   # CustomPainter particle system, 60 FPS
│   │   ├── scan_line_effect.dart      # Retro scan line overlay
│   │   └── scroll_reveal.dart         # Entrance animation on scroll
│   ├── glass/
│   │   ├── glass_card.dart            # Base frosted glass container (4 padding variants)
│   │   └── holographic_card.dart      # Glassmorphism card with neon glow border
│   ├── home/
│   │   ├── cache_info_card.dart       # Cache statistics display
│   │   ├── navigation_shortcuts.dart  # Quick navigation buttons
│   │   ├── settings_card.dart         # Settings summary card
│   │   ├── theme_controls.dart        # Theme mode/variant toggle
│   │   └── welcome_card.dart          # Welcome/greeting card
│   ├── map/
│   │   └── map_webview.dart           # MapTiler WebView with JS bridge
│   ├── navigation/
│   │   ├── compass_widget.dart        # Compass rose with heading
│   │   ├── course_deviation_indicator.dart # XTE visualization
│   │   ├── navigation_sidebar.dart    # Vertical glass nav rail
│   │   └── nmea_connection_widget.dart # NMEA status indicator
│   ├── overlays/
│   │   ├── boat_marker.dart           # Vessel position marker (directional arrow + accuracy ring)
│   │   ├── track_overlay.dart         # Breadcrumb trail (gradient line)
│   │   ├── wave_overlay.dart          # Wave height visualization
│   │   └── wind_overlay.dart          # Wind arrow rendering
│   ├── settings/
│   │   ├── maptiler_key_card.dart     # MapTiler API key configuration
│   │   ├── nmea_settings_card.dart    # NMEA connection settings
│   │   └── nmea_settings_helpers.dart # Settings form helpers
│   └── weather/
│       ├── forecast_timeline.dart     # Forecast timeline display
│       ├── timeline_scrubber.dart     # Time scrubber control
│       ├── weather_detail_cards.dart  # Weather detail info cards
│       └── weather_map_view.dart      # Weather map integration
│
├── utils/
│   ├── navigation_utils.dart     # Navigation helper functions
│   ├── overlay_layout_store.dart # Persist overlay positions to SharedPreferences
│   └── responsive_utils.dart     # Breakpoints, responsive spacing, device detection
│
└── theme/
    ├── app_theme.dart            # 4 ThemeData variants via getThemeForVariant()
    ├── colors.dart               # Ocean Glass color palette (deepNavy, seafoamGreen, etc.)
    ├── dimensions.dart           # Spacing, radii, glass blur/opacity constants
    ├── holographic_colors.dart   # Neon palette (Electric Blue, Magenta, Cyber Purple)
    ├── holographic_effects.dart  # NeonGlow, TextGlow, GlowShadows utilities
    ├── holographic_gradients.dart # Cyberpunk gradient definitions
    ├── holographic_shimmer_utils.dart # Shimmer animation utilities
    ├── holographic_theme_data.dart # Holographic ThemeData configuration
    ├── text_styles.dart          # Typography system (dataValue, heading, body, label)
    └── theme_variant.dart        # ThemeVariant enum (oceanGlass, holographicCyberpunk)

assets/
└── map.html                      # MapTiler GL JS + WebGL wind/wave rendering

test/
├── _fixtures/
│   └── weather_fixtures.dart     # Mock weather API responses
├── integration/
│   └── nmea_ui_integration_test.dart # NMEA → UI update integration test
├── models/
│   ├── boat_position_test.dart   # BoatPosition model tests (19 tests)
│   ├── lat_lng_test.dart         # LatLng model tests
│   ├── nmea_data_test.dart       # NMEAData model tests
│   ├── nmea_error_test.dart      # NMEAError/ConnectionConfig tests
│   ├── nmea_instrument_data_test.dart # Instrument data model tests
│   ├── route_test.dart           # Route/Waypoint model tests
│   ├── viewport_test.dart        # Viewport model tests
│   └── weather_data_test.dart    # WeatherData model tests
├── providers/
│   ├── boat_provider_test.dart   # BoatProvider tests (NMEA, GPS, ISS-018, track)
│   ├── map_provider_test.dart    # MapProvider tests
│   ├── nmea_provider_test.dart   # NMEAProvider tests
│   ├── route_provider_test.dart  # RouteProvider tests
│   ├── settings_provider_test.dart # SettingsProvider tests
│   ├── theme_provider_test.dart  # ThemeProvider tests
│   ├── timeline_provider_test.dart # TimelineProvider tests
│   └── weather_provider_test.dart # WeatherProvider tests
├── services/
│   ├── cache_service_test.dart   # Cache service tests (TTL, LRU, persistence)
│   ├── geo_utils_test.dart       # Geographic calculation tests
│   ├── location_service_test.dart # Location service status tests
│   ├── nmea_parser_instruments_test.dart # Instrument parser tests (HDG, MWV, DPT, MTW)
│   ├── nmea_parser_test.dart     # NMEA parser tests
│   ├── nmea_service_test.dart    # NMEA service tests
│   ├── projection_service_test.dart # Projection tests
│   ├── route_map_bridge_test.dart # Route bridge tests
│   ├── weather_api_parser_test.dart # Weather parser tests (grid/array responses)
│   ├── weather_api_test.dart     # Weather API tests
│   └── wind_texture_generator_test.dart # Wind texture generation tests
├── utils/
│   └── overlay_layout_store_test.dart # Overlay persistence tests
└── widget_test.dart              # HomeScreen widget tests
```

---

## Provider Dependency Graph

```
Layer 0 (No Dependencies):
┌─────────────────────┐      ┌─────────────────────┐
│ SettingsProvider    │      │ RouteProvider       │
│ ← prefs, units     │      │ ← route CRUD, nav   │
└─────────────────────┘      └─────────────────────┘

Layer 1 (Depends on Layer 0):
┌─────────────────────┐      ┌─────────────────────┐
│ CacheProvider       │      │ ThemeProvider       │
│ - Depends: (none)   │      │ - Depends: (none)   │
└─────────────────────┘      └─────────────────────┘

Layer 2 (Depends on Layers 0-1):
┌─────────────────────────────┐   ┌─────────────────────────────┐
│ MapProvider                 │   │ NMEAProvider                │
│ - Depends: Settings, Cache  │   │ - Depends: Settings, Cache  │
└─────────────────────────────┘   └─────────────────────────────┘
                                  ┌─────────────────────────────┐
                                  │ WeatherProvider             │
                                  │ - Depends: Settings, Cache  │
                                  └─────────────────────────────┘

Layer 2+ (Depends on Layer 2 peers):
┌───────────────────────────────────────────────────────────────┐
│ BoatProvider                                                  │
│ - Depends: NMEAProvider, MapProvider                          │
│ - Optional: LocationService (phone GPS), RouteProvider        │
└───────────────────────────────────────────────────────────────┘
┌───────────────────────────────────────────────────────────────┐
│ TimelineProvider                                              │
│ - Depends: WeatherProvider                                    │
└───────────────────────────────────────────────────────────────┘

All 9 providers:
  SettingsProvider, ThemeProvider, CacheProvider,
  MapProvider, NMEAProvider, RouteProvider, WeatherProvider,
  BoatProvider, TimelineProvider

RULES:
- No circular dependencies
- All created in main.dart with constructor injection
- Dependencies injected explicitly (no ProxyProvider)
- ChangeNotifierProvider.value() used in MultiProvider
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

1. Check CacheProvider (cache-first)
      ↓
2. If cached & valid → Return immediately
      ↓
3. Background: WeatherApi.fetchWeather()
      ↓
4. Parse response → WeatherData model
      ↓
5. CacheProvider.set() with TTL
      ↓
6. WeatherProvider.notifyListeners()
      ↓
Widget Rebuild:

- MapScreen updates overlays
- WeatherScreen shows new data

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
**Lines:** ~222  
**Key Responsibilities:**
- Create all 9 providers with constructor injection (bottom-up)
- Initialize providers via `Future.wait` (settings, theme, cache, map)
- Configure named routes for all screens
- Run the app with `MultiProvider` + `ChangeNotifierProvider.value()`

**Critical Code:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize providers (constructor injection, bottom-up)
  final settingsProvider = SettingsProvider();
  final themeProvider = ThemeProvider();
  final cacheProvider = CacheProvider();
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

  await Future.wait([
    settingsProvider.init(),
    themeProvider.init(),
    cacheProvider.init(),
    mapProvider.init(),
  ]);

  runApp(
    MarineNavigationApp(
      settingsProvider: settingsProvider,
      // ... all 9 providers passed to MultiProvider
    ),
  );
}
```

---

### providers/weather_provider.dart

**Purpose:** Manages weather data fetching, caching, and overlay layer toggles  
**Lines:** ~309  
**Dependencies:** SettingsProvider, CacheProvider, WeatherApi  
**Used By:** MapScreen, WeatherScreen, TimelineProvider  

**Key Methods:**

- `fetchForViewport({south, north, west, east})` - Get weather for map bounds
- `refresh({south, north, west, east})` - Force refresh from network
- `toggleLayer(WeatherLayer layer)` - Toggle overlay visibility
- `setLayerActive(WeatherLayer layer, {active})` - Set layer on/off

**State:**

- `WeatherData data` - Current weather conditions (empty by default)
- `bool isLoading` - Network request in progress
- `bool hasData` - Whether data is available
- `bool isStale` - Whether data needs refresh
- `Set<WeatherLayer> activeLayers` - Active overlay layers (wind, wave enabled by default)

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
- **Contract:** ProjectionService pairs with MapViewportService as `ViewportProjector`; all overlays/widgets must consume projection via this contract—no manual pixel math.

---

### widgets/map_webview.dart

**Purpose:** WebView container for MapTiler GL JS  
**Lines:** ~200  
**Dependencies:** webview_flutter, MapProvider  
**Used By:** MapScreen  

**Key Features:**

- JavaScript bridge for bi-directional communication (viewport + tap events)
- Debounced viewport sync (200ms)
- Map control methods (setCenter, setZoom, flyTo)
- Layer visibility toggles
- Graceful fallback (glass card placeholder) when WebView platform is unavailable (used in tests)

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

**ProjectionService**

- **Type:** Static utility (pure math, no state)
- **Methods:** `latLngToScreen()`, `screenToLatLng()`, `webMercatorToWgs84()`
- **Constants:** `EARTH_RADIUS = 6378137.0`, `MAX_LATITUDE = 85.05112878`
- **Contract:** All overlays/widgets must use this—no manual pixel math

**GeoUtils**

- **Type:** Static utility (pure math)
- **Methods:** `distance()` (haversine), `bearing()`, `crossTrackDistance()` (XTE)
- **Used By:** RouteProvider, BoatProvider, NavigationModeScreen

**WeatherApi**

- **Provider:** Open-Meteo Marine
- **Endpoints:** `/v1/marine`
- **Rate Limit:** None (free tier)
- **Retry:** 3 attempts with exponential backoff
- **Timeout:** 15 seconds

**WeatherApiParser**

- **Type:** Static utility
- **Purpose:** Parse Open-Meteo JSON responses into `WeatherData` models
- **Used By:** WeatherApi

**NMEAParser**

- **Format:** NMEA 0183
- **Sentences:** GGA, RMC, VTG, MWV, DPT, HDG, MTW
- **Validation:** Checksum required
- **Performance:** Runs in background isolate

**NMEAParserInstruments**

- **Purpose:** Instrument-specific NMEA sentence parsers (MWV, DPT, HDG, MTW)
- **Used By:** NMEAParser

**NMEAService**

- **Type:** TCP/UDP connection manager
- **Features:** Auto-reconnect, configurable host/port
- **Used By:** NMEAProvider

**NmeaIsolateMessages**

- **Purpose:** Message types for NMEA parser isolate communication
- **Used By:** NMEAProvider, NMEAParser

**LocationService**

- **Type:** Phone GPS wrapper (geolocator package)
- **Purpose:** Fallback GPS when NMEA device unavailable
- **Used By:** BoatProvider (optional)

**RouteMapBridge**

- **Type:** WebView JS bridge helper
- **Purpose:** Render route lines/waypoints on MapTiler WebView via JavaScript
- **Used By:** MapScreen, NavigationModeScreen

**WindTextureGenerator**

- **Type:** WebGL texture generator
- **Purpose:** Generate wind particle textures for GPU-accelerated rendering
- **Used By:** MapWebView (via map.html)

---

## Widget Hierarchy

### MapScreen Widget Tree (SailStream UI)

```
MapScreen (StatefulWidget)
├── Scaffold
│   └── Body
│       └── Stack (Z-index layers from bottom to top)
│           ├── [Layer 0] MapWebView (MapTiler base layer)
│           │   └── JS Bridge: viewport sync, tap events, route rendering
│           │   └── Boat/track rendering via WebView JS bridge (not Flutter CustomPainter)
│           │
│           ├── [Layer 1] DraggableOverlay-wrapped widgets
│           │   ├── DraggableOverlay → WindOverlay (wind arrows, CustomPaint)
│           │   ├── DraggableOverlay → WaveOverlay (wave visualization, CustomPaint)
│           │   ├── DraggableOverlay → BoatMarker (vessel icon, directional arrow + accuracy ring)
│           │   └── DraggableOverlay → TrackOverlay (breadcrumb trail, gradient line)
│           │
│           ├── [Layer 2] Navigation Data Displays
│           │   ├── DraggableOverlay → DataOrb(SOG)
│           │   ├── DraggableOverlay → DataOrb(COG)
│           │   ├── DraggableOverlay → DataOrb(DEPTH)
│           │   └── DraggableOverlay → WindWidget (true wind indicator, 140×140)
│           │
│           ├── [Layer 3] Navigation UI
│           │   ├── Positioned(left) → NavigationSidebar (glass, vertical icons)
│           │   └── Positioned(top) → GlassCard - Top App Bar
│           │
│           └── [Layer 4] Timeline (when in forecast mode)
│               └── Positioned(bottom) → GlassCard - TimelineScrubber
│                   ├── Play/pause/speed controls
│                   └── TimeSlider

Note: Boat position and track breadcrumbs are rendered on the WebView map
via RouteMapBridge JS calls, not as Flutter CustomPainter overlays in the
widget stack. The overlay widgets above are for weather data visualization.
```

## Screen Flows

### Primary Navigation

- **Splash → HomeScreen** (initial load)
- **HomeScreen → MapScreen** (primary nav via `/map`)
- **HomeScreen → DashboardScreen** (overview via `/dashboard`)
- **HomeScreen → WeatherScreen** (weather deep dive via `/weather`)
- **HomeScreen → SettingsScreen** (preferences via `/settings`)
- **HomeScreen → VesselScreen** (vessel info via `/vessel`)
- **HomeScreen → ProfileScreen** (user profile via `/profile`)
- **MapScreen → NavigationModeScreen** (enter navigation mode via `/navigation`)
- **NavigationModeScreen → MapScreen** (back)

### MapScreen Internal Flow

- Map load start → show glass loading overlay → Map ready → load overlays → enable interactions
- Enter forecast mode → show TimelineScrubber + overlays → exit forecast mode → hide scrubber
- Drag wind widgets → persist position via SettingsProvider → restore on reopen
- NavigationSidebar item tap → route to destination screen (Map, Weather, Settings, Dashboard, Vessel, Profile)

### NavigationMode Screen Widget Tree

```
NavigationModeScreen (StatefulWidget)
├── Scaffold
│   ├── AppBar (GlassCard)
│   │   ├── BackButton
│   │   ├── Title("navigation mode")
│   │   └── SettingsButton
│   │
│   └── Body
│       └── Stack
│           ├── [Layer 0] MapWebView (route visualization)
│           │
│           ├── [Layer 1] RouteOverlay
│           │   ├── RouteLine (dashed, current → waypoint)
│           │   ├── WaypointMarkers
│           │   └── PlaceLabels
│           │
│           ├── [Layer 2] Positioned(top: 16)
│           │   └── Row - Data Orbs
│           │       ├── DataOrb(SOG, size: large)
│           │       ├── SizedBox(width: 16)
│           │       ├── DataOrb(COG, size: large)
│           │       ├── SizedBox(width: 16)
│           │       └── DataOrb(DEPTH, size: large)
│           │
│           ├── [Layer 3] Positioned(bottom: 80)
│           │   └── GlassCard - RouteInfoCard
│           │       ├── Text("Next: Waypoint 1")
│           │       ├── Text("2.4 nm")
│           │       └── Text("ETA 19 min")
│           │
│           └── [Layer 4] Positioned(bottom: 16)
│               └── ActionButtonBar (GlassCard)
│                   ├── GlassButton("+ Route")
│                   ├── GlassButton("Mark Position")
│                   ├── GlassButton("Track")
│                   └── GlassButton("Alerts")
```

---

## Module Ownership

| Module | Primary Owner | Lines | Tests | Coverage |
|--------|---------------|-------|-------|----------|
| `services/cache_service.dart` | CacheProvider | 203 | 16 | ✅ 80%+ |
| `services/nmea_parser.dart` | NMEAProvider | 258 | 47 | 94% |
| `services/nmea_parser_instruments.dart` | NMEAProvider | 109 | — | — |
| `services/nmea_service.dart` | NMEAProvider | 282 | 14 | ✅ 80%+ |
| `services/nmea_isolate_messages.dart` | NMEAProvider | 75 | — | — |
| `services/projection_service.dart` | MapProvider | 94 | 38 | 100% |
| `services/weather_api.dart` | WeatherProvider | 202 | 28 | 82% |
| `services/weather_api_parser.dart` | WeatherProvider | 214 | — | — |
| `services/geo_utils.dart` | RouteProvider | 133 | ✅ | ✅ 80%+ |
| `services/location_service.dart` | BoatProvider | 115 | — | — |
| `services/route_map_bridge.dart` | MapProvider | 64 | ✅ | ✅ 80%+ |
| `services/wind_texture_generator.dart` | WeatherProvider | 285 | — | — |
| `providers/weather_provider.dart` | WeatherProvider | 309 | 22 | 78% |
| `providers/boat_provider.dart` | BoatProvider | 279 | 25 | ✅ 80%+ |
| `providers/nmea_provider.dart` | NMEAProvider | 231 | 14 | ✅ 80%+ |
| `providers/route_provider.dart` | RouteProvider | 299 | 30 | ✅ 80%+ |
| `providers/map_provider.dart` | MapProvider | 287 | ✅ | ✅ 80%+ |
| `providers/settings_provider.dart` | SettingsProvider | 299 | ✅ | ✅ 80%+ |
| `providers/theme_provider.dart` | ThemeProvider | 174 | ✅ | ✅ 80%+ |
| `providers/timeline_provider.dart` | TimelineProvider | 208 | ✅ | ✅ 80%+ |
| `providers/cache_provider.dart` | CacheProvider | 150 | — | — |
| `models/boat_position.dart` | BoatProvider | 152 | 19 | ✅ 80%+ |
| `models/nmea_data.dart` | NMEAProvider | 250 | — | — |
| `models/route.dart` | RouteProvider | 146 | ✅ | ✅ 80%+ |
| `models/weather_data.dart` | WeatherProvider | 224 | ✅ | ✅ 80%+ |
| `widgets/map/map_webview.dart` | MapProvider | 274 | 12 | 65% |
| `widgets/overlays/wind_overlay.dart` | WeatherProvider | 266 | 15 | 73% |
| `widgets/overlays/boat_marker.dart` | BoatProvider | 221 | — | ✅ |
| `widgets/overlays/track_overlay.dart` | BoatProvider | 169 | — | ✅ |
| `widgets/overlays/wave_overlay.dart` | WeatherProvider | 209 | — | — |
| `widgets/glass/glass_card.dart` | UI Library | 151 | TBD | — |
| `widgets/glass/holographic_card.dart` | UI Library | 149 | TBD | — |
| `widgets/data_displays/data_orb.dart` | UI Library | 215 | TBD | — |
| `widgets/data_displays/neon_data_orb.dart` | UI Library | 295 | TBD | — |
| `widgets/data_displays/wind_widget.dart` | WeatherProvider | 143 | TBD | — |
| `widgets/navigation/compass_widget.dart` | BoatProvider | 165 | TBD | — |
| `widgets/navigation/navigation_sidebar.dart` | Navigation | 162 | TBD | — |
| `widgets/navigation/nmea_connection_widget.dart` | NMEAProvider | 174 | TBD | — |
| `widgets/navigation/course_deviation_indicator.dart` | RouteProvider | 65 | TBD | — |
| `widgets/common/draggable_overlay.dart` | UI Library | 180 | TBD | — |
| `widgets/common/glow_text.dart` | UI Library | 256 | TBD | — |

---

## Communication Patterns

### Provider → Provider

**FORBIDDEN:** Direct method calls between sibling providers  
**ALLOWED:** Constructor injection of dependencies (no ProxyProvider)

### Provider → Service

**PATTERN:** Provider owns service instance, calls methods, handles async

### Widget → Provider

**READ:** `context.read<Provider>()` for one-time access  
**WATCH:** `context.watch<Provider>()` for reactive updates  
**CONSUMER:** `Consumer<Provider>` widget for scoped rebuilds

### Service → Service

**PATTERN:** Dependency injection in constructor, no singletons

---

## File Size Compliance

| Category | Max Lines | Current Max | Compliant |
|----------|-----------|-------------|-----------|
| Providers | 300 | 309 (WeatherProvider) | ⚠️ Slightly over |
| Services | 300 | 285 (WindTextureGenerator) | ✅ |
| Screens | 300 | 297 (MapScreen) | ✅ |
| Widgets | 300 | 299 (ParticleBackground) | ✅ |
| Models | 300 | 250 (NMEAData) | ✅ |

---

**Document End**
