/// Navigation Shortcuts Widget
///
/// Provides quick navigation buttons to main screens. Theme-aware.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../screens/map_screen.dart';
import '../../screens/navigation_mode_screen.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/holographic_colors.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Navigation shortcuts for home screen
class NavigationShortcuts extends StatelessWidget {
  /// Creates navigation shortcuts.
  const NavigationShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navigate to Screens',
            style: OceanTextStyles.heading2.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: OceanDimensions.spacingS),
          Wrap(
            spacing: OceanDimensions.spacing,
            runSpacing: OceanDimensions.spacingS,
            children: [
              _buildNavButton(
                context,
                icon: Icons.map_outlined,
                label: 'Map View',
                isPrimary: true,
                isHolographic: isHolographic,
                colorScheme: colorScheme,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                ),
              ),
              _buildNavButton(
                context,
                icon: Icons.alt_route,
                label: 'Navigation Mode',
                isPrimary: false,
                isHolographic: isHolographic,
                colorScheme: colorScheme,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NavigationModeScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isHolographic,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
  }) {
    if (isHolographic) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color:
                        HolographicColors.electricBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? HolographicColors.electricBlue
                : HolographicColors.spaceNavy,
            foregroundColor: HolographicColors.pureWhite,
            side: isPrimary
                ? null
                : BorderSide(
                    color:
                        HolographicColors.electricBlue.withValues(alpha: 0.4),
                  ),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? OceanColors.seafoamGreen : OceanColors.surface,
        foregroundColor: OceanColors.pureWhite,
      ),
    );
  }
}
