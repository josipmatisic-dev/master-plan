/// Anchor alarm model — defines a geofence circle around the anchor point.
///
/// When the boat drifts beyond [radiusMeters] from [anchorPosition],
/// the alarm triggers.
library;

import 'lat_lng.dart';

/// The current state of the anchor alarm.
enum AnchorAlarmState {
  /// Alarm is not active.
  inactive,

  /// Anchor is set, boat is within the safe radius.
  safe,

  /// Boat is approaching the geofence boundary (>80% of radius).
  warning,

  /// Boat has drifted outside the geofence radius.
  triggered,
}

/// Immutable anchor alarm configuration and state snapshot.
class AnchorAlarm {
  /// The anchor drop position (center of geofence).
  final LatLng anchorPosition;

  /// Geofence radius in meters.
  final double radiusMeters;

  /// When the anchor was set.
  final DateTime setAt;

  /// Current distance from anchor in meters (updated per position fix).
  final double currentDistanceMeters;

  /// Current alarm state.
  final AnchorAlarmState state;

  /// Maximum drift distance recorded in meters.
  final double maxDriftMeters;

  /// Creates an anchor alarm configuration.
  const AnchorAlarm({
    required this.anchorPosition,
    required this.radiusMeters,
    required this.setAt,
    this.currentDistanceMeters = 0,
    this.state = AnchorAlarmState.safe,
    this.maxDriftMeters = 0,
  });

  /// The warning threshold — 80% of radius.
  double get warningThresholdMeters => radiusMeters * 0.8;

  /// Whether the boat is currently within the safe zone.
  bool get isSafe => state == AnchorAlarmState.safe;

  /// Whether the alarm is triggered (boat outside radius).
  bool get isTriggered => state == AnchorAlarmState.triggered;

  /// Distance remaining before alarm triggers, in meters.
  double get distanceToAlarmMeters =>
      (radiusMeters - currentDistanceMeters).clamp(0, radiusMeters);

  /// Ratio of current distance to radius (0.0 = at anchor, 1.0 = at boundary).
  double get driftRatio =>
      radiusMeters > 0 ? (currentDistanceMeters / radiusMeters).clamp(0, 2) : 0;

  /// Creates a copy with updated distance and auto-computed state.
  AnchorAlarm withDistance(double distanceMeters) {
    final newState = _computeState(distanceMeters);
    return AnchorAlarm(
      anchorPosition: anchorPosition,
      radiusMeters: radiusMeters,
      setAt: setAt,
      currentDistanceMeters: distanceMeters,
      state: newState,
      maxDriftMeters:
          distanceMeters > maxDriftMeters ? distanceMeters : maxDriftMeters,
    );
  }

  AnchorAlarmState _computeState(double distanceMeters) {
    if (distanceMeters >= radiusMeters) {
      return AnchorAlarmState.triggered;
    }
    if (distanceMeters >= warningThresholdMeters) {
      return AnchorAlarmState.warning;
    }
    return AnchorAlarmState.safe;
  }

  @override
  String toString() =>
      'AnchorAlarm(${anchorPosition.latitude.toStringAsFixed(4)}, '
      '${anchorPosition.longitude.toStringAsFixed(4)}, '
      'r=${radiusMeters.toStringAsFixed(0)}m, '
      'd=${currentDistanceMeters.toStringAsFixed(1)}m, $state)';

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'anchorLat': anchorPosition.latitude,
        'anchorLng': anchorPosition.longitude,
        'radiusMeters': radiusMeters,
        'setAt': setAt.toUtc().toIso8601String(),
        'currentDistanceMeters': currentDistanceMeters,
        'state': state.name,
        'maxDriftMeters': maxDriftMeters,
      };

  /// Deserializes from JSON map.
  factory AnchorAlarm.fromJson(Map<String, dynamic> json) {
    return AnchorAlarm(
      anchorPosition: LatLng(
        latitude: (json['anchorLat'] as num).toDouble(),
        longitude: (json['anchorLng'] as num).toDouble(),
      ),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      setAt: DateTime.parse(json['setAt'] as String),
      currentDistanceMeters:
          (json['currentDistanceMeters'] as num?)?.toDouble() ?? 0,
      state: AnchorAlarmState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => AnchorAlarmState.safe,
      ),
      maxDriftMeters: (json['maxDriftMeters'] as num?)?.toDouble() ?? 0,
    );
  }
}
