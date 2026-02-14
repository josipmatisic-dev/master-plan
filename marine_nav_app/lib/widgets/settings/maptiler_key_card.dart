/// MapTiler API key input card for Settings screen.
///
/// Drop-in widget that lets users enter/view their MapTiler API key.
/// Reads/writes via [SettingsProvider.setMapTilerApiKey].
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../glass/glass_card.dart';

/// Card with a TextField for entering the MapTiler API key.
class MapTilerKeyCard extends StatefulWidget {
  /// Creates a MapTiler API key card.
  const MapTilerKeyCard({super.key});

  @override
  State<MapTilerKeyCard> createState() => _MapTilerKeyCardState();
}

class _MapTilerKeyCardState extends State<MapTilerKeyCard> {
  late TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    final key = context.read<SettingsProvider>().mapTilerApiKey;
    _controller = TextEditingController(text: key);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('MapTiler API Key',
                  style: tt.titleSmall?.copyWith(color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscured,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter MapTiler API key',
              hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: cs.primary.withValues(alpha: 0.3)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscured ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
            ),
            onChanged: (value) {
              context.read<SettingsProvider>().setMapTilerApiKey(value.trim());
            },
          ),
          const SizedBox(height: 6),
          Consumer<SettingsProvider>(
            builder: (_, settings, __) => Text(
              settings.hasMapTilerApiKey ? '✓ Key set' : 'No key configured',
              style: tt.bodySmall?.copyWith(
                color: settings.hasMapTilerApiKey
                    ? Colors.green
                    : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
