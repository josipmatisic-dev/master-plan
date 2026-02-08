# Phase 3 Polish & Features - Detailed Specifications

**Phase:** 3 - Polish & Features  
**Purpose:** Advanced features, dark mode, AIS, tides, performance  
**References:** [Phase 3 Plan](../plans/phase-3-polish-features-plan.md)

## Dark Mode System

### Theme Definitions

```dart
class MarineTheme {
  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF2196F3), // Ocean blue
    backgroundColor: Color(0xFFF5F5F5),
    // ... full theme
  );
  
  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF1976D2),
    backgroundColor: Color(0xFF121212),
    // ... full theme
  );
  
  static ThemeData redLight() => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF8B0000), // Dark red
    backgroundColor: Color(0xFF1A0000),
    // Red light mode for night navigation
  );
}
```text

### Theme Persistence

**Fix for ISS-015 (dark mode not persisting):**

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('theme_mode') ?? 'system';
    _mode = ThemeMode.values.firstWhere((m) => m.name == modeStr);
    notifyListeners();
  }
  
  Future<void> setTheme(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }
}
```text

## AIS Integration

**Critical:** Fix ISS-016 (buffer overflow)

### AIS Service with Backpressure

```dart
class AISService {
  final StreamController<AISTarget> _controller = StreamController();
  final Set<int> _visibleMMSI = {};
  Timer? _updateTimer;
  
  Future<void> startProcessing() async {
    // Parse in isolate
    final receivePort = ReceivePort();
    await Isolate.spawn(_aisIsolate, receivePort.sendPort);
    
    // Batch updates (2 fps max) to prevent ISS-016
    _updateTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if (_visibleMMSI.isNotEmpty) {
        _controller.add(/* batched targets */);
      }
    });
  }
  
  // Spatial culling for off-screen targets
  void updateVisibleBounds(Bounds bounds) {
    _visibleMMSI = _allTargets
      .where((t) => bounds.contains(t.position))
      .map((t) => t.mmsi)
      .toSet();
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _controller.close();
    super.dispose();
  }
}
```text

### CPA/TCPA Calculations

```dart
class AISCalculations {
  /// Calculate Closest Point of Approach
  static double calculateCPA(BoatPosition own, AISTarget target) {
    // Vector calculation
  }
  
  /// Calculate Time to CPA
  static Duration calculateTCPA(BoatPosition own, AISTarget target) {
    // Time calculation
  }
}
```text

## Tide Integration

### NOAA API

**Endpoint:** `https://api.tidesandcurrents.noaa.gov/api/prod/datagetter`

**Parameters:**
- product=predictions
- datum=MLLW
- interval=hilo (for high/low only)
- format=json

## Audio Alerts

### Alert Priority System

1. Collision warning (highest)
2. Depth alarm
3. Anchor drag
4. Weather warning
5. Informational (lowest)

**Implementation:**
- Only play highest priority alert
- Lower priority queued
- Mute/snooze functionality

## Performance Optimization

### Overlay Rendering Optimization

```dart
class WindOverlayPainter extends CustomPainter {
  @override
  bool shouldRepaint(WindOverlayPainter old) {
    // Only repaint if data or viewport changed
 return windData != old.windData | | viewport != old.viewport;
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    // Only render visible points
    final visiblePoints = windData.points
      .where((p) => viewport.bounds.contains(p.position))
      .toList();
    
    for (final point in visiblePoints) {
      _drawArrow(canvas, point);
    }
  }
}
```text

---

**For complete task breakdown, see:** [Phase 3 Plan](../plans/phase-3-polish-features-plan.md)
