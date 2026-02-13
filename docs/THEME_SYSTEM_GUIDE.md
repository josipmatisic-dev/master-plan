# SailStream Theme System Guide

## Overview
SailStream supports two visual themes that can be switched at runtime:
- **Ocean Glass** — Professional nautical aesthetic with frosted glass, muted blues
- **Holographic Cyberpunk** — Futuristic neon with particles, glow effects, vibrant gradients

## Architecture

### Key Files
| File | Purpose |
|------|---------|
| `marine_nav_app/lib/theme/theme_variant.dart` | ThemeVariant enum |
| `marine_nav_app/lib/theme/app_theme.dart` | ThemeData factory (4 themes) |
| `marine_nav_app/lib/theme/holographic_colors.dart` | Neon color palette |
| `marine_nav_app/lib/theme/holographic_effects.dart` | Glow/shadow utilities |
| `marine_nav_app/lib/providers/theme_provider.dart` | State management + persistence |

### How Theme Switching Works
1. User toggles via ThemeControls or SettingsScreen
2. `ThemeProvider.toggleThemeVariant()` updates state + persists to SharedPreferences
3. `AppTheme.getThemeForVariant(isDark, variant)` returns new ThemeData
4. MaterialApp animates transition over 400ms (cross-fade)
5. Widgets using `Theme.of(context).colorScheme` update automatically

### Color Mapping
| Semantic | Ocean Glass | Holographic |
|----------|-------------|-------------|
| Primary | seafoamGreen #00C9A7 | Electric Blue #00D9FF |
| Secondary | teal #1D566E | Neon Magenta #FF00FF |
| Surface | deepNavy #1A2F4F | Deep Space #0A0E1A |
| Error | coralRed #FF6B6B | #FF3366 |
| On Surface | pureWhite #FFFFFF | #FFFFFF |

## Adding Theme-Aware Widgets

### Pattern 1: Use colorScheme (preferred)
```dart
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    color: cs.surface,
    child: Text('Hello', style: TextStyle(color: cs.onSurface)),
  );
}
```

### Pattern 2: Variant-specific effects
```dart
Widget build(BuildContext context) {
  final isHolo = context.watch<ThemeProvider>().isHolographic;
  return Stack(children: [
    if (isHolo) IgnorePointer(child: ParticleBackground()),
    // rest of UI
  ]);
}
```

## Visual Effects Components
- **ParticleBackground** — Must wrap in IgnorePointer in Stacks
- **GlassCard** — Auto-adapts: neon glow border (holo) vs frosted blur (ocean)
- **GlowText** — Multi-layer shadow bloom
- **NeonDataOrb** — Pulsing glow ring variant of DataOrb
- **HolographicCard** — Glassmorphism + animated gradient border

## DraggableOverlay System
All map overlay widgets use `DraggableOverlay` for:
- Drag-to-move (GestureDetector pan)
- Drag-to-resize (bottom-right handle, 0.45x–1.5x scale)
- Persistence (position + scale saved to SharedPreferences via OverlayLayoutStore)

### Usage
```dart
DraggableOverlay(
  id: 'map_compass',  // unique key for persistence
  initialPosition: Offset(140, 500),
  child: CompassWidget(...),
)
```

## Testing Theme Changes
1. Run on simulator: `flutter run -d <device-id>`
2. Navigate to Home Screen
3. Tap "Switch to Holographic ⚡" in Theme Controls
4. Verify: neon borders, particle background, glowing title
5. Navigate to Map/Nav screens to verify theme propagation
