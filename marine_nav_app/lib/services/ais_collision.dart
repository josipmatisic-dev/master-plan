/// CPA/TCPA collision warning calculator for AIS targets.
///
/// Computes Closest Point of Approach (CPA) and Time to CPA (TCPA)
/// between own vessel and AIS targets using vector-based relative motion.
library;

import 'dart:math' as math;

import '../models/ais_target.dart';
import '../models/lat_lng.dart';

/// Calculates CPA/TCPA between own vessel and AIS targets.
class AisCollisionCalculator {
  /// CPA warning threshold in nautical miles.
  static const double cpaWarningNm = 1.0;

  /// CPA danger threshold in nautical miles.
  static const double cpaDangerNm = 0.5;

  /// TCPA maximum lookahead in minutes.
  static const double tcpaMaxMinutes = 30.0;

  /// Compute CPA/TCPA between own vessel and a target.
  ///
  /// Returns null if either vessel has no SOG/COG data or if
  /// both vessels are stationary.
  static CpaResult? compute({
    required LatLng ownPosition,
    required double ownSogKnots,
    required double ownCogDegrees,
    required AisTarget target,
  }) {
    final targetSog = target.sog;
    final targetCog = target.cog;
    if (targetSog == null || targetCog == null) return null;
    if (ownSogKnots < 0.1 && targetSog < 0.1) return null;

    // Convert positions to relative X/Y in nautical miles
    final dLat = target.position.latitude - ownPosition.latitude;
    final dLng = target.position.longitude - ownPosition.longitude;
    final cosLat = math.cos(
      ownPosition.latitude * math.pi / 180.0,
    );

    // Relative position in NM (1 degree lat ≈ 60 NM)
    final rx = dLng * cosLat * 60.0;
    final ry = dLat * 60.0;

    // Velocity components in NM/minute
    final ownVx = ownSogKnots / 60.0 * math.sin(ownCogDegrees * _deg2rad);
    final ownVy = ownSogKnots / 60.0 * math.cos(ownCogDegrees * _deg2rad);
    final tgtVx = targetSog / 60.0 * math.sin(targetCog * _deg2rad);
    final tgtVy = targetSog / 60.0 * math.cos(targetCog * _deg2rad);

    // Relative velocity
    final dvx = tgtVx - ownVx;
    final dvy = tgtVy - ownVy;

    // TCPA = -(R · V) / |V|²
    final vSquared = dvx * dvx + dvy * dvy;
    if (vSquared < 1e-10) {
      // Vessels moving in parallel at same speed
      final dist = math.sqrt(rx * rx + ry * ry);
      return CpaResult(cpaNm: dist, tcpaMinutes: 0);
    }

    final tcpa = -(rx * dvx + ry * dvy) / vSquared;

    // CPA distance at time tcpa
    final cpaX = rx + dvx * tcpa;
    final cpaY = ry + dvy * tcpa;
    final cpaDist = math.sqrt(cpaX * cpaX + cpaY * cpaY);

    return CpaResult(cpaNm: cpaDist, tcpaMinutes: tcpa);
  }

  /// Batch compute CPA/TCPA for all targets, returning only warnings.
  static List<AisTarget> computeWarnings({
    required LatLng ownPosition,
    required double ownSogKnots,
    required double ownCogDegrees,
    required Iterable<AisTarget> targets,
  }) {
    final warnings = <AisTarget>[];
    for (final target in targets) {
      final result = compute(
        ownPosition: ownPosition,
        ownSogKnots: ownSogKnots,
        ownCogDegrees: ownCogDegrees,
        target: target,
      );
      if (result == null) continue;
      if (result.tcpaMinutes < 0) continue; // Diverging
      if (result.tcpaMinutes > tcpaMaxMinutes) continue;
      if (result.cpaNm > cpaWarningNm) continue;

      warnings.add(AisTarget(
        mmsi: target.mmsi,
        position: target.position,
        lastUpdate: target.lastUpdate,
        sog: target.sog,
        cog: target.cog,
        heading: target.heading,
        navStatus: target.navStatus,
        name: target.name,
        callSign: target.callSign,
        imo: target.imo,
        shipType: target.shipType,
        dimensions: target.dimensions,
        cpa: result.cpaNm,
        tcpa: result.tcpaMinutes,
      ));
    }
    // Sort by CPA distance (closest first)
    warnings.sort((a, b) => (a.cpa ?? 999).compareTo(b.cpa ?? 999));
    return warnings;
  }

  static const double _deg2rad = math.pi / 180.0;
}
