/// Weather Map View — composite widget combining map + timeline scrubber.
///
/// A reusable widget that provides a [MapWebView] with a [TimelineScrubber]
/// overlay at the bottom. Drop into any screen that needs a weather-aware map.
library;

import 'package:flutter/material.dart';

import '../map/weather_layer_stack.dart';
import 'timeline_scrubber.dart';

/// Combined map + timeline scrubber for weather-aware screens.
///
/// Usage:
/// ```dart
/// const WeatherMapView(height: 300) // Fixed-height with scrubber
/// const WeatherMapView()             // Fill parent with scrubber
/// ```
class WeatherMapView extends StatelessWidget {
  /// Height of the widget. Null = fill parent.
  final double? height;

  /// Whether to show the timeline scrubber overlay.
  final bool showScrubber;

  /// Creates a weather map view.
  const WeatherMapView({
    super.key,
    this.height,
    this.showScrubber = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Stack(
      children: [
        const Positioned.fill(
          child: WeatherLayerStack(height: null),
        ),
        if (showScrubber)
          const Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: TimelineScrubber(),
          ),
      ],
    );

    if (height != null) {
      return SizedBox(height: height, child: content);
    }
    return content;
  }
}
