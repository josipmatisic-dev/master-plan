/// Layer toggle widget for weather overlay visibility control.
///
/// Provides toggle buttons for each weather overlay layer
/// (wind, wave) with visual state indicators.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/weather_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Toggle control for weather overlay layers.
///
/// Displays a compact glass card with toggle buttons for each
/// available weather layer. Reads from and writes to
/// [WeatherProvider].
///
/// Usage:
/// ```dart
/// LayerToggle() // Placed inside a Stack over the map.
/// ```
class LayerToggle extends StatelessWidget {
  /// Creates a layer toggle widget.
  const LayerToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (_, weather, __) {
        return GlassCard(
          padding: GlassCardPadding.small,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleRow(
                icon: Icons.air,
                label: 'Wind',
                isActive: weather.isWindVisible,
                onTap: () => weather.toggleLayer(WeatherLayer.wind),
              ),
              const SizedBox(height: OceanDimensions.spacingXS),
              _buildToggleRow(
                icon: Icons.waves,
                label: 'Waves',
                isActive: weather.isWaveVisible,
                onTap: () => weather.toggleLayer(WeatherLayer.wave),
              ),
              if (weather.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: OceanDimensions.spacingXS),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        OceanColors.seafoamGreen,
                      ),
                    ),
                  ),
                ),
              if (weather.isStale && weather.hasData)
                Padding(
                  padding:
                      const EdgeInsets.only(top: OceanDimensions.spacingXS),
                  child: Text(
                    '${weather.data.age.inMinutes}m old',
                    style: OceanTextStyles.label.copyWith(
                      color: OceanColors.safetyOrange,
                    ),
                  ),
                ),
              if (weather.errorMessage != null && !weather.hasData)
                const Padding(
                  padding: EdgeInsets.only(top: OceanDimensions.spacingXS),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: OceanColors.coralRed,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color:
                isActive ? OceanColors.seafoamGreen : OceanColors.textSecondary,
          ),
          const SizedBox(width: OceanDimensions.spacingXS),
          Text(
            label,
            style: OceanTextStyles.label.copyWith(
              color:
                  isActive ? OceanColors.pureWhite : OceanColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
