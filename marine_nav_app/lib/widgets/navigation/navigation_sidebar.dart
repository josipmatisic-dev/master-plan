/// NavigationSidebar - Vertical glass navigation rail for SailStream.
library;

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

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
///
/// On mobile screens (< 600px) the sidebar collapses into a hamburger icon
/// that expands on tap. On wider screens it behaves as a normal sidebar.
class NavigationSidebar extends StatefulWidget {
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
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < OceanDimensions.breakpointMobile;

    if (!isMobile) {
      return _buildFullSidebar();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassCard(
          borderRadius: OceanDimensions.radiusL,
          child: IconButton(
            icon: Icon(
              _isExpanded ? Icons.close : Icons.menu,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding:
                      const EdgeInsets.only(top: OceanDimensions.spacingS),
                  child: _buildFullSidebar(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFullSidebar() {
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
            for (var i = 0; i < widget.items.length; i++) ...[
              _NavButton(
                item: widget.items[i],
                isActive: i == widget.activeIndex,
                onTap: () => widget.onSelected(i),
              ),
              if (i != widget.items.length - 1)
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
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

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
              ? colorScheme.primary.withValues(alpha: 0.15)
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
