/// NMEA Connection Status Indicator Widget
///
/// Displays real-time NMEA connection status with color-coded indicator
/// and interactive dialog for connection management.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/nmea_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Connection status indicator for NMEA data source
///
/// Shows current connection state with color-coded icon and text:
/// - Green (connected): Active NMEA data flow
/// - Orange (connecting): Connection attempt in progress
/// - Red (error): Connection failed with error message
/// - Gray (disconnected): No active connection
///
/// Tapping the indicator opens a dialog with connection controls
/// and detailed status information.
class NMEAConnectionIndicator extends StatelessWidget {
  /// Creates an NMEA connection status indicator.
  const NMEAConnectionIndicator({super.key});

  /// Builds the connection indicator widget with color-coded status.
  @override
  Widget build(BuildContext context) {
    return Consumer<NMEAProvider>(
      builder: (context, nmea, child) {
        final isConnected = nmea.isConnected;
        final isActive = nmea.isActive;
        final lastError = nmea.lastError;

        // Determine indicator color and icon based on connection state
        Color indicatorColor;
        IconData indicatorIcon;
        String statusText;

        if (isConnected) {
          indicatorColor = OceanColors.seafoamGreen;
          indicatorIcon = Icons.link;
          statusText = 'NMEA Connected';
        } else if (isActive) {
          indicatorColor = OceanColors.safetyOrange;
          indicatorIcon = Icons.sync;
          statusText = 'Connecting...';
        } else if (lastError != null) {
          indicatorColor = OceanColors.coralRed;
          indicatorIcon = Icons.link_off;
          statusText = 'Connection Error';
        } else {
          indicatorColor = OceanColors.textDisabled;
          indicatorIcon = Icons.link_off;
          statusText = 'NMEA Disconnected';
        }

        return GlassCard(
          padding: GlassCardPadding.small,
          child: InkWell(
            onTap: () => _showConnectionDialog(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  indicatorIcon,
                  color: indicatorColor,
                  size: 20,
                ),
                const SizedBox(width: OceanDimensions.spacingS),
                Text(
                  statusText,
                  style: OceanTextStyles.label.copyWith(color: indicatorColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show connection management dialog
  void _showConnectionDialog(BuildContext context) {
    final nmea = context.read<NMEAProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OceanColors.surface,
        title: const Text('NMEA Connection', style: OceanTextStyles.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${_getStatusText(nmea.status)}',
              style: OceanTextStyles.body,
            ),
            if (nmea.lastError != null) ...[
              const SizedBox(height: OceanDimensions.spacingS),
              Text(
                'Error: ${nmea.lastError!.message}',
                style:
                    OceanTextStyles.body.copyWith(color: OceanColors.coralRed),
              ),
            ],
            if (nmea.lastUpdateTime != null) ...[
              const SizedBox(height: OceanDimensions.spacingS),
              Text(
                'Last Update: ${_formatTime(nmea.lastUpdateTime!)}',
                style: OceanTextStyles.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nmea.lastError != null) {
                nmea.clearError();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          if (!nmea.isConnected)
            ElevatedButton(
              onPressed: () {
                nmea.connect();
                Navigator.of(context).pop();
              },
              child: const Text('Connect'),
            )
          else
            ElevatedButton(
              onPressed: () {
                nmea.disconnect();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OceanColors.coralRed,
              ),
              child: const Text('Disconnect'),
            ),
        ],
      ),
    );
  }

  /// Extract status enum name from toString()
  String _getStatusText(dynamic status) {
    return status.toString().split('.').last;
  }

  /// Format DateTime as relative time (e.g., "5s ago", "2m ago")
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}
