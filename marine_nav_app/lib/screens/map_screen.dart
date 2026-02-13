/// MapScreen - SailStream primary map layout with draggable glass overlays.
library;

// ignore_for_file: public_member_api_docs, prefer_const_constructors, prefer_const_declarations

import 'package:flutter/material.dart' hide Viewport;
import 'package:provider/provider.dart';

import '../providers/map_provider.dart';
import '../providers/nmea_provider.dart';
import '../providers/weather_provider.dart';
import '../theme/colors.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../widgets/common/draggable_overlay.dart';
import '../widgets/controls/layer_toggle.dart';
import '../widgets/data_displays/data_orb.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/map/map_webview.dart';
import '../widgets/navigation/compass_widget.dart';
import '../widgets/navigation/navigation_sidebar.dart';
import '../widgets/overlays/wave_overlay.dart';
import '../widgets/overlays/wind_overlay.dart';

/// Primary map screen with draggable layered glass UI.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool isVr = false;

  void _handleNavSelection(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushNamed('/dashboard');
        break;
      case 1:
        break; // already on map
      case 2:
        Navigator.of(context).pushNamed('/navigation');
        break;
      case 3:
        Navigator.of(context).pushNamed('/weather');
        break;
      case 4:
        Navigator.of(context).pushNamed('/settings');
        break;
      case 5:
        Navigator.of(context).pushNamed('/profile');
        break;
      case 6:
        Navigator.of(context).pushNamed('/vessel');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
              const Positioned.fill(child: MapWebView(height: null)),
              _buildWindOverlay(context),
              _buildWaveOverlay(context),
              _buildDraggableTopBar(),
              _buildDraggableDataOrbs(context),
              _buildDraggableCompass(),
              _buildDraggableSidebar(context),
              _buildDraggableWindWidget(),
              _buildDraggableLayerToggle(),
              _buildDraggableTimeline(),
            ],
          ),
        ),
      ),
    );
  }

  // ============ Draggable Widgets ============

  Widget _buildDraggableTopBar() {
    return DraggableOverlay(
      id: 'map_topBar',
      initialPosition: const Offset(16, 8),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 80,
        child: GlassCard(
          padding: GlassCardPadding.small,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'SailStream',
                  style: OceanTextStyles.heading2.copyWith(
                    color: OceanColors.pureWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.search, color: OceanColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableDataOrbs(BuildContext context) {
    final orbSize = context.isMobile ? DataOrbSize.small : DataOrbSize.medium;

    return DraggableOverlay(
      id: 'map_dataOrbs',
      initialPosition: const Offset(16, 70),
      child: Consumer<NMEAProvider>(
        builder: (_, nmea, __) {
          final baseState = nmea.isConnected
              ? DataOrbState.normal
              : DataOrbState.inactive;
          final depth = nmea.currentData?.depthMeters;
          final depthState = nmea.isConnected
              ? (depth != null && depth < 5.0
                  ? DataOrbState.alert
                  : DataOrbState.normal)
              : DataOrbState.inactive;

          return SizedBox(
            width: MediaQuery.of(context).size.width - 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: DataOrb(
                    label: 'SOG',
                    value: nmea.currentData?.speedOverGroundKnots
                            ?.toStringAsFixed(1) ?? '--',
                    unit: 'kts',
                    size: orbSize,
                    state: baseState,
                    heroTag: 'orb-sog',
                  ),
                ),
                const SizedBox(width: OceanDimensions.spacingS),
                Flexible(
                  child: DataOrb(
                    label: 'COG',
                    value: nmea.currentData?.courseOverGroundDegrees
                            ?.toStringAsFixed(0) ?? '--',
                    unit: '°',
                    size: orbSize,
                    state: baseState,
                    heroTag: 'orb-cog',
                  ),
                ),
                const SizedBox(width: OceanDimensions.spacingS),
                Flexible(
                  child: DataOrb(
                    label: 'DEPTH',
                    value: depth?.toStringAsFixed(1) ?? '--',
                    unit: 'm',
                    size: orbSize,
                    state: depthState,
                    heroTag: 'orb-depth',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDraggableCompass() {
    return DraggableOverlay(
      id: 'map_compass',
      initialPosition: const Offset(140, 500),
      child: Consumer<NMEAProvider>(
        builder: (_, nmea, __) {
          final windDeg = nmea.currentData?.windDirectionDegrees;
          final windLabel = windDeg != null
              ? '${_cardinalDirection(windDeg)} ${windDeg.toStringAsFixed(0)}°'
              : '--';
          return CompassWidget(
            headingDegrees:
                nmea.currentData?.courseOverGroundDegrees ?? 0,
            speedKnots:
                nmea.currentData?.speedOverGroundKnots ?? 0,
            windKnots: nmea.currentData?.windSpeedKnots ?? 0,
            windDirection: windLabel,
            isVrEnabled: isVr,
            onToggleVr: () => setState(() => isVr = !isVr),
          );
        },
      ),
    );
  }

  Widget _buildDraggableSidebar(BuildContext context) {
    final items = const [
      NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      NavItem(icon: Icons.map_outlined, label: 'Map'),
      NavItem(icon: Icons.alt_route, label: 'Nav Mode'),
      NavItem(icon: Icons.cloud_outlined, label: 'Weather'),
      NavItem(icon: Icons.settings_outlined, label: 'Settings'),
      NavItem(icon: Icons.person_outline, label: 'Profile'),
      NavItem(icon: Icons.directions_boat_outlined, label: 'Vessel'),
    ];

    return DraggableOverlay(
      id: 'map_sidebar',
      initialPosition: const Offset(0, 200),
      child: NavigationSidebar(
        items: items,
        activeIndex: 1,
        onSelected: (index) => _handleNavSelection(context, index),
      ),
    );
  }

  Widget _buildDraggableWindWidget() {
    return DraggableOverlay(
      id: 'map_wind',
      initialPosition: const Offset(40, 340),
      child: Consumer<NMEAProvider>(
        builder: (_, nmea, __) {
          final windSpeed = nmea.currentData?.windSpeedKnots;
          final windDir = nmea.currentData?.windDirectionDegrees;
          return GlassCard(
            borderRadius: OceanDimensions.radiusM,
            child: SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: ((windSpeed ?? 0) / 40.0).clamp(0.0, 1.0),
                      strokeWidth: 5,
                      backgroundColor:
                          OceanColors.seafoamGreen.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        OceanColors.seafoamGreen,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${windSpeed?.toStringAsFixed(1) ?? '--'} kts',
                        style: OceanTextStyles.bodyLarge.copyWith(
                          color: OceanColors.pureWhite,
                        ),
                      ),
                      const SizedBox(height: OceanDimensions.spacingXS),
                      Text(
                        _cardinalDirection(windDir),
                        style: OceanTextStyles.label.copyWith(
                          color: OceanColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDraggableLayerToggle() {
    return DraggableOverlay(
      id: 'map_layers',
      initialPosition: const Offset(300, 70),
      child: const LayerToggle(),
    );
  }

  Widget _buildDraggableTimeline() {
    return DraggableOverlay(
      id: 'map_timeline',
      initialPosition: Offset(16, MediaQuery.of(context).size.height - 140),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        child: GlassCard(
          padding: GlassCardPadding.small,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.play_arrow, color: OceanColors.pureWhite),
              const SizedBox(width: OceanDimensions.spacingS),
              Flexible(
                child: Text(
                  'Forecast Timeline',
                  style: OceanTextStyles.body.copyWith(
                    color: OceanColors.pureWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: OceanDimensions.spacingS),
              const Icon(Icons.more_horiz, color: OceanColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // ============ Helpers ============

  String _cardinalDirection(double? degrees) {
    if (degrees == null) return '--';
    const dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
                   'S','SSW','SW','WSW','W','WNW','NW','NNW'];
    return dirs[((degrees % 360) / 22.5).round() % 16];
  }

  // ============ Weather Overlays (non-draggable) ============

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
}
