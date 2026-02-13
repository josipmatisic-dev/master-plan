/// Welcome Card Widget
///
/// Displays welcome message and phase status. Theme-aware.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/dimensions.dart';
import '../../theme/holographic_colors.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Welcome card for home screen
class WelcomeCard extends StatelessWidget {
  /// Creates a welcome card.
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHolographic ? Icons.auto_awesome : Icons.sailing,
            size: OceanDimensions.iconXL,
            color: colorScheme.primary,
            shadows: isHolographic
                ? [
                    Shadow(
                      color: HolographicColors.electricBlue
                          .withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          const SizedBox(height: OceanDimensions.spacingM),
          Text(
            isHolographic
                ? 'Holographic Cyberpunk'
                : 'Ocean Glass Design',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
              fontFamily: OceanTextStyles.fontFamily,
              letterSpacing: -0.3,
              color: colorScheme.onSurface,
              shadows: isHolographic
                  ? [
                      Shadow(
                        color: HolographicColors.electricBlue
                            .withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: OceanDimensions.spacingS),
          Text(
            isHolographic
                ? 'Dual Theme System Active ⚡'
                : 'Phase 0 Foundation Complete ✅',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              fontFamily: OceanTextStyles.fontFamily,
              letterSpacing: 0,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
