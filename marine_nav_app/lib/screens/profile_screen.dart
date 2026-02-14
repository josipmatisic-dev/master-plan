import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/theme_variant.dart';
import '../widgets/common/glow_text.dart';
import '../widgets/glass/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _speedLabels = {
    'Knots': SpeedUnit.knots,
    'mph': SpeedUnit.mph,
    'km/h': SpeedUnit.kph,
  };

  static const _depthLabels = {
    'Meters': DepthUnit.meters,
    'Feet': DepthUnit.feet,
    'Fathoms': DepthUnit.fathoms,
  };

  static const _distanceLabels = {
    'Nautical Miles': DistanceUnit.nauticalMiles,
    'Miles': DistanceUnit.miles,
    'Kilometers': DistanceUnit.kilometers,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();

    final speedLabel = _speedLabels.entries
        .firstWhere((e) => e.value == settings.speedUnit)
        .key;
    final depthLabel = _depthLabels.entries
        .firstWhere((e) => e.value == settings.depthUnit)
        .key;
    final distanceLabel = _distanceLabels.entries
        .firstWhere((e) => e.value == settings.distanceUnit)
        .key;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GlowText(
          'Profile & Settings',
          glowStyle: GlowTextStyle.heading,
          color: cs.primary,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // — Profile Header —
          GlassCard(
            padding: GlassCardPadding.medium,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.sailing, size: 32, color: cs.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Captain', style: tt.titleMedium?.copyWith(color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Text('SailStream Navigator', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.verified, color: cs.primary, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // — Theme Selection —
          _sectionTitle(cs, 'Appearance'),
          const SizedBox(height: 8),
          GlassCard(
            padding: GlassCardPadding.medium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: tt.titleMedium?.copyWith(color: cs.onSurface)),
                const SizedBox(height: 8),
                _themeRadio(themeProvider, tt, cs, ThemeVariant.oceanGlass),
                _themeRadio(themeProvider, tt, cs, ThemeVariant.holographicCyberpunk),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // — Unit Preferences —
          _sectionTitle(cs, 'Units'),
          const SizedBox(height: 8),
          GlassCard(
            padding: GlassCardPadding.medium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unitDropdown(tt, cs, 'Speed', speedLabel, _speedLabels.keys.toList(),
                    (v) => settings.setSpeedUnit(_speedLabels[v!]!)),
                const Divider(height: 24),
                _unitDropdown(tt, cs, 'Depth', depthLabel, _depthLabels.keys.toList(),
                    (v) => settings.setDepthUnit(_depthLabels[v!]!)),
                const Divider(height: 24),
                _unitDropdown(tt, cs, 'Distance', distanceLabel, _distanceLabels.keys.toList(),
                    (v) => settings.setDistanceUnit(_distanceLabels[v!]!)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // — Display Preferences —
          _sectionTitle(cs, 'Display'),
          const SizedBox(height: 8),
          GlassCard(
            padding: GlassCardPadding.medium,
            child: Column(
              children: [
                _displayToggle(tt, cs, 'Show Compass', Icons.explore, settings.showCompass,
                    (v) => settings.setShowCompass(v)),
                _displayToggle(tt, cs, 'Show Data Orbs', Icons.blur_circular, settings.showDataOrbs,
                    (v) => settings.setShowDataOrbs(v)),
                _displayToggle(tt, cs, 'Show Speed Arc', Icons.speed, settings.showSpeedArc,
                    (v) => settings.setShowSpeedArc(v)),
                _displayToggle(tt, cs, 'Show Wave Animation', Icons.waves, settings.showWaveAnimation,
                    (v) => settings.setShowWaveAnimation(v)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // — About —
          _sectionTitle(cs, 'About'),
          const SizedBox(height: 8),
          GlassCard(
            padding: GlassCardPadding.medium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _aboutRow(tt, cs, 'App', 'SailStream'),
                const SizedBox(height: 8),
                _aboutRow(tt, cs, 'Version', '1.0.0'),
                const SizedBox(height: 8),
                _aboutRow(tt, cs, 'Build', '2025.07.07+1'),
                const SizedBox(height: 8),
                _aboutRow(tt, cs, 'Engine', 'Flutter'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // — Helper builders —

  Widget _sectionTitle(ColorScheme cs, String title) {
    return GlowText(title, glowStyle: GlowTextStyle.subtle, color: cs.primary);
  }

  Widget _themeRadio(ThemeProvider provider, TextTheme tt, ColorScheme cs, ThemeVariant variant) {
    return RadioListTile<ThemeVariant>(
      value: variant,
      groupValue: provider.themeVariant,
      onChanged: (v) => provider.setThemeVariant(v!),
      fillColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? cs.primary : null),
      contentPadding: EdgeInsets.zero,
      title: Text(variant.displayName, style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
      subtitle: Text(variant.description, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
    );
  }

  Widget _unitDropdown(TextTheme tt, ColorScheme cs, String label, String value,
      List<String> options, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: tt.bodyLarge?.copyWith(color: cs.onSurface))),
        DropdownButton<String>(
          value: value,
          dropdownColor: cs.surface,
          style: tt.bodyLarge?.copyWith(color: cs.primary),
          underline: const SizedBox.shrink(),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _displayToggle(TextTheme tt, ColorScheme cs, String label, IconData icon,
      bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeTrackColor: cs.primary,
      secondary: Icon(icon, color: cs.onSurfaceVariant, size: 20),
      title: Text(label, style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _aboutRow(TextTheme tt, ColorScheme cs, String label, String value) {
    return Row(
      children: [
        Text(label, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: tt.bodyLarge?.copyWith(color: cs.onSurface)),
      ],
    );
  }
}
