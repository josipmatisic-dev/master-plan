# Flutter CI Workflow

This repository includes automated CI/CD for the Flutter application located in `marine_nav_app/`.

## Workflow Details

The Flutter CI workflow (`.github/workflows/flutter-ci.yml`) runs on:
- Every push to the `main` branch
- Every pull request to the `main` branch
- Only when files in `marine_nav_app/` or the workflow file itself are changed

## CI Jobs

The workflow includes four parallel jobs:

### 1. Test Job
- Runs all Flutter tests with coverage
- Uploads coverage reports to Codecov
- Command: `flutter test --coverage`

### 2. Analyze Job
- Performs static code analysis
- Treats all warnings and infos as errors
- Command: `flutter analyze --fatal-infos --fatal-warnings`

### 3. Format Job
- Checks code formatting compliance
- Ensures code follows Dart style guidelines
- Command: `dart format --output=none --set-exit-if-changed .`

### 4. Build Job
- Builds Android APK (debug mode)
- Builds web application
- Verifies that the app compiles successfully
- Commands: 
  - `flutter build apk --debug`
  - `flutter build web`

## Flutter Version

The workflow uses Flutter 3.16.0 (stable channel), which is compatible with the project's SDK constraint (`>=3.2.0 <4.0.0`).

## Caching

Flutter dependencies are cached to speed up subsequent workflow runs.

## Adding More Tests

To add more tests:
1. Create test files in `marine_nav_app/test/`
2. Follow the naming convention: `*_test.dart`
3. Tests will automatically run in the CI pipeline

## Local Development

Before pushing code, you can run these checks locally:

```bash
cd marine_nav_app

# Run tests
flutter test --coverage

# Analyze code
flutter analyze

# Check formatting
dart format --output=none --set-exit-if-changed .

# Build for Android
flutter build apk --debug

# Build for Web
flutter build web
```

## Status Badge

Add this badge to your README to show CI status:

```markdown
![Flutter CI](https://github.com/josipmatisic-dev/master-plan/workflows/Flutter%20CI/badge.svg)
```
