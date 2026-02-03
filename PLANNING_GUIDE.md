<!-- markdownlint-disable-file -->

# Planning Guide for AI Agents

This guide explains the planning structures and workflows used in this repository.

## Overview

This repository uses two complementary planning approaches:

1. **Task-Based Planning** (`.copilot-tracking/`) - Detailed task execution workflow
2. **Implementation Plans** (`/plan/`) - Formal feature specifications

## Planning Structures

### Task-Based Planning (.copilot-tracking/)

Location: `.copilot-tracking/`

**Purpose**: Detailed task-by-task execution tracking with research validation

**Workflow**:
```text
Research → Planning → Implementation → Changes Tracking
```text

**Files**:
- `research/` - Research findings and analysis (MUST exist before planning)
- `plans/` - Task checklists with phase breakdowns
- `details/` - Detailed specifications for each task
- `prompts/` - Implementation instructions for AI agents
- `changes/` - Change tracking throughout implementation

**When to Use**:
- Breaking down work into granular, trackable tasks
- Need research validation before planning
- Want detailed line-by-line references
- Tracking changes throughout implementation
- AI agent collaboration with specific tool requirements

**Agent Instructions**:
- `.github/agents/task-planner.agent.md`
- `.github/agents/task-researcher.agent.md`

### Implementation Plans (/plan/)

Location: `/plan/`

**Purpose**: Formal, structured implementation specifications

**Format**: Standardized template with strict structure requirements

**Sections**:
1. Requirements & Constraints
2. Implementation Steps (phases with task tables)
3. Alternatives
4. Dependencies
5. Files
6. Testing
7. Risks & Assumptions
8. Related Specifications

**When to Use**:
- Creating high-level feature roadmaps
- Formal architectural specifications
- AI-to-AI communication of implementation intent
- Documentation requiring strict template compliance
- Cross-team coordination

**Agent Instructions**:
- `.github/agents/implementation-plan.agent.md`

## How They Work Together

### Complementary Usage

You can use both structures for comprehensive planning:

```text
1. Create Implementation Plan (/plan/)
   ↓
2. Conduct Research (.copilot-tracking/research/)
   ↓
3. Create Task Breakdown (.copilot-tracking/plans/ and details/)
   ↓
4. Execute with Tracking (.copilot-tracking/changes/)
   ↓
5. Update Implementation Plan status (/plan/)
```text

### When to Use Which

**Use Implementation Plan alone** when:
- You need a formal specification document
- The work is well-understood without deep research
- You're creating a roadmap for multiple phases
- Template compliance is required

**Use Task-Based Planning alone** when:
- You need to research before planning
- Work requires granular task tracking
- You want automated AI agent execution
- Changes tracking is critical

**Use Both** when:
- Large features requiring both high-level spec and detailed execution
- Cross-team coordination needs formal spec + individual task tracking
- Long-term projects with multiple phases

## File Naming Conventions

### Task-Based Files (.copilot-tracking/)

Pattern: `YYYYMMDD-task-description-{type}.md`

Examples:
- `20260201-ui-architecture-adaptation-research.md`
- `20260201-ui-architecture-adaptation-plan.instructions.md`
- `20260201-ui-architecture-adaptation-details.md`
- `implement-ui-architecture-adaptation.prompt.md`

### Implementation Plans (/plan/)

Pattern: `[purpose]-[component]-[version].md`

Purpose prefixes: `feature`, `refactor`, `upgrade`, `data`, `infrastructure`, `process`, `architecture`, `design`

Examples:
- `feature-sailstream-ui-architecture-1.md`
- `refactor-map-screen-components-2.md`
- `architecture-provider-dependency-graph-1.md`

## Quick Start

### For AI Agents - Creating Task-Based Plan

1. Check for research: `.copilot-tracking/research/YYYYMMDD-task-description-research.md`
2. If missing, use `task-researcher.agent.md` to create it
3. Use `task-planner.agent.md` to create plan, details, and prompt files
4. Execute using the prompt file
5. Track changes in `.copilot-tracking/changes/`

### For AI Agents - Creating Implementation Plan

1. Use template from `.github/agents/implementation-plan.agent.md`
2. Fill all required sections
3. Ensure no placeholder text remains
4. Save to `/plan/` with correct naming convention
5. Update status badge as work progresses

## Cross-References

Plans should reference each other:

**Implementation Plan → Task Plan**:
```markdown
## 8. Related Specifications
- [Task Checklist](./.copilot-tracking/plans/20260201-ui-architecture-adaptation-plan.instructions.md)
- [Research](./.copilot-tracking/research/20260201-ui-architecture-adaptation-research.md)
```text

**Task Plan → Implementation Plan**:
```markdown
## Research Summary
- #file:../../plan/feature-sailstream-ui-architecture-1.md - Formal implementation specification
```text

## Line Number References

Task-based planning uses precise line references:

Format: `(Lines X-Y)`

Example:
```markdown
- #file:../research/20260201-ui-architecture-research.md (Lines 40-90) - Design Philosophy
```text

**CRITICAL**: Always verify line numbers are accurate and update when files change.

## Status Tracking

### Implementation Plan Status

Uses status badges:
- ![Planned](https://img.shields.io/badge/status-Planned-blue)
- ![In progress](https://img.shields.io/badge/status-In_progress-yellow)
- ![Completed](https://img.shields.io/badge/status-Completed-brightgreen)
- ![On Hold](https://img.shields.io/badge/status-On_Hold-orange)
- ![Deprecated](https://img.shields.io/badge/status-Deprecated-red)

### Task Plan Status

Uses checkboxes in tables:

```markdown
| Task | Description | Completed | Date |
| -------- | --------------------- | --------- | ---------- |
| TASK-001 | Implementation task 1 | ✅ | 2026-02-01 |
| TASK-002 | Implementation task 2 | | |
```text

## Related Documentation

- **Task Planner**: `.github/agents/task-planner.agent.md`
- **Task Researcher**: `.github/agents/task-researcher.agent.md`
- **Implementation Plan**: `.github/agents/implementation-plan.agent.md`
- **Spec-Driven Workflow**: `.github/instructions/spec-driven-workflow-v1.instructions.md`
- **.copilot-tracking README**: `.copilot-tracking/README.md`
- **/plan/ README**: `plan/README.md`

## Example: Current SailStream UI Architecture Work

This work demonstrates using both structures:

**Implementation Plan** (`/plan/feature-sailstream-ui-architecture-1.md`):
- High-level feature specification
- Formal requirements and constraints
- Implementation phases overview
- Dependencies and risks

**Task-Based Planning** (`.copilot-tracking/`):
- Research: `research/20260201-ui-architecture-adaptation-research.md`
- Plan: `plans/20260201-ui-architecture-adaptation-plan.instructions.md`
- Details: `details/20260201-ui-architecture-adaptation-details.md`
- Prompt: `prompts/implement-ui-architecture-adaptation.prompt.md`

Together they provide:
- Formal specification for stakeholders (Implementation Plan)
- Executable task breakdown for AI agents (Task Plans)
- Research foundation (Research file)
- Change tracking (Changes file)

## Best Practices

1. **Always validate research exists** before creating task plans
2. **Keep line references accurate** - verify after any file changes
3. **Use appropriate structure** - don't force-fit work into wrong template
4. **Cross-reference** - link related plans together
5. **Update status** - keep status current as work progresses
6. **Clean up** - archive or remove planning artifacts after completion
7. **Follow templates strictly** - templates ensure AI agents can process plans

## Questions?

Refer to specific agent instruction files in `.github/agents/` for detailed guidelines.
