<!-- markdownlint-disable-file -->

# Copilot Tracking Directory

This directory contains AI agent planning artifacts following the Task Planner and Implementation Plan workflows.

## Directory Structure

```
.copilot-tracking/
├── research/          # Research findings and analysis
├── plans/            # Task checklists with phase breakdowns
├── details/          # Detailed task specifications
├── prompts/          # Implementation prompts for AI agents
└── changes/          # Change tracking files
```

## File Naming Conventions

All files follow the pattern: `YYYYMMDD-task-description-{type}.md`

- **Research files**: `YYYYMMDD-task-description-research.md`
- **Plan files**: `YYYYMMDD-task-description-plan.instructions.md`
- **Details files**: `YYYYMMDD-task-description-details.md`
- **Prompt files**: `implement-task-description.prompt.md`
- **Changes files**: `YYYYMMDD-task-description-changes.md`

## Workflow

### 1. Research Phase

AI agents MUST verify comprehensive research exists before planning:

- Location: `./research/`
- Contains: Tool usage, code examples, project structure analysis, external source research
- Template: See `.github/agents/task-researcher.agent.md`

### 2. Planning Phase

AI agents create three planning files based on validated research:

- **Plan Checklist** (`./plans/`): High-level phases and tasks with line references to details
- **Task Details** (`./details/`): Complete specifications for each task with research references
- **Implementation Prompt** (`./prompts/`): Execution instructions for AI agents

Templates: See `.github/agents/task-planner.agent.md`

### 3. Implementation Phase

AI agents execute implementation following the plan:

- Track all changes in `./changes/` directory
- Update plan checklist as tasks complete
- Follow project conventions and standards

### 4. Cleanup Phase

After implementation completion:

- Review and archive planning artifacts
- Update project documentation
- Remove implementation prompt file

## Cross-References

Planning files maintain accurate line number references between files:

- Details reference Research file line ranges
- Plan checklist references Details file line ranges
- All references use format: `(Lines X-Y)`

## Related Documentation

- Task Planner Instructions: `.github/agents/task-planner.agent.md`
- Task Researcher Instructions: `.github/agents/task-researcher.agent.md`
- Implementation Plan Template: `.github/agents/implementation-plan.agent.md`
- Spec-Driven Workflow: `.github/instructions/spec-driven-workflow-v1.instructions.md`

## Current Tasks

See individual files in subdirectories for active planning work.
