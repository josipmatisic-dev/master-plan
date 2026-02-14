/// Reusable input decoration and dialogs for NMEA settings.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/nmea_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';

/// Standard Ocean Glass input decoration for NMEA settings fields.
InputDecoration nmeaInputDecoration({
  required String labelText,
  String? hintText,
  bool showErrorBorder = false,
}) {
  final baseBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
    borderSide:
        BorderSide(color: OceanColors.textDisabled.withValues(alpha: 0.3)),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
    borderSide: const BorderSide(color: OceanColors.seafoamGreen, width: 2),
  );
  final errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
    borderSide: const BorderSide(color: OceanColors.coralRed, width: 2),
  );

  return InputDecoration(
    labelText: labelText,
    labelStyle:
        OceanTextStyles.label.copyWith(color: OceanColors.textDisabled),
    hintText: hintText,
    hintStyle:
        OceanTextStyles.bodySmall.copyWith(color: OceanColors.textDisabled),
    enabledBorder: baseBorder,
    focusedBorder: focusedBorder,
    errorBorder: showErrorBorder ? errorBorder : null,
    focusedErrorBorder: showErrorBorder ? errorBorder : null,
  );
}

/// Shows the NMEA connection test flow (loading → result dialog).
Future<void> showNmeaTestConnection(BuildContext context) async {
  final nmea = context.read<NMEAProvider>();

  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      backgroundColor: OceanColors.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(OceanColors.seafoamGreen),
          ),
          SizedBox(height: OceanDimensions.spacing),
          Text('Connecting to NMEA...', style: OceanTextStyles.body),
        ],
      ),
    ),
  );

  await nmea.connect();
  await Future.delayed(const Duration(seconds: 2));

  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: OceanColors.surface,
      title: Text(
        nmea.isConnected ? 'Connection Successful' : 'Connection Failed',
        style: OceanTextStyles.heading2,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nmea.isConnected
                ? 'Successfully connected to NMEA data source.'
                : 'Failed to connect to NMEA data source.',
            style: OceanTextStyles.body,
          ),
          if (!nmea.isConnected && nmea.lastError != null) ...[
            const SizedBox(height: OceanDimensions.spacingS),
            Text(
              'Error: ${nmea.lastError!.message}',
              style:
                  OceanTextStyles.body.copyWith(color: OceanColors.coralRed),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (nmea.lastError != null) nmea.clearError();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
