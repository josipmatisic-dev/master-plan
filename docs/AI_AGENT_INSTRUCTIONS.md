# AI Agent Instructions
## Marine Navigation App Development Guidelines

**Version:** 2.0  
**Applies To:** All AI coding assistants working on this project

---

## Table of Contents

1. [Mandatory Behaviors](#mandatory-behaviors)
2. [Forbidden Actions](#forbidden-actions)
3. [Code Patterns](#code-patterns)
4. [Documentation Requirements](#documentation-requirements)
5. [Error Handling](#error-handling)
6. [Testing Requirements](#testing-requirements)
7. [Review Checklist](#review-checklist)

---

## Mandatory Behaviors

### MB.1 Always Read The Bible First

Before making ANY code changes:
1. Read `MASTER_DEVELOPMENT_BIBLE.md` Section A (Failure Analysis)
2. Check `KNOWN_ISSUES_DATABASE.md` for similar patterns
3. Review `CODEBASE_MAP.md` for affected components
4. Verify against Architecture Rules (Section C)

**Failure to read the Bible = Repeating past mistakes**

---

### MB.2 Follow The Architecture Rules

ALL rules in Section C are MANDATORY. No exceptions.

**Critical Rules:**
- **C.1** Single Source of Truth - No duplicate state
- **C.2** Projection Consistency - ALL coordinates through ProjectionService
- **C.3** Provider Discipline - Hierarchy documented, no circular deps
- **C.4** Network Requests - Retry + timeout + cache fallback
- **C.5** File Size Limits - Max 300 lines per file
- **C.10** Dispose Everything - No memory leaks

If a rule prevents your task, STOP and ask for guidance.

---

### MB.3 Use Working Code Inventory

Section B contains battle-tested, working code. REUSE it.

**DO:**
- Copy patterns from B.1-B.8
- Extend existing working classes
- Follow established interfaces

**DON'T:**
- Rewrite working code "your way"
- Introduce new patterns for solved problems
- Ignore proven solutions

---

### MB.4 Update Documentation

Every code change REQUIRES documentation updates:

**Changed Code** → Update:
- `CODEBASE_MAP.md` - If new files/services added
- `KNOWN_ISSUES_DATABASE.md` - If fixing a documented issue
- `FEATURE_REQUIREMENTS.md` - If implementing/changing features
- Code comments - For complex logic

---

### MB.5 Write Tests First

For all new features:
1. Write unit test that fails
2. Implement minimum code to pass
3. Refactor while tests pass
4. Add integration test
5. Document test coverage

**Minimum Coverage:** 80% for all new code

---

## Forbidden Actions

### FA.1 Do NOT Create God Objects

**Forbidden:**
```dart
class MapController extends ChangeNotifier {
  // 1000+ lines
  // Does everything
  // Knows about everything
  // Depends on everything
}
```

**Required:**
```dart
class MapController extends ChangeNotifier {
  final ViewportManager _viewport;
  final OverlayRenderer _renderer;
  // < 300 lines
  // Single responsibility
  // Clear dependencies
}
```

---

### FA.2 Do NOT Mix State Management Approaches

**Forbidden:**
- setState() AND Provider in same widget
- StreamBuilder AND Provider for same data
- Multiple sources of truth

**Required:**
- Provider for all shared state
- setState() ONLY for local UI state (text field, animation)
- Single source of truth per data type

---

### FA.3 Do NOT Do Manual Coordinate Math

**Forbidden:**
```dart
final x = (lng + 180) * width / 360;
final y = (90 - lat) * height / 180;
```

**Required:**
```dart
final offset = ProjectionService.latLngToPixels(lat, lng, viewport);
```

**Why:** This was the root cause of overlay mismatch in Attempt 2 and 4.

---

### FA.4 Do NOT Skip Disposal

**Forbidden:**
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }
  
  // NO dispose() method - MEMORY LEAK
}
```

**Required:**
```dart
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
```

---

### FA.5 Do NOT Make Network Calls Without Error Handling

**Forbidden:**
```dart
final response = await http.get(url);
final data = json.decode(response.body);
return data;
```

**Required:**
```dart
try {
  final response = await httpClient
    .getWithRetry(url)
    .timeout(Duration(seconds: 10));
  
  if (response.statusCode == 200) {
    return parseResponse(response.body);
  } else {
    throw ApiException(response.statusCode);
  }
} on TimeoutException {
  return cacheService.get(cacheKey);
} on SocketException {
  return cacheService.get(cacheKey);
} catch (e) {
  logger.error('API call failed', e);
  rethrow;
}
```

---

### FA.6 Do NOT Use Fixed Dimensions

**Forbidden:**
```dart
Container(
  width: 375,
  height: 667,
  child: Column(
    children: [
      Container(height: 200, child: MapView()),
      Container(height: 150, child: WeatherChart()),
    ],
  ),
)
```

**Required:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    return Column(
      children: [
        Expanded(flex: 3, child: MapView()),
        Expanded(flex: 2, child: WeatherChart()),
      ],
    );
  },
)
```

---

### FA.7 Do NOT Ignore Provider Hierarchy

**Forbidden:**
```dart
// Provider created in widget build
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyProvider(), // WRONG
      child: Consumer<MyProvider>(...),
    );
  }
}
```

**Required:**
```dart
// All providers in main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## Code Patterns

### CP.1 Weather Data Fetching Pattern

```dart
class WeatherProvider extends ChangeNotifier {
  final WeatherApi _api;
  final CacheService _cache;
  
  Future<WeatherData> getWeather(Bounds bounds) async {
    // 1. Check cache first (offline-first)
    final cached = await _cache.get('weather_${bounds.hash}');
    if (cached != null && !cached.isExpired) {
      // Return cached data immediately
      _notifyWeatherUpdate(cached);
      
      // Fetch fresh data in background
      _refreshInBackground(bounds);
      
      return cached;
    }
    
    // 2. Fetch from network with retry
    try {
      final data = await _api.fetchWeather(bounds)
        .timeout(Duration(seconds: 10));
      
      // 3. Update cache
      await _cache.set('weather_${bounds.hash}', data, 
        ttl: Duration(hours: 1));
      
      // 4. Notify listeners
      _notifyWeatherUpdate(data);
      
      return data;
    } catch (e) {
      // 5. Return stale cache on error
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
}
```

---

### CP.2 Map Overlay Rendering Pattern

```dart
class WindOverlay extends StatelessWidget {
  final WeatherData weatherData;
  final Viewport viewport;
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WindOverlayPainter(
        weatherData: weatherData,
        viewport: viewport,
      ),
    );
  }
}

class WindOverlayPainter extends CustomPainter {
  final WeatherData weatherData;
  final Viewport viewport;
  
  WindOverlayPainter({
    required this.weatherData,
    required this.viewport,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final point in weatherData.windPoints) {
      // 1. Convert WGS84 to screen coordinates
      final offset = ProjectionService.latLngToPixels(
        point.latitude,
        point.longitude,
        viewport,
      );
      
      // 2. Check if visible
      if (!_isVisible(offset, size)) continue;
      
      // 3. Render wind arrow
      _drawWindArrow(canvas, offset, point.speed, point.direction);
    }
  }
  
  @override
  bool shouldRepaint(WindOverlayPainter oldDelegate) {
    return weatherData != oldDelegate.weatherData ||
           viewport != oldDelegate.viewport;
  }
}
```

---

### CP.3 NMEA Data Processing Pattern

```dart
class NMEAProvider extends ChangeNotifier {
  final StreamController<NMEAMessage> _controller = StreamController();
  StreamSubscription? _subscription;
  
  Future<void> connectToDevice(String host, int port) async {
    final socket = await Socket.connect(host, port);
    
    // Process in isolate to avoid blocking UI
    final receivePort = ReceivePort();
    await Isolate.spawn(_nmeaIsolate, receivePort.sendPort);
    
    final sendPort = await receivePort.first as SendPort;
    
    // Listen for parsed messages
    _subscription = receivePort.listen((message) {
      if (message is NMEAMessage) {
        _handleMessage(message);
      }
    });
    
    // Forward raw data to isolate
    socket.listen((data) {
      sendPort.send(data);
    });
  }
  
  static void _nmeaIsolate(SendPort sendPort) {
    final buffer = StringBuffer();
    
    ReceivePort().listen((data) {
      if (data is Uint8List) {
        buffer.write(String.fromCharCodes(data));
        
        // Process complete sentences
        final sentences = buffer.toString().split('\r\n');
        for (int i = 0; i < sentences.length - 1; i++) {
          final parsed = NMEAParser.parse(sentences[i]);
          if (parsed != null) {
            sendPort.send(parsed);
          }
        }
        
        // Keep incomplete sentence in buffer
        buffer.clear();
        buffer.write(sentences.last);
      }
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    _controller.close();
    super.dispose();
  }
}
```

---

### CP.4 Timeline Playback Pattern

```dart
class TimelineProvider extends ChangeNotifier {
  List<DateTime> _timestamps = [];
  int _currentFrame = 0;
  PlaybackState _state = PlaybackState.paused;
  double _speed = 1.0;
  Timer? _playbackTimer;
  
  Future<void> play() async {
    if (_state == PlaybackState.playing) return;
    
    _state = PlaybackState.playing;
    notifyListeners();
    
    _scheduleNextFrame();
  }
  
  void _scheduleNextFrame() {
    if (_state != PlaybackState.playing) return;
    if (_currentFrame >= _timestamps.length - 1) {
      pause();
      return;
    }
    
    final currentTime = _timestamps[_currentFrame];
    final nextTime = _timestamps[_currentFrame + 1];
    final realDuration = nextTime.difference(currentTime);
    final playbackDuration = realDuration * (1 / _speed);
    
    _playbackTimer = Timer(playbackDuration, () {
      _currentFrame++;
      notifyListeners();
      _scheduleNextFrame();
    });
  }
  
  void pause() {
    _playbackTimer?.cancel();
    _state = PlaybackState.paused;
    notifyListeners();
  }
  
  void seekToFrame(int frame) {
    _currentFrame = frame.clamp(0, _timestamps.length - 1);
    notifyListeners();
  }
  
  void setSpeed(double speed) {
    final wasPlaying = _state == PlaybackState.playing;
    if (wasPlaying) pause();
    
    _speed = speed;
    
    if (wasPlaying) play();
  }
  
  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
```

---

## Documentation Requirements

### DR.1 Every Provider Must Document Dependencies

```dart
/// Manages weather data fetching and caching.
///
/// **Dependencies:**
/// - [CacheService] for data persistence
/// - [SettingsProvider] for units and preferences
///
/// **Provides:**
/// - Current weather data for visible bounds
/// - 7-day forecast data
/// - Historical weather cache
///
/// **Used By:**
/// - MapScreen for overlay rendering
/// - ForecastScreen for timeline display
/// - WeatherWidgets for current conditions
class WeatherProvider extends ChangeNotifier {
  // ...
}
```

---

### DR.2 Every Model Must Document Units

```dart
class WindData {
  /// Wind speed in meters per second
  final double speed;
  
  /// Wind direction in degrees (0-360, meteorological)
  /// 0° = North, 90° = East, 180° = South, 270° = West
  final double direction;
  
  /// Wind gust speed in meters per second (optional)
  final double? gustSpeed;
  
  const WindData({
    required this.speed,
    required this.direction,
    this.gustSpeed,
  });
}
```

---

### DR.3 Every Service Must Document Error Behavior

```dart
class WeatherApi {
  /// Fetches weather data for the given bounds.
  ///
  /// **Throws:**
  /// - [TimeoutException] if request takes >10 seconds
  /// - [SocketException] if network unavailable
  /// - [ApiException] if server returns error
  /// - [InvalidBoundsException] if bounds exceed limits
  ///
  /// **Returns:**
  /// [WeatherData] with forecast for next 7 days
  Future<WeatherData> fetchWeather(Bounds bounds) async {
    // ...
  }
}
```

---

## Error Handling

### EH.1 Network Errors

```dart
// ALWAYS provide offline fallback
Future<T> fetchData<T>() async {
  try {
    return await _apiCall();
  } on TimeoutException {
    final cached = await _cache.get();
    if (cached != null) return cached;
    throw OfflineException('No network and no cache');
  } on SocketException {
    final cached = await _cache.get();
    if (cached != null) return cached;
    throw OfflineException('No network and no cache');
  }
}
```

---

### EH.2 User-Facing Errors

```dart
// Show helpful error messages
void _showError(BuildContext context, dynamic error) {
  String message;
  String action;
  
  if (error is OfflineException) {
    message = 'No internet connection';
    action = 'Using cached data';
  } else if (error is InvalidBoundsException) {
    message = 'Area too large';
    action = 'Zoom in and try again';
  } else {
    message = 'Something went wrong';
    action = 'Please try again';
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$message. $action'),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () => _retry(),
      ),
    ),
  );
}
```

---

### EH.3 Logging Errors

```dart
// Log all errors for debugging
try {
  await riskyOperation();
} catch (e, stackTrace) {
  logger.error(
    'Operation failed',
    error: e,
    stackTrace: stackTrace,
    context: {
      'user_id': currentUser?.id,
      'viewport': viewport.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
  rethrow;
}
```

---

## Testing Requirements

### TR.1 Unit Test Every Service

```dart
void main() {
  group('NMEAParser', () {
    test('parses valid GGA sentence', () {
      final sentence = r'$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      final result = NMEAParser.parse(sentence);
      
      expect(result, isA<GGAData>());
      expect(result.latitude, closeTo(48.1173, 0.0001));
      expect(result.longitude, closeTo(11.5167, 0.0001));
    });
    
    test('rejects invalid checksum', () {
      final sentence = r'$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*FF';
      final result = NMEAParser.parse(sentence);
      
      expect(result, isNull);
    });
  });
}
```

---

### TR.2 Widget Test User Flows

```dart
void main() {
  testWidgets('Timeline playback controls work', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TimelineProvider(),
        child: MaterialApp(home: TimelineScreen()),
      ),
    );
    
    // Find play button
    final playButton = find.byIcon(Icons.play_arrow);
    expect(playButton, findsOneWidget);
    
    // Tap play
    await tester.tap(playButton);
    await tester.pump();
    
    // Should change to pause button
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });
}
```

---

### TR.3 Integration Test Critical Paths

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Load weather and display on map', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // Wait for map to load
    await tester.pumpAndSettle(Duration(seconds: 3));
    
    // Tap weather overlay button
    await tester.tap(find.byKey(Key('wind_overlay_toggle')));
    await tester.pumpAndSettle();
    
    // Verify overlay visible
    expect(find.byType(WindOverlay), findsOneWidget);
    
    // Pan map
    await tester.drag(find.byType(MapWebView), Offset(-200, 0));
    await tester.pumpAndSettle();
    
    // Overlay should still be visible and positioned correctly
    expect(find.byType(WindOverlay), findsOneWidget);
  });
}
```

---

## Review Checklist

Before submitting code, verify:

### Code Quality
- [ ] No file exceeds 300 lines
- [ ] No method exceeds 50 lines
- [ ] All providers have documented dependencies
- [ ] All models have documented units
- [ ] No hardcoded dimensions
- [ ] All controllers/subscriptions disposed

### Architecture Compliance
- [ ] Single source of truth maintained
- [ ] All coordinates through ProjectionService
- [ ] Provider hierarchy documented
- [ ] No circular dependencies
- [ ] Network calls have retry + timeout
- [ ] Cache fallback implemented

### Testing
- [ ] Unit tests written and passing
- [ ] Coverage ≥ 80%
- [ ] Widget tests for new UI
- [ ] Integration test if critical path

### Documentation
- [ ] CODEBASE_MAP.md updated if structure changed
- [ ] KNOWN_ISSUES_DATABASE.md updated if fixing issue
- [ ] FEATURE_REQUIREMENTS.md updated if implementing feature
- [ ] Code comments explain "why" not "what"

### Performance
- [ ] No synchronous I/O on main thread
- [ ] No unbounded lists
- [ ] Images sized appropriately
- [ ] Animations at 60 FPS
- [ ] Memory usage tested

---

**Remember:** The Bible exists because of 4 failed attempts. Don't repeat history.

---

**Document End**
