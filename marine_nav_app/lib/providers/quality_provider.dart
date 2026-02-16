/// Adaptive quality provider — auto-adjusts rendering quality
/// based on real-time FPS monitoring.
///
/// Disables expensive visual layers when frame rate drops below
/// thresholds to maintain smooth 60fps experience.
library;

import 'package:flutter/foundation.dart';

import '../services/fps_monitor.dart';

/// Rendering quality tiers.
enum QualityLevel {
  /// All effects enabled, full particle count.
  high,

  /// Reduce particle density, disable fog.
  medium,

  /// Minimal effects — wind + ocean only, no atmosphere.
  low,
}

/// Manages adaptive rendering quality based on FPS performance.
///
/// Watches frame rate via [FpsMonitor] and automatically downgrades
/// quality when sustained drops are detected. Upgrades back when
/// performance recovers.
class QualityProvider extends ChangeNotifier {
  late final FpsMonitor _fpsMonitor;

  QualityLevel _level = QualityLevel.high;
  double _currentFps = 60.0;
  bool _autoQuality = true;
  int _downgradeCount = 0;
  int _upgradeCount = 0;

  /// Frames of sustained low/high FPS before changing quality.
  static const _downgradeThreshold = 3;
  static const _upgradeThreshold = 5;

  /// FPS boundaries.
  static const _fpsLow = 40.0;
  static const _fpsMedium = 50.0;
  static const _fpsHigh = 55.0;

  /// Creates a quality provider.
  QualityProvider() {
    _fpsMonitor = FpsMonitor(onFpsUpdate: _onFpsUpdate);
  }

  /// Current quality level.
  QualityLevel get level => _level;

  /// Current measured FPS.
  double get currentFps => _currentFps;

  /// Whether auto-quality adjustment is enabled.
  bool get autoQuality => _autoQuality;

  // Layer visibility based on quality level

  /// Whether fog overlay should render.
  bool get showFog => _level == QualityLevel.high;

  /// Whether rain/precipitation overlay should render.
  bool get showRain => _level != QualityLevel.low;

  /// Whether lightning overlay should render.
  bool get showLightning => _level != QualityLevel.low;

  /// Whether ocean surface caustics should render.
  bool get showOceanSurface => true; // Always on — lightweight shader

  /// Whether wind particles should render.
  bool get showWind => true; // Always on — core feature

  /// Max wind particle count based on quality.
  int get maxParticles {
    return switch (_level) {
      QualityLevel.high => 800,
      QualityLevel.medium => 400,
      QualityLevel.low => 200,
    };
  }

  /// Starts FPS monitoring.
  Future<void> init() async {
    _fpsMonitor.start();
  }

  /// Toggles auto-quality adjustment.
  void setAutoQuality({required bool enabled}) {
    _autoQuality = enabled;
    if (!enabled) {
      _level = QualityLevel.high;
      _downgradeCount = 0;
      _upgradeCount = 0;
      notifyListeners();
    }
  }

  /// Manually sets quality level (disables auto).
  void setQualityLevel(QualityLevel level) {
    _autoQuality = false;
    if (_level != level) {
      _level = level;
      notifyListeners();
    }
  }

  void _onFpsUpdate(double fps) {
    _currentFps = fps;
    if (!_autoQuality) return;

    if (fps < _fpsLow) {
      _upgradeCount = 0;
      _downgradeCount++;
      if (_downgradeCount >= _downgradeThreshold) {
        _downgrade();
        _downgradeCount = 0;
      }
    } else if (fps > _fpsHigh) {
      _downgradeCount = 0;
      _upgradeCount++;
      if (_upgradeCount >= _upgradeThreshold) {
        _upgrade();
        _upgradeCount = 0;
      }
    } else if (fps < _fpsMedium && _level == QualityLevel.high) {
      _downgradeCount++;
      if (_downgradeCount >= _downgradeThreshold) {
        _downgrade();
        _downgradeCount = 0;
      }
    } else {
      // In acceptable range — reset counters
      _downgradeCount = 0;
      _upgradeCount = 0;
    }
  }

  void _downgrade() {
    final newLevel = switch (_level) {
      QualityLevel.high => QualityLevel.medium,
      QualityLevel.medium => QualityLevel.low,
      QualityLevel.low => QualityLevel.low,
    };
    if (newLevel != _level) {
      _level = newLevel;
      debugPrint('QualityProvider: downgrade → $_level (FPS: $_currentFps)');
      notifyListeners();
    }
  }

  void _upgrade() {
    final newLevel = switch (_level) {
      QualityLevel.low => QualityLevel.medium,
      QualityLevel.medium => QualityLevel.high,
      QualityLevel.high => QualityLevel.high,
    };
    if (newLevel != _level) {
      _level = newLevel;
      debugPrint('QualityProvider: upgrade → $_level (FPS: $_currentFps)');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _fpsMonitor.dispose();
    super.dispose();
  }
}
