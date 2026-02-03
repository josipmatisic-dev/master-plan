/// Home Screen - Main Navigation Screen
///
/// Demonstrates Ocean Glass design system and provider usage.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cache_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/map_screen.dart';
import '../screens/navigation_mode_screen.dart';
import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/map/map_webview.dart';

/// Home Screen - Main navigation interface
class HomeScreen extends StatelessWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                OceanColors.background,
                OceanColors.surface,
              ],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: EdgeInsets.all(context.responsiveSpacing),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildWelcomeCard(context),
                    OceanDimensions.spacingL.verticalSpace,
                    _buildNavigationShortcuts(context),
                    OceanDimensions.spacingL.verticalSpace,
                    _buildMapPreview(context),
                    OceanDimensions.spacingL.verticalSpace,
                    _buildThemeControls(context),
                    OceanDimensions.spacingL.verticalSpace,
                    _buildSettingsCard(context),
                    OceanDimensions.spacingL.verticalSpace,
                    _buildCacheCard(context),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationShortcuts(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Navigate to Screens', style: OceanTextStyles.heading2),
          OceanDimensions.spacingS.verticalSpace,
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
                  MaterialPageRoute(builder: (_) => const NavigationModeScreen()),
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

  /// Build app bar
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: context.isMobile ? 120 : 160,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'SailStream',
          style: OceanTextStyles.heading1.copyWith(
            color: OceanColors.textPrimary,
            fontSize: context.isMobile ? 24 : 32,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  /// Build welcome card
  Widget _buildWelcomeCard(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sailing,
            size: OceanDimensions.iconXL,
            color: OceanColors.seafoamGreen,
          ),
          OceanDimensions.spacingM.verticalSpace,
          const Text(
            'Ocean Glass Design',
            style: OceanTextStyles.heading2,
          ),
          OceanDimensions.spacingS.verticalSpace,
          const Text(
            'Phase 0 Foundation Complete ✅',
            style: OceanTextStyles.body,
          ),
        ],
      ),
    );
  }

  /// Build map preview card
  Widget _buildMapPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Map Preview',
          style: OceanTextStyles.heading2,
        ),
        OceanDimensions.spacingS.verticalSpace,
        const MapWebView(),
      ],
    );
  }

  /// Build theme controls
  Widget _buildThemeControls(BuildContext context) {
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

  /// Build settings card
  Widget _buildSettingsCard(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: OceanTextStyles.heading2,
              ),
              OceanDimensions.spacing.verticalSpace,
              _buildSettingRow(
                'Speed Unit',
                settings.speedUnit.name.toUpperCase(),
              ),
              _buildSettingRow(
                'Distance Unit',
                settings.distanceUnit.name,
              ),
              _buildSettingRow(
                'Language',
                settings.language,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build cache info card
  Widget _buildCacheCard(BuildContext context) {
    return Consumer<CacheProvider>(
      builder: (context, cache, _) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cache Status',
                style: OceanTextStyles.heading2,
              ),
              OceanDimensions.spacing.verticalSpace,
              _buildSettingRow(
                'Status',
                cache.isInitialized ? 'Initialized' : 'Not Ready',
              ),
              _buildSettingRow(
                'Size',
                '${cache.cacheSizeMB.toStringAsFixed(2)} MB',
              ),
              _buildSettingRow(
                'Entries',
                cache.stats.entryCount.toString(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build setting row
  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: OceanDimensions.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: OceanTextStyles.body.copyWith(
              color: OceanColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: OceanTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
