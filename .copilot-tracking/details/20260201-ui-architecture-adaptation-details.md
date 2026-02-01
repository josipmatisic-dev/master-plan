<!-- markdownlint-disable-file -->

# Task Details: SailStream UI Architecture Adaptation

## Research Reference

**Source Research**: #file:../research/20260201-ui-architecture-adaptation-research.md

## Phase 1: Update Master Plan Documentation

### Task 1.1: Update MASTER_DEVELOPMENT_BIBLE.md with SailStream UI architecture

Add comprehensive SailStream UI architecture section to the Master Development Bible, documenting the "Ocean Glass" design philosophy and all new UI components.

- **Files**:
  - docs/MASTER_DEVELOPMENT_BIBLE.md - Add new Section G: SailStream UI Architecture
- **Success**:
  - "Ocean Glass" design philosophy documented
  - All 5 UI component types specified (sidebar, data orbs, compass, wind widgets, glass cards)
  - Design system color palette and typography defined
  - Visual hierarchy and layout principles documented
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 40-90) - "Ocean Glass" Design Philosophy
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 92-120) - Design System Specifications
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 122-275) - Screen Structure Analysis
- **Dependencies**:
  - None (first task)

### Task 1.2: Update CODEBASE_MAP.md with new widget structure

Update the project structure documentation to include new SailStream UI widgets and components.

- **Files**:
  - docs/CODEBASE_MAP.md - Update widgets/ directory structure
  - docs/CODEBASE_MAP.md - Update Widget Hierarchy section
- **Success**:
  - New widget directories added: widgets/glass/, widgets/navigation/, widgets/data_displays/
  - Component ownership table updated
  - Widget hierarchy reflects SailStream screen structure
  - Data flow diagrams updated for glass UI components
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 277-340) - Mandatory Project Structure
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 428-510) - New UI Components Required
- **Dependencies**:
  - Task 1.1 completion

### Task 1.3: Update FEATURE_REQUIREMENTS.md with glass UI components

Add detailed feature requirements for all new SailStream glass UI components.

- **Files**:
  - docs/FEATURE_REQUIREMENTS.md - Add FEAT-015: Glass UI Component Library
  - docs/FEATURE_REQUIREMENTS.md - Add FEAT-016: Navigation Mode Screen
  - docs/FEATURE_REQUIREMENTS.md - Add FEAT-017: Draggable Wind Widgets
- **Success**:
  - Glass UI components specified as features with acceptance criteria
  - Navigation mode feature documented with SOG/COG/DEPTH requirements
  - Wind widget feature with draggable, multi-instance behavior
  - UI component tests specified
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 428-510) - New UI Components Required
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 512-550) - Design System Implementation Plan
- **Dependencies**:
  - Task 1.1 and 1.2 completion

### Task 1.4: Create UI_DESIGN_SYSTEM.md documentation

Create new comprehensive design system documentation for SailStream "Ocean Glass" UI.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - New file with complete design system
- **Success**:
  - Color palette fully documented with hex values and usage guidelines
  - Typography system with 4 text styles (data values, headings, body, labels)
  - Glass effect specifications (blur radius, opacity, border radius)
  - Component anatomy diagrams in markdown/ASCII art
  - Animation guidelines for fluid interactions
  - Responsive breakpoints defined
  - Dark mode specifications
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 92-120) - Design System Specifications
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 512-550) - Design System Implementation Plan
- **Dependencies**:
  - Phase 1 completion

## Phase 2: Define Component Specifications

### Task 2.1: Specify Data Orb Widget (SOG/COG/DEPTH displays)

Create detailed specification for circular glass data orb component used for SOG, COG, and DEPTH displays.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - Add Data Orb Component section
- **Success**:
  - Three size variants specified: Small (80px), Medium (140px), Large (200px)
  - Anatomy documented: outer ring, glass background, value text, label text, subtitle
  - Seafoam green glow ring specifications
  - Text hierarchy and sizing for each element
  - Usage examples for SOG (7.2 kts), COG (247° WSW), DEPTH (12.4m)
  - Responsive behavior defined
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 148-168) - Image 2: Navigation Mode Analysis
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 428-460) - Data Orb Widget specification
- **Dependencies**:
  - Task 1.4 completion

### Task 2.2: Specify Compass Widget (with VR toggle, speed indicators)

