/// NavigationSidebar - Vertical glass navigation rail for SailStream.
library;

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/text_styles.dart';
import '../glass/glass_card.dart';

/// Navigation item model.
class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
  });

  /// Icon to display for the navigation item.
  final IconData icon;

  /// Text label for the navigation item.
  final String label;
}

/// Vertical navigation sidebar with active state and callback.
class NavigationSidebar extends StatelessWidget {
  const NavigationSidebar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onSelected,
  });

  /// Items to render in the sidebar.
  final List<NavItem> items;

  /// Index of the currently active item.
  final int activeIndex;

  /// Callback when an item is selected.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: OceanDimensions.radiusL,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: OceanDimensions.spacing,
          horizontal: OceanDimensions.spacingS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _NavButton(
                item: items[i],
                isActive: i == activeIndex,
                onTap: () => onSelected(i),
              ),
              if (i != items.length - 1)
                const SizedBox(height: OceanDimensions.spacingM),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? OceanColors.seafoamGreen : OceanColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OceanDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: OceanDimensions.spacingS,
          horizontal: OceanDimensions.spacing,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? OceanColors.seafoamGreen.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(OceanDimensions.radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: OceanDimensions.icon),
            const SizedBox(height: OceanDimensions.spacingXS),
            Text(
              item.label,
              style: OceanTextStyles.label.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
