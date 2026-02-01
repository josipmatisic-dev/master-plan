# Phase 1 Core Navigation - Detailed Specifications

**Phase:** 1 - Core Navigation  
**Purpose:** Detailed technical specifications for map, GPS, and overlay components  
**References:** [Phase 1 Plan](../plans/phase-1-core-navigation-plan.md)

## Map Integration

### MapWebView Component

**Purpose:** WebView container for MapTiler SDK integration

**Architecture:**
```dart
class MapWebView extends StatefulWidget {
  final ValueChanged<Viewport> onViewportChanged;
  
  @override
  State<MapWebView> createState() => _MapWebViewState();
}

class _MapWebViewState extends State<MapWebView> {
  late final WebViewController _controller;
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FlutterBridge', onMessageReceived: _handleMessage)
      ..loadRequest(Uri.parse('asset://assets/map.html'));
  }
  
  void _handleMessage(JavaScriptMessage message) {
    // Debounce viewport updates (200ms) to avoid ISS-008
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 200), () {
      final data = jsonDecode(message.message);
      widget.onViewportChanged(Viewport.fromJson(data));
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

### Viewport Synchronization

**Critical:** Prevents ISS-001 (overlay projection mismatch)

**Flow:**
1. Map moves in WebView
2. JavaScript bridge sends viewport state (debounced 200ms)
3. MapProvider updates viewport
4. Overlays rebuild with new viewport using ProjectionService

## GPS Integration

### LocationService

**Purpose:** GPS location with accuracy filtering  
**Avoids:** ISS-018 (position jumping)

```dart
class LocationService {
  final Location _location = Location();
  
  Stream<BoatPosition> get positionStream {
    return _location.onLocationChanged
      .where((loc) => loc.accuracy! < 50.0) // Filter low accuracy
      .map((loc) => BoatPosition(
        latitude: loc.latitude!,
        longitude: loc.longitude!,
        speed: loc.speed,
        heading: loc.heading,
        accuracy: loc.accuracy,
        timestamp: DateTime.now(),
      ));
  }
}
```

## Overlay Rendering

### Wind Overlay Specification

**Critical:** Correct wind arrow direction (avoids ISS-012)

```dart
void _drawWindArrow(Canvas canvas, WindData wind, Viewport viewport) {
  // Convert lat/lng to pixels using ProjectionService (avoids ISS-001)
  final offset = ProjectionService.latLngToPixels(
    wind.latitude,
    wind.longitude,
    viewport,
  );
  
  // Convert meteorological direction to mathematical (fixes ISS-012)
  // Meteorological: direction wind is FROM (0° = from North)
  // Mathematical: direction TO (0° = East in canvas)
  final arrowDirection = (wind.direction + 180) % 360;
  final radians = (arrowDirection - 90) * pi / 180;
  
  canvas.save();
  canvas.translate(offset.dx, offset.dy);
  canvas.rotate(radians);
  
  // Draw arrow proportional to speed
  final length = wind.speed * 2.0;
  // ... arrow path drawing
  
  canvas.restore();
}
```

### Track Overlay Specification

**Purpose:** Render track history with proper disposal  
**Avoids:** ISS-006 (memory leaks)

```dart
class TrackOverlay extends StatefulWidget {
  final List<TrackPoint> points;
  final Viewport viewport;
  
  @override
  State<TrackOverlay> createState() => _TrackOverlayState();
}

class _TrackOverlayState extends State<TrackOverlay> {
  // No controllers in this case, but if there were:
  @override
  void dispose() {
    // Always dispose controllers, subscriptions, etc.
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TrackPainter(
        points: widget.points,
        viewport: widget.viewport,
      ),
    );
  }
}
```

## Database Schema

### Track Points Table

```sql
CREATE TABLE track_points (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  speed REAL,
  heading REAL,
  timestamp INTEGER NOT NULL,
  accuracy REAL,
  CONSTRAINT chk_lat CHECK (latitude >= -90 AND latitude <= 90),
  CONSTRAINT chk_lng CHECK (longitude >= -180 AND longitude <= 180)
);

CREATE INDEX idx_timestamp ON track_points(timestamp);
```

**Queries:**
- Insert: Batched (every 5 seconds)
- Select: By time range
- Delete: Oldest when exceeds 10,000 points

## Performance Requirements

- Map rendering: 60 FPS
- GPS updates: 1 Hz (every second)
- Overlay render time: <16ms per frame
- Track query: <50ms
- Viewport sync latency: <200ms

## Testing Focus

**Unit Tests:**
- Viewport calculations with ProjectionService
- Wind direction conversion (ISS-012)
- GPS accuracy filtering (ISS-018)

**Widget Tests:**
- Overlay positioning at zoom 1, 10, 20
- Wind arrows point correct direction

**Integration Tests:**
- Full map + GPS + overlays flow
- Overlay positioning during pan/zoom (ISS-001 check)

---

**For complete task breakdown, see:** [Phase 1 Plan](../plans/phase-1-core-navigation-plan.md)