Create detailed specification for the central compass widget with integrated speed and heading displays.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - Add Compass Widget Component section
- **Success**:
  - Circular layout with compass rose (N/S/E/W markers)
  - Boat speed display (15.2 kt) with positioning
  - Wind data display (15.2 kt N 45°) with wind direction indicator
  - VR toggle button specification
  - Heading display (N 25°) specification
  - Additional data fields (9x∩90, Laye 4 6°) positioning
  - Rotation animation for compass rose
  - Interactive states defined
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 130-146) - Image 1: Main Map Screen Analysis
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 462-482) - Compass Widget specification
- **Dependencies**:
  - Task 2.1 completion

### Task 2.3: Specify True Wind Widget (draggable, circular progress)

Create detailed specification for draggable true wind indicator widget with circular progress visualization.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - Add True Wind Widget Component section
- **Success**:
  - Circular design with frosted glass background
  - Circular progress ring showing wind strength visually
  - Wind speed text (14.2 kts) centered
  - Wind direction text (NNE) below speed
  - Seafoam green accent color for progress ring
  - Draggable behavior specification
  - Multi-instance support documented
  - Edit mode with delete button (trash icon)
  - Size variants: Widget (120px), Card (200px)
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 170-195) - Images 3-4: Wind Widget Analysis
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 484-502) - True Wind Widget specification
- **Dependencies**:
  - Task 2.2 completion

### Task 2.4: Specify Navigation Sidebar (vertical icon navigation)

Create detailed specification for left-side navigation sidebar with icon-based menu.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - Add Navigation Sidebar Component section
- **Success**:
  - Vertical layout with icon buttons
  - Menu items: Dashboard, Map, Weather, Settings, Profile
  - Boat icon at bottom
  - Active state styling with seafoam green highlight
  - Icon specifications (24x24px recommended)
  - Fixed positioning on desktop/tablet
  - Bottom sheet variant for mobile
  - Glassmorphism background
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 130-146) - Image 1: Sidebar Analysis
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 504-518) - Navigation Sidebar specification
- **Dependencies**:
  - Task 2.3 completion

### Task 2.5: Specify Glass Card Component (frosted glass base widget)

Create detailed specification for reusable frosted glass card component used throughout the app.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - Add Glass Card Base Component section
- **Success**:
  - Backdrop blur specification (10px sigma)
  - Opacity specification (80%)
  - Border radius (12px)
  - Background color with alpha
  - Border specification (optional 1px white/10%)
  - Shadow specifications for depth
  - Padding variants (small, medium, large)
  - Usage in different contexts (overlay, modal, info card)
  - Code examples in Dart/Flutter
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 108-120) - UI Components Specifications
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 520-535) - Glass Card specification
- **Dependencies**:
  - Phase 2 completion

## Phase 3: Architecture Documentation

### Task 3.1: Document provider dependency graph for SailStream

Create comprehensive provider architecture documentation preventing past failures.

- **Files**:
  - docs/CODEBASE_MAP.md - Update Provider Dependency Graph section
  - docs/MASTER_DEVELOPMENT_BIBLE.md - Add Provider Architecture Rules
- **Success**:
  - Layer 0-3 provider hierarchy documented
  - All SailStream providers listed with dependencies
  - MapViewportService as single source of truth emphasized
  - Circular dependency prevention rules stated
  - Example provider setup code in main.dart
  - Test provider setup pattern documented
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 342-380) - Critical Architecture Rules
  - #file:../../docs/CODEBASE_MAP.md (Lines 145-180) - Existing Provider Dependency Graph
- **Dependencies**:
  - Phase 2 completion

### Task 3.2: Define widget hierarchy for map screen

Document complete widget tree for SailStream map screen with all glass UI components.

- **Files**:
  - docs/CODEBASE_MAP.md - Update Widget Hierarchy section for MapScreen
- **Success**:
  - Complete Stack layout documented
  - MapWebView as bottom layer
  - Wind particle overlay layer specified
  - Navigation orbs positioning (SOG/COG/DEPTH at top)
  - Compass widget positioning (bottom center)
  - True wind widgets as draggable layer
  - UI controls layer with sidebar
  - Z-index ordering clearly defined
  - Responsive breakpoints for different screen sizes
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 130-195) - Screen Structure Analysis from Images
  - #file:../../docs/CODEBASE_MAP.md (Lines 200-230) - Current Widget Hierarchy
