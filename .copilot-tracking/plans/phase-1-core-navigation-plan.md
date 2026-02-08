---
goal: Phase 1 Core Navigation - Map Display and GPS Tracking  
version: 1.0
date_created: 2026-02-01
last_updated: 2026-02-01
owner: Development Team
status: 'Planned'
tags: [navigation, map, gps, overlays, tracking]
---

# Phase 1: Core Navigation - Implementation Plan

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

**Duration:** Week 3-6 (20 working days)  
**Effort:** ~160 hours  
**Dependencies:** Phase 0 Complete

## Introduction

Phase 1 implements the core navigation features: interactive map display, GPS tracking, boat position marker, track
history, and basic weather overlays. This phase brings together the foundational architecture from Phase 0 with
user-facing navigation features.

**Key Objectives:**
- Implement MapTiler WebView integration with Flutter
- Synchronize WebView viewport with Flutter overlay layer
- Display real-time GPS position with heading indicator
- Render wind and wave overlays using ProjectionService
- Record and display boat track history
- Enable map interactions (zoom, pan, rotate)

**Success Metrics:**
- Map renders at 60 FPS during interactions
- GPS position updates every 1 second
- Overlays stay accurately positioned at all zoom levels
- Track history persists across app restarts
- Zero projection mismatch issues (ISS-001 avoided)
- Test coverage ≥80%

## 1. Requirements & Constraints

### Functional Requirements

- **REQ-101**: Map must render nautical charts and satellite imagery
- **REQ-102**: Support zoom levels 1-20 with smooth transitions
- **REQ-103**: GPS position displayed with heading arrow
- **REQ-104**: Track history with last 10,000 points, color-coded by speed
- **REQ-105**: Wind overlay with directional arrows
- **REQ-106**: Wave overlay with height indicators
- **REQ-107**: All overlays use ProjectionService for coordinate conversion (Avoid ISS-001)
- **REQ-108**: Map interactions must not block UI thread (60 FPS target)

### Architecture Requirements

- **REQ-109**: MapProvider maximum 300 lines
- **REQ-110**: All coordinate transforms through ProjectionService
- **REQ-111**: Viewport state synchronized between WebView and Flutter
- **REQ-112**: No synchronous I/O on main thread
- **REQ-113**: Dispose all animation controllers and subscriptions

### Security Requirements

- **SEC-101**: MapTiler API key from environment variables
- **SEC-102**: GPS permission requested with rationale
- **SEC-103**: Location data not transmitted without user consent

### Known Issues to Avoid

- **ISS-001**: CRITICAL - Overlay projection mismatch at zoom (wind/wave overlays drift)
- **ISS-006**: CRITICAL - Memory leaks from undisposed animation controllers
- **ISS-008**: MEDIUM - WebView JavaScript bridge sync lag (2-3 seconds)
- **ISS-012**: HIGH - Wind arrow direction inverted (meteorological vs mathematical)
- **ISS-018**: MEDIUM - GPS position jumping on reconnect

## 2. Implementation Steps

### Implementation Phase 1: Map WebView Integration

**GOAL-101**: Integrate MapTiler SDK in WebView with Flutter communication bridge

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-101 | Create MapWebView widget with webview_flutter | | |
| TASK-102 | Load MapTiler HTML with JavaScript bridge | | |
| TASK-103 | Implement viewport state message passing | | |
| TASK-104 | Add debounced map move event handler (200ms) to avoid ISS-008 | | |
| TASK-105 | Implement zoom in/out controls | | |
| TASK-106 | Implement map style switching (nautical/satellite) | | |
| TASK-107 | Add rotation gesture support | | |
| TASK-108 | Create widget tests for WebView integration | | |

### Implementation Phase 2: Viewport Synchronization

**GOAL-102**: Synchronize map viewport state between WebView and Flutter overlays (Prevent ISS-001)

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-109 | Create Viewport model with zoom/center/rotation/bounds | | |
| TASK-110 | Create MapProvider to manage viewport state (<300 lines) | | |
| TASK-111 | Implement viewport update from WebView events | | |
| TASK-112 | Add viewport bounds calculation | | |
| TASK-113 | Implement viewport to pixel transform using ProjectionService | | |
| TASK-114 | Add unit tests for viewport calculations | | |
| TASK-115 | Create integration test for WebView ↔ Flutter sync | | |

