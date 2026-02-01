---
mode: agent
model: Claude Sonnet 4
---

# Implementation Prompt: Phase 2 Weather Intelligence

## Prerequisites

✅ Phase 0 and 1 complete  
✅ Review [Phase 2 Plan](../plans/phase-2-weather-intelligence-plan.md)  
✅ Review [Phase 2 Details](../details/phase-2-weather-intelligence-details.md)

## Critical Issues to Avoid

**ISS-004** (CRITICAL): Stale cache - Single unified cache with coordinated invalidation  
**ISS-010** (HIGH): Offline errors - Cache-first architecture  
**ISS-013** (CRITICAL): Timeline OOM - Lazy load frames, max 5 cached  
**ISS-014** (MEDIUM): WebView timeout - Proper timeout handling

## Implementation Steps

Execute tasks in [Phase 2 Plan](../plans/phase-2-weather-intelligence-plan.md) phases 1-10.

### Key Implementations

1. **WeatherProvider** - Cache-first (see Phase 2 Details)
2. **TimelineProvider** - Lazy frame loading (ISS-013)
3. **Weather Overlays** - Precipitation, currents, temperature

### Testing Focus

- Cache-first behavior (ISS-004 check)
- Offline mode (ISS-010 check)
- Timeline memory usage with 168 frames (ISS-013 check)

## Success Criteria

- [ ] All 278 tasks complete
- [ ] Cache-first working
- [ ] No OOM from timeline
- [ ] Tests ≥80% coverage

---

**Next:** [Phase 3](implement-phase-3-polish-features.prompt.md)
