---
applyTo: ".copilot-tracking/changes/20260201-ui-architecture-adaptation-changes.md"
---

<!-- markdownlint-disable-file -->

# Task Checklist: SailStream UI Architecture Adaptation

## Overview

Adapt the master plan documentation to match the exact UI architecture and design specifications from SailStream mockups, implementing the "Ocean Glass" design philosophy with proper Flutter project structure.

## Objectives

- Document complete SailStream UI architecture based on 5 design mockups
- Update master plan docs to reflect "Ocean Glass" design system
- Specify all new UI components required (navigation sidebar, data orbs, compass widget, wind widgets)
- Define strict architecture rules to prevent past failures (god objects, projection mismatches, provider chaos)
- Create comprehensive component specifications for implementation

## Research Summary

### Project Files

- #file:../../docs/MASTER_DEVELOPMENT_BIBLE.md - Current failure analysis and architecture rules
- #file:../../docs/CODEBASE_MAP.md - Existing project structure
- #file:../../docs/FEATURE_REQUIREMENTS.md - Feature specifications
- #file:../../docs/AI_AGENT_INSTRUCTIONS.md - Development guidelines

### External References

- #file:../research/20260201-ui-architecture-adaptation-research.md - Complete design analysis and architecture requirements
- #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 40-90) - "Ocean Glass" Design Philosophy
- #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 92-120) - Design System Specifications
- #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 122-275) - Screen Structure Analysis from mockups
- #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 277-340) - Mandatory Project Structure
- #file:../research/20260201-ui-architecture-adaptation-research.md (Lines 342-380) - Critical Architecture Rules

### Standards References

- #file:../../.github/instructions/dart-n-flutter.instructions.md - Dart and Flutter best practices
- #file:../../.github/instructions/spec-driven-workflow-v1.instructions.md - Specification-driven development workflow
- #file:../../docs/AI_AGENT_INSTRUCTIONS.md - Code quality standards and patterns

## Implementation Checklist

### [ ] Phase 1: Update Master Plan Documentation

- [ ] Task 1.1: Update MASTER_DEVELOPMENT_BIBLE.md with SailStream UI architecture
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 11-28)

- [ ] Task 1.2: Update CODEBASE_MAP.md with new widget structure
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 29-46)

- [ ] Task 1.3: Update FEATURE_REQUIREMENTS.md with glass UI components
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 47-65)

- [ ] Task 1.4: Create UI_DESIGN_SYSTEM.md documentation
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 66-85)

### [ ] Phase 2: Define Component Specifications

- [ ] Task 2.1: Specify Data Orb Widget (SOG/COG/DEPTH displays)
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 88-106)

- [ ] Task 2.2: Specify Compass Widget (with VR toggle, speed indicators)
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 107-127)

- [ ] Task 2.3: Specify True Wind Widget (draggable, circular progress)
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 128-149)

- [ ] Task 2.4: Specify Navigation Sidebar (vertical icon navigation)
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 150-170)

- [ ] Task 2.5: Specify Glass Card Component (frosted glass base widget)
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 171-192)

### [ ] Phase 3: Architecture Documentation

- [ ] Task 3.1: Document provider dependency graph for SailStream
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 195-214)

- [ ] Task 3.2: Define widget hierarchy for map screen
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 215-236)

- [ ] Task 3.3: Document projection service requirements
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 237-257)

- [ ] Task 3.4: Create screen flow documentation
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 258-278)

### [ ] Phase 4: Implementation Guidelines

- [ ] Task 4.1: Update AI_AGENT_INSTRUCTIONS.md with architecture rules
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 281-302)

- [ ] Task 4.2: Create component implementation checklist
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 303-322)

- [ ] Task 4.3: Document testing requirements for UI components
  - Details: .copilot-tracking/details/20260201-ui-architecture-adaptation-details.md (Lines 323-343)

## Dependencies

- Flutter/Dart development environment
- MapTiler SDK for map rendering
- Provider package for state management
- Design mockups and specifications from research file

## Success Criteria

- All master plan documentation files updated to reflect SailStream UI architecture
- Complete specifications for 5 new UI components (data orb, compass, wind widget, sidebar, glass card)
- Architecture rules documented to prevent past failures (god objects, projection issues, provider chaos)
- Implementation-ready component specifications with exact measurements and behavior
- Testing strategy defined for all new UI components