### Implementation Phase 3: GPS Location Service

**GOAL-103**: Integrate GPS location provider with permission handling (Avoid ISS-018)

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-116 | Add location package dependency | | |
| TASK-117 | Create LocationService wrapper | | |
| TASK-118 | Implement permission request flow | | |
| TASK-119 | Add location permission rationale dialog | | |
| TASK-120 | Implement continuous location updates (1 Hz) | | |
| TASK-121 | Add location accuracy filtering (>50m rejected) to prevent ISS-018 | | |
| TASK-122 | Implement mock location provider for testing | | |
| TASK-123 | Create unit tests for LocationService | | |

### Implementation Phase 4: Boat Position Tracking

**GOAL-104**: Display real-time boat position with heading indicator

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-124 | Create BoatProvider for position state (<300 lines) | | |
| TASK-125 | Create BoatPosition model with GPS data | | |
| TASK-126 | Implement position update from LocationService | | |
| TASK-127 | Create BoatMarker widget with heading arrow using ProjectionService | | |
| TASK-128 | Add position smoothing/filtering | | |
| TASK-129 | Implement speed/heading calculations | | |
| TASK-130 | Add "center on boat" button | | |
| TASK-131 | Create widget tests for BoatMarker | | |

### Implementation Phase 5: Track History Recording

**GOAL-105**: Record and persist boat track history

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-132 | Add sqflite dependency | | |
| TASK-133 | Create TrackPoint model | | |
| TASK-134 | Create TrackDatabase service | | |
| TASK-135 | Implement track point insertion (batched) | | |
| TASK-136 | Add track pruning (10,000 point limit) | | |
| TASK-137 | Implement track query by time range | | |
| TASK-138 | Add track deletion | | |
| TASK-139 | Create unit tests for TrackDatabase | | |

### Implementation Phase 6: Track History Display

**GOAL-106**: Render track history polyline on map with proper disposal (Avoid ISS-006)

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-140 | Create TrackOverlay widget | | |
| TASK-141 | Implement polyline rendering with CustomPaint | | |
| TASK-142 | Add speed-based color coding | | |
| TASK-143 | Optimize rendering for 10,000 points | | |
| TASK-144 | Add track visibility toggle | | |
| TASK-145 | Implement track clearing | | |
| TASK-146 | Ensure all controllers disposed in dispose() method | | |
| TASK-147 | Create widget tests for TrackOverlay | | |

### Implementation Phase 7: Wind Overlay

**GOAL-107**: Display wind vectors on map (Avoid ISS-001 and ISS-012)

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-148 | Create WindData model | | |
| TASK-149 | Create WindOverlay widget with CustomPaint | | |
| TASK-150 | Implement wind arrow rendering using ProjectionService | | |
| TASK-151 | Add wind direction conversion (meteorological to mathematical) to fix ISS-012 | | |
| TASK-152 | Implement wind speed to arrow size mapping | | |
| TASK-153 | Add wind overlay visibility toggle | | |
| TASK-154 | Create sample wind data for testing | | |
| TASK-155 | Verify arrows point correct direction (avoid ISS-012) | | |
| TASK-156 | Create widget tests for WindOverlay | | |

### Implementation Phase 8: Wave Overlay

**GOAL-108**: Display wave height and direction indicators (Avoid ISS-001)

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-157 | Create WaveData model | | |
| TASK-158 | Create WaveOverlay widget with CustomPaint | | |
| TASK-159 | Implement wave rendering using ProjectionService | | |
| TASK-160 | Add wave height circles | | |
| TASK-161 | Add wave direction indicators | | |
| TASK-162 | Implement height to circle size mapping | | |
| TASK-163 | Add wave overlay visibility toggle | | |
| TASK-164 | Create sample wave data for testing | | |
| TASK-165 | Create widget tests for WaveOverlay | | |

### Implementation Phase 9: Map Controls

