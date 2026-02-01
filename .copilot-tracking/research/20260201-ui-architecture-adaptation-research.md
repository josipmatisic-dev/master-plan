<!-- markdownlint-disable-file -->

# Research: UI Architecture Adaptation for SailStream

**Date:** 2026-02-01  
**Task:** Adapt master plan to exact UI architecture from SailStream design specifications  
**Status:** Research Complete

---

## Research Sources

### Primary Sources (Now Available)

1. **Copilot Chat Conversation** (sun_feb_01_2026_sail_stream_project_planning_and_architecture.md)
   - 292KB comprehensive planning document
   - Complete architecture analysis from 4 failed attempts
   - Detailed UI wireframes and specifications
   - "Ocean Glass" design philosophy
   - Social features integration plan

2. **UI Design Images** (5 mockups provided):
   - Image 1: Main map screen with "SailStream" branding
   - Image 2: Navigation mode with SOG/COG/DEPTH data orbs
   - Image 3: Wind widget interaction patterns
   - Image 4: Alternative wind widget layouts
   - Image 5: True wind data visualization

---

## Key Findings from Research

### Critical Lessons from Past Failures

From the Copilot conversation analysis (Lines 1-500):

#### Failure #1: Overlay Projection Mismatch
- **Problem**: Wind particles and overlays "stuck to screen" instead of following map
- **Root Cause**: Multiple coordinate projection systems used inconsistently
- **Solution**: Single MapViewportService as source of truth for all overlays

#### Failure #2: God Objects (MapScreen 3,839 lines)
- **Problem**: Single file handling map, weather, NMEA, playback, UI, persistence
- **Root Cause**: Organic growth without architectural planning
- **Solution**: Maximum 500 lines per file, strict separation of concerns

#### Failure #3: Provider Wiring Chaos
- **Problem**: ProviderNotFoundException crashes, duplicate singletons, state divergence
- **Root Cause**: Providers created in multiple places
- **Solution**: All providers created once in main.dart, strict dependency graph

#### Failure #4: UI Chaos When Adding Features
- **Problem**: Every new feature broke existing layouts
- **Root Cause**: No upfront UI planning, ad-hoc widget placement
- **Solution**: ALL screens designed in Figma/mockups BEFORE coding

#### Failure #5: Demo/Test Code Pollution
- **Problem**: Test functions scattered in production code causing bloat
- **Solution**: NO demo/test code in production files, test utilities in test/ only

---

## SailStream UI Architecture Requirements

### "Ocean Glass" Design Philosophy

From the conversation research, the core visual language is defined as:

1. **Data as Fluid Element**: Data flows and connects visually
2. **Contextual Priority & Holographic Layering**: Critical data expands, less critical recedes
3. **Ambient Intelligence**: UI adapts to time of day and weather conditions

### Design System Specifications

#### Color Palette
- **Deep Navy**: #0A1F3F (primary background)
- **Teal**: #1D566E (secondary)
- **Seafoam Green**: #00C9A7 (primary accent) - Note: glupa used this, docs mentioned #7EC8C1
- **Safety Orange**: #FF9A3D (alerts)
- **Coral Red**: #FF6B6B (danger)
- **Pure White**: #FFFFFF (text)

#### Typography
- **Font**: SF Pro Display (or Poppins as alternative)
- **Data Values**: 56pt bold
- **Headings**: 24pt semibold
- **Body**: 16pt regular
- **Labels**: 12pt medium, letter-spacing 0.5px

#### UI Components
- **Glass Cards**: Frosted glass with 12px radius, 80% opacity, backdrop blur (10px)
- **Circular Data Orbs**: 140px diameter with glowing rings
- **Rounded Corners**: 8-12px on all elements (polished sea glass aesthetic)
- **No Sharp Edges**: Everything rounded for safety and aesthetics

---

## Screen Structure Analysis

### From UI Images

#### Image 1: Main Map Screen ("SailStream")
- Left sidebar navigation with icons:
  - Dashboard
  - Map (highlighted in seafoam)
  - Weather
  - Settings
  - Profile
  - Boat icon at bottom
