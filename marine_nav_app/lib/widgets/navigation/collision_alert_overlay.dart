import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ais_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';

/// Overlay widget that displays AIS collision warnings.
///
/// Watches [AisProvider] and shows a red alert card if any targets
/// pose a collision risk (CPA < threshold).
class CollisionAlertOverlay extends StatelessWidget {
  /// Creates a collision alert overlay.
  const CollisionAlertOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final warnings = context.watch<AisProvider>().warnings;

    if (warnings.isEmpty) return const SizedBox.shrink();

    // Warnings are sorted by risk in AisProvider
    final target = warnings.first;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OceanDimensions.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OceanColors.coralRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(OceanDimensions.radius),
              border: Border.all(color: OceanColors.coralRed, width: 2),
              boxShadow: [
                BoxShadow(
                  color: OceanColors.coralRed.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: OceanColors.coralRed,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COLLISION ALERT',
                      style: OceanTextStyles.heading2.copyWith(
                        color: OceanColors.coralRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  target.displayName,
                  style: OceanTextStyles.body
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'CPA: ${target.cpa?.toStringAsFixed(2) ?? "--"} nm',
                  style: OceanTextStyles.dataValue.copyWith(fontSize: 24),
                ),
                Text(
                  'TCPA: ${target.tcpa?.toStringAsFixed(1) ?? "--"} min',
                  style: OceanTextStyles.body,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
