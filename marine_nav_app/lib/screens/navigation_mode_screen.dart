import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ignore_for_file: public_member_api_docs, prefer_const_constructors, prefer_const_declarations

import '../providers/nmea_provider.dart';
import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/common/draggable_overlay.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/map/map_webview.dart';
import '../widgets/navigation/navigation_sidebar.dart';
import '../widgets/navigation/nmea_connection_widget.dart';

/// Navigation mode screen with fullscreen map and draggable overlays.
class NavigationModeScreen extends StatefulWidget {
  const NavigationModeScreen({super.key});

  @override
  State<NavigationModeScreen> createState() => _NavigationModeScreenState();
}

class _NavigationModeScreenState extends State<NavigationModeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
              const Positioned.fill(child: MapWebView(height: null)),
              _buildTopBar(context),
              _buildDataOrbsRow(context),
              _buildSidebar(context),
              _buildRouteInfoCard(context),
              _buildActionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return DraggableOverlay(
      id: 'nav_topBar',
      initialPosition: const Offset(16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassCard(
            padding: GlassCardPadding.small,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: OceanColors.pureWhite),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Navigation',
                  style: OceanTextStyles.heading2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const NMEAConnectionIndicator(),
        ],
      ),
    );
  }

  Widget _buildDataOrbsRow(BuildContext context) {
    final orbSize = context.isMobile ? DataOrbSize.small : DataOrbSize.medium;
    final width = MediaQuery.of(context).size.width - 80;

    return DraggableOverlay(
      id: 'nav_dataOrbs',
      initialPosition: const Offset(16, 65),
      child: SizedBox(
        width: width,
        child: Consumer<NMEAProvider>(
          builder: (context, nmea, _) {
            final data = nmea.currentData;
            final connected = nmea.isConnected;
            final sog = data?.gpvtg?.speedKnots?.toStringAsFixed(1) ?? '--';
            final cog = data?.gprmc?.trackTrue?.toStringAsFixed(0) ?? '--';
            final depth = data?.dpt?.depthMeters.toStringAsFixed(1) ?? '--';
            final depthState = !connected
                ? DataOrbState.inactive
                : (data?.dpt != null && data!.dpt!.depthMeters < 5.0)
                    ? DataOrbState.alert
                    : DataOrbState.normal;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: DataOrb(
                    label: 'SOG',
                    value: sog,
                    unit: 'kts',
                    size: orbSize,
                    state:
                        connected ? DataOrbState.normal : DataOrbState.inactive,
                    heroTag: 'nav-orb-sog',
                  ),
                ),
                Flexible(
                  child: DataOrb(
                    label: 'COG',
                    value: cog,
                    unit: '°',
                    size: orbSize,
                    state:
                        connected ? DataOrbState.normal : DataOrbState.inactive,
                    heroTag: 'nav-orb-cog',
                  ),
                ),
                Flexible(
                  child: DataOrb(
                    label: 'DEPTH',
                    value: depth,
                    unit: 'm',
                    size: orbSize,
                    state: depthState,
                    heroTag: 'nav-orb-depth',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    const items = <NavItem>[
      NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      NavItem(icon: Icons.map_outlined, label: 'Map'),
      NavItem(icon: Icons.alt_route, label: 'Route'),
      NavItem(icon: Icons.settings_outlined, label: 'Settings'),
    ];

    return DraggableOverlay(
      id: 'nav_sidebar',
      initialPosition: const Offset(0, 180),
      child: NavigationSidebar(
        items: items,
        activeIndex: 2,
        onSelected: (index) => _handleNavSelection(context, index),
      ),
    );
  }

  Widget _buildRouteInfoCard(BuildContext context) {
    final bottom = MediaQuery.of(context).size.height - 240;

    return DraggableOverlay(
      id: 'nav_routeInfo',
      initialPosition: Offset(24, bottom),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        child: Consumer<NMEAProvider>(
          builder: (context, nmea, _) {
            final pos = nmea.currentData?.position;
            final sog = nmea.currentData?.speedOverGroundKnots ?? 0.0;
            final eta = sog > 0 ? (2.4 / sog * 60) : 0.0;

            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Next: Waypoint 1', style: OceanTextStyles.heading2),
                  SizedBox(height: OceanDimensions.spacingXS),
                  Text('Distance: 2.4 nm', style: OceanTextStyles.bodySmall),
                  Text('ETA: ${eta.toStringAsFixed(0)} min',
                      style: OceanTextStyles.bodySmall),
                  Text(
                    'Pos: ${pos?.latitude.toStringAsFixed(4) ?? 'N/A'}, '
                    '${pos?.longitude.toStringAsFixed(4) ?? 'N/A'}',
                    style: OceanTextStyles.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).size.height - 130;

    return DraggableOverlay(
      id: 'nav_actions',
      initialPosition: Offset(16, bottom),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        child: GlassCard(
          padding: GlassCardPadding.small,
          child: Wrap(
            spacing: OceanDimensions.spacingS,
            runSpacing: OceanDimensions.spacingS,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _btn('+ Route', cs,
                  () => _snack(context, 'Route creation coming soon')),
              _btn('Mark', cs, () => _markPosition(context)),
              _btn('Track', cs, () => _snack(context, 'Tracking toggled')),
              _btn('Alerts', cs, () => _snack(context, 'No active alerts')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, ColorScheme cs, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary.withValues(alpha: 0.15),
        foregroundColor: cs.onSurface,
        padding: const EdgeInsets.symmetric(
          vertical: OceanDimensions.spacingS,
          horizontal: OceanDimensions.spacingM,
        ),
      ),
      onPressed: onPressed,
      child: Text(label, style: OceanTextStyles.labelLarge),
    );
  }

  void _handleNavSelection(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushNamed('/dashboard');
        break;
      case 1:
        Navigator.of(context).pushNamed('/map');
        break;
      case 2:
        break; // already here
      case 3:
        Navigator.of(context).pushNamed('/settings');
        break;
    }
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _markPosition(BuildContext ctx) {
    final nmea = ctx.read<NMEAProvider>().currentData;
    final msg = nmea?.position != null
        ? 'Waypoint marked at ${nmea!.position!.latitude.toStringAsFixed(4)}, ${nmea.position!.longitude.toStringAsFixed(4)}'
        : 'No position data available';
    _snack(ctx, msg);
  }
}