**GOAL-109**: Add user controls for map interaction

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-166 | Create ZoomControls widget (+/- buttons) | | |
| TASK-167 | Create CompassWidget showing north direction | | |
| TASK-168 | Create LayerToggle widget for overlays | | |
| TASK-169 | Add map style switcher (nautical/satellite) | | |
| TASK-170 | Implement settings FAB for quick access | | |
| TASK-171 | Ensure all dispose() methods implemented (ISS-006) | | |
| TASK-172 | Create widget tests for all controls | | |

### Implementation Phase 10: Testing & Documentation

**GOAL-110**: Comprehensive testing and documentation updates

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-173 | Write unit tests for all services (≥80% coverage) | | |
| TASK-174 | Write widget tests for all widgets (≥80% coverage) | | |
| TASK-175 | Create integration test for full navigation flow | | |
| TASK-176 | Run performance profiling (60 FPS target) | | |
| TASK-177 | Test on low-end devices | | |
| TASK-178 | Update CODEBASE_MAP.md with Phase 1 components | | |
| TASK-179 | Update FEATURE_REQUIREMENTS.md with completed features | | |
| TASK-180 | Document any new issues discovered | | |

## 3. Alternatives

- **ALT-101**: Google Maps instead of MapTiler
  - Rejected: MapTiler has better nautical charts and offline support
  
- **ALT-102**: Native map view instead of WebView
  - Rejected: MapLibre GL JS in WebView provides better control
  
- **ALT-103**: Canvas rendering for map instead of WebView
  - Rejected: Too much effort, MapTiler SDK provides robust solution

## 4. Dependencies

### External Dependencies

- **DEP-101**: webview_flutter ^4.4.0 - WebView integration
- **DEP-102**: location ^5.0.0 - GPS location services
- **DEP-103**: sqflite ^2.3.0 - Local database for track history
- **DEP-104**: path ^1.8.0 - File path utilities
- **DEP-105**: MapTiler API account and key

### Phase Dependencies

- **DEP-106**: Phase 0 must be complete
- **DEP-107**: ProjectionService must be tested and working
- **DEP-108**: Provider architecture must be established

## 5. Files

### New Files

- **FILE-101**: `lib/widgets/map_webview.dart` - Map WebView container
- **FILE-102**: `lib/providers/map_provider.dart` - Map state management
- **FILE-103**: `lib/providers/boat_provider.dart` - Boat position state
- **FILE-104**: `lib/services/location_service.dart` - GPS location wrapper
- **FILE-105**: `lib/services/track_database.dart` - Track persistence
- **FILE-106**: `lib/models/track_point.dart` - Track point model
- **FILE-107**: `lib/widgets/overlays/boat_marker.dart` - Boat position marker
- **FILE-108**: `lib/widgets/overlays/track_overlay.dart` - Track history overlay
- **FILE-109**: `lib/widgets/overlays/wind_overlay.dart` - Wind vector overlay
- **FILE-110**: `lib/widgets/overlays/wave_overlay.dart` - Wave height overlay
- **FILE-111**: `lib/widgets/controls/zoom_controls.dart` - Zoom +/- buttons
- **FILE-112**: `lib/widgets/controls/compass_widget.dart` - North indicator
- **FILE-113**: `lib/widgets/controls/layer_toggle.dart` - Overlay toggles
- **FILE-114**: `lib/screens/map_screen.dart` - Main map screen
- **FILE-115**: `assets/map.html` - MapTiler HTML template

### Modified Files

- **FILE-116**: `docs/CODEBASE_MAP.md` - Add Phase 1 components
- **FILE-117**: `docs/FEATURE_REQUIREMENTS.md` - Update completed features
- **FILE-118**: `lib/main.dart` - Add Phase 1 providers

## 6. Testing

### Unit Tests

- **TEST-101**: Viewport calculations and transformations
- **TEST-102**: LocationService accuracy filtering
- **TEST-103**: TrackDatabase CRUD operations
- **TEST-104**: Wind direction conversion (meteorological to mathematical)
- **TEST-105**: ProjectionService integration with overlays
- **TEST-106**: BoatProvider position updates
- **TEST-107**: MapProvider viewport synchronization

