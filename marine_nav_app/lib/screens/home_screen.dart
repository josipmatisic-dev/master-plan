/// Home Screen - Main Navigation Screen
///
/// Theme-aware home screen that adapts between Ocean Glass and
/// Holographic Cyberpunk styles with particle effects.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/holographic_colors.dart';
import '../theme/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/effects/holographic_shimmer.dart';
import '../widgets/effects/particle_background.dart';
import '../widgets/effects/scan_line_effect.dart';
import '../widgets/effects/scroll_reveal.dart';
import '../widgets/home/cache_info_card.dart';
import '../widgets/home/navigation_shortcuts.dart';
import '../widgets/home/settings_card.dart';
import '../widgets/home/theme_controls.dart';
import '../widgets/home/welcome_card.dart';
import '../widgets/map/weather_layer_stack.dart';

/// Home Screen - Main navigation interface
class HomeScreen extends StatelessWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: isHolographic
                    ? HolographicColors.deepSpaceBackground
                    : const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          OceanColors.background,
                          OceanColors.surface,
                        ],
                      ),
              ),
            ),
            // Particle background (holographic only — interactive)
            if (isHolographic)
              const RepaintBoundary(
                  child: ParticleBackground(interactive: true)),
            // Scan line effect (holographic only)
            if (isHolographic) const ScanLineEffect(),
            // Content
            CustomScrollView(
              slivers: [
                _buildAppBar(context, isHolographic, colorScheme),
                SliverPadding(
                  padding: EdgeInsets.all(context.responsiveSpacing),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ScrollReveal(
                        child: HolographicShimmer(
                          enabled: isHolographic,
                          child: const WelcomeCard(),
                        ),
                      ),
                      OceanDimensions.spacingL.verticalSpace,
                      const ScrollReveal(
                        delay: Duration(milliseconds: 100),
                        child: NavigationShortcuts(),
                      ),
                      OceanDimensions.spacingL.verticalSpace,
                      _buildMapPreview(context, colorScheme),
                      OceanDimensions.spacingL.verticalSpace,
                      const ScrollReveal(
                        delay: Duration(milliseconds: 200),
                        child: ThemeControls(),
                      ),
                      OceanDimensions.spacingL.verticalSpace,
                      const ScrollReveal(
                        delay: Duration(milliseconds: 300),
                        child: SettingsCard(),
                      ),
                      OceanDimensions.spacingL.verticalSpace,
                      const ScrollReveal(
                        delay: Duration(milliseconds: 400),
                        child: CacheInfoCard(),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build app bar
  Widget _buildAppBar(
    BuildContext context,
    bool isHolographic,
    ColorScheme colorScheme,
  ) {
    return SliverAppBar(
      expandedHeight: context.isMobile ? 120 : 160,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'SailStream',
          style: isHolographic
              ? OceanTextStyles.heading1.copyWith(
                  color: HolographicColors.electricBlue,
                  fontSize: context.isMobile ? 24 : 32,
                  shadows: [
                    Shadow(
                      color:
                          HolographicColors.electricBlue.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                    Shadow(
                      color: HolographicColors.neonCyan.withValues(alpha: 0.3),
                      blurRadius: 24,
                    ),
                  ],
                )
              : OceanTextStyles.heading1.copyWith(
                  color: OceanColors.textPrimary,
                  fontSize: context.isMobile ? 24 : 32,
                ),
        ),
        centerTitle: true,
      ),
    );
  }

  /// Build map preview card
  Widget _buildMapPreview(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map Preview',
          style: OceanTextStyles.heading2.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        OceanDimensions.spacingS.verticalSpace,
        const WeatherLayerStack(height: 200),
      ],
    );
  }
}
