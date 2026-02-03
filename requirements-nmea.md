# Requirements - FEAT-002 NMEA Data Integration

**Version:** 1.0  
**Date:** 2026-02-03  
**Priority:** P0 (Must Have)  
**Estimated Effort:** 2 weeks

---

## User Stories

### US-001: Connect to NMEA Device
As a navigator, I want to connect to my boat's NMEA 0183 data stream via TCP/UDP so that the app receives real-time navigation data.

### US-002: Display Boat Data
As a navigator, I want to see my current speed (SOG), course (COG), and depth displayed in real-time so that I can monitor critical navigation parameters.

### US-003: Wind Data
As a sailor, I want to see true wind speed and direction so that I can optimize sail trim and course.

### US-004: Auto-Reconnect
As a navigator, I want the app to automatically reconnect if the NMEA connection is lost so that I don't have to manually reconnect while underway.

---

## Acceptance Criteria (EARS Notation)

### Connection Management
- WHEN the user configures an NMEA connection (TCP or UDP), THE SYSTEM SHALL establish a connection within 5 seconds.
- WHEN the connection is established, THE SYSTEM SHALL display a "Connected" indicator in the UI.
- IF the connection fails, THEN THE SYSTEM SHALL retry with exponential backoff (1s, 2s, 4s, 8s, max 30s).
- WHEN the connection is lost, THE SYSTEM SHALL automatically attempt to reconnect.
- WHEN the user disconnects manually, THE SYSTEM SHALL close the connection and stop reconnection attempts.

### Data Parsing
- WHEN an NMEA sentence is received, THE SYSTEM SHALL validate the checksum before processing.
- IF the checksum is invalid, THEN THE SYSTEM SHALL log the error and skip the sentence.
- WHEN a valid GPGGA sentence is received, THE SYSTEM SHALL extract latitude, longitude, and GPS fix quality.
- WHEN a valid GPRMC sentence is received, THE SYSTEM SHALL extract position, speed over ground, and course over ground.
- WHEN a valid GPVTG sentence is received, THE SYSTEM SHALL extract course and speed.
- WHEN a valid MWV sentence is received, THE SYSTEM SHALL extract wind angle and wind speed.
- WHEN a valid DPT sentence is received, THE SYSTEM SHALL extract depth below transducer.
- IF an unknown sentence type is received, THEN THE SYSTEM SHALL log it and continue processing.

### Performance Requirements
- WHEN NMEA data is received at >100 messages/second, THE SYSTEM SHALL process it without blocking the UI thread.
- WHEN parsing NMEA data, THE SYSTEM SHALL use a background isolate to prevent UI jank.
- WHEN updates are processed, THE SYSTEM SHALL batch notifications every 200ms to avoid excessive rebuilds.
- WHEN the data rate exceeds 200 msg/s, THE SYSTEM SHALL throttle updates while maintaining latest values.

### Data Updates
- WHEN new GPS data is parsed, THE SYSTEM SHALL update the BoatProvider with current position.
- WHEN new speed/course data is parsed, THE SYSTEM SHALL update NavigationModeScreen data orbs.
- WHEN new wind data is parsed, THE SYSTEM SHALL update wind displays.
- WHEN new depth data is parsed, THE SYSTEM SHALL update depth display and trigger depth alarms if configured.

### Error Handling
- IF incomplete sentences remain in the buffer, THEN THE SYSTEM SHALL retain them for the next read.
- IF the buffer exceeds 10KB, THEN THE SYSTEM SHALL clear it and log a warning.
- WHEN a malformed sentence is detected, THE SYSTEM SHALL skip it and continue processing.
- WHEN the connection times out (>30s no data), THE SYSTEM SHALL show "No data" status.

---

## Constraints

- All NMEA parsing MUST occur in a background Dart isolate (prevents ISS-009: UI blocking)
- NMEAProvider MUST be Layer 2 (depends on SettingsProvider for connection config)
- Files MUST stay under 300 lines each
- All controllers/subscriptions MUST be disposed
- No hardcoded connection parameters (read from SettingsProvider)
- Support NMEA 0183 standard only (not NMEA 2000)

---

## Out of Scope (This Increment)

- AIS data parsing (AIVDM sentences) - deferred to FEAT-011
- NMEA output (sending commands to devices)
- Bluetooth NMEA connections (TCP/UDP only)
- NMEA 2000 (PGN-based) support
- Autopilot integration
- Sentence filtering/routing

---

## Dependencies

### Upstream (Must exist first)
- ✅ SettingsProvider (Layer 0) - for connection configuration
- ✅ ThemeProvider (Layer 1) - for UI status indicators
- ✅ CacheProvider (Layer 1) - for storing connection history

### Downstream (Will use this)
- 🔜 BoatProvider (Layer 2) - will consume GPS/speed/heading data
- 🔜 NavigationModeScreen - will display SOG/COG/DEPTH in DataOrbs
- 🔜 Weather overlays - will use position for weather queries

---

## Technical Notes

### NMEA 0183 Format
```
$<talker><sentence_type>,<data_field_1>,<data_field_2>,...*<checksum>\r\n

Example:
$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
```

### Checksum Calculation
```dart
// XOR of all bytes between $ and *
int calculateChecksum(String sentence) {
  final bytes = sentence.codeUnits;
  int checksum = 0;
  for (int i = 1; i < bytes.length; i++) { // Skip $
    if (String.fromCharCode(bytes[i]) == '*') break;
    checksum ^= bytes[i];
  }
  return checksum;
}
```

### Supported Sentences (Phase 1)

| Type | Description | Priority | Fields |
|------|-------------|----------|--------|
| GPGGA | GPS Fix Data | P0 | Time, Lat, Lon, Fix Quality, Satellites, HDOP, Altitude |
| GPRMC | Recommended Minimum | P0 | Time, Status, Lat, Lon, Speed, Course, Date |
| GPVTG | Track & Speed | P1 | True Track, Magnetic Track, Speed (knots), Speed (km/h) |
| MWV | Wind Speed & Angle | P1 | Wind Angle, Reference (R/T), Speed, Unit, Status |
| DPT | Depth | P1 | Depth, Offset, Max Range |

### Performance Budget
- **Parse time:** <1ms per sentence (target)
- **Update latency:** <200ms from receive to UI update
- **Memory:** <10MB for buffers and state
- **CPU:** Background isolate, <5% main thread usage

---

## Testing Requirements

### Unit Tests (≥80% coverage)
- [ ] Checksum validation (valid/invalid)
- [ ] GPGGA parsing
- [ ] GPRMC parsing
- [ ] GPVTG parsing
- [ ] MWV parsing
- [ ] DPT parsing
- [ ] Buffer handling (incomplete sentences)
- [ ] Error cases (malformed, unknown types)

### Integration Tests
- [ ] TCP connection establishment
- [ ] UDP connection establishment
- [ ] Auto-reconnect on connection loss
- [ ] Data flow: NMEA → Parser → Provider → UI
- [ ] High data rate (100+ msg/s)

### Widget Tests
- [ ] Connection status indicator
- [ ] Data orbs update with parsed data
- [ ] Error messages display correctly

---

## Success Metrics

- ✅ Connect to NMEA device within 5 seconds
- ✅ Parse all P0 sentence types correctly
- ✅ Update UI at 1 Hz minimum
- ✅ No UI jank at 200 msg/s data rate
- ✅ Auto-reconnect within 30 seconds of connection loss
- ✅ 80% test coverage
- ✅ All files under 300 lines
