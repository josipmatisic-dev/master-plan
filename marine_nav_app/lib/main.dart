/// Marine Navigation App - Main Entry Point
///
/// SailStream UI with Ocean Glass Design System
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/boat_provider.dart';
import 'providers/cache_provider.dart';
import 'providers/map_provider.dart';
import 'providers/nmea_provider.dart';
import 'providers/route_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/navigation_mode_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize providers
  final settingsProvider = SettingsProvider();
  final themeProvider = ThemeProvider();
  final cacheProvider = CacheProvider();

  // Layer 2 providers
  final mapProvider = MapProvider(
    settingsProvider: settingsProvider,
    cacheProvider: cacheProvider,
  );
  final nmeaProvider = NMEAProvider(
    settingsProvider: settingsProvider,
    cacheProvider: cacheProvider,
  );
  final routeProvider = RouteProvider();
  final boatProvider = BoatProvider(nmeaProvider: nmeaProvider);

  // Initialize all providers that require async init
  await Future.wait([
    settingsProvider.init(),
    themeProvider.init(),
    cacheProvider.init(),
    mapProvider.init(),
  ]);

  runApp(
    MarineNavigationApp(
      settingsProvider: settingsProvider,
      themeProvider: themeProvider,
      cacheProvider: cacheProvider,
      mapProvider: mapProvider,
      nmeaProvider: nmeaProvider,
      routeProvider: routeProvider,
      boatProvider: boatProvider,
    ),
  );
}

/// Marine Navigation App Root Widget
///
/// Implements provider hierarchy following CON-004:
/// Layer 2: (Future) MapProvider, WeatherProvider
/// Layer 1: ThemeProvider, CacheProvider
/// Layer 0: SettingsProvider
class MarineNavigationApp extends StatelessWidget {
  /// The root configuration provider (Layer 0).
  final SettingsProvider settingsProvider;

  /// The theme provider (Layer 1).
  final ThemeProvider themeProvider;

  /// The cache provider (Layer 1).
  final CacheProvider cacheProvider;

  /// The map provider (Layer 2).
  final MapProvider mapProvider;

  /// The NMEA data provider (Layer 2).
  final NMEAProvider nmeaProvider;

  /// The route provider (Layer 2).
  final RouteProvider routeProvider;

  /// The boat position provider (Layer 2).
  final BoatProvider boatProvider;

  /// Creates a MarineNavigationApp with pre-initialized providers.
  const MarineNavigationApp({
    super.key,
    required this.settingsProvider,
    required this.themeProvider,
    required this.cacheProvider,
    required this.mapProvider,
    required this.nmeaProvider,
    required this.routeProvider,
    required this.boatProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Provider hierarchy - acyclic, max 3 layers
    return MultiProvider(
      providers: [
        // Layer 0: No dependencies
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settingsProvider,
        ),

        // Layer 1: Can depend on Layer 0
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
        ),
        ChangeNotifierProvider<CacheProvider>.value(
          value: cacheProvider,
        ),

        // Layer 2: MapProvider (WeatherProvider future)
        ChangeNotifierProvider<MapProvider>.value(
          value: mapProvider,
        ),
        ChangeNotifierProvider<NMEAProvider>.value(
          value: nmeaProvider,
        ),
        ChangeNotifierProvider<RouteProvider>.value(
          value: routeProvider,
        ),
        ChangeNotifierProvider<BoatProvider>.value(
          value: boatProvider,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final systemBrightness = MediaQuery.platformBrightnessOf(context);

          return MaterialApp(
            title: 'SailStream',
            debugShowCheckedModeBanner: false,

            // Theme configuration
            theme: themeProvider.getTheme(systemBrightness),
            themeMode: _getThemeMode(themeProvider.themeMode),

            // Home screen
            home: const HomeScreen(),

            // Named routes for primary surfaces
            routes: {
              '/map': (_) => const MapScreen(),
              '/navigation': (_) => const NavigationModeScreen(),
            },
          );
        },
      ),
    );
  }

  /// Convert AppThemeMode to ThemeMode
  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.redLight:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
