# GitHub Copilot Instructions - Marine Navigation App

## ⚡ Start Here: Essential Reading Order
**Before ANY code change, read in this order (15 min):**
1. **Failure lessons** → `docs/MASTER_DEVELOPMENT_BIBLE.md` Section A (why 4 attempts failed)
2. **This architecture** → `docs/MASTER_DEVELOPMENT_BIBLE.md` Section C (mandatory rules C.1-C.10)
3. **Known gotchas** → `docs/KNOWN_ISSUES_DATABASE.md` (18 issues + solutions)
4. **Code inventory** → `docs/MASTER_DEVELOPMENT_BIBLE.md` Section B (copy working code)

## Quick Context
- **Repo structure:** Master planning docs at root; runnable Flutter app in `marine_nav_app/`
- **Technology stack:** Flutter 3.2+, Provider state management, WebView for MapTiler, HTTP for weather APIs
- **Why this matters:** 4 previous failed attempts documented—avoid repeating: god objects (ISS-002), projection mismatches (ISS-001), circular dependencies (ISS-003), cache race conditions (ISS-004), memory leaks (ISS-006), RenderFlex overflow (ISS-005)
- **Pattern reuse:** Section B of Bible contains battle-tested code; copy don't reinvent—don't rewrite working patterns

## Architecture & data flow
### Provider hierarchy (strict acyclic)
- **Layer 0 (foundation):** `SettingsProvider` only—no dependencies
- **Layer 1 (UI coordination):** `ThemeProvider`, `CacheProvider` depend on Layer 0
- **Layer 2 (domain):** `MapProvider` depends on Layers 0+1 (future: `WeatherProvider`)
- **Declaration:** All providers initialized in `marine_nav_app/lib/main.dart` with `MultiProvider`—never create providers inside widget `build()` methods (see ISS-003)
- **Dependency graph:** Documented in `marine_nav_app/PROVIDER_HIERARCHY.md`; update when adding providers

**Provider Wiring Pattern (from `main.dart`):**
```dart
// CORRECT: Initialize dependencies bottom-up (Layer 0 → 1 → 2)
final settingsProvider = SettingsProvider();
final themeProvider = ThemeProvider();
final cacheProvider = CacheProvider();
final mapProvider = MapProvider(
  settingsProvider: settingsProvider,  // Inject Layer 0 dependency
  cacheProvider: cacheProvider,         // Inject Layer 1 dependency
);
final nmeaProvider = NMEAProvider(
  settingsProvider: settingsProvider,
  cacheProvider: cacheProvider,
);
// Initialize in order (fastest first)
await Future.wait([
  settingsProvider.init(),
  themeProvider.init(),
  cacheProvider.init(),
  mapProvider.init(),
]);
// Pass to MultiProvider
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: settingsProvider),
    ChangeNotifierProvider.value(value: themeProvider),
    ChangeNotifierProvider.value(value: cacheProvider),
    ChangeNotifierProvider.value(value: mapProvider),
    ChangeNotifierProvider.value(value: nmeaProvider),
    ChangeNotifierProvider.value(value: routeProvider),
  ],
  child: MyApp(),
)
```

### Coordinate projection (critical)
- **ProjectionService is mandatory:** ALL lat/lng ↔ screen transforms go through `lib/services/projection_service.dart`
- **Coordinate systems:** MapTiler uses EPSG:3857 (Web Mercator), weather APIs use EPSG:4326 (WGS84)
- **Never do this:**
  ```dart
  // WRONG - causes ISS-001 projection mismatch
  left: (lng + 180) * screenWidth / 360
  ```
- **Always do this:**
  ```dart
  // RIGHT - maintains viewport sync
  final screen = ProjectionService.latLngToScreen(latLng, viewport);
  ```

### Network & caching rules
- **Triple-layer protection:** Retry (3x exponential backoff) + timeout (15s) + cache fallback
- **Single cache coordinator:** `CacheProvider` manages LRU eviction, TTL, version tags—no multiple cache layers (see ISS-004)
- **Reference:** Bible C.4, `lib/services/cache_service.dart`

