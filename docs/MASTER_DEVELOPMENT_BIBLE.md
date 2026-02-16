# Master Development Bible

## Marine Navigation App - Complete Development Reference

**Version:** 7.0  
**Last Updated:** 2026-02-15  
**Status:** BoatProvider, Weather Pipeline, Navigation Mode Added

---

## Table of Contents

1. [Section A: Complete Failure Analysis](#section-a-complete-failure-analysis)
2. [Section B: Working Code Inventory](#section-b-working-code-inventory)
3. [Section C: Architecture Rules](#section-c-architecture-rules)
4. [Section D: Feature Specifications](#section-d-feature-specifications)
5. [Section E: Technical Decisions](#section-e-technical-decisions)
6. [Section F: Development Phases](#section-f-development-phases)
7. [Section G: SailStream UI Architecture](#section-g-sailstream-ui-architecture)

---

## Section A: Complete Failure Analysis

This section documents all critical failures from Attempts 1-4, their root causes, and lessons learned.

### A.1 Map Overlay Projection Mismatch (Attempt 2, Attempt 4)

**Problem:** Wind vector overlays rendered at incorrect positions when zooming/panning the map.

**Root Cause:** Multiple coordinate projection systems used inconsistently:

- MapTiler SDK uses Web Mercator (EPSG:3857)
- Wind data from Open-Meteo in WGS84 (EPSG:4326)
- Flutter overlay widgets assumed linear screen coordinates

**Failed Code Example:**

```dart
// WRONG: Direct lat/lng to pixel conversion
Widget buildWindArrow(double lat, double lng) {
  return Positioned(
    left: (lng + 180) * screenWidth / 360,  // BROKEN
    top: (90 - lat) * screenHeight / 180,   // BROKEN
    child: WindArrowWidget(),
  );
}
```text

**What Went Wrong:**

1. No projection transform between coordinate systems
2. Screen position calculations didn't account for map zoom/pan state
3. WebView map and Flutter overlay had separate viewport states
4. Rotation and tilt transformations completely ignored

**Lesson Learned:** ALL coordinate conversions MUST go through a single ProjectionService that maintains viewport synchronization between WebView and Flutter overlay.

---

### A.2 God Objects and Circular Dependencies (Attempt 1, Attempt 3)

**Problem:** `MapController` grew to 2,847 lines and had circular provider dependencies.

**Root Cause:** Single class trying to manage:

- Map viewport state
- Weather data fetching
- NMEA parsing
- Boat position tracking
- Timeline playback
- User settings
- Cache management
- WebView communication

**Failed Architecture:**

```dart
class MapController extends ChangeNotifier {
  late WeatherService _weatherService;
  late NMEAService _nmeaService;
  late CacheService _cacheService;
  late SettingsService _settingsService;
  
  // _weatherService needs MapController for bounds
  // MapController needs WeatherService for overlays
  // CIRCULAR DEPENDENCY HELL
}
```text

**What Went Wrong:**

1. Single Responsibility Principle violated
2. Providers depending on other providers in constructor
3. No clear data flow boundaries
4. Impossible to test in isolation
5. Changes cascaded across entire codebase

**Lesson Learned:** Maximum 400 lines per controller. Use composition over inheritance. Dependencies flow in ONE direction only.

---

### A.3 Provider Wiring Disasters (Attempt 2)

**Problem:** App crashed with "ProviderNotFoundException" on hot reload.

**Root Cause:** Incorrect provider hierarchy and missing providers in widget tree.

**Failed Code:**

```dart
// WRONG: Provider created inside widget build
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(  // RECREATED ON EVERY BUILD
      create: (_) => MapViewModel(),
      child: Consumer<MapViewModel>(
        builder: (context, model, _) {
          // Accessing WeatherProvider that doesn't exist here
          final weather = context.read<WeatherProvider>();
          return Container();
        },
      ),
    );
  }
}
```text

**What Went Wrong:**

1. Providers created inside widget build methods
2. Provider hierarchy not matching consumption hierarchy
3. ProxyProvider chains too deep (7 levels)
4. Hot reload destroying provider state

**Lesson Learned:** ALL providers created at app root in main.dart. Use Provider.of with listen: false for one-time reads. Document provider dependency graph.

---

### A.4 Cache Invalidation Race Conditions (Attempt 3)

**Problem:** Stale weather data displayed after fetching new data.

**Root Cause:** Multiple cache layers with no coordination:

- In-memory Map cache
- Disk cache via path_provider
- HTTP cache headers
- WebView cache

**Failed Code:**

```dart
Future<WeatherData> getWeather(Bounds bounds) async {
  // Check memory cache
  if (_memoryCache.containsKey(bounds)) {
    return _memoryCache[bounds]!;  // STALE DATA
  }
  
  // Fetch new data
  final data = await _api.fetchWeather(bounds);
  
  // Update cache (no invalidation of related caches)
  _memoryCache[bounds] = data;
  
  // Disk cache still has old data
  // WebView still showing old overlay
  return data;
}
```text

**What Went Wrong:**

1. No cache versioning or timestamps
2. Bounds-based keys didn't account for zoom level differences
3. No cache invalidation cascade
4. Time-based expiry not implemented
5. Cache size limits never enforced (grew to 500MB+)

**Lesson Learned:** Single CacheService with LRU eviction, TTL, and version tags. All caches invalidate together.

---

### A.5 UI Overflow and RenderBox Errors (All Attempts)

**Problem:** "RenderFlex overflowed by 347 pixels" errors on smaller devices.

**Root Cause:** Fixed-size widgets and hardcoded dimensions.

**Failed Code:**

```dart
// WRONG: Fixed heights and no overflow handling
Column(
  children: [
    Container(height: 200, child: MapView()),
    Container(height: 150, child: WeatherChart()),
    Container(height: 100, child: BoatInfo()),
    Container(height: 120, child: Controls()),
    // Total: 570px, but screen is only 667px with status bar
  ],
)
```text

**What Went Wrong:**

1. No Flexible or Expanded widgets
2. SafeArea not used
3. No responsive breakpoints
4. Text didn't wrap
5. Landscape mode never tested

**Lesson Learned:** Use Flexible/Expanded everywhere. Test on smallest target device (iPhone SE: 667×375). Use LayoutBuilder for responsive design.

---

### A.6 Memory Leaks from Animation Controllers (Attempt 2, Attempt 3)

**Problem:** Memory usage climbing 50MB every minute, app crashes after 20 minutes.

**Root Cause:** AnimationController not disposed, TickerProviders accumulating.

**Failed Code:**

```dart
class WindArrowWidget extends StatefulWidget {
  @override
  _WindArrowWidgetState createState() => _WindArrowWidgetState();
}

class _WindArrowWidgetState extends State<WindArrowWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat();  // NEVER DISPOSED
  }
  
  // Missing dispose() method
}
```text

**What Went Wrong:**

1. AnimationControllers created but never disposed
2. Listeners not removed from providers
3. StreamSubscriptions not cancelled
4. Image cache not cleared
5. Hundreds of zombie ticker objects

**Lesson Learned:** EVERY controller/subscription MUST have dispose(). Use lint rules to enforce. Run memory profiler regularly.

---

### A.7 State Management Chaos (Attempt 1, Attempt 4)

**Problem:** App state inconsistent across screens, duplicate API calls, phantom updates.

**Root Cause:** Mixing setState, Provider, and StreamBuilder with no clear pattern.

**What Went Wrong:**

1. Three sources of truth for position data
2. No synchronization between approaches
3. Widget rebuilding excessively
4. State not persisting across navigation
5. Impossible to debug

**Lesson Learned:** ONE state management approach (Provider). Local setState only for pure UI state. Document data flow.

---

### A.8 WebView JavaScript Bridge Sync Issues (Attempt 3, Attempt 4)

**Problem:** Map movements in WebView not triggering Flutter overlay updates for 2-3 seconds.

**Root Cause:** Async communication between WebView and Flutter with no debouncing.

**What Went Wrong:**

1. 60+ messages per second during pan
2. No debouncing or throttling
3. Message queue backed up
4. JSON serialization overhead
5. Overlay updates lagging behind map

**Lesson Learned:** Debounce map events (200ms). Use requestAnimationFrame. Batch updates.

---

### A.9 NMEA Parsing Buffer Overflows (Attempt 2)

**Problem:** App crash when connecting to AIS receiver with high message rate.

**Root Cause:** Synchronous parsing of NMEA sentences in UI thread.

**What Went Wrong:**

1. Network I/O on main thread
2. String parsing blocking UI
3. notifyListeners called excessively
4. No backpressure handling
5. Memory buffer unlimited size

**Lesson Learned:** Use Isolate for NMEA parsing. Batch updates every 200ms. Implement backpressure.

---

### A.10 Offline Mode Data Consistency (Attempt 4)

**Problem:** App showed "No connection" error even with locally cached data.

**Root Cause:** No offline-first architecture, cache only used as fallback.

**What Went Wrong:**

1. Network-first instead of cache-first
2. No stale-while-revalidate pattern
3. Cache not pre-populated
4. No offline indicator to user
5. Critical features required network

**Lesson Learned:** Cache-first architecture. Background sync. Pre-download common areas.

---

## Section B: Working Code Inventory

See AI_AGENT_INSTRUCTIONS.md for detailed working code patterns (B.1-B.8).

Key working components:

- NMEA Parser with checksum validation
- HTTP client with exponential backoff
- LRU disk cache with TTL
- Web Mercator projection service
- Viewport synchronization model
- Beaufort scale calculator
- Marine theme system
- WebView JavaScript integration
- **BoatProvider** — NMEA listener + phone GPS fallback + ISS-018 position filtering via `_isPositionValid()` and `GeoUtils.distanceBetween()`
- **TimelineProvider** — Scrubber + playback + frame mapping for forecast animation
- **WeatherProvider** — Cache-first fetch + debounced viewport-based data retrieval from Open-Meteo
- **LocationService** — Phone GPS wrapper (geolocator package) with permission handling and stream-based updates
- **RouteMapBridge** — WebView JS bridge for route rendering (GeoJSON injection, waypoint markers, dashed polylines)
- **WindTextureGenerator** — Generates WebGL texture data (Float32Array wind vectors) for map.html shader pipeline

---

## Section C: Architecture Rules

### C.1 Single Source of Truth

Each piece of data has exactly ONE authoritative source. No duplicate state across providers, widgets, or caches.

### C.2 Projection Consistency

ALL coordinate transformations go through ProjectionService. No manual lat/lng to pixel math.

### C.3 Provider Discipline

- Maximum 3 dependency layers
- No circular dependencies
- All providers created in main.dart
- Document dependency graph

### C.4 Network Request Discipline

- All requests use RetryableHttpClient
- All requests have timeout (10s default)
- All requests have cache fallback
- Proper error handling (Timeout, Socket, API errors)

### C.5 File Size Limits

- Soft Limit: 400 lines per file
- Hard Limit: 500 lines per file (refactor immediately if exceeded)
- Maximum 50 lines per method
- Refactor if significantly exceeding 500 lines

### C.6 Overlay Rendering Pipeline

1. Data in WGS84
2. Transform to Web Mercator
3. Convert to screen pixels with Viewport
4. Apply rotation/tilt
5. Render to Canvas
6. Update only on data/viewport change

### C.7 Timeline Playback Control

- Max 100 frames in memory
- Lazy loading
- Pauseable
- Speed controls (0.5x, 1x, 2x, 4x)
- Saved progress

### C.8 Cache Invalidation Strategy

- Version tags
- Time-based expiry (TTL)
- LRU eviction
- Coordinated invalidation

### C.9 No Demo Code in Production

Remove all hardcoded keys, mocks, debug prints, test shortcuts before release.

### C.10 Dispose Everything

Every controller, subscription, listener, timer MUST be disposed.

### C.11 WebGL Texture Pipeline

All weather visualization textures go through `WindTextureGenerator` → `map.html` WebGL shaders. Never render weather data via Flutter `CustomPainter` — the WebGL pipeline handles wind/wave/current rendering on the map tile layer.

### C.12 Position Validation (ISS-018)

Position validation via `BoatProvider._isPositionValid()` using `GeoUtils.distanceBetween()` — see ISS-018 in `KNOWN_ISSUES_DATABASE.md`. Note: `GeoUtils.distanceBetween()` returns **nautical miles**; multiply by `1852.0` to get meters.

---

## Section D: Feature Specifications

### D.1 Core Features (Must Have - Phase 1)

- **Map Display:** Interactive map with zoom/pan/rotate, nautical charts, satellite, depth contours
- **NMEA Integration:** GPS position, speed, course, heading, depth, wind
- **Boat Tracking:** Real-time GPS, track history, speed display, ETA, MOB marker
- **Weather Overlays:** Wind vectors, wave height/direction, currents, SST, precipitation

### D.2 Essential Features (Should Have - Phase 2)

- **Weather Forecasting:** 7-day forecast, hourly breakdown, model comparison, confidence
- **Timeline Playback:** Scrub forecast, play/pause, speed controls, export video
- **Dark Mode:** Auto/manual toggle, red light mode, custom schemes
- **Offline Mode:** Download regions, cache weather, offline routing, sync

### D.3 Advanced Features (Nice to Have - Phase 3)

- **Settings:** Units (metric/imperial/nautical), language, map styles, refresh rates
- **Harbor Alerts:** Approaching notifications, marina info, fuel prices, warnings
- **AIS Integration:** Nearby vessels, collision warnings, vessel info, CPA/TCPA
- **Tides:** Tide graphs, predictions, tidal currents, moon phase

### D.4 Polish Features (Phase 3 Continued)

- **Quick Settings:** One-tap toggles, brightness, layer opacity
- **Audio Alerts:** Depth alarm, anchor drag, weather warnings, AIS collision
- **Screenshots:** Capture view, include overlays, annotations, social sharing
- **Performance:** FPS counter, memory stats, network monitor, battery tracking

### D.5 Social Features (Phase 4)

- **Trip Logging:** Auto-save, manual creation, statistics, replay, photos
- **Social Sharing:** Routes, waypoints, reports, community feeds
- **User Profiles:** Boat info, home port, sync, badges
- **Collaborative:** Shared routes, group tracking, chat, reviews

---

## Section E: Technical Decisions

### E.1 Framework: Flutter 3.16+

Cross-platform, high performance, rich ecosystem, geolocation support.

### E.2 State Management: Provider 6.1+

Official recommendation, simple DI, rebuild optimization, good DX.

### E.3 Map Engine: MapTiler SDK + WebView

Nautical chart support, vector tiles, offline capability, 3D terrain, MapLibre GL JS.

### E.4 Weather API: Open-Meteo

Free, ECMWF data, marine variables, 7-day forecasts, hourly resolution.

### E.5 Oceanographic Data: NOAA APIs

Authoritative, real-time, tides/currents, buoy data (CO-OPS, NDBC, NOS).

### E.6 Backend: Supabase

PostgreSQL+PostGIS, real-time subscriptions, auth, storage, RLS.

### E.7 Offline Strategy: Cache-First

Check cache first, return immediately, background refresh, update on success.

Storage: SQLite (structured), Hive (key-value), filesystem (tiles), SharedPreferences (settings).

---

## Section F: Development Phases

### Phase 0: Foundation (Week 1-2)

Setup, base architecture, core services, testing infrastructure.
**Deliverables:** Project init, providers, ProjectionService, CacheService, HTTP client, NMEA parser, theme, CI/CD.

### Phase 1: Core Navigation (Week 3-6)

Map display, GPS tracking, basic overlays.
**Deliverables:** MapWebView, viewport sync, GPS display, track history, wind/wave overlays, basic UI.

### Phase 2: Weather Intelligence (Week 7-10)

Weather integration, forecasting, timeline.
**Deliverables:** Open-Meteo integration, 7-day forecast, timeline scrubber, playback controls, multiple overlays, offline cache.

### Phase 3: Polish & Features (Week 11-14)

Advanced features, UI/UX, performance.
**Deliverables:** Dark mode, settings, harbor alerts, AIS, tides, audio alerts, screenshots, performance monitoring.

### Phase 4: Social & Community (Week 15-18)

Social features, launch prep.
**Deliverables:** Trip logging, social sharing, profiles, collaborative routes, app store assets, beta testing, launch plan.

---

## Section G: SailStream UI Architecture

### G.1 Ocean Glass Design Philosophy

**Vision:** Create a fluid, marine-inspired user interface where data flows like water and UI elements feel like frosted sea glass over nautical charts.

**Core Principles:**

1. **Data as Fluid Element** - Information flows and connects visually
2. **Contextual Priority & Holographic Layering** - Critical data expands, less critical recedes
3. **Ambient Intelligence** - UI adapts to time of day and weather conditions
4. **Glass Aesthetics** - Frosted glass effects with subtle depth and translucency

### G.2 Design System Specifications

**Color Palette:**

- **Deep Navy:** `#0A1F3F` - Primary background, night navigation
- **Teal:** `#1D566E` - Secondary accents, depth
- **Seafoam Green:** `#00C9A7` - Primary accent, active states, data highlights
- **Safety Orange:** `#FF9A3D` - Alerts, warnings, attention
- **Coral Red:** `#FF6B6B` - Danger, critical alerts
- **Pure White:** `#FFFFFF` - Text, icons, contrast

**Typography:**

- **Font Family:** SF Pro Display (iOS/macOS) or Poppins (fallback)
- **Data Values:** 56pt bold - Large numeric displays
- **Headings:** 24pt semibold - Section headers
- **Body Text:** 16pt regular - Standard content
- **Labels:** 12pt medium, 0.5px letter-spacing - Small labels, units

**Glass Effect Specifications:**

- **Backdrop Blur:** 10-12px sigma for frosted glass
- **Opacity:** 75-85% for glass cards
- **Border Radius:** 12-16px for polished sea glass aesthetic
- **Border:** 1px white at 10-20% opacity
- **Shadow:** Subtle depth with multi-layer shadows

### G.3 UI Component Library

#### G.3.1 Glass Card (Base Component)

**Purpose:** Reusable frosted glass container for all overlay UI elements

**Specifications:**

- **Backdrop Blur:** 12px
- **Background:** Dark (#0A1F3F) at 80% opacity or Light (#FFFFFF) at 85% opacity
- **Border Radius:** 16px
- **Border:** 1px white at 20% opacity
- **Padding:** Small (12px), Medium (16px), Large (24px)
- **Shadow:** 0px 8px 32px rgba(0,0,0,0.3)

**Usage:**

```dart
GlassCard(
  padding: GlassCardPadding.medium,
  child: YourContent(),
)
```text

#### G.3.2 Data Orb Widget

**Purpose:** Circular glass display for critical navigation data (SOG, COG, DEPTH)

**Size Variants:**

- **Small:** 80×80px - Compact display
- **Medium:** 140×140px - Standard display (default)
- **Large:** 200×200px - Prominent display

**Anatomy:**

- **Outer Ring:** Seafoam green (#00C9A7) progress indicator or accent ring
- **Glass Background:** Frosted glass effect matching theme
- **Value Text:** 48pt bold (medium size) - Primary data value
- **Unit Text:** 14pt medium - Data unit (kts, °, m)
- **Label Text:** 12pt medium - Data type (SOG, COG, DEPTH)
- **Subtitle** (optional): 10pt regular - Additional context (WSW, ft)

**States:**

- **Normal:** Standard display
- **Alert:** Orange ring for warnings
- **Critical:** Red ring for danger
- **Inactive:** 50% opacity when no data

#### G.3.3 Compass Widget

**Purpose:** Central navigation widget showing heading, speed, and wind data

**Dimensions:** Minimum 200×200px, scales responsively

**Components:**

- **Compass Rose:** Rotating SVG or CustomPaint with N/S/E/W markers
- **Heading Display:** Current magnetic or true heading (e.g., "N 25°")
- **Speed Indicators:** Inner ring showing boat speed (e.g., "15.2 kt")
- **Wind Data:** Wind speed and direction (e.g., "Wind: 15.2 kt N 45°")
- **VR Toggle:** Button to switch between Virtual Reality mode
- **Direction Indicator:** Arrow or triangle pointing to wind direction

**Interaction:**

- Tap to toggle between Magnetic/True heading
- Long press for detailed wind analysis
- VR button opens immersive compass view

#### G.3.4 True Wind Widget

**Purpose:** Draggable, repositionable widget showing true wind data

**Dimensions:**

- **Widget Mode:** 120×120px circular
- **Card Mode:** 200×140px with extended info

**Anatomy:**

- **Circular Progress Ring:** Seafoam green, shows wind strength visually (0-50kt scale)
- **Wind Speed:** 32pt bold centered (e.g., "14.2 kts")
- **Wind Direction:** 16pt medium below speed (e.g., "NNE")
- **Background:** Frosted glass with 85% opacity
- **Drag Handle:** Subtle indicator that widget is movable

**Features:**

- **Draggable:** Long press to enter drag mode
- **Multi-Instance:** Support multiple wind widgets on screen
- **Deletable:** Trash icon appears in edit mode
- **Auto-Hide:** Fades out when not in use (configurable)

#### G.3.5 Navigation Sidebar

**Purpose:** Primary navigation menu for switching between app sections

**Layout:** Vertical icon-based menu on left side (desktop/tablet) or bottom sheet (mobile)

**Menu Items:**

- Dashboard - Overview/home
- Map - Main navigation map
- Weather - Forecast details
- Settings - App configuration
- Profile - User profile
- Boat Icon - Vessel management (bottom position)

**Styling:**

- **Icon Size:** 24×24px
- **Active State:** Seafoam green (#00C9A7) background with glow
- **Inactive State:** White icons at 60% opacity
- **Background:** Frosted glass matching theme
- **Width:** 72px fixed on desktop, full-width sheet on mobile

### G.4 Screen Layouts

#### G.4.1 Main Map Screen

**Z-Index Layers (bottom to top):**

1. MapTiler WebView (base layer)
2. Wind Particle Overlay (animated cyan/teal flowing particles)
3. Wave Overlay (optional)
4. Current Overlay (optional)
5. Boat Track Trail
6. Boat Position Marker
7. Navigation Orbs (SOG/COG/DEPTH) - Top center or corners
8. Compass Widget - Bottom center
9. True Wind Widgets - Draggable, user-positioned
10. Navigation Sidebar - Left edge
11. Top App Bar - Search, location, branding
12. Time Scrubber (when in forecast mode) - Bottom

**Responsive Breakpoints:**

- **Mobile:** < 600px - Bottom navigation, stacked orbs
- **Tablet:** 600-1200px - Side navigation, flexible layouts
- **Desktop:** > 1200px - Full sidebar, multi-column layouts

#### G.4.2 Navigation Mode Screen

**Top Section:**

- Title: "navigation mode"
- Back button (left)
- Settings icon (right)

**Data Orbs Section:**

- Three large data orbs in row: SOG, COG, DEPTH
- Spacing: 16px between orbs

**Map Section:**

- Full-width map with route visualization
- Dashed line from current position to next waypoint
- Waypoint markers with labels
- Place names for navigation reference

**Bottom Info Card:**

- Next waypoint name
- Distance to waypoint
- Estimated Time of Arrival (ETA)
- Glass card background

**Action Buttons:**

- "+ Route" - Create new route
- "Mark Position" - Save current location
- "Track" - Start/stop track recording
- "Alerts" - View/configure navigation alerts

### G.5 Architecture Rules for UI

**Rule G.1: Single Projection Source**
ALL overlays MUST get viewport bounds from MapViewportService. NEVER calculate screen positions independently.

**Rule G.2: Glass Effect Performance**
All backdrop blur effects MUST maintain 60 FPS. Use RepaintBoundary for expensive glass widgets.

**Rule G.3: Responsive Design**
ALL widgets MUST support 3 breakpoints: mobile (<600px), tablet (600-1200px), desktop (>1200px).

**Rule G.4: Dark Mode First**
Design for dark mode as primary. Light mode is secondary for daytime use.

**Rule G.5: No Fixed Dimensions**
Use LayoutBuilder and MediaQuery for all sizing. No hardcoded pixel values except minimum sizes.

**Rule G.6: Draggable Widget State**
Draggable widgets MUST save positions to user preferences. Restore on app restart.

**Rule G.7: Animation Fluidity**
ALL animations MUST use curves (easeInOut, decelerate) and complete in 200-400ms.

### G.6 Failure Guards (Directly Addressing Past Issues)

1. **No God Widgets/Controllers** – Any UI class over 400 lines must be split; overlay state lives in providers, not widgets. (Prevents Attempt 1 god object.)
2. **Projection Single Source** – All lat/lng ↔ screen math flows through `ProjectionService`/`ViewportProjector` to avoid overlay drift. (Fixes Attempt 2/4 projection mismatch.)
3. **Provider Discipline** – Providers are created only in `main.dart` per documented layers; no provider creation in widget subtrees. (Fixes Attempt 2 wiring disasters.)
4. **Viewport Sync Contract** – Map WebView publishes viewport deltas; Flutter overlays consume the same viewport; no duplicate viewport state. (Prevents dual-state divergence.)
5. **Glass Performance Budget** – Backdrop blurs wrapped in `RepaintBoundary` and profiled to hold 60 FPS; fall back to opacity-only styles on low-end devices. (Avoids jank regressions.)
6. **Responsive First** – All SailStream components implement mobile/tablet/desktop layouts via `ResponsiveLayout` helpers; no fixed pixel layouts. (Prevents RenderFlex overflows.)
7. **Persisted Drag Positions** – Draggable widgets (e.g., wind widgets) persist positions in SettingsProvider; default positions loaded on startup. (Avoids lost layouts on restart.)

---

## Appendix

### Glossary

- **AIS:** Automatic Identification System
- **NMEA:** National Marine Electronics Association
- **Web Mercator:** EPSG:3857 projection
- **WGS84:** World Geodetic System 1984
- **LRU:** Least Recently Used
- **TTL:** Time To Live
- **CPA/TCPA:** Closest Point of Approach / Time to CPA

### References

- [Flutter Docs](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [MapLibre GL JS](https://maplibre.org)
- [Open-Meteo API](https://open-meteo.com/en/docs/marine-weather-api)
- [NOAA APIs](https://tidesandcurrents.noaa.gov/api/)
- [NMEA 0183](https://www.nmea.org)

---

<!-- Document End -->
