/// Theme Controls Widget
///
/// Provides theme mode + variant switching controls.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/holographic_colors.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Theme controls for home screen
class ThemeControls extends StatelessWidget {
  /// Creates theme controls.
  const ThemeControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isHolographic = themeProvider.isHolographic;
        final colorScheme = Theme.of(context).colorScheme;

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme Controls',
                style: OceanTextStyles.heading2.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: OceanDimensions.spacing),

              // Theme Variant Toggle
              _buildVariantToggle(context, themeProvider, isHolographic),
              const SizedBox(height: OceanDimensions.spacingM),

              // Divider
              Divider(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: OceanDimensions.spacingS),

              // Theme Mode Buttons
              _buildThemeButton(
                context, 'Dark Mode', AppThemeMode.dark,
                themeProvider, isHolographic,
              ),
              const SizedBox(height: OceanDimensions.spacingS),
              _buildThemeButton(
                context, 'Light Mode', AppThemeMode.light,
                themeProvider, isHolographic,
              ),
              const SizedBox(height: OceanDimensions.spacingS),
              _buildThemeButton(
                context, 'System', AppThemeMode.system,
                themeProvider, isHolographic,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build theme variant toggle (Ocean Glass ↔ Holographic)
  Widget _buildVariantToggle(
    BuildContext context,
    ThemeProvider provider,
    bool isHolographic,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: isHolographic
            ? BoxDecoration(
                borderRadius:
                    BorderRadius.circular(OceanDimensions.radiusS),
                boxShadow: [
                  BoxShadow(
                    color: HolographicColors.neonMagenta
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: ElevatedButton.icon(
          onPressed: () => provider.toggleThemeVariant(),
          icon: Icon(
            isHolographic ? Icons.auto_awesome : Icons.water,
          ),
          label: Text(
            isHolographic
                ? 'Switch to Ocean Glass'
                : 'Switch to Holographic ⚡',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isHolographic
                ? HolographicColors.cyberPurple
                : OceanColors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Build theme mode button
  Widget _buildThemeButton(
    BuildContext context,
    String label,
    AppThemeMode mode,
    ThemeProvider provider,
    bool isHolographic,
  ) {
    final isSelected = provider.themeMode == mode;

    Color bgColor;
    Color fgColor;
    if (isSelected) {
      bgColor = isHolographic
          ? HolographicColors.electricBlue
          : OceanColors.seafoamGreen;
      fgColor = Colors.white;
    } else {
      bgColor = isHolographic
          ? HolographicColors.spaceNavy
          : OceanColors.surface;
      fgColor = isHolographic
          ? HolographicColors.textSecondary
          : OceanColors.textSecondary;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => provider.setThemeMode(mode),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
        ),
        child: Text(label),
      ),
    );
  }
}
