/// Trip recording control card — start/stop recording with live stats.
///
/// Provides a compact control interface for [TripLogService] with
/// recording toggle, distance/time/speed readouts, and export actions.
library;

import 'package:flutter/material.dart';

import '../../models/trip_log.dart';
import '../../theme/holographic_colors.dart';

/// Card widget for controlling trip recording and viewing active stats.
class TripControlCard extends StatelessWidget {
  /// Whether a trip is currently being recorded.
  final bool isRecording;

  /// The currently active trip (null if not recording).
  final TripLog? activeTrip;

  /// List of saved (completed) trips.
  final List<TripLog> savedTrips;

  /// Whether to use holographic theme styling.
  final bool isHolographic;

  /// Called when the user taps the start/stop button.
  final VoidCallback? onToggleRecording;

  /// Called when the user requests GPX export for a trip.
  final ValueChanged<TripLog>? onExportGpx;

  /// Called when the user requests KML export for a trip.
  final ValueChanged<TripLog>? onExportKml;

  /// Creates a [TripControlCard].
  const TripControlCard({
    super.key,
    this.isRecording = false,
    this.activeTrip,
    this.savedTrips = const [],
    this.isHolographic = false,
    this.onToggleRecording,
    this.onExportGpx,
    this.onExportKml,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = isHolographic ? HolographicColors.electricBlue : cs.primary;
    final recordColor = isRecording
        ? (isHolographic ? HolographicColors.neonMagenta : const Color(0xFFFF6B6B))
        : accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + record toggle
        Row(
          children: [
            Icon(Icons.route, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Trip Log',
                style: tt.titleMedium?.copyWith(color: accent),
              ),
            ),
            _RecordButton(
              isRecording: isRecording,
              color: recordColor,
              isHolographic: isHolographic,
              onTap: onToggleRecording,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Active trip stats
        if (isRecording && activeTrip != null)
          _buildActiveTripStats(context, activeTrip!, cs, tt, recordColor)
        else if (!isRecording && savedTrips.isEmpty)
          Text(
            'Tap record to start logging your trip',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          )
        else if (!isRecording && savedTrips.isNotEmpty)
          _buildLastTrip(context, savedTrips.last, cs, tt, accent),
      ],
    );
  }

  Widget _buildActiveTripStats(BuildContext context, TripLog trip,
      ColorScheme cs, TextTheme tt, Color accent) {
    final duration = trip.duration;
    final durStr = '${duration.inHours}h '
        '${(duration.inMinutes % 60).toString().padLeft(2, '0')}m';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatChip(
              label: 'Distance',
              value: '${trip.distanceNm.toStringAsFixed(1)} nm',
              color: accent,
            ),
            _StatChip(
              label: 'Duration',
              value: durStr,
              color: accent,
            ),
            _StatChip(
              label: 'Avg',
              value: '${trip.avgSpeedKnots.toStringAsFixed(1)} kts',
              color: accent,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${trip.waypoints.length} waypoints',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              'Recording…',
              style: tt.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLastTrip(BuildContext context, TripLog trip, ColorScheme cs,
      TextTheme tt, Color accent) {
    final duration = trip.duration;
    final durStr = '${duration.inHours}h '
        '${(duration.inMinutes % 60).toString().padLeft(2, '0')}m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                trip.name,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${savedTrips.length} trip${savedTrips.length == 1 ? '' : 's'}',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${trip.distanceNm.toStringAsFixed(1)} nm  •  $durStr',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            if (onExportGpx != null)
              GestureDetector(
                onTap: () => onExportGpx!(trip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('GPX',
                      style: tt.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
            if (onExportKml != null)
              GestureDetector(
                onTap: () => onExportKml!(trip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('KML',
                      style: tt.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Animated record button with pulsing glow when active.
class _RecordButton extends StatefulWidget {
  final bool isRecording;
  final Color color;
  final bool isHolographic;
  final VoidCallback? onTap;

  const _RecordButton({
    required this.isRecording,
    required this.color,
    required this.isHolographic,
    this.onTap,
  });

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.isRecording) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isRecording
                  ? widget.color.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(color: widget.color, width: 2),
              boxShadow: widget.isRecording
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3 * _scale.value),
                        blurRadius: 8 * _scale.value,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isRecording
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// Small stat chip for displaying a label/value pair.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value,
            style: tt.bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        Text(label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}
