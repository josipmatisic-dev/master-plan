/// Timeline Provider - Layer 2
///
/// Manages weather forecast timeline state: frame selection,
/// playback, and scrubber position. Depends on [WeatherProvider]
/// for frame data (ISS-013: max 5 frames in memory).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/weather_data.dart';
import 'weather_provider.dart';

/// Playback state for the timeline.
enum PlaybackState {
  /// Timeline is paused at a specific frame.
  paused,

  /// Timeline is playing forward through frames.
  playing,
}

/// Timeline Provider - manages forecast frame navigation.
///
/// Provides scrubber position, playback controls, and active
/// frame selection for weather forecast display.
///
/// Usage:
/// ```dart
/// final timeline = context.watch<TimelineProvider>();
/// final frame = timeline.activeFrame;
/// ```
class TimelineProvider extends ChangeNotifier {
  final WeatherProvider _weather;

  int _frameIndex = 0;
  PlaybackState _playbackState = PlaybackState.paused;
  Timer? _playbackTimer;

  /// Playback speed: interval between frame advances.
  static const Duration playbackInterval = Duration(seconds: 2);

  /// Maximum frames to keep accessible (ISS-013).
  static const int maxFramesInMemory = 5;

  /// Creates a TimelineProvider linked to [WeatherProvider].
  TimelineProvider({required WeatherProvider weatherProvider})
      : _weather = weatherProvider {
    _weather.addListener(_onWeatherChanged);
  }

  // ============ Public Getters ============

  /// Current frame index (0-based).
  int get frameIndex => _frameIndex;

  /// Total number of available frames.
  int get frameCount => _allFrames.length;

  /// Whether frames are available.
  bool get hasFrames => _allFrames.isNotEmpty;

  /// Current playback state.
  PlaybackState get playbackState => _playbackState;

  /// Whether timeline is currently playing.
  bool get isPlaying => _playbackState == PlaybackState.playing;

  /// Active frame at the current index (null if no frames).
  WeatherFrame? get activeFrame {
    final frames = _allFrames;
    if (frames.isEmpty || _frameIndex >= frames.length) return null;
    return frames[_frameIndex];
  }

  /// Scrubber position as a normalized value (0.0–1.0).
  double get scrubberPosition {
    final count = _allFrames.length;
    if (count <= 1) return 0.0;
    return _frameIndex / (count - 1);
  }

  /// Time label for the active frame.
  String get activeTimeLabel {
    final frame = activeFrame;
    if (frame == null) return '--:--';
    final h = frame.time.hour.toString().padLeft(2, '0');
    final m = frame.time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Wind/wave data lists for the active frame (for overlay rendering).
  List<WindDataPoint> get activeWindPoints {
    final frame = activeFrame;
    return frame?.windPoints ?? [];
  }

  /// Wave data for the active frame.
  List<WaveDataPoint> get activeWavePoints {
    final frame = activeFrame;
    return frame?.wavePoints ?? [];
  }

  /// All available frames (no sliding window for now).
  List<WeatherFrame> get _allFrames => _weather.data.frames;

  // ============ Frame Navigation ============

  /// Jump to a specific frame index.
  void setFrameIndex(int index) {
    final count = _allFrames.length;
    if (count == 0) return;
    final clamped = index.clamp(0, count - 1);
    if (clamped == _frameIndex) return;
    _frameIndex = clamped;
    notifyListeners();
  }

  /// Set scrubber position (0.0–1.0) and jump to nearest frame.
  void setScrubberPosition(double position) {
    final count = _allFrames.length;
    if (count == 0) return;
    final index = (position.clamp(0.0, 1.0) * (count - 1)).round();
    setFrameIndex(index);
  }

  /// Advance to the next frame. Wraps to start if at end.
  void nextFrame() {
    final count = _allFrames.length;
    if (count == 0) return;
    setFrameIndex((_frameIndex + 1) % count);
  }

  /// Go to the previous frame. Wraps to end if at start.
  void previousFrame() {
    final count = _allFrames.length;
    if (count == 0) return;
    setFrameIndex((_frameIndex - 1 + count) % count);
  }

  // ============ Playback Controls ============

  /// Start playing through frames automatically.
  void play() {
    if (_allFrames.length < 2) return;
    _playbackState = PlaybackState.playing;
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(playbackInterval, (_) {
      nextFrame();
    });
    notifyListeners();
  }

  /// Pause playback at the current frame.
  void pause() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackState = PlaybackState.paused;
    notifyListeners();
  }

  /// Toggle play/pause.
  void togglePlayback() {
    if (isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Reset to the first frame and pause.
  void reset() {
    pause();
    _frameIndex = 0;
    notifyListeners();
  }

  // ============ Internal ============

  void _onWeatherChanged() {
    final count = _weather.data.frames.length;
    if (count == 0) {
      _frameIndex = 0;
      pause();
    } else if (_frameIndex >= count) {
      _frameIndex = count - 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _weather.removeListener(_onWeatherChanged);
    super.dispose();
  }
}