- Top: "SailStream" branding with search and location features
- Map background with wind particle visualization in cyan/teal flowing patterns
- Bottom center: Circular compass widget showing:
  - 15.2 kt (boat speed)
  - Wind: 15.2 kt N 45° (with direction indicator)
  - VR toggle
  - Compass rose in center (showing N direction)
  - Heading: N 25°
  - Additional navigation data (9x∩90, Laye 4 6°)
- Status bar: Battery 100%, signal strength, time 10:23

#### Image 2: Navigation Mode
- Top: "navigation mode" header with back button and settings icon
- Three large circular glass orbs at top:
  - **SOG** (Speed Over Ground): 7.2 kts
  - **COG** (Course Over Ground): 247° WSW
  - **DEPTH**: 12.4m
- Compass orb on right showing N/S/E/W directions
- Map view showing route with:
  - Dashed line from current position to waypoint
  - Boat icon at current position
  - Waypoint marker (Laink location)
  - Place names visible (Vaniets, Weav, Malsoes, Midsi, Fahck, FEIty, Wescerva, Extb)
- Bottom info card: "Next: Waypoint 1 | 2.4 nm | ETA 19 min"
- Action buttons: "+ Route", "Mark Position", "Track", "Alerts"

#### Image 3: Wind Widget Variations
- Multiple "TRUE WIND" circular widgets showing 14.2 kts NNE
- Various sizes and opacity levels demonstrated
- Frosted glass effect with seafoam green accent rings
- Circular progress indicator showing wind speed visually
- "AI" buttons in top corners
- "12tpx" indicator (likely zoom/scale)
- Trash/delete icon for removing widgets
- Page indicators at top (carousel dots)

#### Image 4: Widget Interaction States
- Demonstrates draggable/floating wind data widgets
- "TRUE WIND 14.2 kts NNE" in circular glass orbs
- Multiple instances show contextual positioning over map
- AI assistant buttons positioned strategically
- Page navigation dots indicating multi-panel interface

---

## Architecture Requirements

### Mandatory Project Structure

From conversation Lines 400-500, the required structure is:

```
lib/
├── main.dart                 # Provider setup ONLY (<100 lines)
├── app.dart                  # MaterialApp + routing (<100 lines)
├── core/
│   ├── constants/
│   │   ├── api_keys.dart
│   │   └── app_constants.dart
│   ├── theme/
│   │   └── ocean_theme.dart  # ALL colors, typography
│   └── utils/
│       ├── viewport_projector.dart  # THE ONLY projection utility
│       └── formatters.dart
├── data/
│   ├── models/
│   │   ├── map_viewport.dart
│   │   ├── vessel.dart
│   │   ├── weather_frame.dart
│   │   └── user_profile.dart
│   ├── repositories/
│   │   ├── weather_repository.dart
│   │   ├── vessel_repository.dart
│   │   └── user_repository.dart
│   └── services/
│       ├── nmea_service.dart
│       ├── http_service.dart
│       └── cache_service.dart
├── features/
│   ├── map/
│   │   ├── map_screen.dart           # <500 lines max
│   │   ├── controllers/
│   │   │   ├── map_viewport_service.dart
│   │   │   ├── playback_controller.dart
│   │   │   └── webview_bridge.dart
│   │   ├── overlays/
│   │   │   ├── overlay_host.dart
│   │   │   ├── wind_particle_layer.dart
│   │   │   ├── wave_layer.dart
│   │   │   └── current_layer.dart
│   │   └── widgets/
│   │       ├── time_bar.dart
│   │       ├── vessel_marker.dart
│   │       ├── compass_widget.dart
│   │       └── navigation_orbs.dart
│   ├── social/
│   │   ├── social_screen.dart
│   │   ├── yacht_profile_screen.dart
│   │   └── feed_screen.dart
│   ├── settings/
│   │   └── settings_screen.dart
│   └── connect/
│       └── connect_screen.dart
├── shared/
│   └── widgets/
│       ├── glass_card.dart
│       ├── ocean_button.dart
│       ├── data_orb.dart          # NEW: Circular glass data widget
│       └── wind_widget.dart       # NEW: Draggable wind indicator
└── routes/
    └── app_router.dart
```

