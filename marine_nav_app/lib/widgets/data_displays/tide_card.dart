/// Tide information card — shows next high/low tide with mini curve.
///
/// Displays station name, next tide predictions, and a simple
/// tide curve visualization using data from [TideProvider].
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/tide_data.dart';
import '../../theme/holographic_colors.dart';

/// Glass card displaying tide predictions and a mini curve.
class TideCard extends StatelessWidget {
  /// The tide data to display.
  final TideData? tideData;

  /// The next upcoming high tide prediction.
  final TidePrediction? nextHigh;

  /// The next upcoming low tide prediction.
  final TidePrediction? nextLow;

  /// Whether data is currently loading.
  final bool isLoading;

  /// Optional error message.
  final String? error;

  /// Whether to use holographic theme styling.
  final bool isHolographic;

  /// Called when the user requests a refresh.
  final VoidCallback? onRefresh;

  /// Creates a [TideCard].
  const TideCard({
    super.key,
    this.tideData,
    this.nextHigh,
    this.nextLow,
    this.isLoading = false,
    this.error,
    this.isHolographic = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = isHolographic ? HolographicColors.electricBlue : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Icon(Icons.waves, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tides',
                style: tt.titleMedium?.copyWith(color: accent),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent,
                ),
              )
            else if (onRefresh != null)
              GestureDetector(
                onTap: onRefresh,
                child: Icon(Icons.refresh, size: 16, color: cs.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Station name
        if (tideData != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tideData!.station.name,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // Error state
        if (error != null)
          _buildErrorRow(tt, cs)
        // No data state
        else if (tideData == null && !isLoading)
          _buildEmptyRow(tt, cs)
        // Tide predictions
        else ...[
          _buildTidePredictionRow(
            context,
            label: 'High',
            prediction: nextHigh,
            icon: Icons.arrow_upward,
            color: isHolographic
                ? HolographicColors.neonCyan
                : const Color(0xFF4FC3F7),
          ),
          const SizedBox(height: 6),
          _buildTidePredictionRow(
            context,
            label: 'Low',
            prediction: nextLow,
            icon: Icons.arrow_downward,
            color: isHolographic
                ? HolographicColors.neonMagenta
                : const Color(0xFFFF8A65),
          ),

          // Mini tide curve
          if (tideData != null && tideData!.predictions.length >= 4) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: const Size(double.infinity, 48),
                  painter: _TideCurvePainter(
                    predictions: tideData!.predictions,
                    accentColor: accent,
                    isHolographic: isHolographic,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildTidePredictionRow(
    BuildContext context, {
    required String label,
    required TidePrediction? prediction,
    required IconData icon,
    required Color color,
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (prediction == null) {
      return Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text('$label: --',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      );
    }

    final time = prediction.time.toLocal();
    final now = DateTime.now();
    final diff = time.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60).abs();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    final relStr = hours > 0
        ? 'in ${hours}h ${mins}m'
        : mins > 0
            ? 'in ${mins}m'
            : 'now';
    final heightStr = '${prediction.heightMeters.toStringAsFixed(1)}m';

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
        const Spacer(),
        Text(heightStr,
            style: tt.bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text(timeStr, style: tt.bodySmall?.copyWith(color: cs.onSurface)),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(relStr, style: tt.labelSmall?.copyWith(color: color)),
        ),
      ],
    );
  }

  Widget _buildErrorRow(TextTheme tt, ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.warning_amber, size: 16, color: cs.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            error ?? 'Unknown error',
            style: tt.bodySmall?.copyWith(color: cs.error),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRow(TextTheme tt, ColorScheme cs) {
    return Text(
      'No tide station nearby',
      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
    );
  }
}

/// Paints a simple tide curve from predictions.
class _TideCurvePainter extends CustomPainter {
  final List<TidePrediction> predictions;
  final Color accentColor;
  final bool isHolographic;

  _TideCurvePainter({
    required this.predictions,
    required this.accentColor,
    required this.isHolographic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (predictions.length < 2) return;

    final sorted = List<TidePrediction>.from(predictions)
      ..sort((a, b) => a.time.compareTo(b.time));

    // Find time and height ranges
    final tMin = sorted.first.time.millisecondsSinceEpoch.toDouble();
    final tMax = sorted.last.time.millisecondsSinceEpoch.toDouble();
    final tRange = tMax - tMin;
    if (tRange <= 0) return;

    var hMin = double.infinity;
    var hMax = double.negativeInfinity;
    for (final p in sorted) {
      hMin = math.min(hMin, p.heightMeters);
      hMax = math.max(hMax, p.heightMeters);
    }
    final hRange = hMax - hMin;
    if (hRange <= 0) return;

    // Build smooth path using quadratic bezier between points
    final path = Path();
    final points = <Offset>[];
    for (final p in sorted) {
      final x = (p.time.millisecondsSinceEpoch - tMin) / tRange * size.width;
      final y = (1.0 - (p.heightMeters - hMin) / hRange) * size.height;
      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Draw gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.25),
          accentColor.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);

    // Draw curve line
    final linePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    if (isHolographic) {
      // Neon glow effect
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, glowPaint);
    }

    canvas.drawPath(path, linePaint);

    // Draw "now" indicator
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    if (now >= tMin && now <= tMax) {
      final nowX = (now - tMin) / tRange * size.width;
      final nowPaint = Paint()
        ..color = isHolographic
            ? HolographicColors.neonMagenta.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(nowX, 0), Offset(nowX, size.height), nowPaint);
    }

    // Draw dots for high/low
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < points.length; i++) {
      dotPaint.color = sorted[i].type == TideType.high
          ? (isHolographic
              ? HolographicColors.neonCyan
              : const Color(0xFF4FC3F7))
          : (isHolographic
              ? HolographicColors.neonMagenta
              : const Color(0xFFFF8A65));
      canvas.drawCircle(points[i], 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TideCurvePainter oldDelegate) {
    return predictions != oldDelegate.predictions ||
        accentColor != oldDelegate.accentColor;
  }
}
