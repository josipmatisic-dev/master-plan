import 'package:flutter_test/flutter_test.dart';
import 'package:marine_nav_app/providers/quality_provider.dart';

void main() {
  group('QualityProvider', () {
    late QualityProvider provider;

    setUp(() {
      provider = QualityProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initializes with high quality', () {
      expect(provider.level, QualityLevel.high);
      expect(provider.autoQuality, isTrue);
      expect(provider.currentFps, 60.0);
    });

    test('showFog only at high quality', () {
      expect(provider.showFog, isTrue);
      provider.setQualityLevel(QualityLevel.medium);
      expect(provider.showFog, isFalse);
      provider.setQualityLevel(QualityLevel.low);
      expect(provider.showFog, isFalse);
    });

    test('showRain at high and medium, not low', () {
      expect(provider.showRain, isTrue);
      provider.setQualityLevel(QualityLevel.medium);
      expect(provider.showRain, isTrue);
      provider.setQualityLevel(QualityLevel.low);
      expect(provider.showRain, isFalse);
    });

    test('showLightning at high and medium, not low', () {
      expect(provider.showLightning, isTrue);
      provider.setQualityLevel(QualityLevel.medium);
      expect(provider.showLightning, isTrue);
      provider.setQualityLevel(QualityLevel.low);
      expect(provider.showLightning, isFalse);
    });

    test('showWind and showOceanSurface always true', () {
      for (final level in QualityLevel.values) {
        provider.setQualityLevel(level);
        expect(provider.showWind, isTrue);
        expect(provider.showOceanSurface, isTrue);
      }
    });

    test('maxParticles scales with quality level', () {
      provider.setQualityLevel(QualityLevel.high);
      expect(provider.maxParticles, 800);
      provider.setQualityLevel(QualityLevel.medium);
      expect(provider.maxParticles, 400);
      provider.setQualityLevel(QualityLevel.low);
      expect(provider.maxParticles, 200);
    });

    test('setQualityLevel disables autoQuality', () {
      expect(provider.autoQuality, isTrue);
      provider.setQualityLevel(QualityLevel.medium);
      expect(provider.autoQuality, isFalse);
      expect(provider.level, QualityLevel.medium);
    });

    test('setAutoQuality resets to high', () {
      provider.setQualityLevel(QualityLevel.low);
      expect(provider.level, QualityLevel.low);
      provider.setAutoQuality(enabled: true);
      expect(provider.autoQuality, isTrue);
    });

    test('setAutoQuality disabled resets to high', () {
      provider.setQualityLevel(QualityLevel.low);
      provider.setAutoQuality(enabled: false);
      expect(provider.level, QualityLevel.high);
    });

    test('notifies listeners on quality change', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.setQualityLevel(QualityLevel.low);
      expect(notifyCount, 1);
    });

    test('does not notify when setting same level', () {
      provider.setQualityLevel(QualityLevel.high);
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.setQualityLevel(QualityLevel.high);
      expect(notifyCount, 0);
    });
  });
}
