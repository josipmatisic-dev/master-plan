/// Vessel profile model for storing boat specifications.
///
/// Persisted via CacheProvider. Used by VesselScreen and
/// AIS own-vessel identification.
library;

import 'package:flutter/foundation.dart';

/// A vessel's profile and specifications.
@immutable
class VesselProfile {
  /// Vessel name.
  final String name;

  /// Vessel type (e.g., "Sailing Yacht", "Motor Yacht").
  final String type;

  /// MMSI number for AIS identification. Null if not set.
  final int? mmsi;

  /// Call sign. Null if not set.
  final String? callSign;

  /// IMO number. Null if not set.
  final int? imo;

  /// Flag state / registration country.
  final String? flag;

  /// Home port.
  final String? homePort;

  /// Length overall in meters.
  final double? loaMeters;

  /// Beam (width) in meters.
  final double? beamMeters;

  /// Draft in meters.
  final double? draftMeters;

  /// Displacement in kilograms.
  final double? displacementKg;

  /// Mast height in meters (for air draft / bridge clearance).
  final double? mastHeightMeters;

  /// Engine model description.
  final String? engineModel;

  /// Engine hours.
  final double? engineHours;

  /// Fuel capacity in liters.
  final double? fuelCapacityLiters;

  /// Water capacity in liters.
  final double? waterCapacityLiters;

  /// Creates a vessel profile.
  const VesselProfile({
    required this.name,
    this.type = 'Sailing Yacht',
    this.mmsi,
    this.callSign,
    this.imo,
    this.flag,
    this.homePort,
    this.loaMeters,
    this.beamMeters,
    this.draftMeters,
    this.displacementKg,
    this.mastHeightMeters,
    this.engineModel,
    this.engineHours,
    this.fuelCapacityLiters,
    this.waterCapacityLiters,
  });

  /// Default empty profile.
  static const empty = VesselProfile(name: '');

  /// Whether this profile has a name set.
  bool get isConfigured => name.isNotEmpty;

  /// Creates a copy with replaced fields.
  VesselProfile copyWith({
    String? name,
    String? type,
    int? mmsi,
    String? callSign,
    int? imo,
    String? flag,
    String? homePort,
    double? loaMeters,
    double? beamMeters,
    double? draftMeters,
    double? displacementKg,
    double? mastHeightMeters,
    String? engineModel,
    double? engineHours,
    double? fuelCapacityLiters,
    double? waterCapacityLiters,
  }) {
    return VesselProfile(
      name: name ?? this.name,
      type: type ?? this.type,
      mmsi: mmsi ?? this.mmsi,
      callSign: callSign ?? this.callSign,
      imo: imo ?? this.imo,
      flag: flag ?? this.flag,
      homePort: homePort ?? this.homePort,
      loaMeters: loaMeters ?? this.loaMeters,
      beamMeters: beamMeters ?? this.beamMeters,
      draftMeters: draftMeters ?? this.draftMeters,
      displacementKg: displacementKg ?? this.displacementKg,
      mastHeightMeters: mastHeightMeters ?? this.mastHeightMeters,
      engineModel: engineModel ?? this.engineModel,
      engineHours: engineHours ?? this.engineHours,
      fuelCapacityLiters: fuelCapacityLiters ?? this.fuelCapacityLiters,
      waterCapacityLiters: waterCapacityLiters ?? this.waterCapacityLiters,
    );
  }

  /// Serializes to JSON for persistence.
  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        if (mmsi != null) 'mmsi': mmsi,
        if (callSign != null) 'callSign': callSign,
        if (imo != null) 'imo': imo,
        if (flag != null) 'flag': flag,
        if (homePort != null) 'homePort': homePort,
        if (loaMeters != null) 'loaMeters': loaMeters,
        if (beamMeters != null) 'beamMeters': beamMeters,
        if (draftMeters != null) 'draftMeters': draftMeters,
        if (displacementKg != null) 'displacementKg': displacementKg,
        if (mastHeightMeters != null) 'mastHeightMeters': mastHeightMeters,
        if (engineModel != null) 'engineModel': engineModel,
        if (engineHours != null) 'engineHours': engineHours,
        if (fuelCapacityLiters != null)
          'fuelCapacityLiters': fuelCapacityLiters,
        if (waterCapacityLiters != null)
          'waterCapacityLiters': waterCapacityLiters,
      };

  /// Deserializes from JSON.
  factory VesselProfile.fromJson(Map<String, dynamic> json) {
    return VesselProfile(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Sailing Yacht',
      mmsi: json['mmsi'] as int?,
      callSign: json['callSign'] as String?,
      imo: json['imo'] as int?,
      flag: json['flag'] as String?,
      homePort: json['homePort'] as String?,
      loaMeters: (json['loaMeters'] as num?)?.toDouble(),
      beamMeters: (json['beamMeters'] as num?)?.toDouble(),
      draftMeters: (json['draftMeters'] as num?)?.toDouble(),
      displacementKg: (json['displacementKg'] as num?)?.toDouble(),
      mastHeightMeters: (json['mastHeightMeters'] as num?)?.toDouble(),
      engineModel: json['engineModel'] as String?,
      engineHours: (json['engineHours'] as num?)?.toDouble(),
      fuelCapacityLiters: (json['fuelCapacityLiters'] as num?)?.toDouble(),
      waterCapacityLiters: (json['waterCapacityLiters'] as num?)?.toDouble(),
    );
  }
}
