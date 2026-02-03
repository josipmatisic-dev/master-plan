# Master Plan - Marine Navigation App Documentation

![Flutter CI](https://github.com/josipmatisic-dev/master-plan/workflows/Flutter%20CI/badge.svg)

Master planning documentation for yacht navigation app development based on learnings from 4 failed attempts.

## 📋 Planning & Workflow

This repository uses structured planning approaches for AI agents:

- **`.github/copilot-instructions.md`** - Quick AI agent guide for immediate productivity
- **[PLANNING_GUIDE.md](PLANNING_GUIDE.md)** - Complete guide to planning structures and workflows
- **`.copilot-tracking/`** - Task-based planning with research validation
- **`/plan/`** - Formal implementation plan specifications

See [PLANNING_GUIDE.md](PLANNING_GUIDE.md) for details on when to use each approach.

## 📂 Documentation Files

All comprehensive documentation is located in the **`docs/`** directory:

### Core References (Read First for AI Agents)
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** (~5 KB) - Quick reference for AI coding agents (start here!)
- **[MASTER_DEVELOPMENT_BIBLE.md](docs/MASTER_DEVELOPMENT_BIBLE.md)** (16 KB) - Main comprehensive reference with failure analysis, architecture rules, and development phases
- **[AI_AGENT_INSTRUCTIONS.md](docs/AI_AGENT_INSTRUCTIONS.md)** (18 KB) - Complete guidelines for AI agents building the app (includes SailStream UI patterns)
- **[CODEBASE_MAP.md](docs/CODEBASE_MAP.md)** (18 KB) - Project structure and dependency graphs

### Detailed Specifications
- **[KNOWN_ISSUES_DATABASE.md](docs/KNOWN_ISSUES_DATABASE.md)** (26 KB) - 18 documented issues with root causes and solutions
- **[FEATURE_REQUIREMENTS.md](docs/FEATURE_REQUIREMENTS.md)** (19 KB) - Detailed requirements for 14 features
- **[UI_DESIGN_SYSTEM.md](docs/UI_DESIGN_SYSTEM.md)** (17 KB) - Ocean Glass design system specification

### Quick Start
- **[docs/README.md](docs/README.md)** (~10–14 KB) - Quick navigation guide
- **[DOCUMENTATION_SUMMARY.md](docs/DOCUMENTATION_SUMMARY.md)** (15 KB) - Verification checklist

## 🚀 Quick Start

1. Read [docs/README.md](docs/README.md) for an overview
2. Start with [MASTER_DEVELOPMENT_BIBLE.md](docs/MASTER_DEVELOPMENT_BIBLE.md) for complete context
3. Follow [AI_AGENT_INSTRUCTIONS.md](docs/AI_AGENT_INSTRUCTIONS.md) when implementing

## 🔧 Development

### Flutter Application

The Flutter application is located in the `marine_nav_app/` directory.

**Continuous Integration:** Automated CI/CD runs on every push and pull request. See [.github/workflows/README.md](.github/workflows/README.md) for details.

**Running locally:**
```bash
cd marine_nav_app
flutter pub get
flutter test
flutter analyze
flutter run
```

**iOS parallel development:** The iOS scaffold is already present in `marine_nav_app/ios`. Use a macOS machine with Xcode and CocoaPods installed, then either run `flutter run` with an iOS simulator or device selected, or list devices with `flutter devices` and pass the specific id to `flutter run -d <device-id>`, or open `ios/Runner.xcworkspace` in Xcode.

## 📊 Statistics

- **Documentation Stats:** See [DOCUMENTATION_SUMMARY.md](docs/DOCUMENTATION_SUMMARY.md) for the current file and line counts
- **Total Size:** ~117 KB
- **Code Examples:** 25+ Dart/Flutter examples
- **Issues Documented:** 18 with full analysis
- **Features Specified:** 14 with complete requirements
