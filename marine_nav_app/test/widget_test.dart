import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/main.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/map_provider.dart';
import 'package:marine_nav_app/providers/nmea_provider.dart';
import 'package:marine_nav_app/providers/route_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    await settingsProvider.init();
    await themeProvider.init();
    await cacheProvider.init();
    await mapProvider.init();

    await tester.pumpWidget(
      MarineNavigationApp(
        settingsProvider: settingsProvider,
        themeProvider: themeProvider,
        cacheProvider: cacheProvider,
        mapProvider: mapProvider,
        nmeaProvider: nmeaProvider,
        routeProvider: routeProvider,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SailStream'), findsOneWidget);
    expect(find.text('Map Preview'), findsWidgets);
  });
}
