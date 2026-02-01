/// Settings Provider Tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';

void main() {
  group('SettingsProvider', () {
    late SettingsProvider provider;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = SettingsProvider();
      await provider.init();
    });
    
    test('initializes with default values', () {
      expect(provider.speedUnit, SpeedUnit.knots);
      expect(provider.distanceUnit, DistanceUnit.nauticalMiles);
      expect(provider.language, 'en');
      expect(provider.mapRefreshRate, 5000);
    });
    
    test('updates speed unit', () async {
      await provider.setSpeedUnit(SpeedUnit.kph);
      expect(provider.speedUnit, SpeedUnit.kph);
    });
    
    test('resets to defaults', () async {
      await provider.setSpeedUnit(SpeedUnit.mph);
      await provider.setLanguage('fr');
      await provider.resetToDefaults();
      
      expect(provider.speedUnit, SpeedUnit.knots);
      expect(provider.language, 'en');
    });
  });
}
