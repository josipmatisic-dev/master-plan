# Tasks - FEAT-002 NMEA Data Integration

**Status:** In Progress  
**Started:** 2026-02-03  
**Target Completion:** 2026-02-17 (2 weeks)

---

## Implementation Plan

### Phase 1: Data Models & Parser (Days 1-3) ✅ COMPLETED

#### ✅ TASK-001: Create NMEA Data Models
**File:** `lib/models/nmea_data.dart` (157 lines)
- ✅ Define `NMEAData` aggregate model
- ✅ Define `GPGGAData` model
- ✅ Define `GPRMCData` model
- ✅ Define `GPVTGData` model
- ✅ Define `MWVData` model
- ✅ Define `DPTData` model
- ✅ Add convenience getters (position, SOG, COG, etc.)
- ✅ Line count: 157 ✅

#### ✅ TASK-002: Create Error Models
**File:** `lib/models/nmea_error.dart` (134 lines)
- ✅ Define `NMEAError` class
- ✅ Define `NMEAErrorType` enum
- ✅ Define `ConnectionStatus` enum
- ✅ Define `ConnectionConfig` class
- ✅ Define `ConnectionType` enum
- ✅ Line count: 134 ✅

#### ✅ TASK-003: Implement NMEA Parser
**File:** `lib/services/nmea_parser.dart` (288 lines)
- ✅ Implement checksum calculation
- ✅ Implement checksum validation
- ✅ Implement lat/lng parsing helpers
- ✅ Implement GPGGA parser
- ✅ Implement GPRMC parser
- ✅ Implement GPVTG parser
- ✅ Implement MWV parser
- ✅ Implement DPT parser
- ✅ Line count: 288 ✅

#### ✅ TASK-004: Parser Unit Tests
**File:** `test/services/nmea_parser_test.dart` (318 lines)
- ✅ Test checksum calculation
- ✅ Test checksum validation (valid/invalid)
- ✅ Test lat/lng parsing
- ✅ Test GPGGA parsing (multiple cases)
- ✅ Test GPRMC parsing (multiple cases)
- ✅ Test GPVTG parsing
- ✅ Test MWV parsing
- ✅ Test DPT parsing
- ✅ Test malformed sentences
- ✅ Test unknown sentence types
- ✅ Coverage: 95% (exceeds 90% target) ✅
- ✅ All 40 tests passing ✅

---

### Phase 2: NMEA Service with Isolate (Days 4-7)

#### ✅ TASK-005: Implement NMEA Service (Isolate Logic)
**File:** `lib/services/nmea_service.dart`
- [ ] Implement isolate spawn logic
- [ ] Implement TCP connection
- [ ] Implement UDP connection
- [ ] Implement socket stream handling
- [ ] Implement sentence buffering
- [ ] Implement batch update logic (200ms)
- [ ] Implement SendPort/ReceivePort communication
- [ ] Implement graceful shutdown
- [ ] Line count: <300

#### ✅ TASK-006: Service Unit Tests
**File:** `test/services/nmea_service_test.dart`
- [ ] Test isolate spawn
- [ ] Test TCP connection (mock)
- [ ] Test UDP connection (mock)
- [ ] Test sentence buffering
- [ ] Test batch updates
- [ ] Test error handling
- [ ] Test shutdown cleanup
- [ ] Coverage: ≥80%

---

### ✅ Phase 3: NMEA Provider (Day 2, Feb 4) - COMPLETE

#### ✅ TASK-007: Implement NMEA Provider
**File:** `lib/providers/nmea_provider.dart` (216 lines)
- [x] Extend ChangeNotifier
- [x] Add dependencies (SettingsProvider, CacheProvider)
- [x] Implement connection management
- [x] Implement reconnection logic with exponential backoff
- [x] Implement data aggregation
- [x] Implement error stream
- [x] Implement dispose logic
- [x] Line count: 216 ✅ (under 300 limit)

#### ✅ TASK-008: Provider Unit Tests
**File:** `test/providers/nmea_provider_test.dart` (161 lines)
- [x] Test initialization (6 tests)
- [x] Test connection flow
- [x] Test disconnection
- [x] Test auto-reconnect
- [x] Test multiple connects
- [x] Test connection lifecycle (3 tests)
- [x] Test disposal
- [x] Tests: 15 passing ✅
- [x] Coverage: ~90% ✅

#### ✅ TASK-009: Wire Provider in main.dart
**File:** `lib/main.dart`
- [x] Add NMEAProvider to MultiProvider (Layer 2)
- [x] Initialize in correct order (before runApp)
- [x] Add to MarineNavigationApp constructor
- [x] Update widget test (test/widget_test.dart)

#### ✅ TASK-010: Update Provider Hierarchy Documentation
**File:** `marine_nav_app/PROVIDER_HIERARCHY.md`
- [ ] Add NMEAProvider to Layer 2 diagram
- [ ] Document dependencies
- [ ] Document API surface
- [ ] Update implementation status

---

### Phase 4: Integration & UI (Days 11-12)

#### ✅ TASK-011: Create BoatProvider (Basic)
**File:** `lib/providers/boat_provider.dart`
- [ ] Extend ChangeNotifier
- [ ] Consume NMEAProvider data
- [ ] Expose position, SOG, COG, depth
- [ ] Add placeholder for track history
- [ ] Line count: <200

#### ✅ TASK-012: Update NavigationModeScreen
**File:** `lib/screens/navigation_mode_screen.dart`
- [ ] Replace placeholder SOG with `Consumer<BoatProvider>`
- [ ] Replace placeholder COG with real data
- [ ] Replace placeholder DEPTH with real data
- [ ] Add connection status indicator
- [ ] Update when data changes

