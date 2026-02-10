/// Boat marker overlay widget for rendering vessel position on the map.
///
/// Uses [ProjectionService] to convert geographic coordinates to screen
/// pixels. Shows a directional arrow rotated by course/heading.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart' hide Viewport;

import '../../models/boat_position.dart';
import '../../models/viewport.dart';
import '../../services/projection_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';

/// Renders the vessel position as a directional marker on the map.
///
/// Requires [position] and [viewport] to compute screen placement.
/// Rotates the marker arrow based on [position.courseTrue].
/// Shows a low-accuracy indicator ring when GPS accuracy degrades.
///
/// Usage:
/// ```dart
/// BoatMarker(
///   position: boatProvider.currentPosition!,
///   viewport: mapProvider.viewport,
/// )
/// ```
class BoatMarker extends StatelessWidget {
  /// Current vessel position snapshot.
  final BoatPosition position;

  /// Current map viewport for coordinate projection.
  final Viewport viewport;

  /// Optional MOB position to show a danger marker.
  final BoatPosition? mobPosition;

  /// Marker radius in logical pixels.
  static const double _markerRadius = 12.0;

  /// MOB marker radius in logical pixels.
  static const double _mobRadius = 10.0;

  /// Creates a [BoatMarker] overlay.
  const BoatMarker({
    super.key,
    required this.position,
    required this.viewport,
    this.mobPosition,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BoatMarkerPainter(
          position: position,
          viewport: viewport,
          mobPosition: mobPosition,
        ),
        size: viewport.size,
      ),
    );
  }
}

/// Custom painter for the boat marker and optional MOB marker.
class _BoatMarkerPainter extends CustomPainter {
  final BoatPosition position;
  final Viewport viewport;
  final BoatPosition? mobPosition;

  _BoatMarkerPainter({
    required this.position,
    required this.viewport,
    this.mobPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoatMarker(canvas);

    if (mobPosition != null) {
      _drawMobMarker(canvas, mobPosition!);
    }
  }

  void _drawBoatMarker(Canvas canvas) {
    final screenPos = ProjectionService.latLngToScreen(
      position.position,
      viewport,
    );

    // Low accuracy indicator ring (ISS-018 visual feedback)
    if (!position.isAccurate) {
      final accuracyPaint = Paint()
        ..color = OceanColors.safetyOrange.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        screenPos,
        BoatMarker._markerRadius + OceanDimensions.spacingS,
        accuracyPaint,
      );
    }

    // Outer glow ring
    final glowPaint = Paint()
      ..color = OceanColors.seafoamGreen.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      screenPos,
      BoatMarker._markerRadius + OceanDimensions.spacingXS,
      glowPaint,
    );

    // Main marker body
    final bodyPaint = Paint()
      ..color = OceanColors.seafoamGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(screenPos, BoatMarker._markerRadius, bodyPaint);

    // Inner highlight
    final innerPaint = Paint()
      ..color = OceanColors.pureWhite.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      screenPos,
      BoatMarker._markerRadius * 0.4,
      innerPaint,
    );

    // Direction arrow (rotated by course or heading)
    final bearing = position.courseTrue ?? position.heading;
    if (bearing != null) {
      _drawDirectionArrow(canvas, screenPos, bearing);
    }
  }

  void _drawDirectionArrow(Canvas canvas, Offset center, double bearing) {
    const arrowLength = BoatMarker._markerRadius * 1.8;
    final radians = (bearing - 90) * math.pi / 180.0 + viewport.rotation;

    final tipX = center.dx + arrowLength * math.cos(radians);
    final tipY = center.dy + arrowLength * math.sin(radians);

    final arrowPaint = Paint()
      ..color = OceanColors.pureWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(tipX, tipY), arrowPaint);

    // Arrow head
    const headAngle = 0.5;
    const headLength = 6.0;
    final headLeft = Offset(
      tipX - headLength * math.cos(radians - headAngle),
      tipY - headLength * math.sin(radians - headAngle),
    );
    final headRight = Offset(
      tipX - headLength * math.cos(radians + headAngle),
      tipY - headLength * math.sin(radians + headAngle),
    );

    final headPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(headLeft.dx, headLeft.dy)
      ..moveTo(tipX, tipY)
      ..lineTo(headRight.dx, headRight.dy);

    canvas.drawPath(headPath, arrowPaint);
  }

  void _drawMobMarker(Canvas canvas, BoatPosition mob) {
    final screenPos = ProjectionService.latLngToScreen(
      mob.position,
      viewport,
    );

    // Red danger circle
    final mobPaint = Paint()
      ..color = OceanColors.coralRed
      ..style = PaintingStyle.fill;
    canvas.drawCircle(screenPos, BoatMarker._mobRadius, mobPaint);

    // White border
    final borderPaint = Paint()
      ..color = OceanColors.pureWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(screenPos, BoatMarker._mobRadius, borderPaint);

    // "X" marker
    final xPaint = Paint()
      ..color = OceanColors.pureWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    const offset = 4.0;
    canvas.drawLine(
      Offset(screenPos.dx - offset, screenPos.dy - offset),
      Offset(screenPos.dx + offset, screenPos.dy + offset),
      xPaint,
    );
    canvas.drawLine(
      Offset(screenPos.dx + offset, screenPos.dy - offset),
      Offset(screenPos.dx - offset, screenPos.dy + offset),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoatMarkerPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.viewport != viewport ||
        oldDelegate.mobPosition != mobPosition;
  }
}
