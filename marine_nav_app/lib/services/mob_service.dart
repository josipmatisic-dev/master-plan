/// Man Overboard (MOB) model and service.
///
/// Captures the current boat position as an emergency waypoint
/// and persists it. Supports multiple MOB markers with timestamps.
library;

import 'package:flutter/foundation.dart';

import '../models/boat_position.dart';
import '../models/lat_lng.dart';
import '../services/cache_service.dart';

/// State of a MOB marker.
enum MobState {
  /// Active — crew member in water.
  active,

  /// Recovered — crew member retrieved.
  recovered,

  /// Cancelled — false alarm.
  cancelled,
}

/// A single Man Overboard marker.
@immutable
class MobMarker {
  /// Unique ID.
  final String id;

  /// Position where MOB was triggered.
  final LatLng position;

  /// When MOB was triggered.
  final DateTime timestamp;

  /// Current state.
  final MobState state;

  /// Speed at time of MOB (for drift estimation).
  final double? speedKnots;

  /// Course at time of MOB.
  final double? courseTrue;

  /// Creates a MOB marker.
  const MobMarker({
    required this.id,
    required this.position,
    required this.timestamp,
    this.state = MobState.active,
    this.speedKnots,
    this.courseTrue,
  });

  /// Creates from a BoatPosition.
  factory MobMarker.fromPosition(BoatPosition pos) {
    return MobMarker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      position: pos.position,
      timestamp: pos.timestamp,
      speedKnots: pos.speedKnots,
      courseTrue: pos.courseTrue,
    );
  }

  /// Creates a copy with updated state.
  MobMarker copyWith({MobState? state}) {
    return MobMarker(
      id: id,
      position: position,
      timestamp: timestamp,
      state: state ?? this.state,
      speedKnots: speedKnots,
      courseTrue: courseTrue,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'state': state.name,
        if (speedKnots != null) 'speedKnots': speedKnots,
        if (courseTrue != null) 'courseTrue': courseTrue,
      };

  /// Deserializes from JSON.
  factory MobMarker.fromJson(Map<String, dynamic> json) {
    return MobMarker(
      id: json['id'] as String,
      position: LatLng(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      state: MobState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => MobState.active,
      ),
      speedKnots: (json['speedKnots'] as num?)?.toDouble(),
      courseTrue: (json['courseTrue'] as num?)?.toDouble(),
    );
  }
}

/// Service for managing Man Overboard markers.
///
/// Captures current position, persists markers, and provides
/// bearing/distance to active MOB from current position.
class MobService extends ChangeNotifier {
  final CacheService? _cache;
  final List<MobMarker> _markers = [];

  static const String _cacheKey = 'mob_markers';

  /// Creates a MOB service with optional cache backend.
  MobService({CacheService? cacheService}) : _cache = cacheService;

  /// All MOB markers (active and resolved).
  List<MobMarker> get markers => List.unmodifiable(_markers);

  /// Active MOB markers only.
  List<MobMarker> get activeMarkers =>
      _markers.where((m) => m.state == MobState.active).toList();

  /// Whether there is an active MOB.
  bool get hasActiveMob => _markers.any((m) => m.state == MobState.active);

  /// The most recent active MOB marker.
  MobMarker? get latestActiveMob {
    final active = activeMarkers;
    return active.isNotEmpty ? active.last : null;
  }

  /// Initialize — load persisted markers from cache.
  Future<void> init() async {
    if (_cache == null || !_cache.isInitialized) return;
    final json = _cache.getJson(_cacheKey);
    if (json == null) return;

    try {
      final list = json['markers'] as List;
      _markers.addAll(
        list.map((m) => MobMarker.fromJson(m as Map<String, dynamic>)),
      );
      debugPrint('MobService: Loaded ${_markers.length} MOB markers');
    } catch (e) {
      debugPrint('MobService: Failed to load markers — $e');
    }
  }

  /// Trigger MOB — capture current position.
  MobMarker markMob(BoatPosition position) {
    final marker = MobMarker.fromPosition(position);
    _markers.add(marker);
    _persist();
    notifyListeners();
    debugPrint(
      'MOB TRIGGERED at ${marker.position.latitude}, '
      '${marker.position.longitude}',
    );
    return marker;
  }

  /// Mark a MOB as recovered.
  void recover(String id) {
    _updateState(id, MobState.recovered);
  }

  /// Cancel a MOB (false alarm).
  void cancel(String id) {
    _updateState(id, MobState.cancelled);
  }

  /// Clear all resolved (non-active) markers.
  void clearResolved() {
    _markers.removeWhere((m) => m.state != MobState.active);
    _persist();
    notifyListeners();
  }

  void _updateState(String id, MobState newState) {
    final idx = _markers.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _markers[idx] = _markers[idx].copyWith(state: newState);
    _persist();
    notifyListeners();
  }

  void _persist() {
    if (_cache == null || !_cache.isInitialized) return;
    _cache.putJson(_cacheKey, {
      'markers': _markers.map((m) => m.toJson()).toList(),
    });
  }
}
