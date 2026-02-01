<!-- markdownlint-disable-file -->

# Implementation Plans

This directory contains implementation plans following the standardized template from `.github/agents/implementation-plan.agent.md`.

## Purpose

Implementation plans provide structured, executable specifications for features, refactorings, and architectural changes. They are designed for AI-to-AI communication and automated processing.

## File Naming Convention

Plans follow the pattern: `[purpose]-[component]-[version].md`

**Purpose Prefixes:**
- `feature` - New feature implementation
- `refactor` - Code refactoring
- `upgrade` - System or dependency upgrades
- `data` - Data model or migration changes
- `infrastructure` - Infrastructure or deployment changes
- `process` - Process or workflow improvements
- `architecture` - Architectural changes
- `design` - Design system or UI changes

**Examples:**
- `feature-sailstream-ui-architecture-1.md`
- `refactor-map-screen-components-2.md`
- `upgrade-flutter-sdk-1.md`

## Template Structure

All implementation plans must include:

### Front Matter
```yaml
---
goal: [Concise goal description]
version: [Version number]
date_created: [YYYY-MM-DD]
last_updated: [YYYY-MM-DD]
owner: [Team/Individual]
status: 'Completed'|'In progress'|'Planned'|'Deprecated'|'On Hold'
tags: [List of tags]
---
```

### Required Sections

1. **Introduction** - Brief overview with status badge
2. **Requirements & Constraints** - All requirements, constraints, guidelines, patterns
3. **Implementation Steps** - Phases with task tables
4. **Alternatives** - Alternative approaches considered
5. **Dependencies** - Required tools, frameworks, components
6. **Files** - Files to be created or modified
7. **Testing** - Test requirements
8. **Risks & Assumptions** - Known risks and assumptions
9. **Related Specifications** - Links to related docs

## Plan Status

Status is indicated by badge color:
- **Completed** - Bright green badge
- **In progress** - Yellow badge
- **Planned** - Blue badge
- **Deprecated** - Red badge
- **On Hold** - Orange badge

## AI-Optimized Standards

Plans use:
- Deterministic, unambiguous language
- Machine-parseable formats (tables, lists)
- Specific file paths and line numbers
- Standardized identifier prefixes (REQ-, TASK-, etc.)
- Measurable validation criteria

## Relationship to .copilot-tracking

This directory (`/plan/`) complements `.copilot-tracking/`:

- `/plan/` - Formal implementation plans (template-based)
- `.copilot-tracking/plans/` - Task checklists (workflow-based)
- `.copilot-tracking/details/` - Detailed task specifications
- `.copilot-tracking/research/` - Research findings

Both structures can coexist for comprehensive planning:
- Use `/plan/` for high-level implementation roadmaps
- Use `.copilot-tracking/` for detailed task execution tracking

## Usage

1. **Create Plan**: Use template from `.github/agents/implementation-plan.agent.md`
2. **Fill Sections**: Populate all required sections with specific details
3. **Validate**: Ensure no placeholder text remains
4. **Execute**: Follow plan systematically, updating status as you progress
5. **Update**: Keep plan current as implementation reveals new requirements

## Related Documentation

- Implementation Plan Agent: `.github/agents/implementation-plan.agent.md`
- Task Planner Agent: `.github/agents/task-planner.agent.md`
- Spec-Driven Workflow: `.github/instructions/spec-driven-workflow-v1.instructions.md`

## Current Plans

See individual `.md` files in this directory for active implementation plans.
