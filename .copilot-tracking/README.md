# Copilot Tracking Directory

**Version:** 1.0  
**Last Updated:** 2026-02-01  
**Purpose:** Centralized location for AI agent execution planning, research, and implementation tracking

---

## Directory Structure

```
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

```

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

**Before implementing a feature:**
1. Read `/plans/phase-N-*.md` to understand objectives and dependencies
2. Review `/details/phase-N-*.md` for detailed specifications
3. Check `/prompts/implement-phase-N-*.prompt.md` for step-by-step instructions
4. Reference the main docs (MASTER_DEVELOPMENT_BIBLE, KNOWN_ISSUES_DATABASE, etc.)

**During implementation:**
1. Follow the prompt instructions systematically
2. Validate against success criteria in the plan
3. Check known issues to avoid repeating past mistakes
4. Update documentation as specified in the plan

**After implementation:**
1. Verify all acceptance criteria are met
2. Run tests as specified in the plan
3. Update the plan file with completion status
4. Document any new issues discovered

### For Human Developers

**Planning a new phase:**
1. Review the phase plan to understand scope and effort
2. Check dependencies on previous phases
3. Review risks and assumptions
4. Understand testing requirements

**During development:**
1. Use the detail files for component specifications
2. Reference the prompts for suggested implementation approach
3. Check known issues database for common pitfalls
4. Update plans with progress and discoveries

**Code review:**
1. Verify implementation matches specifications
2. Check that known issues are avoided
3. Ensure documentation is updated
4. Validate test coverage

---

## Document Structure Standards

### Plan Files (`/plans/`)

Each phase plan follows the mandatory template structure defined in the implementation-plan agent instructions:

**Required Sections:**
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
|----------|----------|---------|
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
