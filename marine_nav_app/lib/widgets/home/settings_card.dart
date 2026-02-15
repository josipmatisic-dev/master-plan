/// Settings Card Widget
///
/// Displays current settings information.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../common/setting_row.dart';
import '../glass/glass_card.dart';

/// Settings card for home screen
class SettingsCard extends StatelessWidget {
  /// Creates a settings card.
  const SettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: OceanTextStyles.heading2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: OceanDimensions.spacing),
              SettingRow(
                label: 'Speed Unit',
                value: settings.speedUnit.name.toUpperCase(),
              ),
              SettingRow(
                label: 'Distance Unit',
                value: settings.distanceUnit.name,
              ),
              SettingRow(
                label: 'Language',
                value: settings.language,
              ),
            ],
          ),
        );
      },
    );
  }
}