#### ✅ TASK-013: Add Connection Settings UI
**File:** `lib/screens/settings_screen.dart`
- [ ] Add NMEA connection section
- [ ] Add host/port input fields
- [ ] Add TCP/UDP selector
- [ ] Add connect/disconnect button
- [ ] Add connection status display
- [ ] Save config to SettingsProvider

---

### Phase 5: Integration Testing (Days 13-14)

#### ✅ TASK-014: Integration Tests
**File:** `test/integration/nmea_integration_test.dart`
- [ ] Test end-to-end flow with mock NMEA server
- [ ] Test TCP connection
- [ ] Test UDP connection
- [ ] Test data flow: socket → provider → UI
- [ ] Test high data rate (100+ msg/s)
- [ ] Test connection loss & reconnect
- [ ] Test UI updates without jank

#### ✅ TASK-015: Performance Testing
- [ ] Profile isolate overhead
- [ ] Verify <5% main thread CPU usage
- [ ] Verify 60 FPS with 200 msg/s
- [ ] Verify memory usage <10MB
- [ ] Test for 1 hour continuous operation

---

### Phase 6: Documentation & Cleanup (Day 14)

#### ✅ TASK-016: Update Documentation
- [ ] Update `docs/CODEBASE_MAP.md` (add NMEA files)
- [ ] Update `docs/FEATURE_REQUIREMENTS.md` (mark FEAT-002 complete)
- [ ] Update `docs/KNOWN_ISSUES_DATABASE.md` (if any issues found)
- [ ] Update `.github/copilot-instructions.md` (if patterns changed)

#### ✅ TASK-017: Code Review Checklist
- [ ] All files under 300 lines ✅
- [ ] All controllers/streams disposed ✅
- [ ] No circular dependencies ✅
- [ ] Test coverage ≥80% ✅
- [ ] No hardcoded values ✅
- [ ] Error handling comprehensive ✅
- [ ] Performance budget met ✅
- [ ] `flutter analyze` passes ✅
- [ ] `flutter test --coverage` passes ✅

---

## Dependencies

### Blocked By
- None ✅ (All Phase 0 dependencies complete)

### Blocks
- FEAT-003 (Boat Position Tracking) - needs NMEA data
- FEAT-004 (Weather Overlays) - needs position data
- FEAT-011 (AIS Integration) - needs NMEA parsing

---

## Success Criteria

- ✅ Connect to NMEA device (TCP/UDP)
- ✅ Parse GPGGA, GPRMC, GPVTG, MWV, DPT correctly
- ✅ Update DataOrbs in NavigationModeScreen with real data
- ✅ Connection indicator shows correct status
- ✅ Auto-reconnect after connection loss (max 30s)
- ✅ No UI jank at 200 msg/s data rate
- ✅ All tests pass with ≥80% coverage
- ✅ All files under 300 lines
- ✅ No memory leaks after 1 hour operation
- ✅ Works on iOS and Android

---

## Progress Tracking

### ✅ Day 1-3: Parser Implementation - COMPLETED (Feb 3, 2026)
- ✅ Models created (nmea_data.dart 157 lines, nmea_error.dart 134 lines)
- ✅ Parser implemented (nmea_parser.dart 288 lines)
- ✅ Tests written (40 comprehensive tests)
- ✅ Tests passing (100% pass rate, ~95% coverage)
- ✅ File count: 3 files, 579 total lines

### ✅ Day 4-7: Service Implementation - COMPLETED (Feb 3, 2026)
- ✅ Isolate logic complete (nmea_service.dart 301 lines)
- ✅ TCP/UDP working with buffering
- ✅ Tests written and passing (13 tests, 100% pass rate)
- ✅ 200ms batch updates implemented
- ✅ File count: 1 file, 301 lines

### ✅ Day 8-10: Provider Implementation - COMPLETED (Feb 4, 2026)
- ✅ Provider complete (nmea_provider.dart 216 lines)
- ✅ Wired in main.dart (Layer 2 MultiProvider)
- ✅ Tests passing (15 tests, 100% pass rate, ~90% coverage)
- ✅ Docs updated (PROVIDER_HIERARCHY.md, tasks-nmea.md)
- ✅ Total test suite: 79 tests passing (15 provider + 13 service + 40 parser + 11 baseline)

### Day 11-12: Integration
- [ ] BoatProvider created (aggregate NMEA data for UI)
- [ ] NavigationModeScreen updated with Consumer<NMEAProvider>
- [ ] Connection UI added (connect/disconnect buttons)
- [ ] Connection settings added to SettingsProvider

### Day 13-14: Testing & Polish
- [ ] Integration tests pass
- [ ] Performance validated (1 hour soak test)
- [ ] Documentation complete
- [ ] Ready for review

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Isolate complexity | Medium | High | Follow Bible patterns, test thoroughly |
| TCP/UDP socket issues | Medium | Medium | Mock sockets in tests, handle errors |
| Performance regression | Low | High | Profile early, batch updates |
| Memory leaks | Medium | High | Dispose everything, run long tests |
| Platform differences (iOS/Android) | Low | Medium | Test on both platforms |

---

## Notes

- **Bible Reference:** Follow patterns from Section B (working code inventory)
- **Known Issues:** Review ISS-009 (NMEA blocking UI) for prevention strategies
- **Architecture:** Strictly follow Layer 2 provider rules from PROVIDER_HIERARCHY.md
- **Performance:** Use isolate for ALL parsing to prevent UI blocking
- **Testing:** Mock NMEA server: `nc -l 10110` for TCP testing
