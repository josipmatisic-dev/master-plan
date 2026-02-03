import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/nmea_error.dart';
import '../../providers/nmea_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// NMEA connection settings widget.
class NMEASettingsCard extends StatefulWidget {
  /// Creates an NMEA settings card.
  const NMEASettingsCard({super.key});

  @override
  State<NMEASettingsCard> createState() => _NMEASettingsCardState();
}

class _NMEASettingsCardState extends State<NMEASettingsCard> {
  late TextEditingController _hostController;
  late TextEditingController _portController;
  
  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _hostController = TextEditingController(text: settings.nmeaHost);
    _portController = TextEditingController(text: settings.nmeaPort.toString());
  }
  
  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NMEA Connection', style: OceanTextStyles.heading2),
          const SizedBox(height: OceanDimensions.spacing),
          _buildHostField(),
          const SizedBox(height: OceanDimensions.spacing),
          _buildPortField(),
          const SizedBox(height: OceanDimensions.spacing),
          _buildConnectionTypeDropdown(),
          const SizedBox(height: OceanDimensions.spacing),
          _buildAutoConnectSwitch(),
          const SizedBox(height: OceanDimensions.spacingL),
          _buildTestConnectionButton(),
        ],
      ),
    );
  }

  Widget _buildHostField() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return TextField(
          controller: _hostController,
          style: OceanTextStyles.body,
          decoration: InputDecoration(
            labelText: 'Host',
            labelStyle: OceanTextStyles.label.copyWith(color: OceanColors.textDisabled),
            hintText: 'localhost or IP address',
            hintStyle: OceanTextStyles.bodySmall.copyWith(color: OceanColors.textDisabled),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              borderSide: BorderSide(color: OceanColors.textDisabled.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              borderSide: const BorderSide(color: OceanColors.seafoamGreen, width: 2),
            ),
          ),
          onChanged: (value) {
            settings.setNMEAHost(value);
          },
        );
      },
    );
  }

  Widget _buildPortField() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return TextField(
          controller: _portController,
          style: OceanTextStyles.body,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: 'Port',
            labelStyle: OceanTextStyles.label.copyWith(color: OceanColors.textDisabled),
            hintText: '1-65535',
            hintStyle: OceanTextStyles.bodySmall.copyWith(color: OceanColors.textDisabled),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              borderSide: BorderSide(color: OceanColors.textDisabled.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              borderSide: const BorderSide(color: OceanColors.seafoamGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              borderSide: const BorderSide(color: OceanColors.coralRed, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              borderSide: const BorderSide(color: OceanColors.coralRed, width: 2),
            ),
          ),
          onChanged: (value) {
            final port = int.tryParse(value);
            if (port != null && port >= 1 && port <= 65535) {
              settings.setNMEAPort(port);
            }
          },
        );
      },
    );
  }

  Widget _buildConnectionTypeDropdown() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return DropdownButtonFormField<ConnectionType>(
          initialValue: settings.nmeaConnectionType,
          style: OceanTextStyles.body,
          dropdownColor: OceanColors.surface,
          decoration: InputDecoration(
            labelText: 'Connection Type',
            labelStyle: OceanTextStyles.label.copyWith(color: OceanColors.textDisabled),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              borderSide: BorderSide(color: OceanColors.textDisabled.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              borderSide: const BorderSide(color: OceanColors.seafoamGreen, width: 2),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: ConnectionType.tcp,
              child: Text('TCP'),
            ),
            DropdownMenuItem(
              value: ConnectionType.udp,
              child: Text('UDP'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              settings.setNMEAConnectionType(value);
            }
          },
        );
      },
    );
  }

  Widget _buildAutoConnectSwitch() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return SwitchListTile(
          value: settings.autoConnectNMEA,
          onChanged: (value) {
            settings.setAutoConnectNMEA(value);
          },
          title: const Text('Auto-connect on startup', style: OceanTextStyles.body),
          subtitle: Text(
            'Automatically connect to NMEA when app starts',
            style: OceanTextStyles.bodySmall.copyWith(color: OceanColors.textDisabled),
          ),
          activeTrackColor: OceanColors.seafoamGreen.withValues(alpha: 0.5),
          activeThumbColor: OceanColors.seafoamGreen,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _buildTestConnectionButton() {
    return Consumer<NMEAProvider>(
      builder: (context, nmea, child) {
        final isConnected = nmea.isConnected;
        final isActive = nmea.isActive;
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected 
                  ? OceanColors.coralRed 
                  : OceanColors.seafoamGreen,
              foregroundColor: OceanColors.pureWhite,
              padding: const EdgeInsets.symmetric(
                vertical: OceanDimensions.spacing,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(OceanDimensions.radiusS),
              ),
            ),
            icon: Icon(
              isConnected ? Icons.link_off : Icons.link,
              color: OceanColors.pureWhite,
            ),
            label: Text(
              isConnected ? 'Disconnect' : (isActive ? 'Connecting...' : 'Test Connection'),
              style: OceanTextStyles.labelLarge,
            ),
            onPressed: isActive ? null : () {
              if (isConnected) {
                nmea.disconnect();
              } else {
                _testConnection();
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _testConnection() async {
    final nmea = context.read<NMEAProvider>();
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: OceanColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(OceanColors.seafoamGreen),
            ),
            SizedBox(height: OceanDimensions.spacing),
            Text('Connecting to NMEA...', style: OceanTextStyles.body),
          ],
        ),
      ),
    );
    
    // Attempt connection
    await nmea.connect();
    
    // Wait a moment for connection to establish
    await Future.delayed(const Duration(seconds: 2));
    
    // Dismiss loading dialog
    if (!mounted) return;
    Navigator.of(context).pop();
    
    // Show result dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                style: OceanTextStyles.body.copyWith(color: OceanColors.coralRed),
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
        ],
      ),
    );
  }
}
