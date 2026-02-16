/// AIS Provider — Layer 2 provider managing AIS vessel targets.
///
/// Consumes AisService stream, maintains target map, computes
/// CPA/TCPA warnings, and provides filtered views for UI.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ais_target.dart';
import '../models/lat_lng.dart';
import '../providers/settings_provider.dart';
import '../services/ais_collision.dart';
import '../services/ais_service.dart';

/// AIS Provider - manages vessel targets and collision warnings.
class AisProvider extends ChangeNotifier {
  final SettingsProvider _settings;
  final AisService _service = AisService();

  StreamSubscription<AisTarget>? _targetSub;
  StreamSubscription<AisConnectionState>? _stateSub;
  StreamSubscription<String>? _errorSub;
  Timer? _cleanupTimer;
  Timer? _batchTimer;

  /// Active AIS targets keyed by MMSI.
  final Map<int, AisTarget> _targets = {};

  /// Pending target updates (batched every 500ms).
  final List<AisTarget> _pendingUpdates = [];

  /// Current collision warnings sorted by CPA.
  List<AisTarget> _warnings = [];

  /// Own vessel position for CPA calculations.
  LatLng? _ownPosition;
  double _ownSog = 0;
  double _ownCog = 0;

  /// Connection state.
  AisConnectionState _connectionState = AisConnectionState.disconnected;

  /// Last error message.
  String? _lastError;

  /// Maximum targets to display (performance guard).
  static const int maxTargets = 500;

  /// Stale target cleanup interval.
  static const Duration _cleanupInterval = Duration(minutes: 2);

  AisProvider({required SettingsProvider settingsProvider})
      : _settings = settingsProvider;

  // --- Public getters ---

  Map<int, AisTarget> get targets => Map.unmodifiable(_targets);
  List<AisTarget> get warnings => List.unmodifiable(_warnings);
  AisConnectionState get connectionState => _connectionState;
  String? get lastError => _lastError;
  int get targetCount => _targets.length;
  bool get isConnected => _connectionState == AisConnectionState.connected;

  /// Initialize the provider.
  Future<void> init() async {
    _stateSub = _service.stateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
    _errorSub = _service.errorStream.listen((error) {
      _lastError = error;
      notifyListeners();
    });
  }

  /// Connect to aisstream.io with viewport bounding box.
  Future<void> connect({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    final apiKey = _settings.aisStreamApiKey;
    if (apiKey.isEmpty) {
      _lastError = 'No AIS API key configured';
      notifyListeners();
      return;
    }

    // aisstream.io uses [[lat,lng],[lat,lng]] format
    final boundingBoxes = [
      [
        [swLat, swLng],
        [neLat, neLng],
      ]
    ];

    _targetSub?.cancel();
    _targetSub = _service.targetStream.listen(_onTarget);

    _startBatchTimer();

    // Start stale target cleanup
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _removeStaleTargets();
    });

    await _service.connect(apiKey: apiKey, boundingBoxes: boundingBoxes);
  }

  /// Update viewport bounding box for filtering.
  Future<void> updateViewport({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
  }) async {
    await _service.updateBoundingBoxes([
      [
        [swLat, swLng],
        [neLat, neLng],
      ]
    ]);
  }

  /// Update own vessel position for CPA/TCPA calculations.
  void updateOwnVessel({
    required LatLng position,
    required double sogKnots,
    required double cogDegrees,
  }) {
    _ownPosition = position;
    _ownSog = sogKnots;
    _ownCog = cogDegrees;
    _recomputeWarnings();
  }

  void _onTarget(AisTarget target) {
    _pendingUpdates.add(target);
  }

  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _processBatch(),
    );
  }

  void _processBatch() {
    if (_pendingUpdates.isEmpty) return;

    final updates = List<AisTarget>.from(_pendingUpdates);
    _pendingUpdates.clear();

    for (final update in updates) {
      final existing = _targets[update.mmsi];
      _targets[update.mmsi] =
          existing != null ? existing.merge(update) : update;
    }

    // Evict excess targets (keep newest)
    if (_targets.length > maxTargets) {
      final sorted = _targets.values.toList()
        ..sort((a, b) => b.lastUpdate.compareTo(a.lastUpdate));
      _targets.clear();
      for (final t in sorted.take(maxTargets)) {
        _targets[t.mmsi] = t;
      }
    }

    _recomputeWarnings();
    notifyListeners();
  }

  void _recomputeWarnings() {
    if (_ownPosition == null) {
      _warnings = [];
      return;
    }
    _warnings = AisCollisionCalculator.computeWarnings(
      ownPosition: _ownPosition!,
      ownSogKnots: _ownSog,
      ownCogDegrees: _ownCog,
      targets: _targets.values,
    );
  }

  void _removeStaleTargets() {
    final staleKeys = _targets.entries
        .where((e) => e.value.isStale)
        .map((e) => e.key)
        .toList();
    if (staleKeys.isEmpty) return;
    for (final key in staleKeys) {
      _targets.remove(key);
    }
    notifyListeners();
  }

  /// Disconnect from AIS stream.
  Future<void> disconnect() async {
    _batchTimer?.cancel();
    _targetSub?.cancel();
    await _service.disconnect();
    _targets.clear();
    _warnings = [];
    _pendingUpdates.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _batchTimer?.cancel();
    _cleanupTimer?.cancel();
    _targetSub?.cancel();
    _stateSub?.cancel();
    _errorSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
