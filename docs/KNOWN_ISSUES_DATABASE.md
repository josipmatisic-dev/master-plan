# Known Issues Database

## Marine Navigation App - Issue Tracking & Solutions

**Version:** 5.0  
**Last Updated:** 2026-02-15  
**Purpose:** Comprehensive database of all issues encountered across 4 attempts

---

## Table of Contents

1. [How to Use This Database](#how-to-use-this-database)
2. [Issue Index](#issue-index)
3. [Detailed Issue Records](#detailed-issue-records)

---

## How to Use This Database

**Before writing code:**

1. Search for similar symptoms or error messages
2. Read root cause and prevention rule
3. Apply solution pattern to your code

**When encountering an error:**

1. Search for error message in this document
2. Follow solution steps
3. Update issue status if resolved
4. Add new issue if novel

**Issue Status Codes:**

- 🔴 **CRITICAL** - App crashes or data loss
- 🟠 **HIGH** - Feature broken or unusable
- 🟡 **MEDIUM** - Degraded performance or UX
- 🟢 **LOW** - Minor inconvenience
- ✅ **RESOLVED** - Fix implemented and verified
- 🔄 **IN PROGRESS** - Fix in development
- 📋 **DOCUMENTED** - Workaround available

---

## Issue Index

| ID | Title | Severity | Status | Attempt |
| ---- | ------- | ---------- | -------- | --------- |
| ISS-001 | Overlay projection mismatch at zoom | 🔴 CRITICAL | ✅ RESOLVED | 2, 4 |
| ISS-002 | MapController god object circular deps | 🔴 CRITICAL | ✅ RESOLVED | 1, 3 |
| ISS-003 | ProviderNotFoundException on hot reload | 🟠 HIGH | ✅ RESOLVED | 2 |
| ISS-004 | Stale weather data after fetch | 🟠 HIGH | ⚠️ PARTIAL | 3 |
| ISS-005 | RenderFlex overflow on small devices | 🟠 HIGH | ✅ RESOLVED | All |
| ISS-006 | Memory leak from AnimationControllers | 🔴 CRITICAL | ✅ RESOLVED | 2, 3 |
| ISS-007 | State inconsistency across screens | 🟠 HIGH | ✅ RESOLVED | 1, 4 |
| ISS-008 | WebView overlay sync lag | 🟡 MEDIUM | ✅ RESOLVED | 3, 4 |
| ISS-009 | NMEA parser blocking UI thread | 🔴 CRITICAL | ✅ RESOLVED | 2 |
| ISS-010 | Offline mode shows connection error | 🟠 HIGH | ✅ RESOLVED | 4 |
| ISS-011 | Checksum validation failing | 🟡 MEDIUM | ✅ RESOLVED | 1 |
| ISS-012 | Wind arrow direction inverted | 🟠 HIGH | ✅ RESOLVED | 2 |
| ISS-013 | Timeline playback memory overflow | 🔴 CRITICAL | ✅ RESOLVED | 3 |
| ISS-014 | WebView JavaScript bridge timeout | 🟡 MEDIUM | ✅ RESOLVED | 3 |
| ISS-015 | Dark mode not persisting | 🟢 LOW | ✅ RESOLVED | 2 |
| ISS-016 | AIS message buffer overflow | 🟠 HIGH | 🔄 IN PROGRESS | 4 |
| ISS-017 | Tile cache growing indefinitely | 🟠 HIGH | ✅ RESOLVED | 3 |
| ISS-018 | GPS position jumping on reconnect | 🟡 MEDIUM | ✅ RESOLVED | 4 |
| ISS-019 | CacheProvider shell — no backend | 🟠 HIGH | ✅ RESOLVED | Current |
| ISS-020 | NMEA data not cached across restarts | 🟡 MEDIUM | ✅ RESOLVED | Current |
| ISS-021 | Unused provider deps in NMEAProvider | 🟢 LOW | ✅ RESOLVED | Current |

---

## Detailed Issue Records

### ISS-001: Overlay Projection Mismatch at Zoom

**Issue ID:** ISS-001  
**Title:** Wind overlays render at wrong positions when zooming/panning  
**Category:** Rendering / Coordinate Systems  
**Severity:** 🔴 CRITICAL  
**Status:** ✅ RESOLVED  
**Repository:** Attempt 2, Attempt 4  
**Files Affected:**

- `lib/widgets/overlays/wind_overlay.dart`
- `lib/widgets/overlays/wave_overlay.dart`
- `lib/providers/map_provider.dart`

**Symptoms:**

- Wind arrows appear in wrong locations after zoom
- Overlays drift when panning map
- Rotation causes overlays to detach from positions
- Overlays correct positions disappear at zoom <10

#### Root Cause

Multiple coordinate projection systems used inconsistently:

1. MapTiler uses Web Mercator (EPSG:3857)
2. Weather data in WGS84 (EPSG:4326)
3. Direct lat/lng to pixel conversion without projection transform
4. No synchronization between WebView viewport and Flutter overlay

**Code Example (WRONG):**

```dart
class WindOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (final point in windPoints) {
      // BROKEN: Direct lat/lng to pixel
      final x = (point.lng + 180) * size.width / 360;
      final y = (90 - point.lat) * size.height / 180;
      
      canvas.drawCircle(Offset(x, y), 5, paint);
    }
  }
}
```text

**Solution:**

1. Create ProjectionService for all coordinate transforms
2. Use Web Mercator projection consistently
3. Synchronize viewport state between WebView and Flutter
4. Apply same transformations as map (zoom, pan, rotate)

**Code Example (CORRECT):**

```dart
class WindOverlayPainter extends CustomPainter {
  final Viewport viewport;
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final point in windPoints) {
      // CORRECT: Use ProjectionService
      final offset = ProjectionService.latLngToPixels(
        point.lat,
        point.lng,
        viewport,
      );
      
      // Check visibility
      if (offset.dx >= 0 && offset.dx <= size.width &&
          offset.dy >= 0 && offset.dy <= size.height) {
        canvas.drawCircle(offset, 5, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(WindOverlayPainter old) {
 return viewport != old.viewport | | windPoints != old.windPoints;
  }
}
```text

**Prevention Rule:**

- ALL coordinate conversions MUST go through ProjectionService
- Lint rule: no arithmetic on lat/lng variables
- Code review must verify projection usage
- Integration test with zoom/pan scenarios

---

### ISS-002: MapController God Object with Circular Dependencies

**Issue ID:** ISS-002  
**Title:** MapController grew to 2,847 lines with circular provider dependencies  
**Category:** Architecture / Design  
**Severity:** 🔴 CRITICAL  
**Status:** ✅ RESOLVED  
**Repository:** Attempt 1, Attempt 3  
**Files Affected:**

- `lib/providers/map_controller.dart` (deleted)
- `lib/providers/*` (split into multiple)

**Symptoms:**

- Hot reload breaks app
- Changes cascade across entire codebase
- Impossible to test in isolation
- Stack overflow on initialization
- "ProviderNotFoundException" errors

#### Root Cause
Single class responsible for:

- Map viewport management
- Weather data fetching
- NMEA data processing
- Boat position tracking
- Timeline playback
- User settings
- Cache coordination
- WebView communication

Circular dependencies:

- MapController needs WeatherService for overlays
- WeatherService needs MapController for bounds
- Both initialized in each other's constructor

**Code Example (WRONG):**

```dart
class MapController extends ChangeNotifier {
  late final WeatherService _weatherService;
  late final NMEAService _nmeaService;
  late final CacheService _cacheService;
  
  MapController() {
    // Circular dependency!
    _weatherService = WeatherService(this);
    _nmeaService = NMEAService(this);
    _cacheService = CacheService(this);
  }
  
  // 2,847 lines of mixed responsibilities...
}
```text

**Solution:**

1. Split into focused providers (max 300 lines each)
2. Use composition instead of inheritance
3. Document dependency hierarchy (max 3 layers)
4. Dependencies flow in one direction only
5. Create providers in main.dart with ProxyProvider

**Code Example (CORRECT):**

```dart
// Focused providers
class MapProvider extends ChangeNotifier {
  Viewport _viewport;
  // Only viewport management (~180 lines)
}

class WeatherProvider extends ChangeNotifier {
  final CacheService _cache;
  // Only weather data (~250 lines)
}

// main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => MapProvider()),
    ChangeNotifierProxyProvider<MapProvider, WeatherProvider>(
      create: (_) => WeatherProvider(cache),
      update: (_, map, weather) => weather!..updateBounds(map.bounds),
    ),
  ],
)
```text

**Prevention Rule:**

- Maximum 300 lines per file
- Single Responsibility Principle
- Document all dependencies
- Pre-commit hook checks file size
- CI fails on oversized files

---

### ISS-003: ProviderNotFoundException on Hot Reload

**Issue ID:** ISS-003  
**Title:** App crashes with ProviderNotFoundException during development  
**Category:** State Management  
**Severity:** 🟠 HIGH  
**Status:** ✅ RESOLVED  
**Repository:** Attempt 2  
**Files Affected:**

- `lib/screens/map_screen.dart`
- `lib/screens/forecast_screen.dart`

**Symptoms:**

- Hot reload causes crash
- Error: "Could not find the correct Provider<T> above this widget"
- App works on cold start, breaks on hot reload
- Intermittent crashes during development

#### Root Cause
Providers created inside widget build methods instead of app root:

```dart
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // WRONG: Provider created in build
    return ChangeNotifierProvider(
      create: (_) => MapViewModel(),
      child: Consumer<MapViewModel>(...),
    );
  }
}
```text

Problems:

1. Provider recreated on every build
2. State lost on hot reload
3. Provider hierarchy doesn't match widget hierarchy
4. Nested providers accessing parents that don't exist yet

**Solution:**

1. ALL providers created in main.dart
2. Use `context.read<T>()` for one-time access
3. Use `Consumer<T>` for reactive updates
4. Never create providers in widget trees

**Code Example (CORRECT):**

```dart
// main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        ChangeNotifierProvider(create: (_) => WeatherViewModel()),
      ],
      child: MyApp(),
    ),
  );
}

// map_screen.dart
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // CORRECT: Access existing provider
    return Consumer<MapViewModel>(
      builder: (context, model, child) {
        return Container(...);
      },
    );
  }
}
```text

**Prevention Rule:**

- Providers ONLY in main.dart
- No `ChangeNotifierProvider` in screen/widget files
- Document provider hierarchy in CODEBASE_MAP.md
- Lint rule to detect provider creation outside main

---

### ISS-004: Stale Weather Data After Fetch

**Issue ID:** ISS-004  
**Title:** Old weather data displays after fetching new data  
**Category:** Caching / Data Consistency  
**Severity:** 🟠 HIGH  
**Status:** ⚠️ PARTIAL  
**Repository:** Attempt 3  
**Files Affected:**

- `lib/services/cache_service.dart`
- `lib/providers/weather_provider.dart`
- `lib/widgets/map_webview.dart`

**Symptoms:**

- UI shows yesterday's forecast
- Refresh doesn't update display
- Multiple cache layers out of sync
- WebView shows different data than overlays

#### Root Cause
Four separate cache layers with no coordination:

1. In-memory Map<Bounds, WeatherData>
2. Disk cache (path_provider)
3. HTTP cache headers
4. WebView internal cache

No invalidation strategy:

- Memory cache updated but disk cache stale
- Bounds keys didn't account for zoom differences
- No TTL or timestamps
- Cache grew to 500MB+

**Code Example (WRONG):**

```dart
Future<WeatherData> getWeather(Bounds bounds) async {
  // Check memory only
  if (_memoryCache.containsKey(bounds)) {
    return _memoryCache[bounds]!; // Might be stale
  }
  
  // Fetch new
  final data = await _api.fetchWeather(bounds);
  _memoryCache[bounds] = data;
  
  // Other caches still have old data!
  return data;
}
```text

**Solution:**

1. Single CacheService with unified strategy
2. LRU eviction when size limit reached
3. TTL-based expiry
4. Version tags for cache keys
5. Coordinated invalidation across all layers

**Code Example (CORRECT):**

```dart
class CacheService {
  Future<T?> get<T>(CacheKey key) async {
    final entry = _index[key.toString()];
    if (entry == null) return null;
    
    // Check TTL
    if (DateTime.now().isAfter(entry.expiresAt)) {
      await delete(key);
      return null;
    }
    
    // Update LRU
    entry.lastAccessed = DateTime.now();
    
    return _readFromDisk(key);
  }
  
  Future<void> set<T>(CacheKey key, T value, {Duration? ttl}) async {
    await _evictIfNeeded();
    await _writeToDisk(key, value);
    
    _index[key.toString()] = CacheEntry(
      expiresAt: DateTime.now().add(ttl ?? _defaultTTL),
      lastAccessed: DateTime.now(),
    );
  }
  
  Future<void> invalidateCategory(String category) async {
    final keysToDelete = _index.keys
      .where((k) => k.startsWith(category))
      .toList();
    
    for (final key in keysToDelete) {
      await delete(CacheKey.parse(key));
    }
  }
}
```text

**Prevention Rule:**

- Single source of truth for cached data
- All caches must have TTL
- Document cache invalidation triggers
- Monitor cache size in production

---

### ISS-006: Memory Leak from Undisposed AnimationControllers

**Issue ID:** ISS-006  
**Title:** Memory usage climbs 50MB/minute, app crashes after 20 minutes  
**Category:** Memory Management  
**Severity:** 🔴 CRITICAL  
**Status:** ✅ RESOLVED  
**Repository:** Attempt 2, Attempt 3  
**Files Affected:**

- `lib/widgets/overlays/wind_overlay.dart`
- `lib/widgets/controls/timeline_controls.dart`
- `lib/widgets/common/loading_widget.dart`

**Symptoms:**

- Memory usage increases constantly
- App becomes sluggish after 10 minutes
- Crash with "out of memory" after 20 minutes
- Flutter DevTools shows hundreds of zombie objects
- AnimationController count increases indefinitely

#### Root Cause
AnimationControllers created but never disposed:

```dart
class WindArrowWidget extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<WindArrowWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)..repeat();
  }
  
  // NO dispose() method - LEAK!
}
```text

Additional leaks:

- StreamSubscriptions not cancelled
- Provider listeners not removed
- Timer not cancelled
- Image cache not cleared

#### Solution
Every StatefulWidget with resources MUST dispose them:

**Code Example (CORRECT):**

```dart
class WindArrowWidget extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<WindArrowWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)..repeat();
    _subscription = someStream.listen((data) => _handleData(data));
  }
  
  @override
  void dispose() {
    _controller.dispose();      // Dispose controller
    _subscription?.cancel();    // Cancel subscription
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.navigation),
    );
  }
}
```text

**Prevention Rule:**

- Lint rule: `always_dispose_controllers`
- Every StatefulWidget with resources MUST have dispose()
- Checklist:
  - [ ] AnimationController
  - [ ] TextEditingController
  - [ ] ScrollController
  - [ ] StreamSubscription
  - [ ] Timer
  - [ ] FocusNode
- Memory profiler run in CI
- LeakCanary for debug builds

---

### ISS-009: NMEA Parser Blocking UI Thread

**Issue ID:** ISS-009  
**Title:** App freezes when AIS receiver sends high message rate  
**Category:** Performance / Threading  
**Severity:** 🔴 CRITICAL  
**Status:** ✅ RESOLVED  
**Repository:** Attempt 2  
**Files Affected:**

- `lib/services/nmea_service.dart`
- `lib/providers/nmea_provider.dart`

**Symptoms:**

- UI freezes for 2-3 seconds
- Janky scrolling and animations
- High CPU usage on main thread
- App crash with "Application Not Responding"
- Worse when multiple NMEA devices connected

#### Root Cause
NMEA sentence parsing on main thread:

1. Socket data received on main thread
2. String conversion blocking
3. Parse logic (regex, checksum) CPU intensive
4. notifyListeners() called 30+ times per second

**Code Example (WRONG):**

```dart
void connectToNMEA(String host, int port) {
  Socket.connect(host, port).then((socket) {
    socket.listen((Uint8List data) {
      // BLOCKS UI THREAD
      final sentences = String.fromCharCodes(data).split('\r\n');
      
      for (var sentence in sentences) {
        final parsed = NMEAParser.parse(sentence);
        if (parsed != null) {
          _handleMessage(parsed);
          notifyListeners(); // 30+ times per second!
        }
      }
    });
  });
}
```text

**Solution:**

1. Use Isolate for NMEA parsing
2. Batch updates every 200ms
3. Backpressure handling
4. Buffer size limits

**Code Example (CORRECT):**

```dart
class NMEAService {
  Future<void> connect(String host, int port) async {
    final socket = await Socket.connect(host, port);
    
    // Spawn isolate
    final receivePort = ReceivePort();
    await Isolate.spawn(_parseIsolate, receivePort.sendPort);
    final sendPort = await receivePort.first as SendPort;
    
    // Forward data to isolate
    socket.listen((data) => sendPort.send(data));
    
    // Receive parsed messages
    receivePort.listen((message) {
      if (message is List<NMEAMessage>) {
        _batchUpdate(message); // Batched!
      }
    });
  }
  
  static void _parseIsolate(SendPort sendPort) {
    final buffer = StringBuffer();
    final batch = <NMEAMessage>[];
    Timer? batchTimer;
    
    ReceivePort().listen((data) {
      if (data is Uint8List) {
        buffer.write(String.fromCharCodes(data));
        
        final sentences = buffer.toString().split('\r\n');
        for (int i = 0; i < sentences.length - 1; i++) {
          final parsed = NMEAParser.parse(sentences[i]);
          if (parsed != null) batch.add(parsed);
        }
        
        buffer.clear();
        buffer.write(sentences.last);
        
        // Batch send every 200ms
        batchTimer?.cancel();
        batchTimer = Timer(Duration(milliseconds: 200), () {
          if (batch.isNotEmpty) {
            sendPort.send(List.from(batch));
            batch.clear();
          }
        });
      }
    });
  }
}
```text

**Prevention Rule:**

- No heavy computation on main thread
- Use Isolate for parsing, encoding, crypto
- Batch UI updates (max 5 fps for data streams)
- Monitor main thread jank in DevTools

---

### ISS-012: Wind Arrow Direction Inverted

**Issue ID:** ISS-012  
**Title:** Wind arrows point opposite direction (180° off)  
**Category:** Data Interpretation  
**Severity:** 🟠 HIGH  
**Status:** ✅ RESOLVED  
**Repository:** Attempt 2  
**Files Affected:**

- `lib/widgets/overlays/wind_overlay.dart`
- `lib/utils/conversions.dart`

**Symptoms:**

- Wind arrows point wrong direction
- Always 180 degrees opposite
- Direction correct, arrows backwards
- User reports: "Wind from north shows south"

#### Root Cause
Confusion between meteorological and mathematical wind direction conventions:

- **Meteorological:** Wind direction = where wind is FROM (0° = from North)
- **Mathematical:** Arrow direction = where wind is GOING (0° = toward East)

Wind data from API is meteorological, but arrows drawn with mathematical rotation.

**Code Example (WRONG):**

```dart
void _drawWindArrow(Canvas canvas, Offset pos, double direction) {
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  
  // WRONG: Using meteorological direction directly
  canvas.rotate(direction * pi / 180);
  
  // Draw arrow pointing right (east)
  final path = Path()
    ..moveTo(0, 0)
    ..lineTo(20, 0)
    ..lineTo(15, -5)
    ..lineTo(15, 5)
    ..close();
  
  canvas.drawPath(path, paint);
  canvas.restore();
}
```text

#### Solution
Convert meteorological to mathematical direction:

- Add 180° to reverse direction (FROM → TO)
- Adjust for canvas coordinate system

**Code Example (CORRECT):**

```dart
void _drawWindArrow(Canvas canvas, Offset pos, double meteoDirection) {
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  
  // Convert: meteorological FROM → mathematical TO
  // Also adjust for canvas Y-axis inverted
  final arrowDirection = (meteoDirection + 180) % 360;
  final radians = (arrowDirection - 90) * pi / 180; // -90 for canvas coords
  
  canvas.rotate(radians);
  
  // Draw arrow pointing up (north in canvas space)
  final path = Path()
    ..moveTo(0, -20) // tip
    ..lineTo(-5, -10)
    ..lineTo(-2, -10)
    ..lineTo(-2, 0)   // shaft
    ..lineTo(2, 0)
    ..lineTo(2, -10)
    ..lineTo(5, -10)
    ..close();
  
  canvas.drawPath(path, paint);
  canvas.restore();
}
```text

**Prevention Rule:**

- Document all direction conventions
- Unit tests with known wind directions
- Visual QA with meteorological data
- Comments explaining FROM vs TO

---

### ISS-013: Timeline Playback Memory Overflow

**Issue ID:** ISS-013  
**Title:** Timeline loading all forecast frames causes OutOfMemory  
**Category:** Memory Management  
**Severity:** 🔴 CRITICAL  
**Status:** ✅ RESOLVED  
**Repository:** Attempt 3  
**Files Affected:**

- `lib/providers/timeline_provider.dart`
- `lib/screens/timeline_screen.dart`

**Symptoms:**

- App crashes when loading 7-day forecast
- Memory usage spikes to 800MB+
- Crash: "OutOfMemoryError"
- 168 frames × 5MB each = 840MB

#### Root Cause
Loading all forecast frames into memory at once:

```dart
class TimelineProvider {
  List<WeatherFrame> _frames = [];
  
  Future<void> loadForecast() async {
    // Load 168 hours of data
    for (int hour = 0; hour < 168; hour++) {
      final frame = await _api.getForecastFrame(hour);
      _frames.add(frame); // 5MB each × 168 = 840MB!
    }
  }
}
```text

**Solution:**

1. Lazy load frames as needed
2. Keep only current + next + previous in memory
3. LRU cache for recently viewed frames
4. Preload next frame in background

**Code Example (CORRECT):**

```dart
class TimelineProvider {
  final int _maxCachedFrames = 5;
  final Map<int, WeatherFrame> _frameCache = {};
  int _currentFrameIndex = 0;
  
  Future<WeatherFrame> getCurrentFrame() async {
    return await _loadFrame(_currentFrameIndex);
  }
  
  Future<WeatherFrame> _loadFrame(int index) async {
    // Check cache
    if (_frameCache.containsKey(index)) {
      return _frameCache[index]!;
    }
    
    // Evict if cache full
    if (_frameCache.length >= _maxCachedFrames) {
      // Remove frame furthest from current
      final furthest = _frameCache.keys
        .reduce((a, b) => 
          (a - _currentFrameIndex).abs() > (b - _currentFrameIndex).abs() 
            ? a : b);
      _frameCache.remove(furthest);
    }
    
    // Load from API
    final frame = await _api.getForecastFrame(index);
    _frameCache[index] = frame;
    
    // Preload next frame
    _preloadFrame(index + 1);
    
    return frame;
  }
  
  Future<void> _preloadFrame(int index) async {
    if (index >= 0 && index < 168 && !_frameCache.containsKey(index)) {
      final frame = await _api.getForecastFrame(index);
      
      if (_frameCache.length < _maxCachedFrames) {
        _frameCache[index] = frame;
      }
    }
  }
}
```text

**Prevention Rule:**

- Never load unbounded data into memory
- Use pagination/lazy loading
- Monitor memory usage in production
- Test with maximum data scenarios

---

### ISS-016: AIS Message Buffer Overflow

**Issue ID:** ISS-016  
**Title:** AIS receiver buffer fills up, messages dropped  
**Category:** Performance / Buffering  
**Severity:** 🟠 HIGH  
**Status:** 🔄 IN PROGRESS  
**Repository:** Attempt 4  
**Files Affected:**

- `lib/services/ais_service.dart`
- `lib/providers/nmea_provider.dart`

**Symptoms:**

- AIS targets disappear from display
- Error: "Buffer overflow, 1247 messages dropped"
- CPU usage 80%+ when AIS active
- Stuttering UI during AIS updates

#### Root Cause
AIS receivers can send 100+ messages per second. Current implementation:

1. All messages queued in memory
2. No backpressure mechanism
3. UI updates for every message
4. Buffer grows unbounded

#### Temporary Workaround
Limit AIS update rate to 2 fps:

```dart
Timer.periodic(Duration(milliseconds: 500), (_) {
  if (_pendingAISUpdates.isNotEmpty) {
    notifyListeners();
    _pendingAISUpdates.clear();
  }
});
```text

**Planned Solution:**

1. Implement backpressure with StreamTransformer
2. Spatial indexing to cull off-screen targets
3. Level of detail based on zoom
4. Batch updates every 500ms

**Status:** Fix scheduled for Phase 3

---

### ISS-018: GPS Position Jumping on Reconnect

**Issue ID:** ISS-018  
**Title:** Boat position jumps when GPS reconnects  
**Category:** Data Smoothing  
**Severity:** 🟡 MEDIUM  
**Status:** ✅ RESOLVED  
**Repository:** Attempt 4  
**Files Affected:**

- `lib/providers/boat_provider.dart`
- `lib/services/location_service.dart`

**Symptoms:**

- Boat marker jumps 100m+ when GPS signal restored
- Track line shows unrealistic straight segments
- Speed calculated incorrectly during jumps
- Heading changes 180° instantly

#### Root Cause
GPS receivers output last known position with degraded accuracy when signal lost. When signal restored, position jumps to actual location.

#### Solution (Implemented)
Position validation implemented in `boat_provider.dart` via `_isPositionValid()` method, called in `_processPosition()` before accepting any new position:

```dart
bool _isPositionValid(BoatPosition newPosition) {
  // 1. Accuracy threshold check
  if (newPosition.accuracy > maxAccuracyThresholdMeters) {
    return false; // reject positions with accuracy > 50m
  }

  // 2. Speed sanity check against previous position
  if (_currentPosition != null) {
    final distance = GeoUtils.distanceBetween(
      _currentPosition!.latLng, newPosition.latLng,
    );
    final timeDelta = newPosition.timestamp
        .difference(_currentPosition!.timestamp)
        .inSeconds;
    if (timeDelta > 0) {
      final speed = distance / timeDelta;
      if (speed > maxRealisticSpeedMps) {
        return false; // reject if > 50 m/s (~97 knots)
      }
    }
  }

  return true;
}
```

Constants defined in `boat_position.dart`:
- `maxRealisticSpeedMps = 50.0` (≈97 knots)
- `maxAccuracyThresholdMeters = 50.0`

#### Future Enhancement
Implement Kalman filter for GPS smoothing (optional improvement).

---

### ISS-019: Incomplete CacheProvider Integration

**Issue ID:** ISS-019  
**Title:** CacheProvider is a shell with no backend implementation  
**Category:** Implementation Debt  
**Severity:** 🟠 HIGH  
**Status:** ✅ RESOLVED  
**Repository:** Current  
**Files Affected:**

- `lib/providers/cache_provider.dart`
- `lib/services/cache_service.dart` (NEW)

**Symptoms:**

- Cache statistics UI shows no data
- Weather caching not functional
- 7 TODO items in CacheProvider code

#### Root Cause
CacheProvider was created as an architectural placeholder following ISS-004's single-cache-coordinator design, but the actual CacheService backend was never implemented.

#### Solution Applied

1. Created `CacheService` — disk-backed KV store using SharedPreferences with TTL support and LRU eviction (100-entry default)
2. Rewired CacheProvider to delegate all operations to CacheService
3. Replaced all 7 TODOs with working implementations
4. Added `put(key, value, ttl)` and `getString(key)` public API
5. 16 unit tests covering put/get, TTL expiry, LRU eviction, persistence, statistics

**Note:** Weather disk caching deferred — WeatherData model lacks toJson/fromJson serialization. In-memory staleness checks provide existing cache-first behavior.

---

### ISS-020: NMEA Data Not Cached Across Restarts

**Issue ID:** ISS-020  
**Title:** NMEA configuration and last position not persisted  
**Category:** Implementation Debt  
**Severity:** 🟡 MEDIUM  
**Status:** ✅ RESOLVED  
**Repository:** Current  
**Files Affected:**

- `lib/providers/nmea_provider.dart`

**Symptoms:**

- Connection settings reset on app restart
- Last known position lost on restart
- Auto-reconnect not configurable

#### Root Cause
NMEAProvider had `_settingsProvider` and `_cacheProvider` injected but not yet used (marked `// ignore: unused_field`).

#### Solution Applied

1. Position caching: `_handleData()` caches lat/lng/sog/cog as JSON to `nmea_last_position` key with 24-hour TTL
2. Position restore: `_loadCachedData()` restores last-known position from cache on startup, creating minimal NMEAData with GPRMCData
3. Auto-reconnect gated on `settingsProvider.autoConnectNMEA` setting
4. Removed `// ignore: unused_field` annotations — both providers now actively used

---

### ISS-021: Unused Provider Dependencies in NMEAProvider

**Issue ID:** ISS-021  
**Title:** NMEAProvider holds unused SettingsProvider and CacheProvider references  
**Category:** Code Quality  
**Severity:** 🟢 LOW  
**Status:** ✅ RESOLVED  
**Repository:** Current  
**Files Affected:**

- `lib/providers/nmea_provider.dart`

**Symptoms:**

- `_settingsProvider` and `_cacheProvider` fields marked with `// ignore: unused_field`
- No functional impact

#### Root Cause
Dependencies injected for future use (settings persistence, position caching) but not yet wired.

#### Solution Applied
Both `_settingsProvider` and `_cacheProvider` are now actively used as part of ISS-019 and ISS-020 fixes. The `// ignore: unused_field` annotations have been removed.

---

## Summary Statistics

**Total Issues:** 21  
**Resolved:** 19 (90%)  
**In Progress:** 1 (5%)  
**Documented/Workaround:** 1 (5%)

**By Severity:**

- 🔴 Critical: 5 (all resolved)
- 🟠 High: 9 (8 resolved, 1 in progress)
- 🟡 Medium: 5 (all resolved)
- 🟢 Low: 2 (all resolved)

**Most Common Categories:**

1. Memory Management (3 issues)
2. Coordinate Systems (3 issues)
3. State Management (2 issues)
4. Performance (4 issues)
5. Caching (2 issues)

---

**Document End**
