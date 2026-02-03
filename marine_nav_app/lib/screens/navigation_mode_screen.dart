import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs, prefer_const_constructors, prefer_const_declarations

import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/map/map_webview.dart';
import '../widgets/navigation/navigation_sidebar.dart';

/// Navigation mode screen displaying route info and actions.
class NavigationModeScreen extends StatelessWidget {
  const NavigationModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <NavItem>[
      NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      NavItem(icon: Icons.map_outlined, label: 'Map'),
      NavItem(icon: Icons.alt_route, label: 'Route'),
      NavItem(icon: Icons.settings_outlined, label: 'Settings'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const MapWebView(),
            _buildTopBar(context),
            _buildDataOrbsRow(context),
            _buildRouteInfoCard(context),
            _buildActionBar(context),
            Positioned(
              top: 80,
              bottom: 80,
              left: OceanDimensions.spacing,
              child: NavigationSidebar(
                items: items,
                activeIndex: 2,
                onSelected: (index) => _handleNavSelection(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: OceanDimensions.spacing,
      left: OceanDimensions.spacing,
      child: GlassCard(
        padding: GlassCardPadding.small,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: OceanColors.pureWhite),
              onPressed: () => Navigator.of(context).pushNamed('/map'),
            ),
            const SizedBox(width: OceanDimensions.spacingS),
            const Text('Navigation Mode', style: OceanTextStyles.heading2),
          ],
        ),
      ),
    );
  }

  void _handleNavSelection(BuildContext context, int index) {
    switch (index) {
      case 1:
        Navigator.of(context).pushNamed('/map');
        break;
      case 2:
        // Current screen
        break;
      default:
        break;
    }
  }

  Widget _buildDataOrbsRow(BuildContext context) {
    return Positioned(
      top: context.isMobile ? 80 : 120,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          DataOrb(
            label: 'SOG',
            value: '13.1',
            unit: 'kts',
            size: DataOrbSize.large,
            heroTag: 'orb-sog',
          ),
          SizedBox(width: OceanDimensions.spacingL),
          DataOrb(
            label: 'COG',
            value: '078',
            unit: '°',
            size: DataOrbSize.large,
            heroTag: 'orb-cog',
          ),
          SizedBox(width: OceanDimensions.spacingL),
          DataOrb(
            label: 'DEPTH',
            value: '18',
            unit: 'm',
            size: DataOrbSize.large,
            state: DataOrbState.alert,
            heroTag: 'orb-depth',
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: OceanDimensions.spacingL,
      right: OceanDimensions.spacingL,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Next: Waypoint 1', style: OceanTextStyles.heading2),
            SizedBox(height: OceanDimensions.spacingS),
            Text('Distance: 2.4 nm', style: OceanTextStyles.body),
            SizedBox(height: OceanDimensions.spacingXS),
            Text('ETA: 19 min', style: OceanTextStyles.body),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Positioned(
      bottom: OceanDimensions.spacing,
      left: OceanDimensions.spacing,
      right: OceanDimensions.spacing,
      child: GlassCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(' + Route'),
            _actionButton('Mark Position'),
            _actionButton('Track'),
            _actionButton('Alerts'),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: OceanColors.seafoamGreen.withValues(alpha: 0.15),
        foregroundColor: OceanColors.pureWhite,
        padding: const EdgeInsets.symmetric(
          vertical: OceanDimensions.spacingS,
          horizontal: OceanDimensions.spacing,
        ),
      ),
      onPressed: () {},
      child: Text(label, style: OceanTextStyles.labelLarge),
    );
  }
}
