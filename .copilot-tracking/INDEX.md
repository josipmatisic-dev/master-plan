# Copilot Tracking - Master Index

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Master index of all execution planning artifacts

---

## Quick Navigation

- [Plans](#plans) - Execution plans for each development phase
- [Details](#details) - Detailed specifications and requirements  
- [Prompts](#prompts) - AI agent implementation instructions
- [Research](#research) - Analysis and design research

---

## Plans

Comprehensive execution plans for all development phases (Phase 0 - Phase 4).

| Phase | File | Status | Description |
| ------- | ------ | -------- | ------------- |
| Phase 0 | [phase-0-foundation-plan.md](plans/phase-0-foundation-plan.md) | Planned | Foundation setup, architecture, core services, testing infrastructure |
| Phase 1 | [phase-1-core-navigation-plan.md](plans/phase-1-core-navigation-plan.md) | Planned | Map display, GPS tracking, basic overlays |
| Phase 2 | [phase-2-weather-intelligence-plan.md](plans/phase-2-weather-intelligence-plan.md) | Planned | Weather integration, forecasting, timeline playback |
| Phase 3 | [phase-3-polish-features-plan.md](plans/phase-3-polish-features-plan.md) | Planned | Advanced features, UI/UX polish, performance optimization |
| Phase 4 | [phase-4-social-community-plan.md](plans/phase-4-social-community-plan.md) | Planned | Social features, community, launch preparation |

### Plan Contents

Each plan includes:
- ✅ Objectives - Clear phase goals
- ✅ Dependencies - Required prior work
- ✅ Success Criteria - Measurable outcomes
- ✅ Risk Checks - Known issues to avoid
- ✅ Testing Expectations - Required test coverage
- ✅ Documentation Requirements - What docs to update
- ✅ Known Issues References - ISS-XXX items to avoid

---

## Details

Detailed specifications for components and features in each phase.

| Phase | File | Contents |
| ------- | ------ | ---------- |
| Phase 0 | [phase-0-foundation-details.md](details/phase-0-foundation-details.md) | Project initialization, provider architecture, core services, test infrastructure |
| Phase 1 | [phase-1-core-navigation-details.md](details/phase-1-core-navigation-details.md) | Map component specs, GPS integration, overlay rendering, boat tracking |
| Phase 2 | [phase-2-weather-intelligence-details.md](details/phase-2-weather-intelligence-details.md) | Weather API integration, forecast models, timeline controls, cache strategy |
| Phase 3 | [phase-3-polish-features-details.md](details/phase-3-polish-features-details.md) | Dark mode, settings, alerts, AIS, tides, performance monitoring |
| Phase 4 | [phase-4-social-community-details.md](details/phase-4-social-community-details.md) | Trip logging, social sharing, profiles, collaborative features |

### Detail Contents

Each detail file includes:
- Component anatomy and structure
- Data models and interfaces
- API specifications
- UI/UX requirements
- Performance criteria
- Error handling requirements
- Testing scenarios

---

## Prompts

AI agent implementation prompts with step-by-step instructions.

| Phase | File | Purpose |
| ------- | ------ | --------- |
| Phase 0 | [implement-phase-0-foundation.prompt.md](prompts/implement-phase-0-foundation.prompt.md) | Guide for implementing foundation infrastructure |
| Phase 1 | [implement-phase-1-core-navigation.prompt.md](prompts/implement-phase-1-core-navigation.prompt.md) | Guide for implementing core navigation features |
| Phase 2 | [implement-phase-2-weather-intelligence.prompt.md](prompts/implement-phase-2-weather-intelligence.prompt.md) | Guide for implementing weather features |
| Phase 3 | [implement-phase-3-polish-features.prompt.md](prompts/implement-phase-3-polish-features.prompt.md) | Guide for implementing polish and advanced features |
| Phase 4 | [implement-phase-4-social-community.prompt.md](prompts/implement-phase-4-social-community.prompt.md) | Guide for implementing social and community features |

### Prompt Structure

Each prompt includes:
- Prerequisites check
- Step-by-step execution instructions
- Documentation references
- Known issues to avoid
- Success criteria validation
- Cleanup procedures

---

## Research

Research and analysis documents for design and architecture decisions.

| Date | File | Topic |
| ------ | ------ | ------- |
| 2026-02-01 | [20260201-ui-architecture-adaptation-research.md](research/20260201-ui-architecture-adaptation-research.md) | SailStream UI architecture and "Ocean Glass" design system |

---

## Documentation References

All planning artifacts reference these core documents:

### Primary Documentation

| Document | Purpose | Location |
| ---------- | --------- | ---------- |
| MASTER_DEVELOPMENT_BIBLE | Failure analysis, architecture rules, phases | `/docs/MASTER_DEVELOPMENT_BIBLE.md` |
| AI_AGENT_INSTRUCTIONS | Mandatory behaviors, code patterns | `/docs/AI_AGENT_INSTRUCTIONS.md` |
| KNOWN_ISSUES_DATABASE | All issues, solutions, prevention | `/docs/KNOWN_ISSUES_DATABASE.md` |
| FEATURE_REQUIREMENTS | Detailed feature specifications | `/docs/FEATURE_REQUIREMENTS.md` |
| CODEBASE_MAP | Project structure, dependencies | `/docs/CODEBASE_MAP.md` |

### Agent Instructions

Located in `.github/instructions/`:
- `spec-driven-workflow-v1.instructions.md` - Specification-driven development workflow
- `update-docs-on-code-change.instructions.md` - Documentation maintenance
- `performance-optimization.instructions.md` - Performance best practices
- `secure-coding.instructions.md` - Security guidelines

### Bundled Agents

Located in `.github/agents/`:
- `implementation-plan.agent.md` - Implementation plan generation
- `specification.agent.md` - Technical specification creation
- `task-planner.agent.md` - Task breakdown and planning
- `se-security-reviewer.agent.md` - Security review
- `se-system-architecture-reviewer.agent.md` - Architecture review

---

## Phase Timeline

```text
Phase 0: Foundation (Week 1-2)
├── Setup Flutter project
├── Configure providers
├── Implement core services
└── Setup testing infrastructure

Phase 1: Core Navigation (Week 3-6)
├── Implement map display
├── GPS integration
├── Basic overlays
└── Boat tracking

Phase 2: Weather Intelligence (Week 7-10)
├── Weather API integration
├── Forecast timeline
├── Playback controls
└── Offline caching

Phase 3: Polish & Features (Week 11-14)
├── Dark mode
├── Advanced features (AIS, tides)
├── Performance optimization
└── Audio alerts

Phase 4: Social & Community (Week 15-18)
├── Trip logging
├── Social features
├── Launch preparation
└── Beta testing
```text

---

## Usage Workflow

### For New Feature Implementation

1. **Read Phase Plan** - Understand objectives and scope
2. **Review Detail File** - Get component specifications
3. **Check Known Issues** - Avoid past mistakes
4. **Follow Prompt** - Step-by-step implementation
5. **Validate** - Test against success criteria
6. **Update Docs** - Keep documentation current

### For Bug Fixing

1. **Check KNOWN_ISSUES_DATABASE** - Search for similar issues
2. **Review Affected Phase** - Understand intended behavior
3. **Check Detail Specs** - Verify correct implementation
4. **Apply Solution** - Use proven patterns
5. **Document** - Update known issues if novel

### For Code Review

1. **Verify Against Plan** - Matches phase objectives
2. **Check Architecture Rules** - Follows MASTER_DEVELOPMENT_BIBLE Section C
3. **Review Test Coverage** - Meets phase testing requirements
4. **Validate Documentation** - Updated as required
5. **Scan for Known Issues** - Doesn't repeat past mistakes

---

## Status Legend

- 🟢 **Completed** - All tasks done, tests passing
- 🟡 **In Progress** - Active development
- 🔵 **Planned** - Not yet started
- 🔴 **Blocked** - Waiting on dependencies
- ⚪ **Deprecated** - No longer relevant
# .copilot-tracking Directory Index

This directory contains execution planning artifacts, research, implementation details, and prompts for the Marine Navigation App project.

## Directory Structure

```text
.copilot-tracking/
├── INDEX.md (this file)
├── plans/          # Multi-phase execution plans
├── details/        # Detailed implementation specifications
├── prompts/        # Implementation prompts for agents
└── research/       # Research and analysis documents
```text

## Plans Directory

Comprehensive phase-by-phase execution plans for the Marine Navigation App following the spec-driven workflow:

### Multi-Phase Execution Plans (Phase 0-4)

- **[phase-0-foundation.md](plans/phase-0-foundation.md)** - Week 1-2: Project setup, core services, testing infrastructure
- **[phase-1-core-navigation.md](plans/phase-1-core-navigation.md)** - Week 3-6: Map display, GPS tracking, basic overlays
- **[phase-2-weather-intelligence.md](plans/phase-2-weather-intelligence.md)** - Week 7-10: Weather integration, forecasting, timeline playback
- **[phase-3-polish-features.md](plans/phase-3-polish-features.md)** - Week 11-14: Dark mode, settings, advanced features
- **[phase-4-social-community.md](plans/phase-4-social-community.md)** - Week 15-18: Social features, trip logging, launch prep

### Previous Plans

- **[20260201-ui-architecture-adaptation-plan.instructions.md](plans/20260201-ui-architecture-adaptation-plan.instructions.md)** - UI architecture adaptation

## Details Directory

Detailed implementation specifications for each phase with specific tasks, acceptance criteria, and technical requirements.

- **[phase-0-foundation-details.md](details/phase-0-foundation-details.md)** - Detailed specifications for Phase 0
- **[phase-1-core-navigation-details.md](details/phase-1-core-navigation-details.md)** - Detailed specifications for Phase 1
- **[phase-2-weather-intelligence-details.md](details/phase-2-weather-intelligence-details.md)** - Detailed specifications for Phase 2
- **[phase-3-polish-features-details.md](details/phase-3-polish-features-details.md)** - Detailed specifications for Phase 3
- **[phase-4-social-community-details.md](details/phase-4-social-community-details.md)** - Detailed specifications for Phase 4
- **[20260201-ui-architecture-adaptation-details.md](details/20260201-ui-architecture-adaptation-details.md)** - UI architecture details

## Prompts Directory

Implementation prompts for AI agents to execute the plans.

- **[implement-phase-0.prompt.md](prompts/implement-phase-0.prompt.md)** - Phase 0 implementation prompt
- **[implement-phase-1.prompt.md](prompts/implement-phase-1.prompt.md)** - Phase 1 implementation prompt
- **[implement-phase-2.prompt.md](prompts/implement-phase-2.prompt.md)** - Phase 2 implementation prompt
- **[implement-phase-3.prompt.md](prompts/implement-phase-3.prompt.md)** - Phase 3 implementation prompt
- **[implement-phase-4.prompt.md](prompts/implement-phase-4.prompt.md)** - Phase 4 implementation prompt
- **[implement-ui-architecture-adaptation.prompt.md](prompts/implement-ui-architecture-adaptation.prompt.md)** - UI architecture prompt

## Research Directory

Research documents and analysis.

- **[20260201-ui-architecture-adaptation-research.md](research/20260201-ui-architecture-adaptation-research.md)** - UI architecture research

## How to Use

### For Developers

1. **Start with the Master Documentation:**
   - Read [../docs/MASTER_DEVELOPMENT_BIBLE.md](../docs/MASTER_DEVELOPMENT_BIBLE.md)
   - Review [../docs/KNOWN_ISSUES_DATABASE.md](../docs/KNOWN_ISSUES_DATABASE.md)
   - Understand [../docs/AI_AGENT_INSTRUCTIONS.md](../docs/AI_AGENT_INSTRUCTIONS.md)

2. **Select Your Phase:**
   - Choose the appropriate phase plan (phase-0 through phase-4)
   - Review objectives, dependencies, and success criteria
   - Check for explicit references to known issues to avoid

3. **Review Details:**
   - Open the corresponding details document for your phase
   - Understand specific task requirements and acceptance criteria
   - Reference related files and dependencies

4. **Implement:**
   - Follow the task checklist systematically
   - Test each task according to testing expectations
   - Document as required
   - Update plans with completion status and dates

### For AI Agents

1. **Load Context:**
   - Read the phase plan document
   - Load corresponding details document
   - Reference master documentation as needed

2. **Execute with Prompt:**
   - Use the implementation prompt for your phase
   - Follow task-by-task or phase-by-phase as specified
   - Update tracking and progress continuously

3. **Maintain Quality:**
   - Adhere to all requirements and constraints
   - Run risk checks at each phase
   - Meet all testing expectations
   - Update documentation as specified

## Plan Template Structure

All phase plans follow this structure:

```markdown
---
goal: [Phase Goal]
version: [Version]
date_created: [YYYY-MM-DD]
last_updated: [YYYY-MM-DD]
owner: [Owner]
status: [Status]
tags: [Tags]
---

# Introduction
[Status badge and overview]

## 1. Requirements & Constraints
[All requirements, security, architecture rules]

## 2. Implementation Steps
[Phase-by-phase tasks with completion tracking]

## 3. Alternatives
[Alternative approaches considered]

## 4. Dependencies
[All dependencies listed]

## 5. Files
[Files to create/modify]

## 6. Testing
[Testing requirements and expectations]

## 7. Risks & Assumptions
[Risk analysis and assumptions]

## 8. Related Specifications / Further Reading
[References and links]
```text

## Status Tracking

Plans use the following status values with corresponding badge colors:

- `Planned` (blue) - Not started
- `In progress` (yellow) - Currently being implemented
- `On Hold` (orange) - Temporarily paused
- `Completed` (bright green) - Fully implemented and verified
- `Deprecated` (red) - No longer applicable

## Key Principles

### From MASTER_DEVELOPMENT_BIBLE

1. **Single Source of Truth** - Each piece of data has exactly ONE authoritative source
2. **Projection Consistency** - ALL coordinate transformations through ProjectionService
3. **Provider Discipline** - Max 3 dependency layers, no circular dependencies
4. **File Size Limits** - Max 300 lines per file, 50 lines per method
5. **Dispose Everything** - Every controller/subscription/timer MUST be disposed

### Known Issues to Avoid

- **ISS-001**: Overlay projection mismatch - Use ProjectionService for all coordinates
- **ISS-002**: God objects - Enforce file size limits, single responsibility
- **ISS-003**: Provider chaos - All providers in main.dart
- **ISS-004**: Stale cache - Single CacheService with LRU and TTL
- **ISS-006**: Memory leaks - Explicit disposal required
- **ISS-009**: UI blocking - Use isolates for heavy computation

## Conventions

### File Naming

- Phase plans: `phase-{N}-{name}.md` (e.g., `phase-0-foundation.md`)
- Details: `phase-{N}-{name}-details.md`
- Prompts: `implement-phase-{N}.prompt.md`
- Dated items: `YYYYMMDD-{description}.md`

### Task Identifiers

- `REQ-NNN`: Requirements
- `SEC-NNN`: Security requirements
- `CON-NNN`: Constraints
- `GUD-NNN`: Guidelines
- `PAT-NNN`: Patterns
- `GOAL-NNN`: Phase goals
- `TASK-NNN`: Individual tasks
- `TEST-NNN`: Test cases
- `RISK-NNN`: Risks
- `DEP-NNN`: Dependencies
- `FILE-NNN`: Files
- `ALT-NNN`: Alternatives

### Completion Tracking

Tasks in implementation steps use checkboxes and dates:

```markdown
| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-001 | Do something | ✅ | 2026-02-01 |
| TASK-002 | Do another thing | | |
```text

## Verification

Before considering any phase complete, verify:

- ✅ All tasks in the phase plan are marked complete with dates
- ✅ All acceptance criteria from details document are met
- ✅ Test coverage meets or exceeds targets
- ✅ All known issues referenced are properly avoided
- ✅ Documentation is updated as required
- ✅ Code review completed
- ✅ CI/CD pipeline passing

## Next Steps

1. Review [phase-0-foundation.md](plans/phase-0-foundation.md) to begin
2. Set up your development environment per Phase 0 requirements
3. Follow the implementation steps systematically
4. Track progress by updating completion status and dates
5. Move to subsequent phases only after phase completion verification

---

**Last Updated:** 2026-02-01  
**Maintainer:** Development Team  
**Version:** 1.0
**Maintainer:** Marine Navigation App Development Team  
**Source:** Based on MASTER_DEVELOPMENT_BIBLE and lessons from 4 failed attempts
