# Holographic Cyberpunk Theme - Visual Specification

**Version:** 1.0  
**Based on:** Screenshots in `/Users/master/StudioProjects/screenshots/`  
**Target:** Flutter implementation for Marine Navigation App

---

## Design Analysis from Reference Screenshots

### Overall Aesthetic
- **Style**: Futuristic holographic cyberpunk with heavy neon emphasis
- **Background**: Deep space/cosmic dark backgrounds (#0A0A1A - #1A1A2E range)
- **Primary technique**: Glassmorphism with vibrant neon accents
- **Key differentiator**: High-energy neon glows vs Ocean Glass's subtle professional look

---

## Color Palette

### Primary Colors
| Color Name | Hex Code | RGB | Usage |
|-----------|----------|-----|-------|
| Electric Blue | `#00D9FF` | rgb(0, 217, 255) | Primary accent, active states, glows |
| Neon Cyan | `#00FFFF` | rgb(0, 255, 255) | Secondary accent, highlights |
| Neon Magenta | `#FF00FF` | rgb(255, 0, 255) | Tertiary accent, warnings, glow rings |
| Cyber Purple | `#8B00FF` | rgb(139, 0, 255) | Gradient component, depth |
| Deep Purple | `#4B0082` | rgb(75, 0, 130) | Gradient component, backgrounds |
| Cosmic Black | `#0A0A1A` | rgb(10, 10, 26) | Primary background |
| Space Navy | `#1A1A2E` | rgb(26, 26, 46) | Secondary background, surfaces |
| Pure White | `#FFFFFF` | rgb(255, 255, 255) | Text, icons |

### Gradient Definitions

#### 1. Purple-to-Blue Gradient
```dart
LinearGradient(
  colors: [
    Color(0xFF8B00FF), // Cyber Purple
    Color(0xFF00D9FF), // Electric Blue
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

#### 2. Magenta-to-Cyan Gradient
```dart
LinearGradient(
  colors: [
    Color(0xFFFF00FF), // Neon Magenta
    Color(0xFF00FFFF), // Neon Cyan
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

#### 3. Deep Space Background Gradient
```dart
LinearGradient(
  colors: [
    Color(0xFF0A0A1A), // Cosmic Black
    Color(0xFF1A1A2E), // Space Navy
    Color(0xFF4B0082), // Deep Purple (subtle)
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)
```

---

## Visual Effects Specifications

### 1. Glassmorphism Effect

**Parameters:**
```dart
// Background blur strength
backdropBlur: 20.0 sigma (stronger than Ocean Glass's 12px)

// Surface transparency
backgroundColor: Color.fromRGBO(26, 26, 46, 0.15) // 15% opacity

// Border
borderColor: Color.fromRGBO(0, 217, 255, 0.3) // Electric blue @ 30%
borderWidth: 1.5px
```

**Flutter Implementation:**
```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
  child: Container(
    decoration: BoxDecoration(
      color: Color.fromRGBO(26, 26, 46, 0.15),
      border: Border.all(
        color: Color.fromRGBO(0, 217, 255, 0.3),
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
  ),
)
```

### 2. Neon Glow Effect (Multi-Layer Shadows)

**Default Glow (Idle State):**
```dart
boxShadow: [
  // Inner glow (subtle)
  BoxShadow(
    color: Color(0xFF00D9FF).withOpacity(0.2),
    blurRadius: 8,
    spreadRadius: 0,
  ),
  // Middle glow
  BoxShadow(
    color: Color(0xFF00D9FF).withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: -5,
  ),
  // Outer bloom
  BoxShadow(
    color: Color(0xFF00D9FF).withOpacity(0.4),
    blurRadius: 40,
    spreadRadius: -10,
  ),
]
```

**Intensified Glow (Hover/Active State):**
```dart
boxShadow: [
  // Inner glow (bright)
  BoxShadow(
    color: Color(0xFF00D9FF).withOpacity(0.5),
    blurRadius: 12,
    spreadRadius: 2,
  ),
  // Middle glow
  BoxShadow(
    color: Color(0xFF00D9FF).withOpacity(0.6),
    blurRadius: 30,
    spreadRadius: 0,
  ),
  // Outer bloom (extended)
  BoxShadow(
    color: Color(0xFF00D9FF).withOpacity(0.5),
    blurRadius: 60,
    spreadRadius: -5,
  ),
]
```

### 3. Floating Particle System

**Particle Properties:**
```dart
class Particle {
  // Visual
  double size: 2.0 - 6.0 (random)
  Color color: Electric Blue / Neon Cyan / Neon Magenta (random)
  double opacity: 0.3 - 0.8 (random, pulsing)
  
  // Physics
  Offset position: random screen position
  Offset velocity: Vector2(0.5 - 1.5, -0.3 - 0.8) // upward float
  double lifetime: 5.0 - 10.0 seconds
  
  // Animation
  bool pulsing: true (opacity oscillates 0.3 ↔ 0.8)
  double pulseSpeed: 0.5 - 2.0 Hz
}
```

**Particle Density:**
- Desktop: 80-120 particles
- Tablet: 50-80 particles
- Mobile: 30-50 particles
- Low-end devices: 20-30 particles (auto-detected)

**Performance Budget:** <2ms per frame for particle system

### 4. Gradient Border Animation

**Animated Rotating Gradient:**
```dart
// Rotate gradient angle over 4 seconds
AnimationController(duration: Duration(seconds: 4))
  
// Gradient rotates 0° → 360°
Transform.rotate(
  angle: animation.value * 2 * pi,
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFFF00FF), Color(0xFF00FFFF)],
      ),
    ),
  ),
)
```

### 5. Button Press Animation

**Sequence:**
1. **Touch Down**: Scale 1.0 → 0.92 (80ms, easeOut)
2. **Flash**: Brightness overlay 0% → 40% → 0% (150ms)
3. **Glow Pulse**: Shadow blur 20 → 60 → 20 (200ms)
4. **Touch Up**: Scale 0.92 → 1.0 (120ms, elasticOut)

**Flutter Implementation:**
```dart
GestureDetector(
  onTapDown: (_) => _startPressAnimation(),
  onTapUp: (_) => _endPressAnimation(),
  child: AnimatedScale(
    scale: _isPressed ? 0.92 : 1.0,
    duration: Duration(milliseconds: _isPressed ? 80 : 120),
    curve: _isPressed ? Curves.easeOut : Curves.elasticOut,
    child: AnimatedContainer(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: _isPressed ? 60 : 20,
            // ... other shadow properties
          ),
        ],
      ),
    ),
  ),
)
```

### 6. Scroll Reveal Animation

**Entrance Effects:**
```dart
// When widget enters viewport (80% visible threshold)
AnimatedOpacity(
  opacity: _isVisible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOut,
)

AnimatedScale(
  scale: _isVisible ? 1.0 : 0.9,
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
)

// Stagger delay for multiple items
delay: index * 100ms
```

---

## Typography with Glow

### Glow Text Styles

**Data Value (56pt with bloom):**
```dart
TextStyle(
  fontSize: 56,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  shadows: [
    Shadow(
      color: Color(0xFF00D9FF).withOpacity(0.6),
      blurRadius: 20,
    ),
    Shadow(
      color: Color(0xFF00D9FF).withOpacity(0.3),
      blurRadius: 40,
    ),
  ],
)
```

**Heading with subtle glow:**
```dart
TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w600,
  color: Colors.white,
  shadows: [
    Shadow(
      color: Color(0xFF00D9FF).withOpacity(0.4),
      blurRadius: 12,
    ),
  ],
)
```

---

## Component Specifications

### Holographic Glass Card

**Visual Properties:**
- Background: Space Navy @ 15% opacity
- Border: Electric Blue @ 30% opacity, 1.5px width
- Backdrop blur: 20px sigma
- Shadow: 3-layer neon glow (Electric Blue)
- Border radius: 16px
- Padding: 16px (medium), 24px (large), 12px (small)

**Hover State:**
- Border opacity: 30% → 50%
- Glow intensity: 2x amplification
- Transition: 200ms ease

### Neon Data Orb

**Visual Properties:**
- Size: 80px (small), 140px (medium), 200px (large)
- Background: Radial gradient (deep purple → transparent)
- Ring: 3px width, Electric Blue with glow
- Ring glow: 3-layer shadow (20px, 40px, 60px blur)
- Value text: 48pt with bloom effect
- Label text: 12pt, no glow
- Progress ring: Magenta-to-Cyan gradient with rotation animation

**States:**
- Normal: Electric Blue ring
- Alert: Neon Magenta ring
- Critical: Pulsing red ring (1Hz pulse)
- Inactive: 30% opacity, no glow

---

## Animation Timing

| Animation | Duration | Curve | FPS Target |
|-----------|----------|-------|-----------|
| Theme switch (cross-fade) | 400ms | easeInOutCubic | 60 |
| Hover glow intensify | 200ms | easeOut | 60 |
| Button press | 80-120ms | easeOut/elasticOut | 60 |
| Particle movement | Continuous | linear | 60 |
| Gradient rotation | 4000ms | linear (loop) | 30 |
| Scroll reveal | 600ms | easeOutCubic | 60 |
| Pulsing glow | 2000ms | sine wave | 30 |

---

## Responsive Breakpoints

| Device Class | Width Range | Particle Count | Blur Strength | Glow Layers |
|--------------|-------------|----------------|---------------|-------------|
| Desktop | >1200px | 80-120 | 20px | 3 |
| Tablet | 600-1200px | 50-80 | 16px | 3 |
| Mobile | <600px | 30-50 | 12px | 2 |
| Low-end | (auto-detect) | 20-30 | 10px | 2 |

**Mobile Adaptations:**
- Reduce particle count by 50%
- Reduce blur sigma by 40%
- Remove tertiary glow layer
- Disable gradient border animation (static gradient)

---

## Accessibility Considerations

### Reduced Motion
When `MediaQuery.of(context).disableAnimations == true`:
- Disable particle system
- Disable gradient rotation
- Disable pulsing glow
- Disable scroll reveal (instant appear)
- Keep button press (essential feedback)

### Contrast Ratios
- Text on dark background: 16:1 (White on #0A0A1A)
- Neon glow text: Ensure base text meets 7:1 before glow
- Border contrast: 3:1 minimum (Electric Blue on Space Navy)

---

## Performance Targets

| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| Frame time | <16ms | 16.67ms (60 FPS) |
| Particle render | <2ms | 3ms |
| Blur operations | <3ms | 5ms |
| Glow shadows | <1ms | 2ms |
| Memory (particles) | <5MB | 10MB |
| Theme switch time | <500ms | 1000ms |

---

## Implementation Notes

### Key Differences from Ocean Glass
| Aspect | Ocean Glass | Holographic Cyberpunk |
|--------|-------------|----------------------|
| Color temperature | Cool blue (professional) | Vibrant neon (energetic) |
| Glow intensity | Subtle/none | Prominent multi-layer |
| Background | Solid navy | Particle-filled space |
| Borders | Minimal white @ 20% | Bright neon @ 30-50% |
| Animations | Gentle fades | Dynamic pulses/rotations |
| Use case | Professional navigation | Gaming/entertainment mode |

### Flutter-Specific Optimizations
1. **RepaintBoundary**: Wrap all glowing elements
2. **CustomPainter**: Use for particles (not widgets)
3. **Shader compilation**: Pre-warm blur shaders on app start
4. **Layer caching**: Cache static gradient borders
5. **Opacity optimization**: Use `Opacity` widget sparingly, prefer `Color.withOpacity()`

---

**Document Status:** Ready for implementation  
**Next Step:** Create `lib/theme/holographic_colors.dart` with these specifications
