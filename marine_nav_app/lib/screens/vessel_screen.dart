import 'package:flutter/material.dart';
import '../widgets/common/glow_text.dart';
import '../widgets/glass/glass_card.dart';

// TODO: Replace mock data with VesselProvider when available.

class VesselScreen extends StatelessWidget {
  const VesselScreen({super.key});

  // -- Mock vessel data ------------------------------------------------
  // TODO: Pull from VesselProvider / repository.
  static const _name = 'SV Adriatic Star';
  static const _type = 'Sailing Yacht';
  static const _dimensions = {
    'LOA': '12.8 m',
    'Beam': '4.1 m',
    'Draft': '1.9 m',
    'Displacement': '9,200 kg',
  };
  static const _engine = {
    'Model': 'Yanmar 3YM30',
    'Hours': '1,247 h',
    'Fuel Capacity': '200 L',
    'Oil Pressure': 'Normal',
  };
  static const _equipment = <Map<String, dynamic>>[
    {'name': 'GPS', 'ok': true},
    {'name': 'AIS Transponder', 'ok': true},
    {'name': 'Radar', 'ok': true},
    {'name': 'VHF Radio', 'ok': true},
    {'name': 'Autopilot', 'ok': false},
    {'name': 'Depth Sounder', 'ok': true},
  ];
  static const _safety = <Map<String, dynamic>>[
    {'name': 'Life Raft (6P)', 'ok': true},
    {'name': 'EPIRB', 'ok': true},
    {'name': 'Flares (exp 2026)', 'ok': true},
    {'name': 'Fire Extinguishers', 'ok': true},
    {'name': 'First-Aid Kit', 'ok': false},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GlowText(
          'Vessel',
          glowStyle: GlowTextStyle.heading,
          color: cs.primary,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildHeader(cs, tt),
            const SizedBox(height: 16),
            _buildKeyValueCard('Dimensions', Icons.straighten, _dimensions, cs, tt),
            const SizedBox(height: 16),
            _buildEquipmentCard(cs, tt),
            const SizedBox(height: 16),
            _buildKeyValueCard('Engine', Icons.engineering, _engine, cs, tt),
            const SizedBox(height: 16),
            _buildSafetyCard(cs, tt),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // -- Vessel name & type header ----------------------------------------

  Widget _buildHeader(ColorScheme cs, TextTheme tt) {
    return GlassCard(
      padding: GlassCardPadding.large,
      child: Row(
        children: [
          Icon(Icons.sailing, size: 48, color: cs.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlowText(
                  _name,
                  glowStyle: GlowTextStyle.heading,
                  color: cs.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  _type,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Generic key-value card -------------------------------------------

  Widget _buildKeyValueCard(
    String title,
    IconData icon,
    Map<String, String> entries,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, icon, cs, tt),
          const SizedBox(height: 12),
          ...entries.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  Text(e.value, style: tt.titleMedium?.copyWith(color: cs.onSurface)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Equipment card ---------------------------------------------------

  Widget _buildEquipmentCard(ColorScheme cs, TextTheme tt) {
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Equipment', Icons.settings_input_antenna, cs, tt),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipment.map((item) {
              final ok = item['ok'] as bool;
              return Chip(
                avatar: Icon(
                  ok ? Icons.check_circle : Icons.error_outline,
                  size: 18,
                  color: ok ? Colors.greenAccent : Colors.redAccent,
                ),
                label: Text(
                  item['name'] as String,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface),
                ),
                backgroundColor: cs.surface.withValues(alpha: 0.4),
                side: BorderSide(color: cs.onSurface.withValues(alpha: 0.12)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // -- Safety equipment card --------------------------------------------

  Widget _buildSafetyCard(ColorScheme cs, TextTheme tt) {
    return GlassCard(
      padding: GlassCardPadding.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Safety Equipment', Icons.health_and_safety, cs, tt),
          const SizedBox(height: 12),
          ..._safety.map((item) {
            final ok = item['ok'] as bool;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle : Icons.warning_amber_rounded,
                    size: 20,
                    color: ok ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    ),
                  ),
                  Text(
                    ok ? 'OK' : 'Check',
                    style: tt.bodySmall?.copyWith(
                      color: ok ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // -- Shared section header --------------------------------------------

  Widget _sectionHeader(String title, IconData icon, ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(title, style: tt.titleMedium?.copyWith(color: cs.onSurface)),
      ],
    );
  }
}
