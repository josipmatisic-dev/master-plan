/// MapScreen - SailStream primary map layout with glass overlays.
library;

// ignore_for_file: public_member_api_docs, prefer_const_constructors, prefer_const_declarations

import 'package:flutter/material.dart' hide Viewport;
import 'package:provider/provider.dart';

import '../providers/map_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/controls/layer_toggle.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/data_displays/wind_widget.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/map/map_webview.dart';
import '../widgets/navigation/compass_widget.dart';
import '../widgets/navigation/navigation_sidebar.dart';
import '../widgets/overlays/wave_overlay.dart';
import '../widgets/overlays/wind_overlay.dart';

/// Primary map screen with layered glass UI.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool isVr = false;
  final List<Offset> _windOffsets = [const Offset(40, 200)];

  void _handleNavSelection(BuildContext context, int index) {
    switch (index) {
      case 1:
        // Map (current)
        break;
      case 2:
        Navigator.of(context).pushNamed('/navigation');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const MapWebView(),
            _buildWindOverlay(context),
            _buildWaveOverlay(context),
            _buildTopBar(),
            _buildDataOrbs(context),
            _buildCompass(context),
            _buildNavigationSidebar(context),
            _buildWindWidgets(),
            _buildLayerToggle(context),
            _buildTimelineScrubber(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: OceanDimensions.spacing,
      left: OceanDimensions.spacing,
      right: OceanDimensions.spacing,
      child: GlassCard(
        padding: GlassCardPadding.small,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('SailStream', style: OceanTextStyles.heading2),
            Icon(Icons.search, color: OceanColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDataOrbs(BuildContext context) {
    return Positioned(
      top: context.isMobile ? 120 : 140,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          DataOrb(
            label: 'SOG',
            value: '12.4',
            unit: 'kts',
            size: DataOrbSize.medium,
            heroTag: 'orb-sog',
          ),
          SizedBox(width: OceanDimensions.spacingL),
          DataOrb(
            label: 'COG',
            value: '85',
            unit: '°',
            size: DataOrbSize.medium,
            subtitle: 'E',
            heroTag: 'orb-cog',
          ),
          SizedBox(width: OceanDimensions.spacingL),
          DataOrb(
            label: 'DEPTH',
            value: '24',
            unit: 'm',
            size: DataOrbSize.medium,
            state: DataOrbState.normal,
            heroTag: 'orb-depth',
          ),
        ],
      ),
    );
  }

  Widget _buildCompass(BuildContext context) {
    return Positioned(
      bottom: context.isMobile ? 32 : 48,
      left: 0,
      right: 0,
      child: Center(
        child: CompassWidget(
          headingDegrees: 42,
          speedKnots: 12.4,
          windKnots: 15.2,
          windDirection: 'N 45°',
          isVrEnabled: isVr,
          onToggleVr: () => setState(() => isVr = !isVr),
        ),
      ),
    );
  }

  Widget _buildNavigationSidebar(BuildContext context) {
    final items = const [
      NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      NavItem(icon: Icons.map_outlined, label: 'Map'),
      NavItem(icon: Icons.alt_route, label: 'Nav Mode'),
      NavItem(icon: Icons.cloud_outlined, label: 'Weather'),
      NavItem(icon: Icons.settings_outlined, label: 'Settings'),
      NavItem(icon: Icons.person_outline, label: 'Profile'),
      NavItem(icon: Icons.directions_boat_outlined, label: 'Vessel'),
    ];

    return Positioned(
      top: 100,
      bottom: 100,
      left: OceanDimensions.spacing,
      child: NavigationSidebar(
        items: items,
        activeIndex: 1,
        onSelected: (index) => _handleNavSelection(context, index),
      ),
    );
  }

  Widget _buildWindWidgets() {
    return Stack(
      children: [
        for (var i = 0; i < _windOffsets.length; i++)
          TrueWindWidget(
            speedKnots: 14.2,
            directionLabel: 'NNE',
            progress: 0.6,
            initialOffset: _windOffsets[i],
            onPositionChanged: (offset) {
              setState(() => _windOffsets[i] = offset);
            },
            editMode: true,
          ),
      ],
    );
  }

  Widget _buildTimelineScrubber(BuildContext context) {
    return Positioned(
      bottom: context.isMobile ? 8 : 24,
      left: OceanDimensions.spacingL,
      right: OceanDimensions.spacingL,
      child: GlassCard(
        padding: GlassCardPadding.small,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.play_arrow, color: OceanColors.pureWhite),
            Text('Forecast Timeline', style: OceanTextStyles.body),
            Icon(Icons.more_horiz, color: OceanColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildWindOverlay(BuildContext context) {
    return Consumer2<WeatherProvider, MapProvider>(
      builder: (_, weather, map, __) {
        if (!weather.isWindVisible || !weather.hasData) {
          return const SizedBox.shrink();
        }
        return WindOverlay(
          windPoints: weather.data.windPoints,
          viewport: map.viewport,
        );
      },
    );
  }

  Widget _buildWaveOverlay(BuildContext context) {
    return Consumer2<WeatherProvider, MapProvider>(
      builder: (_, weather, map, __) {
        if (!weather.isWaveVisible || !weather.hasData) {
          return const SizedBox.shrink();
        }
        return WaveOverlay(
          wavePoints: weather.data.wavePoints,
          viewport: map.viewport,
        );
      },
    );
  }

  Widget _buildLayerToggle(BuildContext context) {
    return Positioned(
      top: context.isMobile ? 120 : 140,
      right: OceanDimensions.spacing,
      child: const LayerToggle(),
    );
  }
}
