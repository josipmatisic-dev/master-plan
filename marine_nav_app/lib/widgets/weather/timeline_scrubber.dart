/// Timeline Scrubber — reusable forecast timeline control.
///
/// Renders a horizontal time scrubber with play/pause and frame labels.
/// Wired to [TimelineProvider] and themed with holographic glass style.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/timeline_provider.dart';
import '../../providers/weather_provider.dart';
import '../glass/glass_card.dart';

/// Scrubber for stepping through weather forecast frames.
///
/// Shows play/pause button, slider, and time label.
/// Requires [TimelineProvider] and [WeatherProvider] in the tree.
class TimelineScrubber extends StatelessWidget {
  /// Creates a timeline scrubber widget.
  const TimelineScrubber({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer2<TimelineProvider, WeatherProvider>(
      builder: (context, timeline, weather, _) {
        if (!timeline.hasFrames) return const SizedBox.shrink();

        return GlassCard(
          padding: GlassCardPadding.small,
          child: Row(
            children: [
              // Play/Pause button
              IconButton(
                icon: Icon(
                  timeline.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: cs.primary,
                  size: 22,
                ),
                onPressed: timeline.togglePlayback,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: cs.primary,
                    inactiveTrackColor: cs.onSurface.withValues(alpha: 0.15),
                    thumbColor: cs.primary,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    trackHeight: 3,
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: timeline.scrubberPosition,
                    onChanged: timeline.setScrubberPosition,
                  ),
                ),
              ),
              // Time label
              SizedBox(
                width: 48,
                child: Text(
                  timeline.activeTimeLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
