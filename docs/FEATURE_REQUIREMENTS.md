<!-- markdownlint-disable MD022 MD031 MD032 MD034 MD036 MD040 MD058 MD060 -->
# Feature Requirements
## Marine Navigation App - Detailed Feature Specifications

**Version:** 4.0  
**Last Updated:** 2026-02-01  
**Purpose:** Comprehensive requirements for all planned features (includes SailStream UI)

---

## Table of Contents

1. [Core Features (Phase 1)](#core-features-phase-1)
2. [Essential Features (Phase 2)](#essential-features-phase-2)
3. [Advanced Features (Phase 3)](#advanced-features-phase-3)
4. [Social Features (Phase 4)](#social-features-phase-4)
5. [Feature Priority Matrix](#feature-priority-matrix)

---

## Core Features (Phase 1)

### FEAT-001: Interactive Map Display

**Priority:** P0 (Must Have)  
**Estimated Effort:** 3 weeks  
**Dependencies:** None  
**Owner:** MapProvider

**Description:**
Interactive nautical chart display with multi-layer support, smooth zoom/pan/rotate, and offline tile caching.

**Acceptance Criteria:**
- [ ] Map renders at 60 FPS during pan/zoom
- [ ] Supports zoom levels 1-20
- [ ] Smooth pinch-to-zoom gesture
- [ ] Two-finger rotation
- [ ] Nautical chart layer toggleable
- [ ] Satellite imagery layer toggleable
- [ ] Depth contours visible at zoom >12
- [ ] Buoys and markers visible at zoom >14
- [ ] Map tiles cached for offline use
- [ ] Cache size limit 500MB
- [ ] Tiles auto-download for current region

**Technical Notes:**
- Use MapTiler SDK with MapLibre GL JS
- WebView integration for map rendering (`webview_flutter` scaffold)
- Flutter Canvas for overlay layers
- Viewport synchronization critical (see ISS-001)
- Projection: Web Mercator (EPSG:3857)
- Implementation status: Phase 0 scaffold (`marine_nav_app/lib/providers/map_provider.dart`,
  `marine_nav_app/lib/services/projection_service.dart`,
  `marine_nav_app/lib/widgets/map/map_webview.dart`)

**API Endpoints:**
- MapTiler: `https://api.maptiler.com/maps/{style}/`
- Tile format: Vector tiles (PBF)

**Edge Cases:**
- Handle map load timeout (show error, retry)
- Graceful degradation if tiles unavailable
- Prevent over-zooming (max zoom 20)
- Handle zero network (offline mode)

**Test Scenarios:**
1. Load map with network → Success
2. Load map without network → Cached tiles
3. Pan map smoothly → 60 FPS maintained
4. Zoom in/out → Overlays stay positioned
5. Rotate map → Compass updates correctly

---

### FEAT-002: NMEA Data Integration

**Priority:** P0 (Must Have)  
**Estimated Effort:** 2 weeks  
**Dependencies:** FEAT-001  
**Owner:** NMEAProvider

**Description:**
Connect to NMEA 0183 devices via TCP/UDP, parse sentences, extract GPS position, speed, heading, depth, wind data.

**Acceptance Criteria:**
- [ ] Connect to NMEA device via TCP
- [ ] Connect to NMEA device via UDP
- [ ] Auto-reconnect on connection loss
- [ ] Parse GPGGA sentences (position)
- [ ] Parse GPRMC sentences (position + speed)
- [ ] Parse GPVTG sentences (course + speed)
- [ ] Parse AIVDM sentences (AIS data)
- [ ] Parse MWV sentences (wind)
- [ ] Parse DPT sentences (depth)
- [ ] Validate checksums
- [ ] Handle malformed sentences gracefully
- [ ] Update rate: 1 Hz minimum
- [ ] Processing in background isolate
- [ ] No UI jank during parsing

**Technical Notes:**
- NMEA 0183 standard format: `$<sentence>,<data>*<checksum>\r\n`
- Checksum: XOR of all bytes between $ and *
- Use Isolate for parsing (see ISS-009)
- Buffer size limit: 10KB
- Batch updates every 200ms

**Supported Sentence Types:**
| Type | Description | Priority |
|------|-------------|----------|
| GPGGA | GPS Fix Data | P0 |
| GPRMC | Recommended Minimum | P0 |
| GPVTG | Track & Speed | P1 |
| AIVDM | AIS VHF Data | P1 |
| MWV | Wind Speed & Angle | P1 |
| DPT | Depth | P1 |
| HDG | Heading | P2 |

**Edge Cases:**
- Incomplete sentences in buffer
- Checksum failures (log, skip)
- Unknown sentence types (log, skip)
- Connection timeout (retry with backoff)
- High message rate (>100/sec) → Throttle

**Test Scenarios:**
1. Valid GPGGA → Position updated
2. Invalid checksum → Rejected
3. Incomplete sentence → Buffered
4. Connection lost → Auto-reconnect
5. High rate (200 msg/s) → UI smooth

---

### FEAT-003: Boat Position Tracking

**Priority:** P0 (Must Have)  
**Estimated Effort:** 1 week  
**Dependencies:** FEAT-001, FEAT-002  
**Owner:** BoatProvider

**Description:**
Display real-time boat position on map with heading indicator, track history, speed/distance statistics.

**Acceptance Criteria:**
- [ ] Boat marker shows current position
- [ ] Heading arrow rotates with COG
- [ ] Track history (breadcrumb trail)
- [ ] Track color-coded by speed
- [ ] Track persists across app restarts
- [ ] Configurable track history (1h to 7 days)
- [ ] Speed display (knots/mph/kph)
- [ ] Distance traveled display
- [ ] Average speed display
- [ ] Maximum speed display
- [ ] ETA to waypoint
- [ ] Man Overboard (MOB) quick button
- [ ] Center map on boat button

**Technical Notes:**
- Update position every 1 second
- Store track points in SQLite
- Limit track points: 10,000 max
- Auto-prune old points
- Position smoothing for GPS jitter
- Handle GPS accuracy <50m only

**UI Components:**
- Boat marker: Custom icon with heading arrow
- Track line: Polyline overlay
- Info card: Speed, heading, coordinates
- MOB button: FAB in bottom-right

**Data Model:**
```dart
class BoatPosition {
  final double latitude;
  final double longitude;
  final double? speed;        // m/s
  final double? heading;      // degrees
  final double? accuracy;     // meters
  final DateTime timestamp;
}

class TrackPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
}
```

**Edge Cases:**
- GPS signal lost → Show last known + age
- Low accuracy position → Filter out
- Unrealistic speed → Reject (see ISS-018)
- Track history full → Auto-prune oldest

**Test Scenarios:**
1. GPS updates → Boat marker moves
2. Change heading → Arrow rotates
3. Track records → History saved
4. App restart → Track restored
5. MOB button → Marker placed

---

### FEAT-004: Weather Overlays

**Priority:** P0 (Must Have)  
**Estimated Effort:** 3 weeks  
**Dependencies:** FEAT-001  
**Owner:** WeatherProvider

**Description:**
Display wind vectors, wave height/direction, ocean currents, sea surface temperature as map overlays.

**Acceptance Criteria:**
- [ ] Wind barbs at grid points
- [ ] Wind speed color-coded (Beaufort scale)
- [ ] Wind direction accurate
- [ ] Wave height contours
- [ ] Wave direction arrows
- [ ] Ocean current vectors
- [ ] SST heat map
- [ ] Precipitation radar
- [ ] Toggle each layer independently
- [ ] Opacity slider per layer
- [ ] Overlays positioned correctly at all zooms
- [ ] Update interval: 1 hour
- [ ] Data source: Open-Meteo API
- [ ] Offline cache: 24 hours

**Technical Notes:**
- Use CustomPaint for overlay rendering
- ProjectionService for coordinate transform
- Viewport synchronization (see ISS-001)
- Grid resolution: 0.25° (~25km)
- Update overlays only on data/viewport change

**Overlay Types:**

#### Wind Overlay
- **Source:** Open-Meteo `/v1/marine` API
- **Variables:** `wind_speed_10m`, `wind_direction_10m`
- **Rendering:** Wind barbs (WMO standard)
- **Colors:** Green (<10 kts), Yellow (10-20), Orange (20-30), Red (>30)

#### Wave Overlay
- **Source:** Open-Meteo `/v1/marine` API
- **Variables:** `wave_height`, `wave_direction`
- **Rendering:** Contour lines + arrows
- **Colors:** Blue gradient (0-8m)

#### Current Overlay
- **Source:** Open-Meteo `/v1/marine` API
- **Variables:** `ocean_current_velocity`, `ocean_current_direction`
- **Rendering:** Streamlines or arrows
- **Colors:** Purple gradient

#### SST Overlay
- **Source:** Open-Meteo `/v1/marine` API
- **Variables:** `sea_surface_temperature`
- **Rendering:** Heat map
- **Colors:** Blue (cold) to Red (hot)

**Edge Cases:**
- No data for region → Show message
- Overlay outside viewport → Cull
- Too many overlay points → Decimate
- Old cached data → Show age indicator

**Test Scenarios:**
1. Load wind overlay → Barbs appear
2. Zoom map → Overlays reposition
3. Toggle layer → Overlay hides/shows
4. Change opacity → Overlay transparency
5. Offline → Cached overlay loads

---

## Essential Features (Phase 2)

### FEAT-005: Weather Forecasting

**Priority:** P1 (Should Have)  
**Estimated Effort:** 2 weeks  
**Dependencies:** FEAT-004  
**Owner:** WeatherProvider

**Description:**
7-day marine weather forecast with hourly breakdown, multiple model comparison, confidence indicators.

**Acceptance Criteria:**
- [ ] 7-day forecast (168 hours)
- [ ] Hourly granularity
- [ ] Wind speed/direction forecast
- [ ] Wave height/period forecast
- [ ] Precipitation forecast
- [ ] Temperature forecast
- [ ] Multiple models (ECMWF, GFS, ICON)
- [ ] Model comparison view
- [ ] Forecast confidence/uncertainty
- [ ] Graphical timeline
- [ ] Text summary
- [ ] Update every 6 hours
- [ ] Notifications for weather warnings

**API Endpoints:**
- Open-Meteo: `/v1/marine?forecast_days=7&hourly=...`
- Variables: wind, waves, temperature, precipitation

**UI Layout:**
- Card-based daily summary
- Expandable hourly details
- Graph: Wind speed over time
- Graph: Wave height over time
- Model comparison table

**Data Retention:**
- Cache forecast for 6 hours
- Store last 30 days historical

**Edge Cases:**
- Forecast unavailable → Show cached
- Location too far from shore → Limited data
- API rate limit → Use cached data

---

### FEAT-006: Timeline Playback

**Priority:** P1 (Should Have)  
**Estimated Effort:** 2 weeks  
**Dependencies:** FEAT-005  
**Owner:** TimelineProvider

**Description:**
Animate forecast progression, scrub through time, adjust playback speed, export video.

**Acceptance Criteria:**
- [ ] Scrubber bar for time selection
- [ ] Play/pause button
- [ ] Speed controls (0.5x, 1x, 2x, 4x)
- [ ] Frame-by-frame step
- [ ] Loop option
- [ ] Time range selection
- [ ] Overlays update with timeline
- [ ] Smooth animation (30 FPS)
- [ ] Lazy load frames
- [ ] Memory usage <100MB
- [ ] Export video (MP4)
- [ ] Share screenshot

**Technical Notes:**
- Max 100 frames in memory (see ISS-013)
- Lazy load frames as needed
- Preload next frame
- Background export using ffmpeg

**UI Controls:**
```
[◀◀] [◀] [▶/⏸] [▶▶]  [0.5x] [1x] [2x] [4x]
━━━━━●━━━━━━━━━━━━━━━━━━━
12:00      18:00        00:00
```

**Edge Cases:**
- Fast scrubbing → Skip frames
- Export while playing → Pause first
- Low memory → Reduce cached frames

---

### FEAT-007: Dark Mode & Theming

**Priority:** P1 (Should Have)  
**Estimated Effort:** 1 week  
**Dependencies:** None  
**Owner:** ThemeProvider

**Description:**
Light/dark themes, auto mode based on time, red light mode for night vision, high contrast mode.

**Acceptance Criteria:**
- [ ] Light theme
- [ ] Dark theme
- [ ] Auto switch at sunset/sunrise
- [ ] Red light mode (red on black)
- [ ] High contrast mode
- [ ] Theme persists across restarts
- [ ] Smooth theme transition
- [ ] All widgets support all themes
- [ ] Map style changes with theme
- [ ] No white flash on theme change

**Themes:**

#### Light Theme
- Background: #FFFFFF
- Primary: Marine Blue (#003F87)
- Accent: Nautical Gold (#D4AF37)
- Text: #000000

#### Dark Theme
- Background: #0F0F1E
- Surface: #1A1A2E
- Primary: Marine Blue (#003F87)
- Accent: Nautical Gold (#D4AF37)
- Text: #FFFFFF

#### Red Light Theme
- Background: #000000
- Surface: #1A0000
- Primary: #FF0000
- Accent: #880000
- Text: #FF0000

**Technical Notes:**
- Use ThemeData and ColorScheme
- Persist preference in SharedPreferences
- Sunset/sunrise via location + timezone
- Animate theme change with AnimatedTheme

---

### FEAT-008: Offline Mode

**Priority:** P1 (Should Have)  
**Estimated Effort:** 2 weeks  
**Dependencies:** FEAT-001, FEAT-004  
**Owner:** CacheProvider

**Description:**
Download map regions and weather data for offline use, background sync, storage management.

**Acceptance Criteria:**
- [ ] Download map region
- [ ] Region selection by bounds
- [ ] Download progress indicator
- [ ] Cache weather data
- [ ] Cache forecast data
- [ ] Cache tide data
- [ ] Background sync when online
- [ ] Storage usage display
- [ ] Clear cache option
- [ ] Auto-cleanup old data
- [ ] Offline indicator in UI
- [ ] All features work offline (degraded)

**Storage Limits:**
- Map tiles: 500MB
- Weather data: 100MB
- Total: 1GB

**Download UI:**
- Map region selector
- Size estimate
- Download button
- Progress bar
- Cancel option

**Sync Strategy:**
- Check network every 5 minutes
- Download updates in background
- Notify user when fresh data available
- Respect metered connections

**Edge Cases:**
- Storage full → Show warning
- Download interrupted → Resume
- Old cached data → Show age
- No network → Use cached only

---

## Advanced Features (Phase 3)

### FEAT-009: Settings & Configuration

**Priority:** P2 (Nice to Have)  
**Estimated Effort:** 1 week  
**Dependencies:** None  
**Owner:** SettingsProvider

**Description:**
User preferences for units, language, map style, data refresh, privacy.

**Acceptance Criteria:**
- [ ] Unit system (metric/imperial/nautical)
- [ ] Language selection
- [ ] Map style preference
- [ ] Data refresh interval
- [ ] GPS update rate
- [ ] Track history duration
- [ ] Cache size limit
- [ ] Privacy settings
- [ ] Analytics opt-in/out
- [ ] Location sharing opt-in/out
- [ ] Settings persist
- [ ] Import/export settings

**Settings Categories:**

#### Units
- Distance: NM / km / mi
- Speed: kts / kph / mph
- Depth: m / ft / fathoms
- Temperature: °C / °F
- Pressure: hPa / inHg

#### Display
- Theme: Light / Dark / Auto
- Map style: Nautical / Satellite / Hybrid
- Overlay opacity
- Font size
- Track color

#### Data
- GPS update rate: 1s / 2s / 5s
- Weather refresh: 1h / 3h / 6h
- Forecast days: 3 / 7 / 10
- Cache size: 100MB / 500MB / 1GB

---

### FEAT-010: Harbor & Marina Alerts

**Priority:** P2 (Nice to Have)  
**Estimated Effort:** 1 week  
**Dependencies:** FEAT-003  
**Owner:** BoatProvider

**Description:**
Notify when approaching harbors, show marina information, fuel prices, weather warnings.

**Acceptance Criteria:**
- [ ] Detect approaching harbor
- [ ] Notification 5NM from harbor
- [ ] Marina details (name, location, contact)
- [ ] Fuel availability & prices
- [ ] Services (pump-out, electric, water)
- [ ] Weather warnings for harbor
- [ ] Tide information
- [ ] Harbor hazards
- [ ] User ratings/reviews
- [ ] Add custom harbors

**Data Sources:**
- OpenStreetMap: Marina locations
- User submissions: Fuel prices, reviews
- NOAA: Weather warnings, tides

**Notification:**
```
⚓ Approaching San Francisco Bay
5.2 NM away • ETA 45 min

Fuel: $4.89/gal
Services: ⚡ 🚿 🛢️
Weather: ⚠️ Small craft advisory
```

---

### FEAT-011: AIS Integration

**Priority:** P2 (Nice to Have)  
**Estimated Effort:** 2 weeks  
**Dependencies:** FEAT-002, FEAT-003  
**Owner:** NMEAProvider

**Description:**
Display AIS targets, collision warnings, vessel information, CPA/TCPA calculations.

**Acceptance Criteria:**
- [ ] Display AIS targets on map
- [ ] Target icons by vessel type
- [ ] Target heading/speed vectors
- [ ] Tap target for details
- [ ] Collision warning (CPA <0.5NM, TCPA <10min)
- [ ] Vessel name, MMSI, callsign
- [ ] Vessel dimensions
- [ ] Navigation status
- [ ] Track AIS targets
- [ ] Filter by distance
- [ ] Filter by type

**AIS Data:**
- Message type 1,2,3: Position reports
- Message type 5: Static data
- Message type 18,19: Class B position

**CPA/TCPA Algorithm:**
1. Calculate relative velocity
2. Find closest point of approach (CPA)
3. Calculate time to CPA (TCPA)
4. If CPA <0.5 NM AND TCPA <10 min → Warn

**Collision Warning:**
```
⚠️ COLLISION WARNING

Vessel: PACIFIC STAR (MMSI: 123456789)
CPA: 0.3 NM
TCPA: 6 minutes
Bearing: 045°
```

---

### FEAT-012: Tide Predictions

**Priority:** P2 (Nice to Have)  
**Estimated Effort:** 1 week  
**Dependencies:** FEAT-001  
**Owner:** WeatherProvider

**Description:**
Tide predictions, current station data, high/low times, tidal current display.

**Acceptance Criteria:**
- [ ] Tide graph for location
- [ ] High/low predictions
- [ ] Current tide height
- [ ] Tidal current data
- [ ] Current station markers
- [ ] 7-day tide calendar
- [ ] Moon phase
- [ ] Sunrise/sunset times
- [ ] Slack water times
- [ ] Max flood/ebb

**Data Source:**
- NOAA CO-OPS API
- Stations: https://tidesandcurrents.noaa.gov/stations.html
- Predictions: https://api.tidesandcurrents.noaa.gov/api/prod/

**Tide Graph:**
```
High: 6.2 ft at 11:32 AM
────────────────────────
        ╱╲
    ╱───    ───╲     ╱
───              ───
Low: 0.8 ft at 5:47 AM
────────────────────────
6AM   9AM   12PM  3PM   6PM
```

---

## Social Features (Phase 4)

### FEAT-013: Trip Logging

**Priority:** P3 (Future)  
**Estimated Effort:** 2 weeks  
**Dependencies:** FEAT-003  
**Owner:** BoatProvider

**Description:**
Auto-save trips, manual trip creation, statistics, replay, photo attachments.

**Acceptance Criteria:**
- [ ] Auto-detect trip start/end
- [ ] Manual trip creation
- [ ] Trip name & description
- [ ] Trip statistics (distance, time, avg speed, max speed)
- [ ] Trip replay with timeline
- [ ] Attach photos to trip
- [ ] Export trip (GPX, KML)
- [ ] Share trip
- [ ] Trip calendar
- [ ] Search trips

**Trip Detection:**
- Start: Speed >2 kts for 1 minute
- End: Speed <0.5 kts for 5 minutes

**Trip Data:**
```dart
class Trip {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceNM;
  final double maxSpeedKts;
  final double avgSpeedKts;
  final List<TrackPoint> track;
  final List<Photo> photos;
}
```

---

### FEAT-014: Social Sharing

**Priority:** P3 (Future)  
**Estimated Effort:** 2 weeks  
**Dependencies:** FEAT-013  
**Owner:** Backend

**Description:**
Share routes, waypoints, trip reports, screenshots, community feeds.

**Acceptance Criteria:**
- [ ] Share route publicly
- [ ] Share waypoint with friends
- [ ] Trip report with photos
- [ ] Like/comment on shares
- [ ] Follow other users
- [ ] Community feed
- [ ] Trending routes
- [ ] Safety reports
- [ ] Fish reports

**Privacy Levels:**
- Public: Anyone can see
- Friends: Only followers
- Private: Only me

---

### FEAT-015: Glass UI Component Library

**Priority:** P0 (Must Have)  
**Estimated Effort:** 2 weeks  
**Dependencies:** None  
**Owner:** UI Library Team

**Description:**
Complete implementation of the Ocean Glass design system with reusable frosted glass UI components including GlassCard, DataOrb, CompassWidget, WindWidget, and NavigationSidebar.

**Acceptance Criteria:**
- [ ] GlassCard base component with backdrop blur (12px)
- [ ] GlassCard supports 3 padding sizes (small, medium, large)
- [ ] GlassCard supports dark and light themes
- [ ] GlassCard maintains 60 FPS with blur effects
- [ ] DataOrb widget with 3 size variants (80px, 140px, 200px)
- [ ] DataOrb displays value, unit, label, and optional subtitle
- [ ] DataOrb supports 3 states (normal, alert, critical)
- [ ] DataOrb has seafoam green accent ring
- [ ] All components use Ocean Glass color palette
- [ ] All components support responsive breakpoints
- [ ] Typography follows SF Pro Display specifications
- [ ] Glass effects work on iOS and Android
- [ ] Performance: No frame drops during animations
- [ ] Widget tests for all components
- [ ] Golden tests for visual regression

**Technical Notes:**
- Use BackdropFilter for frosted glass effect
- Use RepaintBoundary for performance optimization
- Follow Effective Dart guidelines
- Maximum 300 lines per widget file
- Use const constructors where possible

**Color Palette:**
- Deep Navy: #0A1F3F
- Teal: #1D566E
- Seafoam Green: #00C9A7
- Safety Orange: #FF9A3D
- Coral Red: #FF6B6B
- Pure White: #FFFFFF

**Test Scenarios:**
1. GlassCard renders with blur on both platforms
2. DataOrb displays all size variants correctly
3. Color palette matches specifications
4. Theme switching works without errors
5. Performance maintains 60 FPS with multiple glass widgets

---

### FEAT-016: Navigation Mode Screen

**Priority:** P1 (Should Have)  
**Estimated Effort:** 1 week  
**Dependencies:** FEAT-001, FEAT-015  
**Owner:** Navigation Team

**Description:**
Dedicated navigation mode screen with large data orbs for SOG, COG, and DEPTH, route visualization, waypoint management, and action buttons for creating routes and marking positions.

**Acceptance Criteria:**
- [ ] Navigation mode accessible from main map
- [ ] Three large data orbs at top (SOG, COG, DEPTH)
- [ ] Map displays current route with dashed line
- [ ] Waypoint markers visible with labels
- [ ] Bottom info card shows next waypoint details
- [ ] Info card displays distance and ETA
- [ ] Action buttons: + Route, Mark Position, Track, Alerts
- [ ] + Route button creates new route
- [ ] Mark Position saves current location
- [ ] Track button starts/stops tracking
- [ ] Alerts button shows navigation warnings
- [ ] Back button returns to main map
- [ ] Settings button opens navigation settings
- [ ] Screen updates in real-time with NMEA data
- [ ] Smooth transitions between screens

**Technical Notes:**
- Use Hero animations for data orb transitions
- Calculate ETA based on SOG and distance
- Update route visualization when viewport changes
- Store user-created routes in local database
- Validate waypoint coordinates

**UI Layout:**
- Top section: 120px for data orbs
- Map section: Expanded to fill remaining space
- Bottom info card: 60px fixed height
- Action button bar: 56px fixed height
- Spacing: 16px between all elements

**Edge Cases:**
- No route defined → Hide route visualization
- No next waypoint → Show "No Active Route"
- Invalid GPS → Show "No GPS Signal"
- SOG/COG/DEPTH unavailable → Show "--" in orbs

**Test Scenarios:**
1. Enter navigation mode from map → Success
2. Create new route → Saved to database
3. Mark current position → Waypoint created
4. Start tracking → Breadcrumb trail visible
5. Update NMEA data → Orbs update in real-time
6. Calculate ETA → Matches manual calculation

---

### FEAT-017: Draggable Wind Widgets

**Priority:** P1 (Should Have)  
**Estimated Effort:** 1 week  
**Dependencies:** FEAT-002, FEAT-015  
**Owner:** Weather Team

**Description:**
Draggable, multi-instance true wind widgets that can be positioned anywhere on the map. Widgets display wind speed and direction with circular progress indicators and support delete functionality.

**Acceptance Criteria:**
- [ ] WindWidget displays true wind speed (kts)
- [ ] WindWidget displays wind direction (compass point)
- [ ] Circular progress ring visualizes wind strength
- [ ] Progress ring color: Seafoam green (#00C9A7)
- [ ] Widget is draggable via long press
- [ ] Multiple wind widgets can coexist
- [ ] Widget positions saved to preferences
- [ ] Positions restored on app restart
- [ ] Edit mode shows delete button (trash icon)
- [ ] Tap delete button removes widget
- [ ] Widget auto-hides after inactivity (optional)
- [ ] Widget size: 120×120px (widget mode)
- [ ] Card size: 200×140px (card mode)
- [ ] Frosted glass background with 85% opacity
- [ ] Smooth drag animations
- [ ] Wind data updates in real-time from NMEA

**Technical Notes:**
- Use Draggable widget for repositioning
- Use DragTarget for drop validation
- Save positions as JSON in shared preferences
- Limit to 5 wind widgets maximum
- Use AnimatedOpacity for auto-hide
- Calculate wind strength percentage (0-50kt scale)

**Interaction States:**
- Normal: Display only
- Long Press: Enter drag mode
- Dragging: Show outline and opacity
- Edit Mode: Show delete button
- Deleted: Fade out animation

**Data Sources:**
- True Wind: MWV NMEA sentence
- Apparent Wind: VWR NMEA sentence
- Fallback: Weather forecast data

**Edge Cases:**
- No wind data → Show "--" in widget
- Widget dragged off screen → Snap to nearest edge
- Maximum widgets reached → Show toast warning
- Invalid wind data → Show error indicator

**Test Scenarios:**
1. Add wind widget → Appears on screen
2. Drag widget → Position updates smoothly
3. Restart app → Positions restored
4. Delete widget → Removed from screen
5. Update wind data → Widget updates in real-time
6. Add 6th widget → Show error message

---

## Feature Priority Matrix

| Feature | Priority | Phase | Effort | Complexity | Risk |
|---------|----------|-------|--------|------------|------|
| Map Display | P0 | 1 | 3w | High | Medium |
| NMEA Integration | P0 | 1 | 2w | Medium | Low |
| Boat Tracking | P0 | 1 | 1w | Low | Low |
| Weather Overlays | P0 | 1 | 3w | High | High |
| Glass UI Library | P0 | 1 | 2w | Medium | Low |
| Forecasting | P1 | 2 | 2w | Medium | Low |
| Timeline Playback | P1 | 2 | 2w | Medium | Medium |
| Navigation Mode | P1 | 2 | 1w | Low | Low |
| Draggable Wind Widgets | P1 | 2 | 1w | Low | Low |
| Dark Mode | P1 | 2 | 1w | Low | Low |
| Offline Mode | P1 | 2 | 2w | Medium | Medium |
| Settings | P2 | 3 | 1w | Low | Low |
| Harbor Alerts | P2 | 3 | 1w | Low | Low |
| AIS Integration | P2 | 3 | 2w | High | Medium |
| Tides | P2 | 3 | 1w | Low | Low |
| Trip Logging | P3 | 4 | 2w | Medium | Low |
| Social Sharing | P3 | 4 | 2w | Medium | High |

**Risk Levels:**
- **Low:** Well-understood, proven technology
- **Medium:** Some unknowns, new integration
- **High:** Novel approach, potential blockers

---

**Document End**
