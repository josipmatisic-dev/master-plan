/// Theme Controls Widget
///
/// Provides theme switching controls.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
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
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Theme Controls',
                style: OceanTextStyles.heading2,
              ),
              OceanDimensions.spacing.verticalSpace,
              _buildThemeButton(
                context,
                'Dark Mode',
                AppThemeMode.dark,
                themeProvider,
              ),
              OceanDimensions.spacingS.verticalSpace,
              _buildThemeButton(
                context,
                'Light Mode',
                AppThemeMode.light,
                themeProvider,
              ),
              OceanDimensions.spacingS.verticalSpace,
              _buildThemeButton(
                context,
                'System',
                AppThemeMode.system,
                themeProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build theme button
  Widget _buildThemeButton(
    BuildContext context,
    String label,
    AppThemeMode mode,
    ThemeProvider provider,
  ) {
    final isSelected = provider.themeMode == mode;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => provider.setThemeMode(mode),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? OceanColors.seafoamGreen : OceanColors.surface,
          foregroundColor:
              isSelected ? OceanColors.pureWhite : OceanColors.textSecondary,
        ),
        child: Text(label),
      ),
    );
  }
}
