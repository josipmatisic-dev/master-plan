# ParticleBackground Widget - Usage Guide

## Overview

`ParticleBackground` is a high-performance particle effect system designed for the Holographic Cyberpunk theme. It renders floating particles with pulsing opacity animations using `CustomPainter` for optimal 60 FPS performance.

## Features

### ✨ Performance
- **CustomPainter-based rendering** for minimal overhead
- **RepaintBoundary wrapping** to isolate repaints
- **Reusable Paint objects** to avoid memory allocations
- **<2ms per frame** particle rendering
- **Auto-adaptive density** - reduces particles if FPS drops below 50

### 🎨 Visual Features
- **Neon colors**: Electric Blue, Neon Cyan, Neon Magenta (from HolographicColors)
- **Pulsing animation**: Opacity oscillates via sine wave (0.5-2.0 Hz)
- **Smooth physics**: Upward float with velocity vectors
- **Particle lifetime**: 5-10 seconds (auto-respawn)

### 📱 Responsive Design
- **Desktop (>1200px)**: 80-120 particles
- **Tablet (600-1200px)**: 50-80 particles
- **Mobile (<600px)**: 30-50 particles
- **Low-end devices**: Auto-reduces to 20-30 particles

### ♿ Accessibility
- **Respects `disableAnimations` flag** for motion-sensitive users
- **Proper lifecycle management** (dispose controller)
- **Performance monitoring** with optional debug logging

## Basic Usage

### Simple Background

```dart
import 'package:marine_nav_app/widgets/effects/particle_background.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Particle background
        ParticleBackground(),
        
        // Your content on top
        Center(
          child: Text('Navigation Data'),
        ),
      ],
    );
  }
}
```

### Custom Particle Count

```dart
// Desktop with specific particle count
ParticleBackground(
  particleCount: 150,
),
```

### Custom Colors

```dart
ParticleBackground(
  colors: [
    Color(0xFF00D9FF), // Electric Blue
    Color(0xFFFF00FF), // Neon Magenta
  ],
),
```

### Debug Mode (FPS Monitoring)

```dart
ParticleBackground(
  debugMode: true, // Logs FPS and particle count reductions
),
```

## Architecture

### Particle Class
- **Properties**: Size, color, velocity, lifetime, position
- **Physics**: Update position based on velocity each frame
- **Animation**: Pulsing opacity via sine wave
- **Lifecycle**: Auto-respawns at bottom of screen when dead

### ParticlePainter (CustomPainter)
- **Efficient rendering** using reusable Paint object
- **Bounds checking** to avoid drawing off-screen particles
- **shouldRepaint**: Always returns true (particles are always moving)

### ParticleBackground (StatefulWidget)
- **AnimationController**: 60 FPS animation ticker
- **FPS monitoring**: Tracks frame timing and auto-reduces on low performance
- **Accessibility**: Disables animations when `disableAnimations` is true
- **Lifecycle**: Proper disposal of controller and timer

## Performance Considerations

### Memory
- **Particles**: ~200 bytes per particle × 100 particles = ~20KB
- **Paint objects**: 1 reusable object (minimal overhead)
- **Total overhead**: <5MB for maximum particle count

### CPU
- **Update loop**: O(n) where n = particle count
- **Paint loop**: O(n) with bounds checking
- **FPS target**: 60 FPS (16.67ms per frame)
- **Budget**: <2ms for particle rendering

### Optimization Tips

1. **Use RepaintBoundary** - Already done in the widget
2. **Wrap in Stack** - Put other widgets on top, not overlapping
3. **Monitor debug logs** - Check for FPS drops and auto-reduction
4. **Respect user preferences** - System honors `disableAnimations`

## Responsive Behavior Example

```dart
class HolographicScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Particle background adapts automatically
        ParticleBackground(),
        
        // Content adapts to screen size
        SingleChildScrollView(
          child: Column(
            children: [
              // Your adaptive layout
            ],
          ),
        ),
      ],
    );
  }
}
```

Screen sizes and particle counts:
- 1920×1080 (Desktop): 80-120 particles
- 1024×768 (Tablet): 50-80 particles  
- 375×667 (Mobile): 30-50 particles
- Low-end: 20-30 particles (auto-detected)

## Performance Monitoring

### Debug Output Example

```
flutter: ParticleBackground: FPS=45.0, reducing particles to 40
flutter: ParticleBackground: FPS=52.0, reducing particles to 32
```

Enable with:
```dart
ParticleBackground(debugMode: true)
```

## Color Palette (HolographicColors)

```dart
static const List<Color> particleColors = [
  Color(0xFF00D9FF), // Electric Blue
  Color(0xFF00FFFF), // Neon Cyan
  Color(0xFFFF00FF), // Neon Magenta
];
```

These colors are randomly selected for each particle.

## Animation Parameters

| Parameter | Min | Max | Default Range |
|-----------|-----|-----|----------------|
| Size (px) | 2.0 | 6.0 | 2.0-6.0 |
| Velocity X | 0.5 | 1.5 | 0.5-1.5 |
| Velocity Y | -0.8 | -0.3 | -0.3 to -0.8 |
| Lifetime (s) | 5.0 | 10.0 | 5.0-10.0 |
| Pulse Speed (Hz) | 0.5 | 2.0 | 0.5-2.0 |
| Opacity | 0.3 | 0.8 | Pulsing |

## Lifecycle

1. **initState()**: 
   - Colors determined
   - AnimationController created and started
   - Initial particles spawned
   - FPS monitoring started

2. **_onAnimationUpdate()** (60 times/second):
   - Particles updated (position, age, opacity)
   - Dead particles respawned
   - FPS monitored every 1 second
   - Particle count reduced if FPS < 50

3. **didChangeDependencies()**:
   - Particle count recalculated on screen size change

4. **dispose()**:
   - AnimationController disposed
   - FPS timer stopped

## Troubleshooting

### High Memory Usage
- **Solution**: Reduce `particleCount` or check for debug mode
- **Check**: Enable debug mode to see FPS and particle count changes

### Low FPS
- **Automatic**: System reduces particle count automatically
- **Manual**: Set `particleCount` to lower value
- **Check**: View debug logs for FPS metric

### Particles Not Visible
- **Check**: Ensure ParticleBackground is NOT on top of other widgets
- **Solution**: Use Stack with ParticleBackground first

### Animations Choppy on Mobile
- **Expected**: `disableAnimations` will disable particle system
- **Fallback**: System auto-reduces particles on low FPS

## File Structure

```
lib/
├── widgets/
│   └── effects/
│       ├── particle_background.dart      (310 lines)
│       └── PARTICLE_BACKGROUND_USAGE.md  (This file)
├── theme/
│   └── holographic_colors.dart           (HolographicColors class)
```

## Testing

```dart
testWidgets('ParticleBackground renders without errors', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            ParticleBackground(),
            Center(child: Text('Test')),
          ],
        ),
      ),
    ),
  );
  
  expect(find.byType(ParticleBackground), findsOneWidget);
  expect(find.byType(CustomPaint), findsOneWidget);
  
  await tester.pumpAndSettle();
});
```

## See Also

- `lib/theme/holographic_colors.dart` - Color definitions
- `HOLOGRAPHIC_THEME_SPEC.md` - Complete design specification
- Flutter CustomPainter documentation
- Flutter AnimationController documentation
