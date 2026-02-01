# Quick Implementation Guide - Phase 0 Backend Services

**Use this guide for rapid implementation once Flutter SDK is available**

---

## Step 1: Initialize Flutter Project (5 minutes)

```bash
# Create Flutter project
flutter create marine_nav_app --org com.marinenavapp --project-name marine_nav_app

# Navigate to project
cd marine_nav_app

# Verify
flutter doctor
```

---

## Step 2: Add Dependencies (5 minutes)

Edit `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  http: ^1.0.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  sqflite: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

Run:
```bash
flutter pub get
```

---

## Step 3: Create Directory Structure (2 minutes)

```bash
mkdir -p lib/models
mkdir -p lib/providers
mkdir -p lib/services
mkdir -p lib/theme
mkdir -p lib/utils
mkdir -p test/unit/services
mkdir -p test/unit/models
mkdir -p test/widget/providers
```

---

## Step 4: Implement Data Models (30 minutes)

### LatLng (lib/models/lat_lng.dart)

```dart
class LatLng {
  final double latitude;
  final double longitude;
  
  const LatLng(this.latitude, this.longitude)
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;
  
  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
  
  @override
  String toString() => 'LatLng($latitude, $longitude)';
  
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
  
  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      );
}
```

**Test (test/unit/models/lat_lng_test.dart):**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/models/lat_lng.dart';

void main() {
  group('LatLng', () {
    test('should create valid coordinate', () {
      const latLng = LatLng(45.5231, -122.6765);
      expect(latLng.latitude, 45.5231);
      expect(latLng.longitude, -122.6765);
    });
    
    test('should enforce latitude bounds', () {
      expect(() => LatLng(91, 0), throwsA(isA<AssertionError>()));
      expect(() => LatLng(-91, 0), throwsA(isA<AssertionError>()));
    });
    
    test('should enforce longitude bounds', () {
      expect(() => LatLng(0, 181), throwsA(isA<AssertionError>()));
      expect(() => LatLng(0, -181), throwsA(isA<AssertionError>()));
    });
    
    test('should support equality', () {
      const a = LatLng(45.5, -122.6);
      const b = LatLng(45.5, -122.6);
      const c = LatLng(45.6, -122.6);
      
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
    
    test('should serialize to JSON', () {
      const latLng = LatLng(45.5, -122.6);
      final json = latLng.toJson();
      
      expect(json['latitude'], 45.5);
      expect(json['longitude'], -122.6);
    });
    
    test('should deserialize from JSON', () {
      final json = {'latitude': 45.5, 'longitude': -122.6};
      final latLng = LatLng.fromJson(json);
      
      expect(latLng.latitude, 45.5);
      expect(latLng.longitude, -122.6);
    });
  });
}
```

**Copy pattern for other models:** Bounds, Viewport, BoatPosition, CacheEntry, NMEAMessage
- All from `docs/BACKEND_SERVICES_SPECIFICATION.md`

---

## Step 5: Implement ProjectionService (1 hour)

### lib/services/projection_service.dart

