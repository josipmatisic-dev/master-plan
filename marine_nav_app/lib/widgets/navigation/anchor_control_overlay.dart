import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/boat_provider.dart';
import '../../services/anchor_alarm_service.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

class AnchorControlOverlay extends StatelessWidget {
  const AnchorControlOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final boatProvider = context.watch<BoatProvider>();
    final service = boatProvider.anchorAlarm;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final isActive = service.isActive;
        final isTriggered = service.isTriggered;
        final alarm = service.alarm;

        if (isTriggered) {
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(OceanDimensions.radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: OceanColors.coralRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(OceanDimensions.radius),
                    border: Border.all(color: OceanColors.coralRed, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: OceanColors.coralRed.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _buildContent(
                      context, service, isActive, isTriggered, alarm, boatProvider),
                ),
              ),
            ),
          );
        }

        return Center(
          child: GlassCard(
            child: _buildContent(
                context, service, isActive, isTriggered, alarm, boatProvider),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AnchorAlarmService service,
    bool isActive,
    bool isTriggered,
    var alarm,
    var boatProvider,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.anchor,
              color: isTriggered
                  ? OceanColors.coralRed
                  : (isActive
                      ? OceanColors.seafoamGreen
                      : OceanColors.pureWhite),
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? 'ANCHOR SET' : 'ANCHOR READY',
              style: OceanTextStyles.heading2.copyWith(
                color: isTriggered ? OceanColors.coralRed : null,
              ),
            ),
          ],
        ),
        if (isActive && alarm != null) ...[
          const SizedBox(height: 8),
          Text(
            'Drift: ${alarm.currentDistanceMeters.toStringAsFixed(1)}m / '
            '${alarm.radiusMeters.toStringAsFixed(0)}m',
            style: OceanTextStyles.dataValue.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OceanColors.coralRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: service.clearAnchor,
                child: const Text('WEIGH ANCHOR'),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OceanColors.seafoamGreen,
              foregroundColor: OceanColors.deepNavy,
            ),
            onPressed: () {
              final pos = boatProvider.currentPosition;
              if (pos != null) {
                service.setAnchorAtPosition(pos);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No GPS position!')),
                );
              }
            },
            child: const Text('DROP ANCHOR'),
          ),
        ],
      ],
    );
  }
}
