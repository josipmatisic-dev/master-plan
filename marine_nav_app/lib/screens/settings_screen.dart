import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/holographic_colors.dart';
import '../theme/text_styles.dart';
import '../theme/theme_variant.dart';
import '../widgets/effects/holographic_shimmer.dart';
import '../widgets/effects/particle_background.dart';
import '../widgets/effects/scan_line_effect.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/settings/nmea_settings_card.dart';

/// Settings screen for configuring app preferences and NMEA connection.
class SettingsScreen extends StatelessWidget {
  /// Creates a settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isHolographic = context.watch<ThemeProvider>().isHolographic;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isHolographic
            ? HolographicColors.cosmicBlack
            : OceanColors.deepNavy,
        title: Text(
          'Settings',
          style: OceanTextStyles.heading2.copyWith(
            color: isHolographic ? HolographicColors.electricBlue : null,
            shadows: isHolographic
                ? [
                    Shadow(
                      color:
                          HolographicColors.electricBlue.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OceanColors.pureWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor:
          isHolographic ? HolographicColors.cosmicBlack : OceanColors.deepNavy,
      body: Stack(
        children: [
          if (isHolographic) ...[
            Container(
              decoration: const BoxDecoration(
                gradient: HolographicColors.deepSpaceBackground,
              ),
            ),
            const IgnorePointer(
              child: RepaintBoundary(
                child: ParticleBackground(interactive: false),
              ),
            ),
            const ScanLineEffect(),
          ],
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(OceanDimensions.spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HolographicShimmer(
                    enabled: isHolographic,
                    child: const NMEASettingsCard(),
                  ),
                  const SizedBox(height: OceanDimensions.spacingL),
                  HolographicShimmer(
                    enabled: isHolographic,
                    child: _buildThemeSection(context),
                  ),
                  const SizedBox(height: OceanDimensions.spacingL),
                  HolographicShimmer(
                    enabled: isHolographic,
                    child: _buildGeneralSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildThemeSection(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme', style: OceanTextStyles.heading2),
          const SizedBox(height: OceanDimensions.spacing),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return DropdownButtonFormField<ThemeVariant>(
                initialValue: themeProvider.themeVariant,
                style: OceanTextStyles.body,
                dropdownColor: OceanColors.surface,
                decoration: InputDecoration(
                  labelText: 'Theme Variant',
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
                items: ThemeVariant.values.map((variant) {
                  return DropdownMenuItem(
                    value: variant,
                    child: Text(variant.displayName),
                  );
                }).toList(),
                onChanged: (ThemeVariant? value) {
                  if (value != null) {
                    themeProvider.setThemeVariant(value);
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
