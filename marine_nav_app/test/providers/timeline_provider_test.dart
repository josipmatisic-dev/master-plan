/// Timeline Provider Tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marine_nav_app/models/weather_data.dart';
import 'package:marine_nav_app/providers/cache_provider.dart';
import 'package:marine_nav_app/providers/settings_provider.dart';
import 'package:marine_nav_app/providers/timeline_provider.dart';
import 'package:marine_nav_app/providers/weather_provider.dart';
import 'package:marine_nav_app/services/weather_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../_fixtures/weather_fixtures.dart';

void main() {
  late SettingsProvider settingsProvider;
  late CacheProvider cacheProvider;
  late WeatherProvider weatherProvider;
  late TimelineProvider timelineProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settingsProvider = SettingsProvider();
    await settingsProvider.init();
    cacheProvider = CacheProvider();
    await cacheProvider.init();
  });

  tearDown(() {
    timelineProvider.dispose();
    weatherProvider.dispose();
    cacheProvider.dispose();
  });

  TimelineProvider createTimeline({http.Client? client}) {
    final api = WeatherApiService(
      client: client ??
          MockClient((_) async {
            return http.Response(sampleWeatherResponse, 200);
          }),
    );
    weatherProvider = WeatherProvider(
      settingsProvider: settingsProvider,
      cacheProvider: cacheProvider,
      api: api,
    );
    timelineProvider = TimelineProvider(weatherProvider: weatherProvider);
    return timelineProvider;
  }

  Future<void> loadWeatherData() async {
    await weatherProvider.refresh(
      south: 58.0,
      north: 62.0,
      west: 8.0,
      east: 12.0,
    );
  }

  group('TimelineProvider', () {
    // ============ Initialization ============

    test('initializes with no frames', () {
      createTimeline();
      expect(timelineProvider.hasFrames, false);
      expect(timelineProvider.frameIndex, 0);
      expect(timelineProvider.activeFrame, isNull);
      expect(timelineProvider.isPlaying, false);
    });

    test('activeTimeLabel is --:-- when no frames', () {
      createTimeline();
      expect(timelineProvider.activeTimeLabel, '--:--');
    });

    // ============ Frame Navigation ============

    test('has frames after weather data loads', () async {
      createTimeline();
      await loadWeatherData();
      expect(timelineProvider.hasFrames, true);
      expect(timelineProvider.frameCount, greaterThan(0));
    });

    test('activeFrame returns data after load', () async {
      createTimeline();
      await loadWeatherData();
      expect(timelineProvider.activeFrame, isNotNull);
      expect(timelineProvider.activeFrame, isA<WeatherFrame>());
    });

    test('setFrameIndex changes active frame', () async {
      createTimeline();
      await loadWeatherData();
      final count = timelineProvider.frameCount;
      if (count >= 2) {
        timelineProvider.setFrameIndex(1);
        expect(timelineProvider.frameIndex, 1);
      }
    });

    test('setFrameIndex clamps to valid range', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.setFrameIndex(999);
      expect(
        timelineProvider.frameIndex,
        lessThanOrEqualTo(timelineProvider.frameCount - 1),
      );
      timelineProvider.setFrameIndex(-5);
      expect(timelineProvider.frameIndex, 0);
    });

    test('nextFrame advances and wraps', () async {
      createTimeline();
      await loadWeatherData();
      final count = timelineProvider.frameCount;
      for (var i = 0; i < count; i++) {
        timelineProvider.nextFrame();
      }
      // After wrapping, should be back at 0
      expect(timelineProvider.frameIndex, 0);
    });

    test('previousFrame goes back and wraps', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.previousFrame();
      // Should wrap to last frame
      expect(
        timelineProvider.frameIndex,
        timelineProvider.frameCount - 1,
      );
    });

    // ============ Scrubber ============

    test('scrubberPosition is 0 at start', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.setFrameIndex(0);
      expect(timelineProvider.scrubberPosition, 0.0);
    });

    test('setScrubberPosition navigates to frame', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.setScrubberPosition(1.0);
      expect(
        timelineProvider.frameIndex,
        timelineProvider.frameCount - 1,
      );
    });

    // ============ Playback ============

    test('play starts playback', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.play();
      expect(timelineProvider.isPlaying, true);
      timelineProvider.pause();
    });

    test('pause stops playback', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.play();
      timelineProvider.pause();
      expect(timelineProvider.isPlaying, false);
    });

    test('togglePlayback toggles state', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.togglePlayback();
      expect(timelineProvider.isPlaying, true);
      timelineProvider.togglePlayback();
      expect(timelineProvider.isPlaying, false);
    });

    test('reset pauses and goes to frame 0', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.setFrameIndex(1);
      timelineProvider.play();
      timelineProvider.reset();
      expect(timelineProvider.frameIndex, 0);
      expect(timelineProvider.isPlaying, false);
    });

    // ============ Active Data ============

    test('activeWindPoints returns list for active frame', () async {
      createTimeline();
      await loadWeatherData();
      final wind = timelineProvider.activeWindPoints;
      // May be empty or have 1 point depending on frame data
      expect(wind, isA<List<WindDataPoint>>());
    });

    test('activeWavePoints returns list for active frame', () async {
      createTimeline();
      await loadWeatherData();
      final wave = timelineProvider.activeWavePoints;
      expect(wave, isA<List<WaveDataPoint>>());
    });

    test('activeTimeLabel returns HH:MM format', () async {
      createTimeline();
      await loadWeatherData();
      final label = timelineProvider.activeTimeLabel;
      expect(label, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    // ============ Listener ============

    test('notifies listeners on frame change', () async {
      createTimeline();
      await loadWeatherData();
      int count = 0;
      timelineProvider.addListener(() => count++);
      timelineProvider.nextFrame();
      expect(count, 1);
    });

    // ============ Dispose ============

    test('dispose cancels playback timer', () async {
      createTimeline();
      await loadWeatherData();
      timelineProvider.play();
      // Should not throw
      timelineProvider.dispose();
      // Recreate so tearDown doesn't double-dispose
      timelineProvider = TimelineProvider(weatherProvider: weatherProvider);
    });
  });
}
