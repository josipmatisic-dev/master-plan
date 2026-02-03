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
          _buildConnectionIndicator(context),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(BuildContext context) {
    return Consumer<NMEAProvider>(
      builder: (context, nmea, child) {
        final isConnected = nmea.isConnected;
        final isActive = nmea.isActive;
        final lastError = nmea.lastError;
        
        // Determine indicator color and icon
        Color indicatorColor;
        IconData indicatorIcon;
        String statusText;
        
        if (isConnected) {
          indicatorColor = OceanColors.seafoamGreen;
          indicatorIcon = Icons.link;
          statusText = 'NMEA Connected';
        } else if (isActive) {
          indicatorColor = OceanColors.safetyOrange;
          indicatorIcon = Icons.sync;
          statusText = 'Connecting...';
        } else if (lastError != null) {
          indicatorColor = OceanColors.coralRed;
          indicatorIcon = Icons.link_off;
          statusText = 'Connection Error';
        } else {
          indicatorColor = OceanColors.textDisabled;
          indicatorIcon = Icons.link_off;
          statusText = 'NMEA Disconnected';
        }
        
        return GlassCard(
          padding: GlassCardPadding.small,
          child: InkWell(
            onTap: () => _showConnectionDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  indicatorIcon,
                  color: indicatorColor,
                  size: 20,
                ),
                const SizedBox(width: OceanDimensions.spacingS),
                Text(
                  statusText,
                  style: OceanTextStyles.label.copyWith(color: indicatorColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConnectionDialog(BuildContext context) {
    final nmea = context.read<NMEAProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OceanColors.surface,
        title: const Text('NMEA Connection', style: OceanTextStyles.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${_getStatusText(nmea.status)}',
              style: OceanTextStyles.body,
            ),
            if (nmea.lastError != null) ...[
              const SizedBox(height: OceanDimensions.spacingS),
              Text(
                'Error: ${nmea.lastError!.message}',
                style: OceanTextStyles.body.copyWith(color: OceanColors.coralRed),
              ),
            ],
            if (nmea.lastUpdateTime != null) ...[
              const SizedBox(height: OceanDimensions.spacingS),
              Text(
                'Last Update: ${_formatTime(nmea.lastUpdateTime!)}',
                style: OceanTextStyles.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nmea.lastError != null) {
                nmea.clearError();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          if (!nmea.isConnected)
            ElevatedButton(
              onPressed: () {
                nmea.connect();
                Navigator.of(context).pop();
              },
              child: const Text('Connect'),
            )
          else
            ElevatedButton(
              onPressed: () {
                nmea.disconnect();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OceanColors.coralRed,
              ),
              child: const Text('Disconnect'),
            ),
        ],
      ),
    );
  }

  String _getStatusText(dynamic status) {
    return status.toString().split('.').last;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
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
        backgroundColor: OceanColors.seafoamGreen.withOpacity(0.15),
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
