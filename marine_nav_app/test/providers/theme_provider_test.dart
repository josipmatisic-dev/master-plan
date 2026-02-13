import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marine_nav_app/providers/theme_provider.dart';
import 'package:marine_nav_app/theme/theme_variant.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider', () {
    test('defaults to oceanGlass variant', () async {
      final provider = ThemeProvider();
      await provider.init();
      expect(provider.themeVariant, ThemeVariant.oceanGlass);
      expect(provider.isHolographic, false);
      expect(provider.isOceanGlass, true);
    });

    test('toggleThemeVariant switches to holographic', () async {
      final provider = ThemeProvider();
      await provider.init();
      await provider.toggleThemeVariant();
      expect(provider.themeVariant, ThemeVariant.holographicCyberpunk);
      expect(provider.isHolographic, true);
    });

    test('toggleThemeVariant switches back to ocean', () async {
      final provider = ThemeProvider();
      await provider.init();
      await provider.toggleThemeVariant();
      await provider.toggleThemeVariant();
      expect(provider.themeVariant, ThemeVariant.oceanGlass);
    });

    test('setThemeVariant persists choice', () async {
      final provider = ThemeProvider();
      await provider.init();
      await provider.setThemeVariant(ThemeVariant.holographicCyberpunk);

      // Create new provider and verify persistence
      final provider2 = ThemeProvider();
      await provider2.init();
      expect(provider2.themeVariant, ThemeVariant.holographicCyberpunk);
    });

    test('notifies listeners on variant change', () async {
      final provider = ThemeProvider();
      await provider.init();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.toggleThemeVariant();
      expect(notified, true);
    });

    test('defaults to dark theme mode', () async {
      final provider = ThemeProvider();
      await provider.init();
      expect(provider.themeMode, AppThemeMode.dark);
    });

    test('setThemeMode persists and notifies', () async {
      final provider = ThemeProvider();
      await provider.init();
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.setThemeMode(AppThemeMode.light);
      expect(provider.themeMode, AppThemeMode.light);
      expect(notified, true);
    });

    test('toggleTheme switches between dark and light', () async {
      final provider = ThemeProvider();
      await provider.init();
      await provider.toggleTheme();
      expect(provider.themeMode, AppThemeMode.light);
      await provider.toggleTheme();
      expect(provider.themeMode, AppThemeMode.dark);
    });

    test('red light mode', () async {
      final provider = ThemeProvider();
      await provider.init();
      await provider.enableRedLightMode();
      expect(provider.isRedLightMode, true);
      await provider.disableRedLightMode();
      expect(provider.isRedLightMode, false);
      expect(provider.themeMode, AppThemeMode.dark);
    });
  });
}
