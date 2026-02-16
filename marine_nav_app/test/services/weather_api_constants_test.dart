import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/services/weather_api.dart';

void main() {
  group('WeatherApiService constants', () {
    test('forecastDays is 2', () {
      expect(WeatherApiService.forecastDays, 2);
    });

    test('defaultGridSize is 5', () {
      expect(WeatherApiService.defaultGridSize, 5);
    });

    test('maxGridSize is 8', () {
      expect(WeatherApiService.maxGridSize, 8);
    });
  });
}
