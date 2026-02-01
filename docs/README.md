# Marine Navigation App Documentation

This directory contains comprehensive documentation based on learnings from 4 failed development attempts.

## 📚 Documentation Files

### 1. MASTER_DEVELOPMENT_BIBLE.md
**Purpose:** The single source of truth for the entire project  
**Sections:**
- Complete failure analysis from all 4 attempts
- Working code inventory (battle-tested patterns)
- Mandatory architecture rules
- Feature specifications categorized by phase
- Technical decisions with rationale
- Development phases with deliverables

**When to read:** Before starting ANY development work

---

### 2. AI_AGENT_INSTRUCTIONS.md
**Purpose:** Mandatory guidelines for AI coding assistants  
**Sections:**
- Mandatory behaviors (read Bible first, follow rules, update docs)
- Forbidden actions (god objects, mixed state, manual coordinate math)
- Code patterns (weather fetching, overlay rendering, NMEA processing)
- Documentation requirements
- Error handling guidelines
- Testing requirements
- Review checklist

**When to read:** Before making any code changes

---

### 3. CODEBASE_MAP.md
**Purpose:** Complete map of Flutter project structure  
**Sections:**
- Directory structure (lib/, screens/, services/, widgets/, etc.)
- Provider dependency graph with 3-layer hierarchy
- Data flow diagrams (weather, NMEA, overlay rendering)
- Key files reference with line counts
- Service layer architecture
- Widget hierarchy visualization
- Module ownership and test coverage

**When to read:** When navigating the codebase or adding new components

---

### 4. KNOWN_ISSUES_DATABASE.md
**Purpose:** Comprehensive database of all issues from 4 attempts  
**Sections:**
- 18 documented issues with status
- Detailed issue records with symptoms, root cause, solutions
- Code examples (wrong vs correct)
- Prevention rules
- Summary statistics

**When to read:** When encountering errors or before implementing similar features

---

### 5. FEATURE_REQUIREMENTS.md
**Purpose:** Detailed specifications for all planned features  
**Sections:**
- Core features (Phase 1): Map, NMEA, boat tracking, weather overlays
- Essential features (Phase 2): Forecasting, timeline, dark mode, offline
- Advanced features (Phase 3): Settings, harbor alerts, AIS, tides
- Social features (Phase 4): Trip logging, sharing
- Feature priority matrix with effort/complexity/risk

**When to read:** Before implementing any feature

---

## 🎯 Quick Start Guide

### For New Developers
1. Read MASTER_DEVELOPMENT_BIBLE.md Section A (Failure Analysis)
2. Skim KNOWN_ISSUES_DATABASE.md to understand common pitfalls
3. Review CODEBASE_MAP.md to understand project structure
4. Read relevant sections in FEATURE_REQUIREMENTS.md for your task

### For AI Coding Assistants
1. Read AI_AGENT_INSTRUCTIONS.md in full
2. Follow mandatory behaviors and avoid forbidden actions
3. Use working code patterns from Section B of the Bible
4. Update documentation for every code change

### Before Writing Code
1. ✅ Read the Bible section for your area
2. ✅ Check KNOWN_ISSUES_DATABASE.md for similar problems
3. ✅ Verify architecture rules compliance
4. ✅ Review working code patterns
5. ✅ Write tests first

### Before Submitting Code
- [ ] All architecture rules followed
- [ ] File size <300 lines
- [ ] All disposables disposed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No demo code included

---

## 📊 Documentation Statistics

| Document | Lines | Size | Purpose |
|----------|-------|------|---------|
| MASTER_DEVELOPMENT_BIBLE.md | 488 | 16KB | Primary reference |
| AI_AGENT_INSTRUCTIONS.md | 801 | 18KB | AI guidelines |
| CODEBASE_MAP.md | 501 | 18KB | Structure map |
| KNOWN_ISSUES_DATABASE.md | 958 | 26KB | Issue database |
| FEATURE_REQUIREMENTS.md | 748 | 19KB | Feature specs |
| **TOTAL** | **3,496** | **97KB** | Complete docs |

---

## 🚨 Critical Learnings

### Top 5 Failure Causes
1. **Projection Mismatch** - Mixed coordinate systems (ISS-001)
2. **God Objects** - 2,847-line controllers (ISS-002)
3. **Memory Leaks** - Undisposed AnimationControllers (ISS-006)
4. **Cache Chaos** - 4 uncoordinated cache layers (ISS-004)
5. **UI Thread Blocking** - NMEA parsing on main thread (ISS-009)

### Top 5 Architecture Rules
1. **Single Source of Truth** - No duplicate state
2. **Projection Consistency** - All coordinates through ProjectionService
3. **Provider Discipline** - Max 3 layers, no circular deps
4. **File Size Limits** - Max 300 lines per file
5. **Dispose Everything** - No memory leaks

### Top 5 Working Patterns
1. **NMEA Parser** - Checksum validation, isolate processing
2. **HTTP Retry** - Exponential backoff, cache fallback
3. **LRU Cache** - TTL, size limits, coordinated invalidation
4. **Web Mercator Projection** - WGS84 ↔ Screen pixels
5. **Viewport Sync** - WebView ↔ Flutter overlay coordination

---

## 🔄 Document Maintenance

### When to Update
- **MASTER_DEVELOPMENT_BIBLE.md** - When discovering new failures or patterns
- **AI_AGENT_INSTRUCTIONS.md** - When adding new mandatory behaviors
- **CODEBASE_MAP.md** - When adding new files/services/providers
- **KNOWN_ISSUES_DATABASE.md** - When encountering new issues
- **FEATURE_REQUIREMENTS.md** - When specs change or new features added

### Version Control
All documentation is versioned and dated. Update version number and date when making changes.

---

## 📞 Support

For questions about the documentation:
1. Check KNOWN_ISSUES_DATABASE.md for similar questions
2. Review relevant section in MASTER_DEVELOPMENT_BIBLE.md
3. Consult FEATURE_REQUIREMENTS.md for feature-specific details

---

**Remember:** These documents exist because of 4 failed attempts costing months of development time. Read them. Follow them. Don't repeat history.

---

**Last Updated:** 2024-02-01
