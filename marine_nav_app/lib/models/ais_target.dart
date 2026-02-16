/// AIS target model representing a vessel detected via AIS.
library;

import 'package:flutter/foundation.dart';

import 'lat_lng.dart';

/// AIS navigation status codes (ITU-R M.1371).
enum AisNavStatus {
  /// Under way using engine.
  underWayEngine(0, 'Under way using engine'),

  /// Vessel is at anchor.
  atAnchor(1, 'At anchor'),

  /// Vessel not under command.
  notUnderCommand(2, 'Not under command'),

  /// Vessel has restricted maneuverability.
  restrictedManeuverability(3, 'Restricted manoeuvrability'),

  /// Vessel constrained by draught.
  constrainedByDraught(4, 'Constrained by draught'),

  /// Vessel is moored.
  moored(5, 'Moored'),

  /// Vessel is aground.
  aground(6, 'Aground'),

  /// Engaged in fishing.
  fishing(7, 'Engaged in fishing'),

  /// Under way sailing.
  underWaySailing(8, 'Under way sailing'),

  /// Navigation status unknown.
  unknown(15, 'Not defined');

  /// Creates an [AisNavStatus] with code and description.
  const AisNavStatus(this.code, this.description);

  /// The AIS navigation status code.
  final int code;

  /// Human-readable description of the status.
  final String description;

  /// Returns the [AisNavStatus] corresponding to the given code.
  static AisNavStatus fromCode(int code) {
    return AisNavStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => AisNavStatus.unknown,
    );
  }
}

/// Ship type categories derived from AIS type codes.
enum ShipCategory {
  /// Cargo vessel.
  cargo,

  /// Tanker vessel.
  tanker,

  /// Passenger vessel.
  passenger,

  /// Fishing vessel.
  fishing,

  /// Sailing vessel.
  sailing,

  /// Pleasure craft.
  pleasure,

  /// Tug or special craft.
  tug,

  /// Military vessel.
  military,

  /// Search and Rescue vessel.
  searchAndRescue,

  /// Other or unknown type.
  other;

  /// Derive category from AIS ship type code (0-99).
  static ShipCategory fromTypeCode(int code) {
    if (code >= 70 && code <= 79) return ShipCategory.cargo;
    if (code >= 80 && code <= 89) return ShipCategory.tanker;
    if (code >= 60 && code <= 69) return ShipCategory.passenger;
    if (code == 30) return ShipCategory.fishing;
    if (code == 36) return ShipCategory.sailing;
    if (code == 37) return ShipCategory.pleasure;
    if (code >= 31 && code <= 32) return ShipCategory.tug;
    if (code == 35) return ShipCategory.military;
    if (code == 51) return ShipCategory.searchAndRescue;
    return ShipCategory.other;
  }
}

/// An AIS vessel target with position, kinematics, and identity.
@immutable
class AisTarget {
  /// Maritime Mobile Service Identity (unique vessel identifier).
  final int mmsi;

  /// Current position (WGS84).
  final LatLng position;

  /// Speed over ground in knots. Null if unavailable.
  final double? sog;

  /// Course over ground in degrees (0-359.9). Null if unavailable.
  final double? cog;

  /// True heading in degrees (0-359). Null if unavailable.
  final int? heading;

  /// Navigation status (moored, under way, etc.).
  final AisNavStatus navStatus;

  /// Rate of turn in degrees/minute. Null if unavailable.
  final double? rateOfTurn;

  /// Vessel name. Null until static data received.
  final String? name;

  /// Call sign. Null until static data received.
  final String? callSign;

  /// IMO number. Null until static data received.
  final int? imo;

  /// AIS ship type code (0-99).
  final int shipType;

  /// Derived ship category.
  ShipCategory get category => ShipCategory.fromTypeCode(shipType);

  /// Ship dimensions in meters [A, B, C, D] from AIS reference point.
  final List<int>? dimensions;

  /// Overall length in meters (derived from dimensions A+B).
  double? get lengthMeters {
    if (dimensions == null || dimensions!.length < 2) return null;
    final len = dimensions![0] + dimensions![1];
    return len > 0 ? len.toDouble() : null;
  }

  /// Overall beam in meters (derived from dimensions C+D).
  double? get beamMeters {
    if (dimensions == null || dimensions!.length < 4) return null;
    final beam = dimensions![2] + dimensions![3];
    return beam > 0 ? beam.toDouble() : null;
  }

  /// Destination string from AIS voyage data. Null if unknown.
  final String? destination;

  /// Draught in meters (×10 in raw AIS). Null if unknown.
  final double? draught;

  /// ETA as DateTime. Null if unknown.
  final DateTime? eta;

  /// Timestamp of last position update.
  final DateTime lastUpdate;

  /// Closest Point of Approach in nautical miles. Null if not computed.
  final double? cpa;