### Widget Tests

- **TEST-108**: MapWebView rendering and initialization
- **TEST-109**: BoatMarker positioning and rotation
- **TEST-110**: WindOverlay arrow rendering and direction
- **TEST-111**: WaveOverlay circle rendering
- **TEST-112**: TrackOverlay polyline rendering
- **TEST-113**: All map controls (zoom, compass, toggles)

### Integration Tests

- **TEST-114**: Full map + GPS + tracking flow
- **TEST-115**: Overlay positioning at various zoom levels (ISS-001 check)
- **TEST-116**: Performance test with 10K track points (60 FPS target)
- **TEST-117**: Memory leak test (ISS-006 check)

## 7. Risks & Assumptions

### Risks

- **RISK-101**: WebView performance on low-end devices
  - Severity: Medium
  - Mitigation: Extensive device testing, fallback options
  
- **RISK-102**: GPS accuracy issues indoors/urban
  - Severity: Medium
  - Mitigation: Accuracy filtering, user feedback on location quality
  
- **RISK-103**: Overlay misalignment (ISS-001 recurrence)
  - Severity: Critical
  - Mitigation: Comprehensive testing at all zoom levels, ProjectionService validation

- **RISK-104**: Memory leaks from complex overlay rendering (ISS-006)
  - Severity: High
  - Mitigation: Strict dispose() implementation, memory profiling

### Assumptions

- **ASSUMPTION-101**: WebView supports MapLibre GL JS on all target devices
- **ASSUMPTION-102**: 1 Hz GPS update rate sufficient for marine navigation
- **ASSUMPTION-103**: 10K track points sufficient for typical usage
- **ASSUMPTION-104**: MapTiler API stable and performant

## 8. Related Specifications / Further Reading

### Primary Documentation

- [MASTER_DEVELOPMENT_BIBLE.md](../../docs/MASTER_DEVELOPMENT_BIBLE.md)
  - Section A.1: Map overlay projection mismatch (ISS-001)
  - Section A.6: Memory leaks from animation controllers (ISS-006)
  - Section A.8: WebView JavaScript bridge sync issues (ISS-008)
  - Section D.1: Core Features (Phase 1)
  
- [AI_AGENT_INSTRUCTIONS.md](../../docs/AI_AGENT_INSTRUCTIONS.md)
  - FA.3: Do NOT do manual coordinate math
  - FA.4: Do NOT skip disposal
  - CP.2: Map overlay rendering pattern
  
- [KNOWN_ISSUES_DATABASE.md](../../docs/KNOWN_ISSUES_DATABASE.md)
  - ISS-001: Overlay projection mismatch at zoom
  - ISS-006: Memory leak from AnimationControllers
  - ISS-008: WebView overlay sync lag
  - ISS-012: Wind arrow direction inverted
  - ISS-018: GPS position jumping on reconnect
  
- [FEATURE_REQUIREMENTS.md](../../docs/FEATURE_REQUIREMENTS.md)
  - FEAT-001: Interactive Map Display
  - FEAT-002: NMEA Data Integration
  - FEAT-003: Boat Position Tracking

### Detail Specifications

- [phase-1-core-navigation-details.md](../details/phase-1-core-navigation-details.md) - Detailed component specifications

### Implementation Prompt

- [implement-phase-1-core-navigation.prompt.md](../prompts/implement-phase-1-core-navigation.prompt.md) - Step-by-step implementation guide

---

**Phase 1 Completion Criteria:**

- [ ] All 180 tasks completed
- [ ] Map renders at 60 FPS during pan/zoom/rotate
- [ ] GPS position updates accurately every second
- [ ] Overlays stay correctly positioned at all zoom levels (ISS-001 prevented)
- [ ] Wind arrows point correct direction (ISS-012 prevented)
- [ ] No memory leaks detected (ISS-006 prevented)
- [ ] Track history persists across app restarts
- [ ] All tests passing (≥80% coverage)
- [ ] Documentation updated
- [ ] Ready for Phase 2 implementation

**Next Phase:** [Phase 2: Weather Intelligence](phase-2-weather-intelligence-plan.md)

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-01  
**Status:** Planned
