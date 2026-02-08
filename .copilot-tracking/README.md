# Copilot Tracking Directory

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Centralized location for AI agent execution planning, research, and implementation tracking

---
# Copilot Tracking - Planning and Execution Artifacts

This directory contains planning documents, detailed specifications, and execution prompts for implementing the Marine Navigation App using GitHub Copilot and AI-assisted development.

## Directory Structure

```text
.copilot-tracking/
├── README.md                    # This file - directory overview
├── INDEX.md                     # Master index of all planning artifacts
├── plans/                       # Execution plans for each phase
│   ├── phase-0-foundation-plan.md
│   ├── phase-1-core-navigation-plan.md
│   ├── phase-2-weather-intelligence-plan.md
│   ├── phase-3-polish-features-plan.md
│   └── phase-4-social-community-plan.md
├── details/                     # Detailed specifications and requirements
│   ├── phase-0-foundation-details.md
│   ├── phase-1-core-navigation-details.md
│   ├── phase-2-weather-intelligence-details.md
│   ├── phase-3-polish-features-details.md
│   └── phase-4-social-community-details.md
├── prompts/                     # Implementation prompts for AI agents
│   ├── implement-phase-0-foundation.prompt.md
│   ├── implement-phase-1-core-navigation.prompt.md
│   ├── implement-phase-2-weather-intelligence.prompt.md
│   ├── implement-phase-3-polish-features.prompt.md
│   └── implement-phase-4-social-community.prompt.md
└── research/                    # Research and analysis documents
    └── 20260201-ui-architecture-adaptation-research.md

```text

---

## Purpose

This directory contains comprehensive execution planning artifacts for the Marine Navigation App development. It serves as the single source of truth for:

1. **Phase-by-phase implementation plans** with detailed task breakdowns
2. **Detailed specifications** for each feature and component
3. **Implementation prompts** that reference existing documentation and known issues
4. **Research documents** for design and architecture analysis

---

## How to Use This Directory

### For AI Agents

#### Before implementing a feature
1. Read `/plans/phase-N-*.md` to understand objectives and dependencies
2. Review `/details/phase-N-*.md` for detailed specifications
3. Check `/prompts/implement-phase-N-*.prompt.md` for step-by-step instructions
4. Reference the main docs (MASTER_DEVELOPMENT_BIBLE, KNOWN_ISSUES_DATABASE, etc.)

#### During implementation
1. Follow the prompt instructions systematically
2. Validate against success criteria in the plan
3. Check known issues to avoid repeating past mistakes
4. Update documentation as specified in the plan

#### After implementation
1. Verify all acceptance criteria are met
2. Run tests as specified in the plan
3. Update the plan file with completion status
4. Document any new issues discovered

### For Human Developers

#### Planning a new phase
1. Review the phase plan to understand scope and effort
2. Check dependencies on previous phases
3. Review risks and assumptions
4. Understand testing requirements

#### During development
1. Use the detail files for component specifications
2. Reference the prompts for suggested implementation approach
3. Check known issues database for common pitfalls
4. Update plans with progress and discoveries

#### Code review
1. Verify implementation matches specifications
2. Check that known issues are avoided
3. Ensure documentation is updated
4. Validate test coverage

---

## Document Structure Standards

### Plan Files (`/plans/`)

Each phase plan follows the mandatory template structure defined in the implementation-plan agent instructions:

#### Required Sections
1. **Introduction** - Overview and goals
2. **Requirements & Constraints** - What must be followed
3. **Implementation Steps** - Phase-by-phase task breakdown
4. **Alternatives** - Approaches considered but not chosen
5. **Dependencies** - Required components/libraries
6. **Files** - Affected file list
7. **Testing** - Test requirements
8. **Risks & Assumptions** - What could go wrong

**Identifier Prefixes:**
- `REQ-XXX` - Requirements
- `SEC-XXX` - Security requirements
- `CON-XXX` - Constraints
- `GUD-XXX` - Guidelines
- `PAT-XXX` - Patterns
- `TASK-XXX` - Tasks
- `GOAL-XXX` - Phase goals
- `ALT-XXX` - Alternatives
- `DEP-XXX` - Dependencies
- `FILE-XXX` - Files
- `TEST-XXX` - Tests
- `RISK-XXX` - Risks
- `ASSUMPTION-XXX` - Assumptions

### Detail Files (`/details/`)

Provide comprehensive specifications for each component:
- Component anatomy and structure
- Data models and interfaces
- API specifications
- UI/UX requirements
- Performance criteria
- Error handling requirements

### Prompt Files (`/prompts/`)

AI agent implementation instructions:
- Step-by-step execution instructions
- References to relevant documentation
- Known issues to avoid
- Success criteria
- Cleanup procedures

---

## Key Documentation References

All plans and prompts reference these core documents:

| Document | Location | Purpose |
| ---------- | ---------- | --------- |
| MASTER_DEVELOPMENT_BIBLE | `/docs/MASTER_DEVELOPMENT_BIBLE.md` | Complete failure analysis, architecture rules, development phases |
| AI_AGENT_INSTRUCTIONS | `/docs/AI_AGENT_INSTRUCTIONS.md` | Mandatory behaviors, forbidden actions, code patterns |
| CODEBASE_MAP | `/docs/CODEBASE_MAP.md` | Project structure, dependencies, data flow |
| FEATURE_REQUIREMENTS | `/docs/FEATURE_REQUIREMENTS.md` | Detailed feature specifications |
| KNOWN_ISSUES_DATABASE | `/docs/KNOWN_ISSUES_DATABASE.md` | All issues encountered, solutions, prevention rules |

---

## Version Control

- Plans are versioned in Git alongside code
- Status updates are made directly in plan files
- Completed tasks marked with ✅ and date
- New plans follow naming convention: `phase-N-description-plan.md`

---

## Best Practices

**DO:**
- ✅ Read all referenced documentation before starting
- ✅ Update plan status as you progress
- ✅ Document new issues discovered
- ✅ Follow all identifier conventions
- ✅ Reference known issues to avoid

**DON'T:**
- ❌ Skip reading the MASTER_DEVELOPMENT_BIBLE
- ❌ Modify existing documentation (only add new plans)
- ❌ Start implementation without a plan
- ❌ Ignore known issues
- ❌ Leave plan status outdated

---

**For detailed index of all artifacts, see [INDEX.md](INDEX.md)**
├── research/          # Research findings and analysis
├── plans/            # Task checklists with phase breakdowns
├── details/          # Detailed task specifications
├── prompts/          # Implementation prompts for AI agents
└── changes/          # Change tracking files
```text

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
```text

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

```text
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
```text

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
```text

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
| ------- | ------ | --------- | -------- | -------- |
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
