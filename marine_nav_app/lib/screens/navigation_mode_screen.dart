import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ignore_for_file: public_member_api_docs, prefer_const_constructors, prefer_const_declarations

import '../providers/nmea_provider.dart';
import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/map/map_webview.dart';
import '../widgets/navigation/navigation_sidebar.dart';
import '../widgets/navigation/nmea_connection_widget.dart';

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
      right: OceanDimensions.spacing,
      child: Row(
        children: [
          GlassCard(
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
          const Spacer(),
          const NMEAConnectionIndicator(),
        ],
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
      case 3:
        Navigator.of(context).pushNamed('/settings');
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
      child: Consumer<NMEAProvider>(
        builder: (context, nmea, child) {
          final data = nmea.currentData;
          final isConnected = nmea.isConnected;
          
          // Extract values from NMEA data or use fallback
          final sog = data?.gpvtg?.speedKnots?.toStringAsFixed(1) ?? '--';
          final cog = data?.gprmc?.trackTrue?.toStringAsFixed(0) ?? '--';
          final depth = data?.dpt?.depthMeters.toStringAsFixed(1) ?? '--';
          
          // Determine states based on connection and data
          final sogState = isConnected ? DataOrbState.normal : DataOrbState.inactive;
          final cogState = isConnected ? DataOrbState.normal : DataOrbState.inactive;
          
          // Depth alert if shallow (< 5m) or unknown
          final depthState = !isConnected 
              ? DataOrbState.inactive
              : (data?.dpt != null && data!.dpt!.depthMeters < 5.0)
                  ? DataOrbState.alert
                  : DataOrbState.normal;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DataOrb(
                label: 'SOG',
                value: sog,
                unit: 'kts',
                size: DataOrbSize.large,
                state: sogState,
                heroTag: 'orb-sog',
              ),
              const SizedBox(width: OceanDimensions.spacingL),
              DataOrb(
                label: 'COG',
                value: cog,
                unit: '°',
                size: DataOrbSize.large,
                state: cogState,
                heroTag: 'orb-cog',
              ),
              const SizedBox(width: OceanDimensions.spacingL),
              DataOrb(
                label: 'DEPTH',
                value: depth,
                unit: 'm',
                size: DataOrbSize.large,
                state: depthState,
                heroTag: 'orb-depth',
              ),
            ],
          );
        },
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