```dart
import 'dart:math';
import 'dart:ui';
import 'package:marine_nav_app/models/lat_lng.dart';
import 'package:marine_nav_app/models/viewport.dart';

class ProjectionService {
  static const double EARTH_RADIUS = 6378137.0;
  static const double MAX_LATITUDE = 85.05112878;
  
  Point wgs84ToWebMercator(double lat, double lng) {
    lat = lat.clamp(-MAX_LATITUDE, MAX_LATITUDE);
    lng = ((lng + 180) % 360) - 180;
    
    double latRad = lat * pi / 180;
    double lngRad = lng * pi / 180;
    
    double x = EARTH_RADIUS * lngRad;
    double y = EARTH_RADIUS * log(tan(pi / 4 + latRad / 2));
    
    return Point(x, y);
  }
  
  LatLng webMercatorToWgs84(double x, double y) {
    double lng = (x / EARTH_RADIUS) * 180 / pi;
    double lat = (2 * atan(exp(y / EARTH_RADIUS)) - pi / 2) * 180 / pi;
    
    lat = lat.clamp(-90.0, 90.0);
    lng = ((lng + 180) % 360) - 180;
    
    return LatLng(lat, lng);
  }
  
  Point latLngToScreen(LatLng latLng, Viewport viewport, Size screenSize) {
    Point mercator = wgs84ToWebMercator(latLng.latitude, latLng.longitude);
    Point centerMercator = wgs84ToWebMercator(
      viewport.center.latitude,
      viewport.center.longitude,
    );
    
    double scale = pow(2, viewport.zoom) as double;
    
    double dx = (mercator.x - centerMercator.x) * scale;
    double dy = (mercator.y - centerMercator.y) * scale;
    
    if (viewport.bearing != 0) {
      double bearingRad = viewport.bearing * pi / 180;
      double rotatedX = dx * cos(bearingRad) - dy * sin(bearingRad);
      double rotatedY = dx * sin(bearingRad) + dy * cos(bearingRad);
      dx = rotatedX;
      dy = rotatedY;
    }
    
    double screenX = screenSize.width / 2 + dx;
    double screenY = screenSize.height / 2 - dy;
    
    return Point(screenX, screenY);
  }
  
  LatLng screenToLatLng(Offset screenPoint, Viewport viewport, Size screenSize) {
    double dx = screenPoint.dx - screenSize.width / 2;
    double dy = screenSize.height / 2 - screenPoint.dy;
    
    if (viewport.bearing != 0) {
      double bearingRad = -viewport.bearing * pi / 180;
      double rotatedX = dx * cos(bearingRad) - dy * sin(bearingRad);
      double rotatedY = dx * sin(bearingRad) + dy * cos(bearingRad);
      dx = rotatedX;
      dy = rotatedY;
    }
    
    double scale = pow(2, viewport.zoom) as double;
    
    Point centerMercator = wgs84ToWebMercator(
      viewport.center.latitude,
      viewport.center.longitude,
    );
    
    double x = centerMercator.x + dx / scale;
    double y = centerMercator.y + dy / scale;
    
    return webMercatorToWgs84(x, y);
  }
}
```

**Test:** See `docs/BACKEND_SERVICES_SPECIFICATION.md` Section "ProjectionService Tests"

---

## Step 6: Implement CacheService (2 hours)

Key points:
- Use `path_provider` for cache directory
- Metadata in JSON file
- LRU tracking with lastAccess timestamp
- TTL checking on get()
- Eviction when size > 500MB

**Full implementation:** `docs/BACKEND_SERVICES_SPECIFICATION.md` Section "CacheService"

---

## Step 7: Implement HttpClient (1 hour)

Key points:
- 3 retry attempts
- Exponential backoff (1s, 2s, 4s)
- 30s timeout
- Sanitized logging

**Full implementation:** `docs/BACKEND_SERVICES_SPECIFICATION.md` Section "HttpClient"

---

## Step 8: Implement NMEAParser (2 hours)

Key points:
- Checksum validation (XOR of bytes)
- Parse GPGGA, GPRMC, GPVTG
- Convert DDMM.MMMM to decimal degrees
- Handle missing fields gracefully

**Full implementation:** `docs/BACKEND_SERVICES_SPECIFICATION.md` Section "NMEAParser"

---

## Step 9: Implement DatabaseService (1 hour)

Key points:
- Use sqflite package
- Create schema on init()
- Parameterized queries only

**Full implementation:** `docs/BACKEND_SERVICES_SPECIFICATION.md` Section "DatabaseService"

---

## Step 10: Implement Providers (2 hours)

### SettingsProvider

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SpeedUnit { knots, mph, kph }
enum DistanceUnit { nauticalMiles, miles, kilometers }

class SettingsProvider extends ChangeNotifier {
  SpeedUnit _speedUnit = SpeedUnit.knots;
  DistanceUnit _distanceUnit = DistanceUnit.nauticalMiles;
  String _language = 'en';
  
