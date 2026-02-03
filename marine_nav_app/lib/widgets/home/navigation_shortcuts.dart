/// Navigation Shortcuts Widget
///
/// Provides quick navigation buttons to main screens.
library;

import 'package:flutter/material.dart';

import '../../screens/map_screen.dart';
import '../../screens/navigation_mode_screen.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Navigation shortcuts for home screen
class NavigationShortcuts extends StatelessWidget {
  /// Creates navigation shortcuts.
  const NavigationShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Navigate to Screens', style: OceanTextStyles.heading2),
          const SizedBox(height: OceanDimensions.spacingS),
          Wrap(
            spacing: OceanDimensions.spacing,
            runSpacing: OceanDimensions.spacingS,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Map View'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OceanColors.seafoamGreen,
                  foregroundColor: OceanColors.pureWhite,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NavigationModeScreen(),
                  ),
                ),
                icon: const Icon(Icons.alt_route),
                label: const Text('Navigation Mode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OceanColors.surface,
                  foregroundColor: OceanColors.pureWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
