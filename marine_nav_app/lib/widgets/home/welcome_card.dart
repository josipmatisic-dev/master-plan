/// Welcome Card Widget
///
/// Displays welcome message and phase status.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Welcome card for home screen
class WelcomeCard extends StatelessWidget {
  /// Creates a welcome card.
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sailing,
            size: OceanDimensions.iconXL,
            color: OceanColors.seafoamGreen,
          ),
          SizedBox(height: OceanDimensions.spacingM),
          Text(
            'Ocean Glass Design',
            style: OceanTextStyles.heading2,
          ),
          SizedBox(height: OceanDimensions.spacingS),
          Text(
            'Phase 0 Foundation Complete ✅',
            style: OceanTextStyles.body,
          ),
        ],
      ),
    );
  }
}