  SpeedUnit get speedUnit => _speedUnit;
  DistanceUnit get distanceUnit => _distanceUnit;
  String get language => _language;
  
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _speedUnit = SpeedUnit.values[prefs.getInt('speed_unit') ?? 0];
    _distanceUnit = DistanceUnit.values[prefs.getInt('distance_unit') ?? 0];
    _language = prefs.getString('language') ?? 'en';
    notifyListeners();
  }
  
  Future<void> setSpeedUnit(SpeedUnit unit) async {
    _speedUnit = unit;
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> setDistanceUnit(DistanceUnit unit) async {
    _distanceUnit = unit;
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    await _saveSettings();
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('speed_unit', _speedUnit.index);
    await prefs.setInt('distance_unit', _distanceUnit.index);
    await prefs.setString('language', _language);
  }
}
```

**Copy pattern for:** ThemeProvider, CacheProvider

---

## Step 11: Wire Up main.dart (30 minutes)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/theme_provider.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/services/cache_service.dart';
import 'package:marine_nav_app/services/http_client.dart';
import 'package:marine_nav_app/services/projection_service.dart';
import 'package:marine_nav_app/services/nmea_parser.dart';
import 'package:marine_nav_app/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final cacheService = CacheService();
  await cacheService.init();
  
  final httpClient = HttpClient();
  final projectionService = ProjectionService();
  final nmeaParser = NMEAParser();
  final databaseService = DatabaseService();
  await databaseService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, ThemeProvider>(
          create: (_) => ThemeProvider(
            Provider.of<SettingsProvider>(_, listen: false),
          ),
          update: (_, settings, themeProvider) => themeProvider!,
        ),
        ChangeNotifierProxyProvider<SettingsProvider, CacheProvider>(
          create: (_) => CacheProvider(
            Provider.of<SettingsProvider>(_, listen: false),
            cacheService,
          )..init(),
          update: (_, settings, cacheProvider) => cacheProvider!,
        ),
        Provider<CacheService>.value(value: cacheService),
        Provider<HttpClient>.value(value: httpClient),
        Provider<ProjectionService>.value(value: projectionService),
        Provider<NMEAParser>.value(value: nmeaParser),
        Provider<DatabaseService>.value(value: databaseService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Marine Navigation App',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
```

---

## Step 12: Run Tests (30 minutes)

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
lcov --summary coverage/lcov.info
```

**Fix any failing tests**

---

## Step 13: Verify Architecture Compliance (15 minutes)

```bash
# Check line counts
find lib -name "*.dart" -exec wc -l {} \; | awk '$1 > 300 {print "FAIL: " $2 " has " $1 " lines"}'

# Should output nothing (all files < 300 lines)

# Run linter
flutter analyze

# Should output: No issues found!
```

---

## Step 14: Set Up CI/CD (30 minutes)

Create `.github/workflows/test.yml`:

```yaml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run analyzer
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Check coverage
        run: |
          lcov --summary coverage/lcov.info
          coverage=$(lcov --summary coverage/lcov.info 2>&1 | grep lines | awk '{print $2}' | sed 's/%//')
          echo "Coverage: $coverage%"
          if (( $(echo "$coverage < 80" | bc -l) )); then
            echo "Coverage $coverage% is below 80%"
            exit 1
          fi
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```

> **Security Note**: For production use, pin GitHub Actions to specific commit SHAs instead of version tags to prevent supply chain attacks. For example:
> - `actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11` (v4.1.1)
> - `subosito/flutter-action@2783a3f08e1baf891508463f8c6653c258246225` (v2.12.0)
> - `codecov/codecov-action@e28ff129e5465c2c0dcc6f003fc735cb6ae0c673` (v4.5.0)

---

## Completion Checklist

- [ ] Flutter project initialized
- [ ] Dependencies installed
- [ ] Directory structure created
- [ ] All 6 data models implemented
- [ ] All 5 services implemented
- [ ] All 3 providers implemented
- [ ] main.dart wired up
- [ ] All unit tests written
- [ ] All tests passing
- [ ] Coverage ≥ 80%
- [ ] All files < 300 lines
- [ ] Linter passing
- [ ] CI/CD workflows created
- [ ] Documentation updated

---

## Total Time Estimate: 12-16 hours

**Can be done in 2-3 focused work days**

---

## References

- Complete implementations: `docs/BACKEND_SERVICES_SPECIFICATION.md`
- Architecture: `docs/PHASE_0_ARCHITECTURE.md`
- Summary: `docs/PHASE_0_BACKEND_SUMMARY.md`
