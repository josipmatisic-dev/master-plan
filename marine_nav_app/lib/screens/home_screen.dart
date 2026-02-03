/// Home Screen - Main Navigation Screen
///
/// Demonstrates Ocean Glass design system and provider usage.
library;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/home/cache_info_card.dart';
import '../widgets/home/navigation_shortcuts.dart';
import '../widgets/home/settings_card.dart';
import '../widgets/home/theme_controls.dart';
import '../widgets/home/welcome_card.dart';
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
                    const WelcomeCard(),
                    OceanDimensions.spacingL.verticalSpace,
                    const NavigationShortcuts(),
                    OceanDimensions.spacingL.verticalSpace,
                    _buildMapPreview(context),
                    OceanDimensions.spacingL.verticalSpace,
                    const ThemeControls(),
                    OceanDimensions.spacingL.verticalSpace,
                    const SettingsCard(),
                    OceanDimensions.spacingL.verticalSpace,
                    const CacheInfoCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
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
}
