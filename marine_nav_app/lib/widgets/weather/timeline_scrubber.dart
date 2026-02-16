/// Timeline Controls — reusable forecast timeline control widget.
///
/// Renders a horizontal timeline control bar with navigation and playback controls.
/// Features:
///   - Previous Frame button (IconButton)
///   - Play/Pause button (IconButton, prominent)
///   - Next Frame button (IconButton)
///   - Scrubber/Slider (Expanded)
///   - Time Label (Text)
///
/// Wired to [TimelineProvider] and themed with holographic glass style.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/timeline_provider.dart';
import '../../providers/weather_provider.dart';
import '../glass/glass_card.dart';

/// Timeline Controls for stepping through weather forecast frames.
///
/// Shows previous/play/pause/next buttons, slider, and time label.
/// Requires [TimelineProvider] and [WeatherProvider] in the tree.
class TimelineScrubber extends StatelessWidget {
  /// Creates a timeline controls widget.
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Previous Frame button
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: cs.primary,
                  size: 20,
                ),
                onPressed: timeline.previousFrame,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Previous Frame',
              ),
              const SizedBox(width: 4),
              // Play/Pause button (prominent)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    timeline.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: cs.primary,
                    size: 24,
                  ),
                  onPressed: timeline.togglePlayback,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  tooltip: timeline.isPlaying ? 'Pause' : 'Play',
                ),
              ),
              const SizedBox(width: 4),
              // Next Frame button
              IconButton(
                icon: Icon(
                  Icons.skip_next,
                  color: cs.primary,
                  size: 20,
                ),
                onPressed: timeline.nextFrame,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Next Frame',
              ),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
