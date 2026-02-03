/// Cache Info Card Widget
///
/// Displays cache status and statistics.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cache_provider.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../common/setting_row.dart';
import '../glass/glass_card.dart';

/// Cache info card for home screen
class CacheInfoCard extends StatelessWidget {
  /// Creates a cache info card.
  const CacheInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CacheProvider>(
      builder: (context, cache, _) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cache Status',
                style: OceanTextStyles.heading2,
              ),
              OceanDimensions.spacing.verticalSpace,
              SettingRow(
                label: 'Status',
                value: cache.isInitialized ? 'Initialized' : 'Not Ready',
              ),
              SettingRow(
                label: 'Size',
                value: '${cache.cacheSizeMB.toStringAsFixed(2)} MB',
              ),
              SettingRow(
                label: 'Entries',
                value: cache.stats.entryCount.toString(),
              ),
            ],
          ),
        );
      },
    );
  }
}
