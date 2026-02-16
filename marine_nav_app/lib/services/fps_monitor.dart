/// FPS monitor using SchedulerBinding frame timings.
///
/// Tracks rolling average frame duration and detects sustained drops
/// below target thresholds for adaptive quality control.
library;

import 'dart:collection';

import 'package:flutter/scheduler.dart';

/// Monitors frame rendering performance via [SchedulerBinding].
class FpsMonitor {
  /// Number of frames to average over.
  static const _windowSize = 60;

  /// Callback invoked when average FPS changes significantly.
  final void Function(double avgFps) onFpsUpdate;

  final Queue<double> _frameDurations = Queue<double>();
  double _avgFps = 60.0;
  bool _active = false;

  /// Creates an FPS monitor with the given callback.
  FpsMonitor({required this.onFpsUpdate});

  /// Current rolling average FPS.
  double get avgFps => _avgFps;

  /// Whether monitoring is active.
  bool get isActive => _active;

  /// Starts monitoring frame timings.
  void start() {
    if (_active) return;
    _active = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  /// Stops monitoring and clears history.
  void stop() {
    if (!_active) return;
    _active = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _frameDurations.clear();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final totalMs = timing.totalSpan.inMicroseconds / 1000.0;
      _frameDurations.addLast(totalMs);
      if (_frameDurations.length > _windowSize) {
        _frameDurations.removeFirst();
      }
    }

    if (_frameDurations.length >= 10) {
      double sum = 0;
      for (final d in _frameDurations) {
        sum += d;
      }
      final avgMs = sum / _frameDurations.length;
      final newFps = (1000.0 / avgMs).clamp(0.0, 120.0);

      // Only notify on meaningful change (>2 FPS difference)
      if ((newFps - _avgFps).abs() > 2.0) {
        _avgFps = newFps;
        onFpsUpdate(newFps);
      }
    }
  }

  /// Releases resources.
  void dispose() {
    stop();
  }
}
