import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/vessel_provider.dart';
import '../theme/holographic_colors.dart';
import '../widgets/common/glow_text.dart';
import '../widgets/effects/holographic_shimmer.dart';
import '../widgets/effects/particle_background.dart';
import '../widgets/effects/scan_line_effect.dart';
import '../widgets/glass/glass_card.dart';

/// Screen displaying vessel details and specifications.
class VesselScreen extends StatelessWidget {
  /// Creates a [VesselScreen].
  const VesselScreen({super.key});

  // -- Default fallback when no profile is configured --------------------
  static const _defaultName = 'Not Configured';
  static const _defaultType = 'Tap to set up vessel profile';
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
    final isHolographic = context.watch<ThemeProvider>().isHolographic;
    final vessel = context.watch<VesselProvider>();
    final p = vessel.profile;

    final vesselName = p.isConfigured ? p.name : _defaultName;
    final vesselType = p.isConfigured ? p.type : _defaultType;
    final dimensions = <String, String>{
      'LOA': p.loaMeters != null ? '${p.loaMeters} m' : '—',
      'Beam': p.beamMeters != null ? '${p.beamMeters} m' : '—',
      'Draft': p.draftMeters != null ? '${p.draftMeters} m' : '—',
      'Displacement': p.displacementKg != null
          ? '${p.displacementKg!.toStringAsFixed(0)} kg'
          : '—',
    };
    final engine = <String, String>{
      'Model': p.engineModel ?? '—',
      'Hours': p.engineHours != null
          ? '${p.engineHours!.toStringAsFixed(0)} h'
          : '—',
      'Fuel Capacity': p.fuelCapacityLiters != null
          ? '${p.fuelCapacityLiters!.toStringAsFixed(0)} L'
          : '—',
    };

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
          color: isHolographic ? HolographicColors.electricBlue : cs.primary,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (isHolographic) ...[
            Container(
              decoration: const BoxDecoration(
                gradient: HolographicColors.deepSpaceBackground,
              ),
            ),
            const IgnorePointer(
              child: RepaintBoundary(
                child: ParticleBackground(interactive: false),
              ),
            ),
            const ScanLineEffect(),
          ],
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                HolographicShimmer(
                  enabled: isHolographic,
                  child: _buildHeader(vesselName, vesselType, cs, tt),
                ),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: _buildKeyValueCard(
                      'Dimensions', Icons.straighten, dimensions, cs, tt),
                ),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: _buildEquipmentCard(cs, tt),
                ),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: _buildKeyValueCard(
                      'Engine', Icons.engineering, engine, cs, tt),
                ),
                const SizedBox(height: 16),
                HolographicShimmer(
                  enabled: isHolographic,
                  child: _buildSafetyCard(cs, tt),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Vessel name & type header ----------------------------------------

  Widget _buildHeader(String name, String type, ColorScheme cs, TextTheme tt) {
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
                  name,
                  glowStyle: GlowTextStyle.heading,
                  color: cs.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  type,
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
                  Text(e.key,
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  Text(e.value,
                      style: tt.titleMedium?.copyWith(color: cs.onSurface)),
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

  Widget _sectionHeader(
      String title, IconData icon, ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(title, style: tt.titleMedium?.copyWith(color: cs.onSurface)),
      ],
    );
  }
}
