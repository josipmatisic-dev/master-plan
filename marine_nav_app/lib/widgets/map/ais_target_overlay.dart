/// AIS target overlay — renders tracked vessels on the map.
///
/// Uses the same geo-to-screen projection as WindParticleOverlay.
/// Targets are colored by threat level (CPA/TCPA) and shaped by
/// ship category. Labels appear at higher zoom levels.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/ais_target.dart';
import '../../models/lat_lng.dart';
import '../../models/viewport.dart';
import '../../services/ais_collision.dart';
import '../../services/projection_service.dart';

/// Threat level derived from CPA/TCPA for visual styling.
enum _ThreatLevel { safe, warning, danger }

/// Renders AIS vessel targets as map overlay symbols.
///
/// Each target is drawn as a directional icon colored by collision
/// threat level. Uses [ProjectionService] for geo-anchored Mercator
/// projection so targets track correctly during pan/zoom.
class AisTargetOverlay extends StatelessWidget {
  /// AIS targets to render (from AisProvider).
  final Map<int, AisTarget> targets;

  /// Full map viewport for Mercator projection.
  final Viewport viewport;

  /// Whether the holographic theme is active.
  final bool isHolographic;

  /// Creates an AIS target overlay.
  const AisTargetOverlay({
    super.key,
    required this.targets,
    required this.viewport,
    this.isHolographic = false,
  });

  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: CustomPaint(
        painter: _AisTargetPainter(
          targets: targets,
          viewport: viewport,
          isHolographic: isHolographic,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// CustomPainter that draws AIS vessel symbols on the map.
class _AisTargetPainter extends CustomPainter {
  final Map<int, AisTarget> targets;
  final Viewport viewport;
  final bool isHolographic;

  // Reusable paints
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _headingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  final Paint _warningRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _glowFillPaint = Paint()..style = PaintingStyle.fill;

  _AisTargetPainter({
    required this.targets,
    required this.viewport,
    required this.isHolographic,
  });

  double get zoom => viewport.zoom;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || viewport.size.isEmpty) return;

    final bounds = viewport.bounds;
    final showLabels = zoom >= 10;
    final symbolSize = _symbolSizeForZoom(zoom);

    for (final target in targets.values) {
      // Cull targets outside viewport (with padding)
      if (!_isInBounds(
          target.position.latitude, target.position.longitude, bounds)) {
        continue;
      }

      // Geo-to-screen projection via ProjectionService (Mercator)
      final screen = ProjectionService.latLngToScreen(
        LatLng(
          latitude: target.position.latitude,
          longitude: target.position.longitude,
        ),
        viewport,
      );

      final threat = _threatLevel(target);
      final colors = _colorsForThreat(threat);

      // Draw CPA warning ring for threatened targets
      if (threat != _ThreatLevel.safe) {
        _drawWarningRing(canvas, screen, symbolSize, threat, colors);
      }

      // Draw vessel symbol (rotated by COG/heading)
      final angle = _vesselAngle(target);
      _drawVesselSymbol(
        canvas,
        screen,
        symbolSize,
        angle,
        target.category,
        colors,
      );

      // Draw heading/COG vector line
      if (target.sog != null && target.sog! > 0.5) {
        _drawHeadingVector(canvas, screen, symbolSize, angle, target.sog!, colors);
      }

      // Draw name label at higher zoom
      if (showLabels) {
        _drawLabel(canvas, screen, symbolSize, target, colors);
      }
    }
  }

  /// Determine symbol size based on zoom level.
  double _symbolSizeForZoom(double z) {
    if (z >= 14) return 14;
    if (z >= 12) return 12;
    if (z >= 10) return 10;
    if (z >= 8) return 8;
    return 6;
  }

  /// Check if lat/lng is within viewport bounds (with 10% padding).
  bool _isInBounds(
    double lat,
    double lng,
    ({double south, double north, double west, double east}) bounds,
  ) {
    final latPad = (bounds.north - bounds.south) * 0.1;
    final lngPad = (bounds.east - bounds.west) * 0.1;
    return lat >= bounds.south - latPad &&
        lat <= bounds.north + latPad &&
        lng >= bounds.west - lngPad &&
        lng <= bounds.east + lngPad;
  }

  /// Determine threat level from CPA/TCPA.
  _ThreatLevel _threatLevel(AisTarget target) {
    final cpa = target.cpa;
    final tcpa = target.tcpa;
    if (cpa == null || tcpa == null || tcpa < 0) return _ThreatLevel.safe;
    if (cpa <= AisCollisionCalculator.cpaDangerNm) return _ThreatLevel.danger;
    if (cpa <= AisCollisionCalculator.cpaWarningNm) return _ThreatLevel.warning;
    return _ThreatLevel.safe;
  }

  /// Get fill/stroke colors based on threat level and theme.
  ({Color fill, Color stroke, Color glow}) _colorsForThreat(
      _ThreatLevel threat) {
    if (isHolographic) {
      return switch (threat) {
        _ThreatLevel.safe => (
            fill: const Color(0xFF00D9FF),
            stroke: const Color(0xCC00D9FF),
            glow: const Color(0x4400D9FF),
          ),
        _ThreatLevel.warning => (
            fill: const Color(0xFFFFAA00),
            stroke: const Color(0xCCFFAA00),
            glow: const Color(0x66FFAA00),
          ),
        _ThreatLevel.danger => (
            fill: const Color(0xFFFF00FF),
            stroke: const Color(0xCCFF00FF),
            glow: const Color(0x66FF00FF),
          ),
      };
    }
    return switch (threat) {
      _ThreatLevel.safe => (
          fill: const Color(0xFF00C9A7),
          stroke: const Color(0xCCFFFFFF),
          glow: const Color(0x3300C9A7),
        ),
      _ThreatLevel.warning => (
          fill: const Color(0xFFFF9A3D),
          stroke: const Color(0xCCFFFFFF),
          glow: const Color(0x44FF9A3D),
        ),
      _ThreatLevel.danger => (
          fill: const Color(0xFFFF6B6B),
          stroke: const Color(0xCCFFFFFF),
          glow: const Color(0x66FF6B6B),
        ),
    };
  }

  /// Get vessel direction angle in radians (COG preferred, heading fallback).
  double _vesselAngle(AisTarget target) {
    final deg = target.cog ?? target.heading?.toDouble() ?? 0;
    return deg * math.pi / 180.0;
  }

  /// Draw pulsing warning ring around threatened targets.
  void _drawWarningRing(Canvas canvas, Offset center, double symbolSize,
      _ThreatLevel threat, ({Color fill, Color stroke, Color glow}) colors) {
    final ringRadius = symbolSize * (threat == _ThreatLevel.danger ? 2.5 : 2.0);
    _warningRingPaint
      ..color = colors.glow
      ..strokeWidth = threat == _ThreatLevel.danger ? 2.5 : 1.5;
    canvas.drawCircle(center, ringRadius, _warningRingPaint);

    // Inner glow
    if (isHolographic) {
      _glowFillPaint.color = colors.glow.withValues(alpha: 0.15);
      canvas.drawCircle(center, ringRadius, _glowFillPaint);
    }
  }

  /// Draw the vessel symbol shape rotated to heading.
  void _drawVesselSymbol(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    ShipCategory category,
    ({Color fill, Color stroke, Color glow}) colors,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = _shapeForCategory(category, size);

    // Glow behind symbol (holographic only)
    if (isHolographic) {
      _fillPaint.color = colors.glow;
      canvas.drawPath(path, _fillPaint);
    }

    // Fill
    _fillPaint.color = colors.fill;
    canvas.drawPath(path, _fillPaint);

    // Stroke outline
    _strokePaint.color = colors.stroke;
    canvas.drawPath(path, _strokePaint);

    canvas.restore();
  }

  /// Ship-category-specific icon shapes (centered at origin, pointing up).
  Path _shapeForCategory(ShipCategory category, double s) {
    final path = Path();
    switch (category) {
      case ShipCategory.sailing:
      case ShipCategory.pleasure:
        // Sailboat: tall triangle
        path.moveTo(0, -s * 1.3);
        path.lineTo(-s * 0.6, s * 0.8);
        path.lineTo(s * 0.6, s * 0.8);
        path.close();
      case ShipCategory.fishing:
        // Diamond shape
        path.moveTo(0, -s);
        path.lineTo(-s * 0.7, 0);
        path.lineTo(0, s);
        path.lineTo(s * 0.7, 0);
        path.close();
      case ShipCategory.cargo:
      case ShipCategory.tanker:
        // Wide rectangle with pointed bow
        path.moveTo(0, -s * 1.2);
        path.lineTo(-s * 0.8, -s * 0.3);
        path.lineTo(-s * 0.8, s * 0.9);
        path.lineTo(s * 0.8, s * 0.9);
        path.lineTo(s * 0.8, -s * 0.3);
        path.close();
      case ShipCategory.passenger:
        // Rounded rectangle with pointed bow
        path.moveTo(0, -s * 1.2);
        path.lineTo(-s * 0.7, -s * 0.2);
        path.lineTo(-s * 0.7, s * 0.9);
        path.quadraticBezierTo(-s * 0.7, s * 1.1, 0, s * 1.1);
        path.quadraticBezierTo(s * 0.7, s * 1.1, s * 0.7, s * 0.9);
        path.lineTo(s * 0.7, -s * 0.2);
        path.close();
      case ShipCategory.tug:
      case ShipCategory.searchAndRescue:
        // Small compact circle
        path.addOval(Rect.fromCircle(center: Offset.zero, radius: s * 0.7));
      case ShipCategory.military:
        // Pentagon
        for (int i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 5;
          final x = s * math.cos(a);
          final y = s * math.sin(a);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
      case ShipCategory.other:
        // Default: simple triangle (arrow)
        path.moveTo(0, -s);
        path.lineTo(-s * 0.6, s * 0.6);
        path.lineTo(0, s * 0.3);
        path.lineTo(s * 0.6, s * 0.6);
        path.close();
    }
    return path;
  }

  /// Draw speed vector line ahead of vessel.
  void _drawHeadingVector(
    Canvas canvas,
    Offset center,
    double symbolSize,
    double angle,
    double sogKnots,
    ({Color fill, Color stroke, Color glow}) colors,
  ) {
    // Vector length proportional to speed (capped at 5× symbol)
    final vectorLen = math.min(sogKnots * 2, symbolSize * 5);
    final endX = center.dx + vectorLen * math.sin(angle);
    final endY = center.dy - vectorLen * math.cos(angle);

    _headingPaint.color = colors.fill.withValues(alpha: 0.6);
    canvas.drawLine(center, Offset(endX, endY), _headingPaint);
  }

  /// Draw vessel name/SOG label.
  void _drawLabel(
    Canvas canvas,
    Offset center,
    double symbolSize,
    AisTarget target,
    ({Color fill, Color stroke, Color glow}) colors,
  ) {
    final displayName = target.displayName;
    final sogStr =
        target.sog != null ? ' ${target.sog!.toStringAsFixed(1)}kn' : '';
    final label = '$displayName$sogStr';

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: colors.stroke,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);

    // Position label below vessel symbol
    final labelOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy + symbolSize + 4,
    );
    textPainter.paint(canvas, labelOffset);
    textPainter.dispose();
  }

  @override
  bool shouldRepaint(covariant _AisTargetPainter oldDelegate) {
    return oldDelegate.targets != targets ||
        oldDelegate.viewport.center != viewport.center ||
        oldDelegate.viewport.zoom != viewport.zoom ||
        oldDelegate.viewport.rotation != viewport.rotation ||
        oldDelegate.isHolographic != isHolographic;
  }
}
