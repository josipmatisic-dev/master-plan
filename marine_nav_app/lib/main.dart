/// Marine Navigation App - Main Entry Point
/// 
/// SailStream UI with Ocean Glass Design System
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/cache_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

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
  
  // Initialize all providers
  await Future.wait([
    settingsProvider.init(),
    themeProvider.init(),
    cacheProvider.init(),
  ]);
  
  runApp(
    MarineNavigationApp(
      settingsProvider: settingsProvider,
      themeProvider: themeProvider,
      cacheProvider: cacheProvider,
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
  /// Settings provider for application-wide settings
  final SettingsProvider settingsProvider;
  
  /// Theme provider for managing app theme
  final ThemeProvider themeProvider;
  
  /// Cache provider for managing cached data
  final CacheProvider cacheProvider;
  
  /// Creates a new instance of [MarineNavigationApp]
  const MarineNavigationApp({
    super.key,
    required this.settingsProvider,
    required this.themeProvider,
    required this.cacheProvider,
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
        
        // Layer 2 (Future): MapProvider, WeatherProvider
        // Will depend on Layer 0 and Layer 1
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