### File organization
- **Size limit:** Max 300 lines per Dart file/provider (hard limit from ISS-002 god object lesson)
- **Dispose discipline:** All `AnimationController`, `StreamSubscription`, `TextEditingController` must have `dispose()` (see ISS-006 memory leaks)

## Critical Service Layer Patterns

### NMEA Data Stream (Real-time Boat Position & Telemetry)
**Key Files:** `lib/services/nmea_service.dart`, `lib/providers/nmea_provider.dart`, `lib/models/nmea_data.dart`

**Pattern:**
- `NMEAService` runs in background isolate (separate thread) to avoid blocking UI
- Batches NMEA sentences every 200ms before notifying listeners
- Handles TCP/UDP connections with auto-reconnect
- **Use:** `NMEAProvider.nmeaStream` (Stream<NMEAData>) for real-time updates
- **Integration:** Called from `NMEAProvider` which is in Layer 2 (domain)
- **Example:**
  ```dart
  context.watch<NMEAProvider>().nmeaStream.listen((data) {
    print('${data.latitude}, ${data.longitude}, SOG: ${data.sog}');
  });
  ```

### Projection Service (All Coordinate Transforms)
**Key File:** `lib/services/projection_service.dart`
**Rule (ISS-001):** NEVER do manual lat/lng→screen math. ALWAYS use `ProjectionService`.

**Methods:**
```dart
// WGS84 (EPSG:4326) ← → Web Mercator (EPSG:3857)
Offset latLngToScreen(LatLng, Viewport) → screen position
LatLng screenToLatLng(Offset, Viewport) → geographic coordinate
Point webMercatorToWgs84(x, y) → conversion for map tiles
```
**Pattern:**
- `Viewport` contains map center, zoom, rotation, tilt
- Updated by `MapProvider` when user pans/zooms
- All wind arrows, wave overlays, AIS targets use this service
- **Anti-pattern:** `left: (lng + 180) * width / 360` → causes ISS-001

### Geo Utilities (Distance/Bearing Calculations)
**Key File:** `lib/services/geo_utils.dart`
**Use for:**
- Distance between two points: `GeoUtils.distance(from, to)` → meters
- Bearing/heading: `GeoUtils.bearing(from, to)` → degrees (0-360)
- Destination point: `GeoUtils.destination(from, distance, bearing)`
- **Coordinate format:** All methods accept `LatLng` model

## UI system (SailStream / Dual Theme)

### Theme System Architecture
The app supports two visual themes via `ThemeVariant`:
- **Ocean Glass** (default) — Professional nautical theme with frosted glass effects
- **Holographic Cyberpunk** — Futuristic neon theme with particles, glows, gradients

