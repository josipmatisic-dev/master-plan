/// AIS target model representing a vessel detected via AIS.
library;

import 'package:flutter/foundation.dart';

import 'lat_lng.dart';

/// AIS navigation status codes (ITU-R M.1371).
enum AisNavStatus {
  underWayEngine(0, 'Under way using engine'),
  atAnchor(1, 'At anchor'),
  notUnderCommand(2, 'Not under command'),
  restrictedManeuverability(3, 'Restricted manoeuvrability'),
  constrainedByDraught(4, 'Constrained by draught'),
  moored(5, 'Moored'),
  aground(6, 'Aground'),
  fishing(7, 'Engaged in fishing'),
  underWaySailing(8, 'Under way sailing'),
  unknown(15, 'Not defined');

  const AisNavStatus(this.code, this.description);
  final int code;
  final String description;

  static AisNavStatus fromCode(int code) {
    return AisNavStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => AisNavStatus.unknown,
    );
  }
}

/// Ship type categories derived from AIS type codes.
enum ShipCategory {
  cargo,
  tanker,
  passenger,
  fishing,
  sailing,
  pleasure,
  tug,
  military,
  searchAndRescue,
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
  String toString() => 'AisTarget($mmsi, ${displayName}, '
      '${position.latitude.toStringAsFixed(4)}, '
      '${position.longitude.toStringAsFixed(4)}, '
      'SOG: ${sog?.toStringAsFixed(1) ?? "?"} kn)';
}

/// Result of CPA/TCPA calculation between own vessel and a target.
@immutable
class CpaResult {
  /// Distance at closest point in nautical miles.
  final double cpaNm;

  /// Time to closest point in minutes. Negative means diverging.
  final double tcpaMinutes;

  const CpaResult({required this.cpaNm, required this.tcpaMinutes});

  /// Whether this represents a collision risk.
  bool get isWarning => cpaNm < 1.0 && tcpaMinutes > 0 && tcpaMinutes < 30;

  /// Whether this is a critical danger.
  bool get isDanger => cpaNm < 0.5 && tcpaMinutes > 0 && tcpaMinutes < 15;
}
