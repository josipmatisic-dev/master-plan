# Local Implementation Guide - Phase 0 Foundation

This guide provides step-by-step instructions for implementing Phase 0 Foundation in your local VS Code environment where Flutter SDK is available.

## Prerequisites

- ✅ Flutter SDK installed and working in VS Code
- ✅ VS Code with Flutter extension
- ✅ Git repository cloned locally

## Implementation Approach

You have complete specifications created by specialized agents:
- **Backend Services**: `BACKEND_SERVICES_SPECIFICATION.md`
- **Frontend/UI**: `FRONTEND_IMPLEMENTATION_REPORT.md`
- **Architecture**: `PHASE_0_ARCHITECTURE.md`
- **Quick Guide**: `QUICK_IMPLEMENTATION_GUIDE.md`

## Option 1: Quick Implementation (Recommended - 2-3 hours)

Follow the `QUICK_IMPLEMENTATION_GUIDE.md` which provides:
- 14 step-by-step tasks
- Complete code for all files
- Copy-paste ready implementations
- Estimated 12-16 hours for complete Phase 0

### Quick Start:
```bash
cd /path/to/master-plan
# Create Flutter project in parent directory
cd ..
flutter create marine_nav_app
cd marine_nav_app

# Follow QUICK_IMPLEMENTATION_GUIDE.md steps 1-14
# Copy code from BACKEND_SERVICES_SPECIFICATION.md
```

## Option 2: Agent-Driven Implementation (Automated)

Use the specialized agents to implement directly in your local environment:

### Step 1: Pull Latest Specifications
```bash
git pull origin main
```

### Step 2: Create Flutter Project
```bash
# In parent directory of master-plan
cd ..
flutter create marine_nav_app --org dev.josipmatisic --description "Marine navigation app with SailStream UI"
cd marine_nav_app
```

### Step 3: Use Task Agent for Implementation

Open VS Code in the `marine_nav_app` directory and use GitHub Copilot Chat:

```
@workspace Implement Phase 0 Foundation for Marine Navigation App using the specifications in:
- ../master-plan/BACKEND_SERVICES_SPECIFICATION.md
- ../master-plan/PHASE_0_ARCHITECTURE.md  
- ../master-plan/QUICK_IMPLEMENTATION_GUIDE.md

Follow all architecture rules from ../master-plan/docs/MASTER_DEVELOPMENT_BIBLE.md Section C.
Implement all services, models, providers, and theme system as specified.
```

## Option 3: Manual Implementation (Full Control)

### Phase 1: Project Setup (30 min)

```bash
# Create Flutter project
flutter create marine_nav_app --org dev.josipmatisic
cd marine_nav_app

# Add dependencies to pubspec.yaml
```

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  http: ^1.1.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  sqflite: ^2.3.0
  latlong2: ^0.9.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

### Phase 2: Directory Structure (5 min)

```bash
mkdir -p lib/{models,providers,services,screens,widgets,theme,utils}
mkdir -p test/{models,providers,services,widgets}
```

### Phase 3: Copy Implementation Files (2 hours)

Open `BACKEND_SERVICES_SPECIFICATION.md` and copy each service implementation:

**Services to copy:**
1. `lib/services/cache_service.dart` (lines 50-350 in spec)
2. `lib/services/http_client.dart` (lines 360-640 in spec)
3. `lib/services/projection_service.dart` (lines 650-920 in spec)
4. `lib/services/nmea_parser.dart` (lines 930-1200 in spec)
5. `lib/services/database_service.dart` (lines 1210-1480 in spec)

**Models to copy:**
1. `lib/models/lat_lng.dart` (lines 1490-1590 in spec)
2. `lib/models/bounds.dart` (lines 1600-1720 in spec)
3. `lib/models/viewport.dart` (lines 1730-1820 in spec)
4. `lib/models/boat_position.dart` (lines 1830-1930 in spec)
5. `lib/models/cache_entry.dart` (lines 1940-2020 in spec)
6. `lib/models/nmea_message.dart` (lines 2030-2130 in spec)

**Providers to copy:**
1. `lib/providers/settings_provider.dart` (from FRONTEND_IMPLEMENTATION_REPORT.md)
2. `lib/providers/theme_provider.dart` (from FRONTEND_IMPLEMENTATION_REPORT.md)
3. `lib/providers/cache_provider.dart` (from FRONTEND_IMPLEMENTATION_REPORT.md)

**Theme files to copy:**
1. `lib/theme/colors.dart`
2. `lib/theme/text_styles.dart`
3. `lib/theme/dimensions.dart`
4. `lib/theme/app_theme.dart`

**Main application:**
1. `lib/main.dart` (from FRONTEND_IMPLEMENTATION_REPORT.md)

### Phase 4: Install Dependencies (5 min)

```bash
flutter pub get
```

### Phase 5: Run Tests (30 min)

Copy test files from `BACKEND_SERVICES_SPECIFICATION.md` (lines 2500-4200) and run:

```bash
flutter test
```

Expected: 71+ tests passing, 80%+ coverage

### Phase 6: Verify Build (5 min)

```bash
flutter analyze
flutter run -d chrome  # or your preferred device
```

## Expected Results

After implementation:
- ✅ 28 files created (~3,770 lines of code)
- ✅ All tests passing (71+ test cases)
- ✅ 80%+ code coverage
- ✅ App runs without errors
- ✅ Theme switching works
- ✅ All architecture rules followed

## Verification Checklist

Use `IMPLEMENTATION_VERIFICATION.md` for complete task-by-task checklist:

- [ ] All 6 project initialization tasks complete
- [ ] All 5 core services implemented
- [ ] All 6 data models implemented  
- [ ] All 3 providers implemented
- [ ] All 5 theme system components implemented
- [ ] All tests passing
- [ ] CI/CD configured
- [ ] Documentation updated

## Timeline Estimates

| Approach | Time | Difficulty |
|----------|------|------------|
| Quick Guide (copy-paste) | 2-3 hours | Easy |
| Agent-Driven (automated) | 1-2 hours | Very Easy |
| Manual Implementation | 12-16 hours | Medium |

## Next Steps After Phase 0

Once Phase 0 is complete and verified:
1. Commit all changes to a new branch: `git checkout -b phase-0-foundation`
2. Push to GitHub: `git push origin phase-0-foundation`
3. Create PR for review
4. Proceed to Phase 1: Core Navigation

## Support Documentation

All specifications include:
- Complete working code
- Architecture justifications
- Test cases with expected outputs
- Error handling patterns
- Performance optimizations

Refer to these documents for any questions:
- `BACKEND_SERVICES_SPECIFICATION.md` - All backend code
- `FRONTEND_IMPLEMENTATION_REPORT.md` - All frontend code
- `PHASE_0_ARCHITECTURE.md` - Architecture patterns
- `QUICK_IMPLEMENTATION_GUIDE.md` - Step-by-step tasks
- `docs/MASTER_DEVELOPMENT_BIBLE.md` - Architecture rules

## Troubleshooting

**If Flutter commands fail:**
```bash
flutter doctor -v  # Check Flutter installation
flutter clean      # Clean build cache
flutter pub get    # Reinstall dependencies
```

**If tests fail:**
- Check that all services are properly imported
- Verify test helper files are in place
- Run individual test files: `flutter test test/services/cache_service_test.dart`

**If build fails:**
- Run `flutter analyze` to check for errors
- Verify all imports are correct
- Check that pubspec.yaml has all dependencies

## Questions?

All implementation details are in the specification documents created by the specialized agents. They contain complete, production-ready code that follows all architecture rules from the Master Development Bible.
