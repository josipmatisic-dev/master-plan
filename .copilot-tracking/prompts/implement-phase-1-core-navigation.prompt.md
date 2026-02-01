---
mode: agent
model: Claude Sonnet 4
---

# Implementation Prompt: Phase 1 Core Navigation

## Prerequisites

✅ Phase 0 complete  
✅ Read all required documentation (see Phase 0 prompt)  
✅ Review [Phase 1 Plan](../plans/phase-1-core-navigation-plan.md)  
✅ Review [Phase 1 Details](../details/phase-1-core-navigation-details.md)

## Critical Issues to Avoid

**ISS-001** (CRITICAL): Overlay projection mismatch - Use ProjectionService for ALL coordinate transforms  
**ISS-006** (CRITICAL): Memory leaks - Dispose all controllers  
**ISS-008** (MEDIUM): WebView lag - Debounce to 200ms  
**ISS-012** (HIGH): Wind direction inverted - Convert meteorological to mathematical  
**ISS-018** (MEDIUM): GPS jumping - Filter accuracy <50m

## Implementation Steps

Execute all tasks in [Phase 1 Plan](../plans/phase-1-core-navigation-plan.md) phases 1-10.

### Key Components

1. **MapWebView** - WebView integration with JavaScript bridge
2. **Viewport Sync** - Critical for overlay positioning (ISS-001)
3. **GPS Integration** - With accuracy filtering (ISS-018)
4. **Overlays** - Wind (ISS-012), Wave, Track using ProjectionService

### Testing Focus

- Overlay positioning at zoom 1, 10, 20 (ISS-001 check)
- Wind arrow direction correctness (ISS-012 check)
- Memory profiling (ISS-006 check)
- GPS accuracy filtering (ISS-018 check)

## Success Criteria

- [ ] All 180 tasks complete
- [ ] Map at 60 FPS
- [ ] Overlays correctly positioned
- [ ] No memory leaks
- [ ] Tests ≥80% coverage

---

**Next:** [Phase 2](implement-phase-2-weather-intelligence.prompt.md)
