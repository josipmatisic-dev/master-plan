# Design - FEAT-002 NMEA Data Integration

**Version:** 1.0  
**Date:** 2026-02-03  
**Status:** Draft

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Component Design](#component-design)
3. [Data Models](#data-models)
4. [Data Flow](#data-flow)
5. [API Specifications](#api-specifications)
6. [Error Handling Strategy](#error-handling-strategy)
7. [Performance Considerations](#performance-considerations)
8. [Testing Strategy](#testing-strategy)

---

## Architecture Overview

### System Context

```text
┌─────────────────────────────────────────────────────────┐
│                    Marine Nav App                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │          NMEAProvider (Layer 2)                  │  │
│  │  - Connection state management                   │  │
│  │  - Data aggregation                              │  │
│  │  - Provider notifications                        │  │
│  └─────────────────┬────────────────────────────────┘  │
│                    │                                    │
│  ┌─────────────────▼────────────────────────────────┐  │
│  │         NMEAService (Isolate)                    │  │
│  │  - TCP/UDP socket handling                       │  │
│  │  - Sentence parsing & validation                 │  │
│  │  - Checksum verification                         │  │
│  └─────────────────┬────────────────────────────────┘  │
│                    │                                    │
└────────────────────┼─────────────────────────────────────┘
                     │
              ┌──────▼──────┐
              │ NMEA Device │
              │  (TCP/UDP)  │
              └─────────────┘
```text

### Provider Hierarchy Integration

```text
Layer 0: SettingsProvider (connection config)
         │
Layer 1: CacheProvider (connection history)
         │
Layer 2: NMEAProvider ◄─── NEW
         │
         ├─► BoatProvider (consumes GPS/speed/heading)
         └─► WeatherProvider (consumes position)
```text

---

## Component Design

### 1. NMEAProvider (Layer 2)

**Responsibility:** Manage NMEA connection lifecycle and expose parsed data to the app.

**File:** `lib/providers/nmea_provider.dart`

**Public API:**

```dart
class NMEAProvider extends ChangeNotifier {
  // State
  ConnectionStatus get status;
  NMEAData? get currentData;
  DateTime? get lastUpdate;
  Stream<NMEAError> get errors;
  
  // Actions
  Future<void> connect(ConnectionConfig config);
  Future<void> disconnect();
  Future<void> reconnect();
  
  // Lifecycle
  Future<void> init();
  @override
  void dispose();
}
```text

**Dependencies:**

- `SettingsProvider` - for connection configuration
- `CacheProvider` - for caching last known position
- `NMEAService` - for actual parsing (via isolate)

**Line Count Target:** <250 lines

---

### 2. NMEAService (Background Isolate)

**Responsibility:** Handle low-level TCP/UDP communication and NMEA parsing without blocking UI.

**File:** `lib/services/nmea_service.dart`

**Public API:**

```dart
class NMEAService {
  static Future<void> startIsolate(SendPort sendPort);
  static Future<void> connect(String host, int port, ConnectionType type);
  static Future<void> disconnect();
  
  // Internal parsing (not exposed)
  static NMEASentence? parseSentence(String raw);
  static bool validateChecksum(String sentence);
}
```text

**Isolate Communication:**

- **Main → Isolate:** Connection commands (connect, disconnect)
- **Isolate → Main:** Parsed data, errors, status updates

**Line Count Target:** <300 lines

---

### 3. NMEA Parser

**Responsibility:** Parse individual NMEA sentences into structured data.

**File:** `lib/services/nmea_parser.dart`

**Parsers:**

```dart
class NMEAParser {
  static GPGGAData? parseGPGGA(List<String> fields);
  static GPRMCData? parseGPRMC(List<String> fields);
  static GPVTGData? parseGPVTG(List<String> fields);
  static MWVData? parseMWV(List<String> fields);
  static DPTData? parseDPT(List<String> fields);
  
  // Utility
  static int calculateChecksum(String sentence);
  static bool validateChecksum(String sentence);
  static double parseLatitude(String value, String hemisphere);
  static double parseLongitude(String value, String hemisphere);
}
```text

**Line Count Target:** <250 lines

---

## Data Models

### Connection Models

```dart
enum ConnectionType { tcp, udp }

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ConnectionConfig {
  final String host;
  final int port;
  final ConnectionType type;
  final Duration timeout;
  final bool autoReconnect;
  
  const ConnectionConfig({
    required this.host,
    required this.port,
    this.type = ConnectionType.tcp,
    this.timeout = const Duration(seconds: 10),
    this.autoReconnect = true,
  });
}
```text

### NMEA Data Models

```dart
class NMEAData {
  final GPGGAData? gpgga;
  final GPRMCData? gprmc;
  final GPVTGData? gpvtg;
  final MWVData? mwv;
  final DPTData? dpt;
  final DateTime timestamp;
  
  const NMEAData({
    this.gpgga,
    this.gprmc,
    this.gpvtg,
    this.mwv,
    this.dpt,
    required this.timestamp,
  });
  
  // Convenience getters
  LatLng? get position => gpgga?.position ?? gprmc?.position;
  double? get speedOverGround => gprmc?.speedKnots ?? gpvtg?.speedKnots;
  double? get courseOverGround => gprmc?.trackDegrees ?? gpvtg?.trackTrue;
  double? get depth => dpt?.depthMeters;
  WindData? get wind => mwv != null 
    ? WindData(speed: mwv!.speedKnots, direction: mwv!.angleDegrees)
    : null;
}

class GPGGAData {
  final LatLng position;
  final DateTime time;
  final int fixQuality;      // 0=invalid, 1=GPS, 2=DGPS
  final int satellites;
  final double? hdop;
  final double? altitudeMeters;
  
  const GPGGAData({
    required this.position,
    required this.time,
    required this.fixQuality,
    required this.satellites,
    this.hdop,
    this.altitudeMeters,
  });
}

class GPRMCData {
  final LatLng position;
  final DateTime dateTime;
  final double? speedKnots;
  final double? trackDegrees;
  final bool isValid;
  
  const GPRMCData({
    required this.position,
    required this.dateTime,
    this.speedKnots,
    this.trackDegrees,
    required this.isValid,
  });
}

class GPVTGData {
  final double? trackTrue;      // True track (degrees)
  final double? trackMagnetic;  // Magnetic track (degrees)
  final double? speedKnots;
  final double? speedKmh;
  
  const GPVTGData({
    this.trackTrue,
    this.trackMagnetic,
    this.speedKnots,
    this.speedKmh,
  });
}

class MWVData {
  final double angleDegrees;    // Wind angle (0-360)
  final String reference;       // 'R'=relative, 'T'=true
  final double speedKnots;
  final bool isValid;
  
  const MWVData({
    required this.angleDegrees,
    required this.reference,
    required this.speedKnots,
    required this.isValid,
  });
}

class DPTData {
  final double depthMeters;
  final double? offsetMeters;
  final double? maxRangeMeters;
  
  const DPTData({
    required this.depthMeters,
    this.offsetMeters,
    this.maxRangeMeters,
  });
}
```text

### Error Model

```dart
class NMEAError {
  final NMEAErrorType type;
  final String message;
  final DateTime timestamp;
  final String? sentence;
  
  const NMEAError({
    required this.type,
    required this.message,
    required this.timestamp,
    this.sentence,
  });
}

enum NMEAErrorType {
  connection,
  timeout,
  checksum,
  parsing,
  buffer,
  unknown,
}
```text

---

## Data Flow

### Connection Flow

```text
[User] → [SettingsProvider] → [NMEAProvider.connect()]
                                      ↓
                              [Spawn Isolate]
                                      ↓
                              [NMEAService.connect()]
                                      ↓
                              [Socket.connect()]
                                      ↓
                              [Status: connected] → [SendPort → Main]
                                      ↓
                              [NMEAProvider.notifyListeners()]
                                      ↓
                              [UI: Connection indicator]
```text

### Data Processing Flow

```text
[NMEA Device] → [Socket Stream]
                      ↓
              [Isolate Buffer]
                      ↓
              [Split by \r\n]
                      ↓
        [For each sentence:]
              ↓
        [Validate Checksum]
              ↓ (valid)
        [Parse by Type]
              ↓
        [Create Data Object]
              ↓
        [Batch Updates (200ms)]
              ↓
        [SendPort → Main]
              ↓
        [NMEAProvider.update()]
              ↓
        [notifyListeners()]
              ↓
        [Consumer<NMEAProvider>]
              ↓
        [Update DataOrbs]
```text

### Error Flow

```text
[Parse Error] → [Log to Console]
                      ↓
              [Create NMEAError]
                      ↓
              [Send to Error Stream]
                      ↓
              [Provider.errors.add()]
                      ↓
              [UI: Error Snackbar]
```text

---

## API Specifications

### NMEAProvider API

#### Connection Management

```dart
// Connect to NMEA device
Future<void> connect(ConnectionConfig config) async {
  if (_status == ConnectionStatus.connected) {
    await disconnect();
  }
  
  _status = ConnectionStatus.connecting;
  notifyListeners();
  
  try {
    await _service.connect(config);
    _status = ConnectionStatus.connected;
  } catch (e) {
    _status = ConnectionStatus.error;
    _errorController.add(NMEAError(
      type: NMEAErrorType.connection,
      message: e.toString(),
      timestamp: DateTime.now(),
    ));
  }
  
  notifyListeners();
}

// Disconnect from device
Future<void> disconnect() async {
  await _service.disconnect();
  _status = ConnectionStatus.disconnected;
  notifyListeners();
}

// Reconnect with backoff
Future<void> reconnect() async {
  if (!_config.autoReconnect) return;
  
  _status = ConnectionStatus.reconnecting;
  notifyListeners();
  
  for (int attempt = 0; attempt < 5; attempt++) {
    final delay = Duration(seconds: math.min(30, math.pow(2, attempt).toInt()));
    await Future.delayed(delay);
    
    try {
      await connect(_config);
      return;
    } catch (e) {
      // Continue to next attempt
    }
  }
  
  _status = ConnectionStatus.error;
  notifyListeners();
}
```text

#### Data Access

```dart
// Get latest NMEA data
NMEAData? get currentData => _currentData;

// Get last update timestamp
DateTime? get lastUpdate => _lastUpdate;

// Stream of errors
Stream<NMEAError> get errors => _errorController.stream;

// Connection status
ConnectionStatus get status => _status;
```text

---

## Error Handling Strategy

### Checksum Errors

- **Action:** Log warning, skip sentence, continue processing
- **User Impact:** None (silent)
- **Logging:** Debug level

### Malformed Sentences

- **Action:** Log error, skip sentence, continue processing
- **User Impact:** None (silent)
- **Logging:** Warning level

### Connection Timeout

- **Action:** Auto-reconnect with exponential backoff
- **User Impact:** "Reconnecting..." indicator
- **Logging:** Info level

### Buffer Overflow

- **Action:** Clear buffer, log error
- **User Impact:** Data loss for that cycle
- **Logging:** Error level

### Unknown Sentence Types

- **Action:** Log info, skip sentence
- **User Impact:** None
- **Logging:** Debug level

---

## Performance Considerations

### Isolate Strategy

- **Main thread:** UI updates, provider state
- **Background isolate:** Socket I/O, parsing, checksum validation
- **Communication:** SendPort/ReceivePort with batched messages

### Batching Strategy

```dart
// Accumulate parsed data for 200ms before sending to main
Timer.periodic(Duration(milliseconds: 200), (timer) {
  if (_batchedData.isNotEmpty) {
    sendPort.send(_batchedData);
    _batchedData.clear();
  }
});
```text

### Memory Management

- **Buffer limit:** 10KB (clear if exceeded)
- **Parsed data cache:** Last 10 sentences per type
- **Error log:** Last 100 errors (circular buffer)

### Throttling

```dart
// If data rate > 200 msg/s, sample every Nth message
if (_messageRate > 200) {
  final skipFactor = (_messageRate / 100).floor();
  if (_messageCount % skipFactor != 0) {
    return; // Skip this message
  }
}
```text

---

## Testing Strategy

### Unit Tests

**nmea_parser_test.dart:**

- ✅ Checksum calculation
- ✅ Checksum validation
- ✅ Latitude/longitude parsing
- ✅ GPGGA parsing (valid/invalid)
- ✅ GPRMC parsing (valid/invalid)
- ✅ GPVTG parsing (valid/invalid)
- ✅ MWV parsing (valid/invalid)
- ✅ DPT parsing (valid/invalid)
- ✅ Malformed sentence handling
- ✅ Unknown sentence type handling

**nmea_provider_test.dart:**

- ✅ Connection state transitions
- ✅ Auto-reconnect logic
- ✅ Data aggregation
- ✅ Error handling
- ✅ Disposal cleanup

### Integration Tests

**nmea_integration_test.dart:**

- ✅ End-to-end: Mock NMEA stream → UI update
- ✅ TCP connection establishment
- ✅ UDP connection establishment
- ✅ Connection loss → reconnect
- ✅ High data rate (100+ msg/s)

### Mock Data

```dart
const mockNMEASentences = [
  r'$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47',
  r'$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W*6A',
  r'$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48',
  r'$MWV,045,R,10.5,N,A*2F',
  r'$DPT,8.5,0.0,*4D',
];
```text

---

## File Structure

```text
lib/
├── models/
│   ├── nmea_data.dart           # All NMEA data models
│   └── nmea_error.dart          # Error types
├── providers/
│   └── nmea_provider.dart       # Layer 2 provider
└── services/
    ├── nmea_service.dart        # Isolate + socket handling
    └── nmea_parser.dart         # Sentence parsing

test/
├── services/
│   ├── nmea_parser_test.dart
│   └── nmea_service_test.dart
├── providers/
│   └── nmea_provider_test.dart
└── integration/
    └── nmea_integration_test.dart
```text

---

## Dependencies

**pubspec.yaml additions:**

```yaml
dependencies:
  # Already have flutter, provider
  
dev_dependencies:
  # Already have flutter_test, mockito
```text

**No new dependencies needed!** ✅ All functionality uses Dart core libraries.

---

## Implementation Order

1. ✅ Define data models (`nmea_data.dart`, `nmea_error.dart`)
2. ✅ Implement parser (`nmea_parser.dart`) + unit tests
3. ✅ Implement service with isolate (`nmea_service.dart`) + tests
4. ✅ Implement provider (`nmea_provider.dart`) + tests
5. ✅ Wire provider in `main.dart`
6. ✅ Update `PROVIDER_HIERARCHY.md`
7. ✅ Integration tests
8. ✅ Update documentation

---

## Acceptance Validation

- [ ] Connect to mock NMEA server (TCP)
- [ ] Receive and parse GPGGA, GPRMC correctly
- [ ] DataOrbs in NavigationModeScreen update in real-time
- [ ] Connection indicator shows "Connected"
- [ ] Disconnect/reconnect works
- [ ] Auto-reconnect after connection loss
- [ ] No UI jank at 100+ msg/s
- [ ] All tests pass with ≥80% coverage
- [ ] All files under 300 lines
- [ ] No memory leaks after 1 hour operation