- **Dependencies**:
  - Task 3.1 completion

### Task 3.3: Document projection service requirements

Specify the single source of truth projection service to prevent coordinate system failures.

- **Files**:
  - docs/MASTER_DEVELOPMENT_BIBLE.md - Add Projection Service Requirements section
  - docs/AI_AGENT_INSTRUCTIONS.md - Add Projection Rules
- **Success**:
  - ViewportProjector as THE ONLY projection utility emphasized
  - All lat/lng to screen coordinate conversions must use this service
  - MapViewportService provides current viewport bounds
  - Overlay rendering must check viewport.isValid
  - Debug grid overlay testing pattern documented
  - Example code for proper projection usage
  - Error cases and fallback behavior specified
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 342-380) - Rule 5: Projection Consistency
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 20-40) - Failure #1: Overlay Projection Mismatch
- **Dependencies**:
  - Task 3.2 completion

### Task 3.4: Create screen flow documentation

Document user navigation flows between all SailStream screens.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - Add Screen Flow and Navigation section
- **Success**:
  - Splash → Connect → Map flow documented
  - Navigation sidebar transitions specified
  - Map ↔ Navigation Mode transition
  - Settings access from any screen
  - Profile access pattern
  - Deep linking support for social features
  - Back button behavior for each screen
  - Diagram/flowchart in markdown format
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 130-195) - Screen Structure Analysis
  - Copilot Chat conversation - Screen flow discussions
- **Dependencies**:
  - Phase 3 completion

## Phase 4: Implementation Guidelines

### Task 4.1: Update AI_AGENT_INSTRUCTIONS.md with architecture rules

Add SailStream-specific architecture rules to prevent repeating past failures.

- **Files**:
  - docs/AI_AGENT_INSTRUCTIONS.md - Add SailStream Architecture Rules section
- **Success**:
  - Rule 1: Single source of truth for map bounds (MapViewportService)
  - Rule 2: File size limits (500 lines max, MapScreen orchestration only)
  - Rule 3: Provider discipline (created ONLY in main.dart)
  - Rule 4: Network requests (always use HttpService.getWithRetry())
  - Rule 5: Projection consistency (ViewportProjector only)
  - Rule 6: No demo/test code in production
  - Rule 7: UI changes require design review
  - Code examples for each rule
  - Violation detection patterns
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 342-380) - Critical Architecture Rules
  - Copilot Chat conversation Lines 400-500 - Architecture rules for AI agents
- **Dependencies**:
  - Phase 3 completion

### Task 4.2: Create component implementation checklist

Provide implementation-ready checklist for building each UI component.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - Add Implementation Checklist section
- **Success**:
  - Checklist for Glass Card component implementation
  - Checklist for Data Orb widget implementation
  - Checklist for Compass widget implementation
  - Checklist for True Wind widget implementation
  - Checklist for Navigation Sidebar implementation
  - Each checklist includes: file creation, styling, state management, testing, integration
  - Dependencies between components clearly marked
- **Research References**:
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 428-550) - New UI Components Required
  - Phase 2 task specifications
- **Dependencies**:
  - Task 4.1 completion

### Task 4.3: Document testing requirements for UI components

Specify comprehensive testing strategy for all SailStream glass UI components.

- **Files**:
  - docs/UI_DESIGN_SYSTEM.md - Add Testing Requirements section
- **Success**:
  - Widget tests for each component specified
  - Golden tests for glass effect rendering
  - Integration tests for draggable widgets
  - Projection accuracy tests for overlays
  - Responsive layout tests at 3 breakpoints
  - Dark mode theme tests
  - Performance tests (60 FPS requirement)
  - Example test code for each component type
- **Research References**:
  - #file:../../docs/AI_AGENT_INSTRUCTIONS.md - Existing testing patterns
  - #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 552-580) - Success Criteria
- **Dependencies**:
  - Phase 4 completion

## Dependencies

- Flutter/Dart development environment
- Existing master plan documentation in docs/
- Research file with complete analysis

## Success Criteria

- All documentation files updated with SailStream UI specifications
- 5 UI components fully specified with implementation details
- Architecture rules preventing past failures clearly documented
- Provider dependency graph defined and documented
- Testing strategy comprehensive and actionable
- Implementation-ready checklists provided for all components
