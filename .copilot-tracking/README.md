# Copilot Tracking - Planning and Execution Artifacts

This directory contains planning documents, detailed specifications, and execution prompts for implementing the Marine Navigation App using GitHub Copilot and AI-assisted development.

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
├── README.md              # This file - explains how to use the planning system
├── plans/                 # High-level implementation plans (checklists)
├── details/              # Detailed technical specifications
├── prompts/              # Execution prompts for AI agents
└── research/             # Research and analysis documents
```

## Purpose

These artifacts enable a **best-in-market development process** by:

1. **Planning First**: Comprehensive plans before coding starts
2. **Spec-Driven**: Detailed specifications guide implementation
3. **AI-Optimized**: Structured for AI agent consumption and execution
4. **Quality-Focused**: Integrate performance, security, UX, testing, and documentation requirements
5. **Traceable**: Clear connection between requirements, plans, specs, and implementation

## How to Use This System

### For Phase 0 Foundation Work

Phase 0 establishes the core architecture, services, and testing infrastructure. Start here before implementing any features.

**Step 1: Review the Plan**

Read: `.copilot-tracking/plans/phase-0-foundation-1.md`

This provides:
- Complete task checklist (43 tasks across 8 phases)
- Requirements and constraints from existing documentation
- Architecture rules that MUST be followed
- Dependencies and file list
- Testing requirements
- Risk analysis

**Step 2: Study the Detailed Specification**

Read: `.copilot-tracking/details/phase-0-foundation-details-1.md`

This provides:
- Technical specifications for each service
- Data model designs with code examples
- Provider architecture and dependencies
- Performance benchmarks
- Security requirements
- Complete file structure

**Step 3: Execute Using the Prompt**

Follow: `.copilot-tracking/prompts/execute-phase-0-foundation-1.prompt.md`

This provides:
- Step-by-step implementation workflow
- Required reading list (critical context)
- Code examples and commands
- Validation checklist
- Success metrics

**Step 4: Reference Bundle Resources**

Use the Copilot bundle resources throughout implementation:

#### Agents (for specialized help)
- `@implementation-plan` - Generate or update implementation plans
- `@specification` - Create technical specifications
- `@se-security-reviewer` - Security code review
- `@se-system-architecture-reviewer` - Architecture review
- `@se-ux-ui-designer` - UX/UI guidance
- `@se-technical-writer` - Documentation help

#### Instructions (automatic guidelines)
- `dart-n-flutter.instructions.md` - Flutter/Dart best practices
- `spec-driven-workflow-v1.instructions.md` - Development workflow
- `security-and-owasp.instructions.md` - Security standards
- `performance-optimization.instructions.md` - Performance best practices
- `update-docs-on-code-change.instructions.md` - Documentation sync

#### Prompts (for specific tasks)
- `create-specification.prompt.md` - Generate specifications
- `breakdown-feature-implementation.prompt.md` - Break down features into tasks
- `documentation-writer.prompt.md` - Generate/update documentation

**Step 5: Validate Against Documentation**

Continuously reference existing documentation:

- `docs/MASTER_DEVELOPMENT_BIBLE.md` - Architecture rules and failure analysis
- `docs/AI_AGENT_INSTRUCTIONS.md` - Mandatory development behaviors
- `docs/CODEBASE_MAP.md` - Project structure reference
- `docs/FEATURE_REQUIREMENTS.md` - Feature specifications
- `docs/KNOWN_ISSUES_DATABASE.md` - Common problems and solutions

## File Naming Conventions

### Plans (`/plans/`)

Format: `phase-[N]-[name]-[version].md`

Examples:
- `phase-0-foundation-1.md` - Phase 0 Foundation work
- `phase-1-core-navigation-1.md` - Phase 1 Core Navigation

### Details (`/details/`)

Format: `phase-[N]-[name]-details-[version].md`

Examples:
- `phase-0-foundation-details-1.md` - Phase 0 detailed specifications
- `phase-1-core-navigation-details-1.md` - Phase 1 detailed specifications

### Prompts (`/prompts/`)

Format: `execute-phase-[N]-[name]-[version].prompt.md`

Examples:
- `execute-phase-0-foundation-1.prompt.md` - Phase 0 execution instructions
- `execute-phase-1-core-navigation-1.prompt.md` - Phase 1 execution instructions

## Document Relationships

```
┌─────────────────────────┐
│   Implementation Plan   │  High-level checklist, requirements, constraints
│   (plans/)              │  References: docs/*, .github/instructions/*
└───────────┬─────────────┘
            │ references
            ▼
┌─────────────────────────┐
│  Detailed Specification │  Technical details, code specs, architecture
│  (details/)             │  References: plan, docs/*, .github/instructions/*
└───────────┬─────────────┘
            │ references
            ▼
┌─────────────────────────┐
│   Execution Prompt      │  Step-by-step workflow, validation checklist
│   (prompts/)            │  References: plan, details, docs/*, .github/*
└─────────────────────────┘
            │
            ▼
┌─────────────────────────┐
│   Implementation Code   │  Actual Flutter/Dart code
│   (future: separate     │  References: all above docs
│    app repository)      │
└─────────────────────────┘
```

## Quality Standards Integration

All planning documents integrate requirements from:

### Performance (from .github/instructions/performance-optimization.instructions.md)
- Map rendering at 60 FPS
- UI responsiveness during background processing
- Memory leak prevention
- Cache size limits

### Security (from .github/instructions/security-and-owasp.instructions.md)
- No hardcoded secrets
- Input validation
- API response validation
- HTTPS only

### UX (from .github/agents/se-ux-ui-designer.agent.md)
- Responsive design
- Accessibility considerations
- Consistent UI patterns
- Error handling UX

### Testing (from .github/instructions/spec-driven-workflow-v1.instructions.md)
- 80% code coverage minimum
- Unit tests for all services
- Widget tests for UI components
- Integration tests for critical flows

### Documentation (from .github/instructions/update-docs-on-code-change.instructions.md)
- Dartdoc comments on public APIs
- Update CODEBASE_MAP.md when structure changes
- Inline comments for complex logic
- Keep specifications in sync with code

## Creating New Planning Documents

When creating plans for future phases:

1. **Use the Implementation Plan Agent**
   ```
   @implementation-plan Create implementation plan for Phase [N]: [Name]
   ```

2. **Follow the Template**
   See `.github/agents/implementation-plan.agent.md` for the mandatory template structure

3. **Reference Existing Documentation**
   - Link to `docs/MASTER_DEVELOPMENT_BIBLE.md` for architecture rules
   - Link to `docs/FEATURE_REQUIREMENTS.md` for feature specs
   - Link to `.github/instructions/*` for best practices

4. **Include All Required Sections**
   - Requirements & Constraints
   - Implementation Steps (with tasks table)
   - Alternatives
   - Dependencies
   - Files
   - Testing
   - Risks & Assumptions
   - Related Specifications

5. **Create Supporting Documents**
   - Detailed specification in `/details/`
   - Execution prompt in `/prompts/`

## Development Workflow Example

Here's how a developer would use this system:

```bash
# 1. Review the plan
cat .copilot-tracking/plans/phase-0-foundation-1.md

# 2. Read detailed specs
cat .copilot-tracking/details/phase-0-foundation-details-1.md

# 3. Read execution prompt
cat .copilot-tracking/prompts/execute-phase-0-foundation-1.prompt.md

# 4. Read required documentation
cat docs/MASTER_DEVELOPMENT_BIBLE.md
cat docs/AI_AGENT_INSTRUCTIONS.md
cat .github/instructions/dart-n-flutter.instructions.md

# 5. Create Flutter project
flutter create marine_nav_app --org com.marineav

# 6. Implement each task from the plan
# Use Copilot agents for help:
# - @se-security-reviewer for security review
# - @se-system-architecture-reviewer for architecture questions
# - @specification for creating detailed specs

# 7. Run tests after each major component
flutter test --coverage

# 8. Validate against checklist
# Check off tasks in the plan as you complete them

# 9. Update documentation
# Update docs/CODEBASE_MAP.md with new files
# Add dartdoc comments to all public APIs

# 10. Final validation
flutter analyze
flutter test --coverage
# Verify all tasks checked off
```

## Benefits of This Approach

### For Human Developers
- Clear roadmap with detailed instructions
- No guessing about architecture or patterns
- Built-in quality standards
- Comprehensive reference documentation

### For AI Agents
- Structured, machine-readable format
- Deterministic instructions
- Clear validation criteria
- Complete context in one place

### For Project Success
- Prevents past failures (god objects, circular deps, projection issues)
- Ensures consistency across phases
- Maintains high quality standards
- Reduces technical debt
- Facilitates code reviews

## Phase Progress Tracking

| Phase | Plan | Details | Prompt | Status |
|-------|------|---------|--------|--------|
| Phase 0: Foundation | ✅ | ✅ | ✅ | Planned |
| Phase 1: Core Navigation | 🔜 | 🔜 | 🔜 | Not Started |
| Phase 2: Weather Intelligence | 🔜 | 🔜 | 🔜 | Not Started |
| Phase 3: Polish & Features | 🔜 | 🔜 | 🔜 | Not Started |
| Phase 4: Social & Community | 🔜 | 🔜 | 🔜 | Not Started |

## Getting Help

If you have questions about:

- **Planning process**: See `.github/agents/implementation-plan.agent.md`
- **Technical specifications**: See `.github/agents/specification.agent.md`
- **Architecture**: See `docs/MASTER_DEVELOPMENT_BIBLE.md`
- **Development workflow**: See `.github/instructions/spec-driven-workflow-v1.instructions.md`
- **Flutter best practices**: See `.github/instructions/dart-n-flutter.instructions.md`

## Contributing

When updating planning documents:

1. Maintain the template structure
2. Reference existing documentation
3. Update related documents (plan ↔ details ↔ prompt)
4. Keep documentation in sync with implementation
5. Add lessons learned to `docs/KNOWN_ISSUES_DATABASE.md`

## License

All planning documents are part of the Marine Navigation App project.

---

**Next Step**: Start with Phase 0 by reviewing `plans/phase-0-foundation-1.md`
