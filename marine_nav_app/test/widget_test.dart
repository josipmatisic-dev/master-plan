import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/main.dart';
import 'package:marine_nav_app/providers/ais_provider.dart';
import 'package:marine_nav_app/providers/boat_provider.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/nmea_provider.dart';
import 'package:marine_nav_app/providers/quality_provider.dart';
import 'package:marine_nav_app/providers/route_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/theme_provider.dart';
import 'package:marine_nav_app/providers/tide_provider.dart';
import 'package:marine_nav_app/providers/timeline_provider.dart';
import 'package:marine_nav_app/providers/vessel_provider.dart';
import 'package:marine_nav_app/providers/weather_provider.dart';
import 'package:marine_nav_app/services/location_service.dart';
import 'package:marine_nav_app/services/mob_service.dart';
import 'package:marine_nav_app/services/trip_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub location service for tests.
class StubLocationService extends LocationService {
  @override
  Future<void> start() async {}
}

void main() {
  testWidgets('HomeScreen renders main UI', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final settingsProvider = SettingsProvider();
    final themeProvider = ThemeProvider();
    final cacheProvider = CacheProvider();
    final mapProvider = MapProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    final nmeaProvider = NMEAProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    final routeProvider = RouteProvider();
    final weatherProvider = WeatherProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    final boatProvider = BoatProvider(
      nmeaProvider: nmeaProvider,
      mapProvider: mapProvider,
      locationService: StubLocationService(),
    );
    final timelineProvider = TimelineProvider(
      weatherProvider: weatherProvider,
    );
    final aisProvider = AisProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    final tideProvider = TideProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );
    final tripLogService = TripLogService();
    final mobService = MobService();
    final vesselProvider = VesselProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
    );

    await settingsProvider.init();
    await themeProvider.init();
    await cacheProvider.init();
    await mapProvider.init();
    await aisProvider.init();
    await tideProvider.init();
    await tripLogService.init();
    await mobService.init();
    await vesselProvider.init();

    await tester.pumpWidget(
      MarineNavigationApp(
        settingsProvider: settingsProvider,
        themeProvider: themeProvider,
        cacheProvider: cacheProvider,
        mapProvider: mapProvider,
        nmeaProvider: nmeaProvider,
        routeProvider: routeProvider,
        weatherProvider: weatherProvider,
        boatProvider: boatProvider,
        timelineProvider: timelineProvider,
        aisProvider: aisProvider,
        tideProvider: tideProvider,
        tripLogService: tripLogService,
        mobService: mobService,
        vesselProvider: vesselProvider,
        qualityProvider: QualityProvider(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SailStream'), findsOneWidget);
    expect(find.text('Map Preview'), findsWidgets);
  });
}
