import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/settings/nmea_settings_card.dart';

/// Settings screen for configuring app preferences and NMEA connection.
class SettingsScreen extends StatelessWidget {
  /// Creates a settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: OceanColors.deepNavy,
        title: const Text('Settings', style: OceanTextStyles.heading2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OceanColors.pureWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: OceanColors.deepNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OceanDimensions.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NMEASettingsCard(),
              const SizedBox(height: OceanDimensions.spacingL),
              _buildGeneralSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('General', style: OceanTextStyles.heading2),
          const SizedBox(height: OceanDimensions.spacing),
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return DropdownButtonFormField<SpeedUnit>(
                initialValue: settings.speedUnit,
                style: OceanTextStyles.body,
                dropdownColor: OceanColors.surface,
                decoration: InputDecoration(
                  labelText: 'Speed Unit',
                  labelStyle: OceanTextStyles.label
                      .copyWith(color: OceanColors.textDisabled),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(OceanDimensions.radiusS),
                    borderSide: BorderSide(
                        color: OceanColors.textDisabled.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(OceanDimensions.radiusS),
                    borderSide: const BorderSide(
                        color: OceanColors.seafoamGreen, width: 2),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SpeedUnit.knots,
                    child: Text('Knots'),
                  ),
                  DropdownMenuItem(
                    value: SpeedUnit.mph,
                    child: Text('Miles per hour'),
                  ),
                  DropdownMenuItem(
                    value: SpeedUnit.kph,
                    child: Text('Kilometers per hour'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.setSpeedUnit(value);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
