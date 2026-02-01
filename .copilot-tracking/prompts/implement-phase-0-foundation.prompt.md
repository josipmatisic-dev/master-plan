---
mode: agent
model: Claude Sonnet 4
---

# Implementation Prompt: Phase 0 Foundation

## Prerequisites Check

✅ Read [MASTER_DEVELOPMENT_BIBLE.md](../../docs/MASTER_DEVELOPMENT_BIBLE.md) - Section A (Failures), Section C (Rules)  
✅ Read [AI_AGENT_INSTRUCTIONS.md](../../docs/AI_AGENT_INSTRUCTIONS.md) - All sections  
✅ Review [KNOWN_ISSUES_DATABASE.md](../../docs/KNOWN_ISSUES_DATABASE.md) - All relevant issues  
✅ Review [Phase 0 Plan](../plans/phase-0-foundation-plan.md)  
✅ Review [Phase 0 Details](../details/phase-0-foundation-details.md)

## Implementation Steps

Execute all tasks in [Phase 0 Plan](../plans/phase-0-foundation-plan.md) following the implementation phases 1-8.

### Key Focus Areas

1. **ProjectionService** - Critical for ISS-001 prevention
2. **CacheService** - Critical for ISS-004 prevention
3. **Provider Hierarchy** - Critical for ISS-002, ISS-003 prevention
4. **Disposal Pattern** - Critical for ISS-006 prevention

### Testing Requirements

- ProjectionService: 100% coverage, test known coordinate pairs
- CacheService: 100% coverage, test LRU, TTL, size limits
- Providers: Test initialization order, no circular deps

## Success Criteria

- [ ] All 64 tasks complete
- [ ] Tests passing (100% coverage for Phase 0)
- [ ] No circular dependencies
- [ ] CI/CD pipeline green

---

**Next:** [Phase 1](implement-phase-1-core-navigation.prompt.md) after Phase 0 complete