---

## Critical Architecture Rules

### Rule 1: Single Source of Truth for Map Bounds
- ALL overlays MUST get bounds from MapViewportService
- NEVER calculate bounds independently in overlay widgets
- If viewport.isValid == false, render nothing

### Rule 2: File Size Limits
- No file may exceed 500 lines without explicit approval
- MapScreen is orchestration ONLY - no business logic
- If file approaches 400 lines, propose extraction

### Rule 3: Provider Discipline
- Providers created ONLY in main.dart
- NEVER create provider instances in widgets
- NEVER create duplicate singletons
- Always use context.read<T>() or context.watch<T>()

### Rule 4: Network Requests
- NEVER use http.get() directly
- ALWAYS use HttpService.getWithRetry()
- ALWAYS handle errors gracefully with user feedback

### Rule 5: Projection Consistency
- ALL lat/lon to screen conversions MUST use ViewportProjector
- NEVER write custom projection math in overlay widgets
- Test projections with debug grid overlay

### Rule 6: No Demo/Test Code in Production
- NO if (demoMode) in production files
- NO test utilities in lib/ directory
- Debug flags must be compile-time constants

### Rule 7: UI Changes Require Design Review
- NEVER add UI elements without checking design spec
- NEVER modify existing widget positions
- ALWAYS check responsive behavior on 3 screen sizes

---

## Feature Requirements

### MVP Core Features (Phase 1)

From conversation analysis, essential features are:

1. **Map Display** (P0)
   - MapTiler WebView integration
   - Smooth pan/zoom/rotate
   - Viewport synchronization with overlays

2. **NMEA WiFi Parsing** (P0)
   - Hardware-agnostic WiFi scanning
   - Real-time data parsing in Isolate
   - Position, speed, heading, depth, wind data

3. **Wind Particle Visualization** (P0)
   - Windy.com-style flowing particles
   - Cyan/teal colored particles
   - Performance: 60 FPS required

4. **Navigation Data Display** (P0)
   - SOG/COG/Depth orbs (from Image 2)
   - Compass widget (from Image 1)
   - True wind widget (from Images 3-4)
   - Route planning with waypoints

5. **Glass UI Components** (P0)
   - Frosted glass cards
   - Circular data orbs
   - Draggable widgets
   - Responsive layouts

### Phase 2 Features (Social Layer)

1. **User Authentication**
2. **Yacht Profile (Public/Private)**
3. **Live Position Sharing**
4. **Social Feed**
5. **Nearby Boats Display**

### Phase 3 Features (Engagement)

1. **Streaks/Badges**
2. **Push Notifications**
3. **Crew Management**
4. **Logbook**
5. **Harbor Alerts**

---

## Code to PORT from glupa (Working Code)

### Keep (Working Well)

From conversation Lines 350-400:

```
✅ lib/services/nmea_parser.dart - NMEA sentence parsing
✅ lib/services/forecast/forecast_http_client.dart - HTTP with retry
✅ lib/services/forecast/http_retry.dart - getWithRetry function
✅ lib/services/forecast/open_meteo_wind_source.dart - Weather API
✅ lib/services/forecast/forecast_cache_service.dart - Disk caching
✅ lib/utils/viewport_projector.dart - Projection math
✅ lib/models/map_viewport.dart - Viewport model
✅ lib/models/beaufort_scale.dart - Wind classification
✅ lib/theme/ocean_theme.dart - Color system
✅ assets/www/index.html - MapTiler WebView
```

### Rewrite (Architecture Problems)

