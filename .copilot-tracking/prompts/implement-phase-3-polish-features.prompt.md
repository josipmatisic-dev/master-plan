---
mode: agent
model: Claude Sonnet 4
---

# Implementation Prompt: Phase 3 Polish & Features

## Prerequisites

✅ Phase 0-2 complete  
✅ Review [Phase 3 Plan](../plans/phase-3-polish-features-plan.md)  
✅ Review [Phase 3 Details](../details/phase-3-polish-features-details.md)

## Critical Issues to Avoid

**ISS-005** (HIGH): Overflow on small devices - Use Flexible/Expanded, test iPhone SE  
**ISS-006** (CRITICAL): Memory leaks - Dispose all controllers  
**ISS-015** (LOW): Dark mode not persisting - Use SharedPreferences  
**ISS-016** (HIGH): AIS buffer overflow - Isolate processing, backpressure, spatial culling

## Implementation Steps

Execute tasks in [Phase 3 Plan](../plans/phase-3-polish-features-plan.md) phases 1-10.

### Key Implementations

1. **Dark Mode** - With persistence (fix ISS-015)
2. **AIS Service** - Fix ISS-016 with isolate + backpressure
3. **Performance** - Profiling and optimization

### Testing Focus

- Responsive layouts on iPhone SE 667x375 (ISS-005)
- AIS with 100+ targets (ISS-016)
- Memory profiling (ISS-006)
- Theme persistence (ISS-015)

## Success Criteria

- [ ] All 377 tasks complete
- [ ] ISS-016 fixed and documented
- [ ] 60 FPS maintained
- [ ] Tests ≥80% coverage

---

**Next:** [Phase 4](implement-phase-4-social-community.prompt.md)
