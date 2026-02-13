/// Map WebView placeholder widget.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/map_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive_utils.dart';
import '../glass/glass_card.dart';

/// WebView container for the MapTiler integration.
class MapWebView extends StatefulWidget {
  /// Height of the map container. Null means fill parent.
  final double? height;

  /// Creates the MapWebView widget.
  const MapWebView({
    super.key,
    this.height = 280,
  });

  @override
  State<MapWebView> createState() => _MapWebViewState();
}

class _MapWebViewState extends State<MapWebView> {
  WebViewController? _controller;
  bool _webViewAvailable = true;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance == null) {
      _webViewAvailable = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'MapBridge',
        onMessageReceived: (message) {
          debugPrint('MapBridge: ${message.message}');
        },
      )
      ..loadFlutterAsset('assets/map.html');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, _) {
        final Widget layoutChild = LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              if (!size.isEmpty && size != mapProvider.viewport.size) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  mapProvider.setSize(size);
                });
              }

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: OceanColors.surface,
                  borderRadius: BorderRadius.circular(OceanDimensions.radius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(OceanDimensions.radius),
                  child: Stack(
                    children: [
                      if (_webViewAvailable && _controller != null)
                        WebViewWidget(controller: _controller!)
                      else
                        _buildFallback(),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            OceanDimensions.spacingS,
                          ),
                          child: GlassCard(
                            padding: GlassCardPadding.small,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Map Preview',
                                  style: OceanTextStyles.bodySmall.copyWith(
                                    color: OceanColors.textPrimary,
                                  ),
                                ),
                                OceanDimensions.spacingS.verticalSpace,
                                Text(
                                  'Center: '
                                  '${mapProvider.viewport.center.latitude.toStringAsFixed(2)}, '
                                  '${mapProvider.viewport.center.longitude.toStringAsFixed(2)}',
                                  style: OceanTextStyles.label.copyWith(
                                    color: OceanColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Zoom: '
                                  '${mapProvider.viewport.zoom.toStringAsFixed(1)}',
                                  style: OceanTextStyles.label.copyWith(
                                    color: OceanColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        if (widget.height != null) {
          return SizedBox(height: widget.height, child: layoutChild);
        }
        return layoutChild;
      },
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map,
            size: OceanDimensions.iconXL,
            color: OceanColors.seafoamGreen,
          ),
          OceanDimensions.spacingS.verticalSpace,
          Text(
            'Map View (WebView pending)',
            style: OceanTextStyles.body.copyWith(
              color: OceanColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