```
⚠️ lib/screens/map_screen.dart - Split into components (was 3,839 lines)
⚠️ lib/widgets/forecast_overlay_host.dart - Simplify
⚠️ lib/services/forecast/forecast_state.dart - Clean up
⚠️ lib/widgets/quick_settings_panel.dart - Responsive redesign
```

---

## New UI Components Required

Based on image analysis:

### 1. Navigation Sidebar (Image 1)
- Vertical icon-based navigation
- Icons: Dashboard, Map, Weather, Settings, Profile, Boat
- Active state with seafoam green highlight
- Fixed left position on desktop/tablet
- Bottom sheet on mobile

### 2. Data Orb Widget (Image 2)
- Circular frosted glass container
- Large centered value (56pt bold)
- Label below (12pt medium)
- Optional subtitle (direction, units)
- Subtle glow effect on seafoam ring
- Sizes: Small (80px), Medium (140px), Large (200px)

### 3. Compass Widget (Image 1)
- Circular design with N/S/E/W markers
- Rotating compass rose
- Current heading display
- VR (Virtual Reality) toggle button
- Speed indicators around perimeter
- Boat speed and wind data integrated

### 4. True Wind Widget (Images 3-4)
- Draggable circular widget
- Circular progress indicator showing wind strength
- Wind speed and direction text
- Frosted glass background
- Seafoam green accent color
- Multiple instances supported
- Deletable (trash icon when editing)

### 5. Route Info Card (Image 2)
- Bottom-positioned info banner
- Next waypoint information
- Distance and ETA
- Frosted glass background
- Rounded corners

### 6. Action Button Bar (Image 2)
- Horizontal button layout
- Glass-style buttons: "+ Route", "Mark Position", "Track", "Alerts"
- Bottom-positioned above route card
- Responsive width

---

## Design System Implementation Plan

### Theme Structure

Create `lib/core/theme/ocean_theme.dart` with:

```dart
class OceanTheme {
  // Colors
  static const deepNavy = Color(0xFF0A1F3F);
  static const teal = Color(0xFF1D566E);
  static const seafoamGreen = Color(0xFF00C9A7);
  static const safetyOrange = Color(0xFFFF9A3D);
  static const coralRed = Color(0xFFFF6B6B);
  
  // Typography
  static const String fontFamily = 'SF Pro Display';
  static const dataValueStyle = TextStyle(fontSize: 56, fontWeight: FontWeight.bold);
  static const headingStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const bodyStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static const labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  
  // Glass Effects
  static const glassBlur = 10.0;
  static const glassOpacity = 0.8;
  static const borderRadius = 12.0;
}
```

---

## Success Criteria

### For Research Phase
- [x] Analyze all provided images
- [x] Extract design specifications
- [x] Document architecture requirements
- [x] Identify components to build
- [x] List code to port vs rewrite

### For Planning Phase
- [ ] Create detailed implementation plan
- [ ] Define component hierarchy
- [ ] Specify data flow architecture
- [ ] Document widget specifications
- [ ] Create testing strategy

### For Implementation Phase
- [ ] Set up project structure
- [ ] Implement glass UI components
- [ ] Build navigation framework
- [ ] Create data orb widgets
- [ ] Implement wind visualization
- [ ] Port working services from glupa
- [ ] Add social features infrastructure

---

## External References

- #file:../../docs/CODEBASE_MAP.md - Current planned structure
- #file:../../docs/MASTER_DEVELOPMENT_BIBLE.md - Failure analysis
- #file:../../docs/FEATURE_REQUIREMENTS.md - Feature specifications
- #file:../../docs/AI_AGENT_INSTRUCTIONS.md - Development guidelines
- Copilot Chat: sun_feb_01_2026_sail_stream_project_planning_and_architecture.md (292KB)

---

## Research Status Summary

- **Project Understanding**: ✅ Complete
- **Current Architecture**: ✅ Documented
- **Design Requirements**: ✅ Extracted from images and conversation
- **Implementation Specifications**: ✅ Detailed from research
- **External Resources**: ✅ All accessible and analyzed

**Status**: Ready to proceed with planning phase