  /// Time to CPA in minutes. Null if not computed.
  final double? tcpa;

  /// Creates a new [AisTarget].
  const AisTarget({
    required this.mmsi,
    required this.position,
    required this.lastUpdate,
    this.sog,
    this.cog,
    this.heading,
    this.navStatus = AisNavStatus.unknown,
    this.rateOfTurn,
    this.name,
    this.callSign,
    this.imo,
    this.shipType = 0,
    this.dimensions,
    this.destination,
    this.draught,
    this.eta,
    this.cpa,
    this.tcpa,
  });

  /// Merges new data into this target, keeping existing values for nulls.
  AisTarget merge(AisTarget update) {
    return AisTarget(
      mmsi: mmsi,
      position: update.position,
      lastUpdate: update.lastUpdate,
      sog: update.sog ?? sog,
      cog: update.cog ?? cog,
      heading: update.heading ?? heading,
      navStatus: update.navStatus != AisNavStatus.unknown
          ? update.navStatus
          : navStatus,
      rateOfTurn: update.rateOfTurn ?? rateOfTurn,
      name: update.name ?? name,
      callSign: update.callSign ?? callSign,
      imo: update.imo ?? imo,
      shipType: update.shipType != 0 ? update.shipType : shipType,
      dimensions: update.dimensions ?? dimensions,
      destination: update.destination ?? destination,
      draught: update.draught ?? draught,
      eta: update.eta ?? eta,
      cpa: update.cpa ?? cpa,
      tcpa: update.tcpa ?? tcpa,
    );
  }

  /// Whether this target is stale (no update for over 5 minutes).
  bool get isStale =>
      DateTime.now().difference(lastUpdate) > const Duration(minutes: 5);

  /// Display name: vessel name, or MMSI if name unknown.
  String get displayName =>
      name?.trim().isNotEmpty == true ? name!.trim() : 'MMSI $mmsi';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AisTarget && other.mmsi == mmsi);

  @override
  int get hashCode => mmsi.hashCode;

  @override
  String toString() => 'AisTarget($mmsi, $displayName, '
      '${position.latitude.toStringAsFixed(4)}, '
      '${position.longitude.toStringAsFixed(4)}, '
      'SOG: ${sog?.toStringAsFixed(1) ?? "?"} kn)';

  /// Serializes to JSON for cache persistence.
  Map<String, dynamic> toJson() => {
        'mmsi': mmsi,
        'lat': position.latitude,
        'lng': position.longitude,
        'lastUpdate': lastUpdate.toUtc().toIso8601String(),
        if (sog != null) 'sog': sog,
        if (cog != null) 'cog': cog,
        if (heading != null) 'heading': heading,
        'navStatus': navStatus.code,
        if (rateOfTurn != null) 'rateOfTurn': rateOfTurn,
        if (name != null) 'name': name,
        if (callSign != null) 'callSign': callSign,
        if (imo != null) 'imo': imo,
        'shipType': shipType,
        if (dimensions != null) 'dimensions': dimensions,
        if (destination != null) 'destination': destination,
        if (draught != null) 'draught': draught,
        if (eta != null) 'eta': eta!.toUtc().toIso8601String(),
      };

  /// Deserializes from JSON cache entry.
  factory AisTarget.fromJson(Map<String, dynamic> json) {
    return AisTarget(
      mmsi: json['mmsi'] as int,
      position: LatLng(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
      ),
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      sog: (json['sog'] as num?)?.toDouble(),
      cog: (json['cog'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toInt(),
      navStatus: AisNavStatus.fromCode(json['navStatus'] as int? ?? 15),
      rateOfTurn: (json['rateOfTurn'] as num?)?.toDouble(),
      name: json['name'] as String?,
      callSign: json['callSign'] as String?,
      imo: json['imo'] as int?,
      shipType: json['shipType'] as int? ?? 0,
      dimensions: (json['dimensions'] as List?)?.cast<int>(),
      destination: json['destination'] as String?,
      draught: (json['draught'] as num?)?.toDouble(),
      eta: json['eta'] != null ? DateTime.parse(json['eta'] as String) : null,
    );
  }
}

/// Result of CPA/TCPA calculation between own vessel and a target.
@immutable
class CpaResult {
  /// Distance at closest point in nautical miles.
  final double cpaNm;

  /// Time to closest point in minutes. Negative means diverging.
  final double tcpaMinutes;

  /// Creates a [CpaResult] with the given [cpaNm] and [tcpaMinutes].
  const CpaResult({required this.cpaNm, required this.tcpaMinutes});

  /// Whether this represents a collision risk.
  bool get isWarning => cpaNm < 1.0 && tcpaMinutes > 0 && tcpaMinutes < 30;

  /// Whether this is a critical danger.
  bool get isDanger => cpaNm < 0.5 && tcpaMinutes > 0 && tcpaMinutes < 15;
}
