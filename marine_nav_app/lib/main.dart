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
import 'providers/timeline_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/navigation_mode_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/vessel_screen.dart';
import 'screens/weather_screen.dart';

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
  );
  final timelineProvider = TimelineProvider(
    weatherProvider: weatherProvider,
  );

  // Initialize all providers
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
      weatherProvider: weatherProvider,
      boatProvider: boatProvider,
      timelineProvider: timelineProvider,
    ),
  );
}

/// Marine Navigation App Root Widget
///
/// Implements provider hierarchy following CON-004:
/// Layer 2: MapProvider, NMEAProvider, RouteProvider, WeatherProvider
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

  /// The weather provider (Layer 2).
  final WeatherProvider weatherProvider;

  /// The boat position provider (Layer 2).
  final BoatProvider boatProvider;

  /// The timeline provider (Layer 2).
  final TimelineProvider timelineProvider;

  /// Creates a MarineNavigationApp with pre-initialized providers.
  const MarineNavigationApp({
    super.key,
    required this.settingsProvider,
    required this.themeProvider,
    required this.cacheProvider,
    required this.mapProvider,
    required this.nmeaProvider,
    required this.routeProvider,
    required this.weatherProvider,
    required this.boatProvider,
    required this.timelineProvider,
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

        // Layer 2: Domain providers (depend on Layers 0+1)
        ChangeNotifierProvider<MapProvider>.value(
          value: mapProvider,
        ),
        ChangeNotifierProvider<NMEAProvider>.value(
          value: nmeaProvider,
        ),
        ChangeNotifierProvider<RouteProvider>.value(
          value: routeProvider,
        ),
        ChangeNotifierProvider<WeatherProvider>.value(
          value: weatherProvider,
        ),
        ChangeNotifierProvider<BoatProvider>.value(
          value: boatProvider,
        ),
        ChangeNotifierProvider<TimelineProvider>.value(
          value: timelineProvider,
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

            // Animated cross-fade when switching themes
            themeAnimationDuration: const Duration(milliseconds: 400),
            themeAnimationCurve: Curves.easeInOut,

            // Home screen
            home: const HomeScreen(),

            // Named routes for primary surfaces
            routes: {
              '/dashboard': (_) => const DashboardScreen(),
              '/map': (_) => const MapScreen(),
              '/navigation': (_) => const NavigationModeScreen(),
              '/weather': (_) => const WeatherScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/profile': (_) => const ProfileScreen(),
              '/vessel': (_) => const VesselScreen(),
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
