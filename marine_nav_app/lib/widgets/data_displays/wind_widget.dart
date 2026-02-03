/// TrueWindWidget - Draggable wind info bubble.
///
/// Shows wind speed/direction with circular progress ring and supports drag callbacks.
library;

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Callback when position changes.
typedef WindWidgetPositionChanged = void Function(Offset offset);

/// Draggable wind widget supporting edit/delete callbacks.
class TrueWindWidget extends StatefulWidget {
  const TrueWindWidget({
    super.key,
    required this.speedKnots,
    required this.directionLabel,
    this.progress, // 0-1 scale for ring
    this.initialOffset = Offset.zero,
    this.onPositionChanged,
    this.onDelete,
    this.editMode = false,
  });

  /// Wind speed in knots.
  final double speedKnots;

  /// Cardinal direction label (e.g., NNE).
  final String directionLabel;

  /// Optional progress fraction (0-1) filling the ring.
  final double? progress;

  /// Starting screen position for the widget.
  final Offset initialOffset;

  /// Callback fired when the widget is dragged to a new position.
  final WindWidgetPositionChanged? onPositionChanged;

  /// Optional delete callback shown in edit mode.
  final VoidCallback? onDelete;

  /// Enables edit affordances like delete button.
  final bool editMode;

  @override
  State<TrueWindWidget> createState() => _TrueWindWidgetState();
}

class _TrueWindWidgetState extends State<TrueWindWidget> {
  late Offset offset;

  @override
  void initState() {
    super.initState();
    offset = widget.initialOffset;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Draggable<Offset>(
        feedback: _buildBubble(opacity: 0.85),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            offset = details.offset;
          });
          widget.onPositionChanged?.call(offset);
        },
        child: _buildBubble(),
      ),
    );
  }

  Widget _buildBubble({double opacity = 1}) {
    return GlassCard(
      borderRadius: OceanDimensions.radiusM,
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: widget.progress?.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: OceanColors.seafoamGreen.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    OceanColors.seafoamGreen,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.speedKnots.toStringAsFixed(1)} kts',
                    style: OceanTextStyles.heading2,
                  ),
                  const SizedBox(height: OceanDimensions.spacingXS),
                  Text(
                    widget.directionLabel,
                    style: OceanTextStyles.bodySmall.copyWith(
                      color: OceanColors.textSecondary,
                    ),
                  ),
                  if (widget.editMode && widget.onDelete != null) ...[
                    const SizedBox(height: OceanDimensions.spacingS),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: OceanColors.coralRed),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete wind widget',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