**Key files:**
- `lib/theme/theme_variant.dart` — `ThemeVariant` enum (oceanGlass, holographicCyberpunk)
- `lib/theme/holographic_colors.dart` — Neon palette (Electric Blue #00D9FF, Magenta, Cyber Purple)
- `lib/theme/holographic_effects.dart` — NeonGlow, TextGlow, GlowShadows utilities
- `lib/theme/app_theme.dart` — 4 ThemeData variants via `getThemeForVariant(isDark, variant)`
- `lib/providers/theme_provider.dart` — Manages AppThemeMode + ThemeVariant, persisted to SharedPreferences

**Theme-aware pattern:** Widgets use `Theme.of(context).colorScheme` for colors (adapts automatically). For variant-specific effects (particles, neon glow), use `context.watch<ThemeProvider>().isHolographic`.

### DraggableOverlay System
All map/nav overlay widgets are draggable and resizable:
- `lib/widgets/common/draggable_overlay.dart` — Wraps any widget with drag + resize
- `lib/utils/overlay_layout_store.dart` — Persists position/scale to SharedPreferences
- Resize via bottom-right handle (scale 0.45x–1.5x)
- Used in `MapScreen` and `NavigationModeScreen`

### Design tokens (all in `lib/theme/`)
- **Colors** (`colors.dart`):
  - Primary: `deepNavy` #0A1F3F (backgrounds), `seafoamGreen` #00C9A7 (accents/active)
  - Secondary: `teal` #1D566E (depth), `safetyOrange` #FF9A3D (warnings), `coralRed` #FF6B6B (danger)
  - Surface: `surface` #1A2F4F (cards), `pureWhite` #FFFFFF (text/icons)
- **Typography** (`text_styles.dart`):
  - Data values: `dataValue` 56pt bold (SOG/COG displays)
  - Headings: `heading1` 32pt, `heading2` 24pt semibold
  - Body: `body` 16pt, `bodySmall` 14pt regular
  - Labels: `label` 12pt medium, 0.5px letter-spacing (units/captions)
- **Spacing** (`dimensions.dart`):
  - Scale: `spacingXS` 4px, `spacingS` 8px, `spacingM` 12px, `spacing` 16px, `spacingL` 24px, `spacingXL` 32px
  - Radii: `radiusS` 8px, `radiusM` 12px, `radius` 16px, `radiusL` 20px
  - Glass: `glassBlur` 12px, `glassOpacity` 0.75, `glassBorderOpacity` 0.2
  - Breakpoints: `breakpointMobile` 600px, `breakpointTablet` 1200px
- **No magic numbers:** Use tokens exclusively

### Glass components library
#### Core components
- **GlassCard** (`lib/widgets/glass/glass_card.dart`): Base frosted glass container
  - Padding variants: `small` 12px, `medium` 16px, `large` 24px, `none` 0px
  - Backdrop blur: 12px standard, 15px intense
  - Always wrapped in `RepaintBoundary` for 60 FPS
  - Example: `GlassCard(padding: GlassCardPadding.medium, child: ...)`

#### Holographic effect widgets
- **ParticleBackground** (`lib/widgets/effects/particle_background.dart`): CustomPainter particle system, 60 FPS, adaptive density. Must wrap in `IgnorePointer` when used in Stack.
- **HolographicCard** (`lib/widgets/glass/holographic_card.dart`): Glassmorphism card with neon glow border
- **NeonDataOrb** (`lib/widgets/data_displays/neon_data_orb.dart`): Rotating neon orb for holographic theme
- **GlowText** (`lib/widgets/common/glow_text.dart`): Multi-layer shadow text for bloom effect
- **DraggableOverlay** (`lib/widgets/common/draggable_overlay.dart`): Drag + resize wrapper with persistence

#### SailStream navigation widgets
- **DataOrb** (`lib/widgets/data_displays/data_orb.dart`): Circular data display for critical nav data
  - Size variants: `small` 80px, `medium` 140px, `large` 200px
  - States: `normal`, `alert` (orange ring), `critical` (red ring), `inactive` (50% opacity)
  - Components: seafoam green accent ring, value (48pt), unit (14pt), label (12pt), optional subtitle
  - Hero animation support via `heroTag` parameter
  - Example: `DataOrb(label: 'SOG', value: '13.1', unit: 'kts', size: DataOrbSize.large, state: DataOrbState.normal)`
  
- **TrueWindWidget** (`lib/widgets/data_displays/wind_widget.dart`): Draggable wind indicator
  - Fixed size: 140×140px with circular progress ring
  - Draggable with `onPositionChanged` callback
  - Edit mode shows delete button
  - Example: `TrueWindWidget(speedKnots: 14.2, directionLabel: 'NNE', progress: 0.6)`

- **NavigationSidebar** (`lib/widgets/navigation/navigation_sidebar.dart`): Vertical glass nav rail
  - Accepts list of `NavItem(icon, label)`
  - Active state highlighting (seafoamGreen background)
  - Auto-sized with rounded corners (`radiusL`)
  - Example: `NavigationSidebar(items: navItems, activeIndex: 2, onSelected: (i) => ...)`

#### Responsive layout
- **ResponsiveUtils** (`lib/utils/responsive_utils.dart`):
  - Breakpoints: mobile <600px, tablet 600-1200px, desktop >1200px
  - Extension methods: `context.isMobile`, `context.isTablet`, `context.isDesktop`
  - Spacing multiplier: 1.0x mobile, 1.25x tablet, 1.5x desktop
  - Use `ResponsiveUtils.getResponsiveValue()` for breakpoint-specific values

### Layout requirements
- **No fixed heights:** Use `Flexible`/`Expanded` everywhere (see ISS-005 RenderFlex overflow)
- **SafeArea always:** Wrap top-level screens in `SafeArea` (prevents notch/status bar overlap)
- **Stack positioning:** Use `Positioned` with `OceanDimensions.spacing` for overlay elements
- **Test targets:** iPhone SE (375×667) minimum, test landscape orientation
- **Performance:** All glass widgets auto-wrapped in `RepaintBoundary` to prevent cascading repaints

## Workflows & commands
### Local development
```bash
cd marine_nav_app

# Install dependencies
flutter pub get

# Static analysis (CI will fail on warnings)
flutter analyze --fatal-infos --fatal-warnings

# Format check (match Dart style exactly)
dart format --output=none --set-exit-if-changed .
# Auto-format files
dart format .

# Run tests with coverage (target ≥80%)
flutter test --coverage

# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Hot reload during development (press 'r' in terminal)
# Hot restart (press 'R' in terminal)
```

### CI validation (runs on every PR)
**Workflow:** `.github/workflows/flutter-ci.yml`
- **Tests**: `flutter test --coverage` → Codecov upload
- **Analysis**: `flutter analyze --fatal-warnings` (treats warnings as errors)
- **Formatting**: `dart format --output=none --set-exit-if-changed .` (must match Dart style exactly)
- **Builds**: Android APK (debug) + Web (validates compilation)
- **Runs on**: Push to `main`, PRs to `main`, changes in `marine_nav_app/`
- See `.github/workflows/README.md` for details

### iOS parallel development
- iOS scaffold ready in `marine_nav_app/ios/`
- Requires: macOS + Xcode + CocoaPods
- Open `ios/Runner.xcworkspace` in Xcode or use `flutter run -d <ios-device-id>`

### Testing Strategy
**Test Organization:**
- **Unit tests** (`test/providers/`, `test/services/`, `test/models/`): Test business logic in isolation
- **Widget tests** (`test/widget_test.dart`): Test UI components and screen rendering
- **Integration tests** (`test/integration/`): Test real workflows (e.g., NMEA → UI update → map render)

**Running Tests:**
```bash
# Run all tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/providers/map_provider_test.dart

# Run tests matching name pattern
flutter test --name "NMEA"

# Watch mode for TDD
flutter test --watch
```

**Writing Tests:**
1. Mock external dependencies: `SharedPreferences`, `http.Client`, streams
2. Test provider initialization: `setUp()` initializes all dependencies
3. Verify state changes: Use `notifyListeners()` and `tester.pump()`
4. Always test `dispose()` cleanup

**Example (Provider Test):**
```dart
void main() {
  test('MapProvider updates viewport on pan', () async {
    final settingsProvider = SettingsProvider();
    final cacheProvider = CacheProvider();
    final mapProvider = MapProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    
    // Test state change
    mapProvider.pan(lat: 10.5, lng: 20.3);
    expect(mapProvider.viewport.center.latitude, 10.5);
    
    // Clean up
    mapProvider.dispose();
  });
}
```

**Coverage Requirements:**
- Minimum 80% coverage for new code
- Run: `flutter test --coverage`
- Check: `coverage/lcov.info`

## Project-Specific Code Patterns

### Provider Initialization Pattern
**ALL providers must:**
1. Accept dependencies via constructor (no global state)
2. Have `Future<void> init()` method that loads persisted state
3. Override `dispose()` to clean up controllers/subscriptions
4. Extend `ChangeNotifier` for `notifyListeners()` support

**Pattern:**
```dart
class ExampleProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final CacheProvider _cache;
  late StreamSubscription _sub;
  
  ExampleProvider({
    required SettingsProvider settingsProvider,
    required CacheProvider cacheProvider,
  })  : _settings = settingsProvider,
        _cache = cacheProvider;
  
  Future<void> init() async {
    // Load from cache, start listeners, etc.
    _sub = _stream.listen((_) => notifyListeners());
  }
  
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
```

### Error Handling Pattern
**Network requests use triple-layer protection:**
```dart
// Retry (3x exponential backoff) + timeout (15s) + cache fallback
Future<T> _retryWithBackoff<T>(
  Future<T> Function() request,
  {int maxRetries = 3}
) async {
  Duration delay = Duration(milliseconds: 100);
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await request().timeout(Duration(seconds: 15));
    } on TimeoutException {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(delay);
      delay *= 2; // Exponential backoff
    }
  }
  throw Exception('Failed after retries');
}
```

### Stream Usage Pattern
**Always clean up streams in `dispose()`:**
```dart
class DataProvider extends ChangeNotifier {
  final List<StreamSubscription> _subscriptions = [];
  
  void startListening(Stream<Data> stream) {
    _subscriptions.add(
      stream.listen((_) => notifyListeners())
    );
  }
  
  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
```

### Widget Tree Pattern
**Never use `context.read()` in build—use `Consumer` or `watch()`:**
```dart
// WRONG - data won't update
Widget build(BuildContext context) {
  final data = context.read<DataProvider>().data;
  return Text(data);
}

// CORRECT - Rebuilds when data changes
Widget build(BuildContext context) {
  final data = context.watch<DataProvider>().data;
  return Text(data);
}

// CORRECT - Fine-grained rebuilds
Widget build(BuildContext context) {
  return Consumer<DataProvider>(
    builder: (_, provider, __) => Text(provider.data),
  );
}
```

## Documentation sync (mandatory)
When you change:
- **Add/modify files:** Update `docs/CODEBASE_MAP.md` (directory structure section)
- **Fix documented issue:** Update `docs/KNOWN_ISSUES_DATABASE.md` (mark ✅ RESOLVED, add solution)
- **Implement feature:** Update `docs/FEATURE_REQUIREMENTS.md` (check acceptance criteria)
- **Change provider hierarchy:** Update `marine_nav_app/PROVIDER_HIERARCHY.md` (dependency graph)

## Common gotchas from 4 failed attempts
1. **Projection mismatch (ISS-001):** Wind arrows at wrong positions → use `ProjectionService` always
2. **God objects (ISS-002):** `MapController` hit 2,847 lines → enforce 300-line limit
3. **Provider crashes (ISS-003):** Hot reload killed providers → create in `main.dart` only
4. **Stale cache (ISS-004):** Multiple cache layers → single `CacheProvider` coordinator
5. **Memory leaks (ISS-006):** Undisposed controllers → override `dispose()` everywhere
6. **UI overflow (ISS-005):** Fixed heights → use `Flexible`/`Expanded`

## Quick reference checklist
Before starting work:
- [ ] Read Bible Section A (failure patterns) for context
- [ ] Check `KNOWN_ISSUES_DATABASE.md` for similar problems
- [ ] Verify against Architecture Rules (Bible Section C)
- [ ] Use working patterns from Bible Section B

While coding:
- [ ] Keep files under 300 lines
- [ ] All coordinates through `ProjectionService`
- [ ] Providers created in `main.dart` only
- [ ] Dispose all controllers/subscriptions
- [ ] Use design tokens, not magic numbers
- [ ] Write tests (≥80% coverage)

Before committing:
- [ ] Run `flutter analyze --fatal-warnings` (must pass)
- [ ] Run `dart format .` (auto-format)
- [ ] Run `flutter test --coverage` (verify tests pass)
- [ ] Update documentation (4 docs listed in "Documentation sync" section)
