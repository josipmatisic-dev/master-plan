/// Map WebView placeholder widget.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/map_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive_utils.dart';
import '../glass/glass_card.dart';

/// Placeholder widget for the MapTiler WebView container.
class MapWebView extends StatelessWidget {
  /// Height of the map container.
  final double height;

  /// Creates the MapWebView widget.
  const MapWebView({
    super.key,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, _) {
        return SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              if (size != mapProvider.viewport.size) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  mapProvider.setSize(size);
                });
              }

              return GlassCard(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: OceanColors.surface,
                    borderRadius: BorderRadius.circular(OceanDimensions.radius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map,
                        size: OceanDimensions.iconXL,
                        color: OceanColors.seafoamGreen,
                      ),
                      OceanDimensions.spacingS.verticalSpace,
                      const Text(
                        'Map View (WebView pending)',
                        style: OceanTextStyles.body,
                      ),
                      OceanDimensions.spacingS.verticalSpace,
                      Text(
                        'Center: ${mapProvider.viewport.center.latitude.toStringAsFixed(2)}, '
                        '${mapProvider.viewport.center.longitude.toStringAsFixed(2)}',
                        style: OceanTextStyles.label,
                      ),
                      Text(
                        'Zoom: ${mapProvider.viewport.zoom.toStringAsFixed(1)}',
                        style: OceanTextStyles.label,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
