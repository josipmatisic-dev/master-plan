# GitHub Copilot Instructions - Marine Navigation App

## Quick context
- **Repo structure:** Master planning docs at root; runnable Flutter app in `marine_nav_app/`
- **Read first, code second:** `docs/MASTER_DEVELOPMENT_BIBLE.md` (Sections A: failure analysis, C: architecture rules), then `docs/AI_AGENT_INSTRUCTIONS.md`, `docs/KNOWN_ISSUES_DATABASE.md` (18 documented issues), and `docs/CODEBASE_MAP.md`
- **Why this matters:** 4 previous failed attempts documented—avoid repeating god objects, projection mismatches, circular dependencies, and cache race conditions
- **Pattern reuse:** Section B of Bible contains battle-tested code; copy don't reinvent

## Architecture & data flow
### Provider hierarchy (strict acyclic)
- **Layer 0 (foundation):** `SettingsProvider` only—no dependencies
- **Layer 1 (UI coordination):** `ThemeProvider`, `CacheProvider` depend on Layer 0
- **Layer 2 (domain):** `MapProvider` depends on Layers 0+1 (future: `WeatherProvider`)
- **Declaration:** All providers initialized in `marine_nav_app/lib/main.dart` with `MultiProvider`—never create providers inside widget `build()` methods (see ISS-003)
- **Dependency graph:** Documented in `marine_nav_app/PROVIDER_HIERARCHY.md`; update when adding providers

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

## UI system (SailStream / Ocean Glass)
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
flutter pub get
flutter analyze --fatal-infos --fatal-warnings  # CI will fail on warnings
dart format --output=none --set-exit-if-changed .
flutter test --coverage  # Target ≥80% for new code
flutter run -d <device>  # or flutter devices to list
```

### CI validation (runs on every PR)
- Tests with coverage → Codecov upload
- Static analysis (treats warnings as errors)
- Format check (no auto-format, must match Dart style)
- Builds: Android APK (debug) + Web
- See `.github/workflows/README.md` for details

### iOS parallel development
- iOS scaffold ready in `marine_nav_app/ios/`
- Requires: macOS + Xcode + CocoaPods
- Open `ios/Runner.xcworkspace` in Xcode or use `flutter run -d <ios-device-id>`

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
- [ ] Read Bible Section A (failure patterns) for context
- [ ] Check `KNOWN_ISSUES_DATABASE.md` for similar problems
- [ ] Verify against Architecture Rules (Bible Section C)
- [ ] Use working patterns from Bible Section B
- [ ] Keep files under 300 lines
- [ ] All coordinates through `ProjectionService`
- [ ] Providers created in `main.dart` only
- [ ] Dispose all controllers/subscriptions
- [ ] Use design tokens, not magic numbers
- [ ] Update documentation (4 docs listed above)
- [ ] Write tests (≥80% coverage)
