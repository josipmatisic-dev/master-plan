/// Setting Row Widget
///
/// Reusable widget for displaying key-value pairs in settings/info cards.
library;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';

/// Displays a key-value setting row
class SettingRow extends StatelessWidget {
  /// The label text.
  final String label;

  /// The value text.
  final String value;

  /// Creates a setting row.
  const SettingRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: OceanDimensions.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: OceanTextStyles.body.copyWith(
                color: OceanColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: OceanDimensions.spacingS),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: OceanTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: OceanColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
