# UI Design System

## SailStream - Ocean Glass Design Language

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Status:** Initial Release

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Glass Effects](#glass-effects)
5. [Component Library](#component-library)
6. [Layout System](#layout-system)
7. [Animation Guidelines](#animation-guidelines)
8. [Responsive Design](#responsive-design)
9. [Implementation Checklist](#implementation-checklist)
10. [Testing Requirements](#testing-requirements)

---

## Design Philosophy

### Ocean Glass Vision

**"Data flows like water, UI feels like frosted sea glass over nautical charts"**

The Ocean Glass design system creates a fluid, marine-inspired interface where information is presented with clarity and depth, using translucent glass-like surfaces that float above the map layer.

### Core Principles

#### 1. Data as Fluid Element

Information flows and connects visually. Data transitions are smooth and organic, mimicking the movement of water.

#### 2. Contextual Priority & Holographic Layering

Critical navigation data expands and becomes prominent when needed. Less critical information recedes into the background, creating a visual hierarchy through depth.

#### 3. Ambient Intelligence

The UI adapts to environmental conditions:

- **Night Navigation:** Deep navy backgrounds with reduced brightness
- **Daytime Use:** Lighter glass effects with higher contrast
- **Weather Conditions:** UI color temperature adjusts to conditions

#### 4. Glass Aesthetics

All UI elements use frosted glass effects with subtle translucency, creating depth while maintaining readability over complex map backgrounds.

---

## Color System

### Primary Palette

| Color Name | Hex Code | RGB | Usage |
| ------------ | ---------- | ----- | ------- |
| Deep Navy | `#0A1F3F` | rgb(10, 31, 63) | Primary background, night mode |
| Teal | `#1D566E` | rgb(29, 86, 110) | Secondary accents, depth |
| Seafoam Green | `#00C9A7` | rgb(0, 201, 167) | Primary accent, active states |
| Safety Orange | `#FF9A3D` | rgb(255, 154, 61) | Warnings, alerts |
| Coral Red | `#FF6B6B` | rgb(255, 107, 107) | Danger, critical alerts |
| Pure White | `#FFFFFF` | rgb(255, 255, 255) | Text, icons, borders |

### Semantic Colors

```dart
// lib/theme/ocean_colors.dart
class OceanColors {
  // Primary Colors
  static const deepNavy = Color(0xFF0A1F3F);
  static const teal = Color(0xFF1D566E);
  static const seafoamGreen = Color(0xFF00C9A7);
  static const safetyOrange = Color(0xFFFF9A3D);
  static const coralRed = Color(0xFFFF6B6B);
  static const pureWhite = Color(0xFFFFFFFF);
  
  // Semantic Colors
  static const primary = seafoamGreen;
  static const secondary = teal;
  static const background = deepNavy;
  static const surface = Color(0xFF1A2F4F); // Lighter navy for surfaces
  static const error = coralRed;
  static const warning = safetyOrange;
  static const success = seafoamGreen;
  
  // Text Colors
  static const textPrimary = pureWhite;
  static const textSecondary = Color(0xFFB0C4DE); // Light steel blue
  static const textDisabled = Color(0xFF5A6F89); // Medium gray-blue
  
  // Opacity Variants
  static final glassBackground = deepNavy.withOpacity(0.75);
  static final glassBackgroundLight = pureWhite.withOpacity(0.85);
  static final glassBorder = pureWhite.withOpacity(0.2);
}
```text

### Color Usage Guidelines

- **Deep Navy:** Use for main app background, night mode, behind glass surfaces
- **Seafoam Green:** Active states, progress indicators, primary actions
- **Safety Orange:** Non-critical warnings, attention-grabbing elements
- **Coral Red:** Critical alerts, danger zones, error states
- **Pure White:** All text, icons, and borders for maximum contrast

---

## Typography

### Font Stack

**Primary:** SF Pro Display (iOS/macOS)  
**Fallback:** Poppins, system-ui, sans-serif

### Type Scale

| Style Name | Size | Weight | Line Height | Letter Spacing | Usage |
| ------------ | ------ | -------- | ------------- | ---------------- | ------- |
| Data Value | 56pt | Bold (700) | 1.2 | 0 | Large numeric displays (SOG, COG) |
| Heading 1 | 32pt | Semibold (600) | 1.3 | -0.5px | Screen titles |
| Heading 2 | 24pt | Semibold (600) | 1.4 | -0.3px | Section headers |
| Body Large | 18pt | Regular (400) | 1.5 | 0 | Prominent body text |
| Body | 16pt | Regular (400) | 1.5 | 0 | Standard content |
| Body Small | 14pt | Regular (400) | 1.5 | 0 | Secondary content |
| Label Large | 14pt | Medium (500) | 1.3 | 0.5px | Form labels, units |
| Label | 12pt | Medium (500) | 1.3 | 0.5px | Small labels, captions |
| Label Small | 10pt | Medium (500) | 1.3 | 0.8px | Tiny labels, hints |

### Implementation

```dart
// lib/theme/ocean_text_styles.dart
class OceanTextStyles {
  static const String fontFamily = 'SF Pro Display';
  static const String fallbackFont = 'Poppins';
  
  static const dataValue = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFamily: fontFamily,
  );
  
  static const heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.5,
    fontFamily: fontFamily,
  );
  
  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.3,
    fontFamily: fontFamily,
  );
  
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );
}
```text

---

## Glass Effects

### Frosted Glass Specifications

**Backdrop Blur:** 10-12px sigma  
**Opacity:** 75-85% based on theme  
**Border:** 1px white at 10-20% opacity  
**Border Radius:** 12-16px for polished sea glass aesthetic  
**Shadow:** Multi-layer shadows for depth

### Glass Effect Variants

#### Standard Glass (Default)

```dart
Container(
  decoration: BoxDecoration(
    color: OceanColors.deepNavy.withOpacity(0.75),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 32,
        offset: Offset(0, 8),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: child,
    ),
  ),
)
```text

#### Light Glass (Daytime)

- Opacity: 85%
- Background: Pure white (#FFFFFF)
- Border: Black at 10% opacity

#### Intense Glass (Overlays)

- Opacity: 85%
- Blur: 15px sigma
- Shadow: More pronounced

### Performance Guidelines

**CRITICAL:** Glass effects MUST maintain 60 FPS performance.

- Use `RepaintBoundary` for complex glass widgets
- Limit number of simultaneous blur effects (max 5 on screen)
- Use cached blur for static content
- Test on low-end devices (iPhone 8, Android mid-range)

---

## Component Library

### 1. Glass Card

**Purpose:** Base reusable container with frosted glass effect

#### Specifications

**Padding Variants:**

- Small: 12px
- Medium: 16px
- Large: 24px

**Border Radius:** 16px  
**Border:** 1px white at 20% opacity  
**Shadow:** 0px 8px 32px rgba(0,0,0,0.3)

#### Implementation

```dart
// lib/widgets/glass/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';

enum GlassCardPadding { small, medium, large }

class GlassCard extends StatelessWidget {
  final Widget child;
  final GlassCardPadding padding;
  final bool isDark;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding = GlassCardPadding.medium,
    this.isDark = true,
  });
  
  double get _paddingValue {
    switch (padding) {
      case GlassCardPadding.small:
        return 12.0;
      case GlassCardPadding.medium:
        return 16.0;
      case GlassCardPadding.large:
        return 24.0;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? Color(0xFF0A1F3F).withOpacity(0.75)
          : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: EdgeInsets.all(_paddingValue),
            child: child,
          ),
        ),
      ),
    );
  }
}
```text

#### Usage

```dart
GlassCard(
  padding: GlassCardPadding.medium,
  child: Text('Your content here'),
)
```text

---

### 2. Data Orb Widget

**Purpose:** Circular glass display for critical navigation data (SOG, COG, DEPTH)

#### Size Variants

| Variant | Diameter | Value Font | Label Font | Usage |
| --------- | ---------- | ------------ | ------------ | ------- |
| Small | 80px | 32pt bold | 10pt medium | Compact displays |
| Medium | 140px | 48pt bold | 12pt medium | Standard (default) |
| Large | 200px | 64pt bold | 14pt medium | Prominent displays |

#### Anatomy

```text
┌─────────────────┐
│   ╭───────╮    │  ← Outer ring (seafoam green accent)
│  ╱         ╲   │
│ │  48.0 kt  │  │  ← Value (48pt bold)
│ │    SOG    │  │  ← Label (12pt medium)
│  ╲         ╱   │
│   ╰───────╯    │
└─────────────────┘
```text

#### States

- **Normal:** Standard display with seafoam green ring
- **Alert:** Orange ring (#FF9A3D) for warnings
- **Critical:** Red ring (#FF6B6B) for danger
- **Inactive:** 50% opacity when no data available

#### Implementation Checklist

- [ ] Create DataOrb widget accepting type (SOG/COG/DEPTH)
- [ ] Implement 3 size variants
- [ ] Add circular progress ring for visual feedback
- [ ] Support normal, alert, critical, inactive states
- [ ] Display value, unit, label, optional subtitle
- [ ] Apply frosted glass background
- [ ] Ensure text is readable over all backgrounds
- [ ] Test with real NMEA data
- [ ] Write widget tests
- [ ] Create golden tests for each size/state

---

### 3. Compass Widget

**Purpose:** Central navigation widget showing heading, speed, and wind data

#### Specifications

**Minimum Size:** 200×200px  
**Scales:** Responsive up to 300×300px on larger screens

#### Components

1. **Compass Rose:** Rotating SVG with N/S/E/W markers
2. **Heading Display:** "N 25°" (magnetic or true)
3. **Speed Indicator:** "15.2 kt" in inner ring
4. **Wind Data:** "Wind: 15.2 kt N 45°"
5. **VR Toggle:** Button for Virtual Reality mode
6. **Direction Arrow:** Points to wind direction

#### Interaction

- Single tap: Toggle Magnetic/True heading
- Long press: Detailed wind analysis
- VR button: Open immersive compass view

#### Implementation Checklist

- [ ] Create CompassWidget with rotating compass rose
- [ ] Implement N/S/E/W marker positioning
- [ ] Add boat speed display in center
- [ ] Add wind speed and direction display
- [ ] Implement VR toggle button
- [ ] Add heading text display
- [ ] Implement rotation animation (smooth, 60 FPS)
- [ ] Handle tap gestures for mode switching
- [ ] Apply glass background
- [ ] Test rotation performance
- [ ] Write widget tests
- [ ] Create golden tests

---

### 4. True Wind Widget

**Purpose:** Draggable widget showing true wind data with circular progress

#### Size Variants

- **Widget Mode:** 120×120px circular
- **Card Mode:** 200×140px with extended info

#### Anatomy

```text
┌──────────────┐
│  ╭────────╮  │  ← Circular progress ring (seafoam)
│ │ 14.2 kts │  │  ← Wind speed (32pt bold)
│ │   NNE    │  │  ← Wind direction (16pt medium)
│  ╰────────╯  │
└──────────────┘
```text

#### Features

- **Draggable:** Long press to enter drag mode
- **Multi-Instance:** Up to 5 widgets on screen
- **Deletable:** Trash icon in edit mode
- **Auto-Hide:** Fades after inactivity (optional)
- **Position Persistence:** Saved to preferences

#### Implementation Checklist

- [ ] Create WindWidget with circular design
- [ ] Implement circular progress ring (0-50kt scale)
- [ ] Add wind speed and direction text
- [ ] Make widget draggable via LongPress
- [ ] Implement position saving to preferences
- [ ] Restore positions on app restart
- [ ] Add edit mode with delete button
- [ ] Support multiple instances (max 5)
- [ ] Implement auto-hide with timer
- [ ] Apply glass background
- [ ] Test drag performance
- [ ] Write widget tests
- [ ] Create golden tests

---

### 5. Navigation Sidebar

**Purpose:** Primary app navigation menu

#### Layout

**Desktop/Tablet:** Vertical sidebar on left (72px wide)  
**Mobile:** Bottom sheet or drawer

#### Menu Items

1. Dashboard - Overview icon
2. Map - Map icon (highlighted when active)
3. Weather - Cloud icon
4. Settings - Gear icon
5. Profile - Person icon
6. Boat Icon - Vessel management (bottom)

#### Styling

- **Icon Size:** 24×24px
- **Active State:** Seafoam green background with glow effect
- **Inactive State:** White icons at 60% opacity
- **Background:** Frosted glass
- **Spacing:** 16px between icons

#### Implementation Checklist

- [ ] Create NavigationSidebar widget
- [ ] Implement vertical icon layout
- [ ] Add all 6 menu items with icons
- [ ] Implement active state highlighting
- [ ] Apply glass background
- [ ] Add navigation routing
- [ ] Responsive: sidebar (desktop) / drawer (mobile)
- [ ] Smooth transitions between items
- [ ] Test on all screen sizes
- [ ] Write widget tests

---

## Layout System

### Responsive Breakpoints

```dart
class Breakpoints {
  static const mobile = 600.0;   // < 600px
  static const tablet = 1200.0;  // 600-1200px
  static const desktop = 1200.0; // > 1200px
}
```text

### Layout Helper

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```text

### Spacing Scale

```dart
class OceanSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```text

---

## Animation Guidelines

### Animation Principles

1. **Fluid Motion:** All animations should feel smooth like water
2. **Purpose:** Animate only when it aids understanding
3. **Performance:** Maintain 60 FPS on all devices
4. **Consistency:** Use standard durations and curves

### Duration Standards

- **Fast:** 150ms - Hover states, small transitions
- **Medium:** 250ms - Most UI transitions
- **Slow:** 400ms - Page transitions, complex animations

### Curve Standards

```dart
class OceanCurves {
  static const ease = Curves.ease;
  static const easeIn = Curves.easeIn;
  static const easeOut = Curves.easeOut;
  static const easeInOut = Curves.easeInOut;
  static const decelerate = Curves.decelerate;
}
```text

### Common Animations

**Fade In/Out:**

```dart
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 250),
  curve: Curves.easeInOut,
  child: child,
)
```text

**Slide Transition:**

```dart
SlideTransition(
  position: Tween<Offset>(
    begin: Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: controller,
    curve: Curves.easeOut,
  )),
  child: child,
)
```text

---

## Responsive Design

### Screen Size Adaptations

#### Mobile (< 600px)

- Stack data orbs vertically
- Full-width components
- Bottom navigation
- Smaller font sizes
- Reduced padding

#### Tablet (600-1200px)

- Two-column layouts
- Side navigation drawer
- Flexible component sizing
- Standard font sizes

#### Desktop (> 1200px)

- Multi-column layouts
- Fixed sidebar navigation
- Larger components
- Maximum content width: 1600px

### Component Scaling

```dart
double getOrbSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < Breakpoints.mobile) {
    return 80.0;  // Small orb on mobile
  } else if (width < Breakpoints.desktop) {
    return 140.0; // Medium orb on tablet
  } else {
    return 200.0; // Large orb on desktop
  }
}
```text

---

## Implementation Checklist

### Phase 1: Base Components

- [ ] Set up Ocean Glass theme in app_theme.dart
- [ ] Create ocean_colors.dart with color palette
- [ ] Create ocean_text_styles.dart with typography
- [ ] Implement GlassCard base component
- [ ] Test GlassCard on iOS and Android
- [ ] Create glass_button.dart
- [ ] Create glass_modal.dart
- [ ] Write unit tests for theme files

### Phase 2: Data Display Components

- [ ] Implement DataOrb with all size variants
- [ ] Test DataOrb with real NMEA data
- [ ] Implement CompassWidget with rotation
- [ ] Test compass performance (60 FPS)
- [ ] Implement WindWidget with draggable behavior
- [ ] Test wind widget multi-instance
- [ ] Write widget tests for all components
- [ ] Create golden tests for visual regression

### Phase 3: Navigation Components

- [ ] Implement NavigationSidebar
- [ ] Add routing integration
- [ ] Test responsive behavior
- [ ] Implement RouteInfoCard
- [ ] Implement ActionButtonBar
- [ ] Write integration tests

### Phase 4: Screen Layouts

- [ ] Update MapScreen with glass overlays
- [ ] Implement NavigationModeScreen
- [ ] Test screen transitions
- [ ] Verify performance on all devices
- [ ] Complete accessibility testing

---

## Testing Requirements

### Widget Tests

**Required for Each Component:**

- [ ] Renders without errors
- [ ] Displays correct data
- [ ] Handles null/missing data
- [ ] Responds to user interaction
- [ ] Theme switching works
- [ ] Accessibility labels present

### Golden Tests

**Visual Regression Testing:**

- [ ] Each component in all size variants
- [ ] Each component in all states
- [ ] Dark mode vs light mode
- [ ] Mobile, tablet, desktop layouts

### Performance Tests

**Requirements:**

- [ ] Glass blur maintains 60 FPS
- [ ] Animations are smooth
- [ ] No jank during scrolling
- [ ] Memory usage acceptable
- [ ] Battery impact minimal

### Integration Tests

**User Flows:**

- [ ] Navigate between screens
- [ ] Drag and position wind widgets
- [ ] Toggle compass modes
- [ ] View data orbs with live data
- [ ] Create and follow route

---

**Document End**
