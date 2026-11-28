import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// One horizontal sub-tab item rendered inside [AdminSubTabBar].
class AdminSubTab {
  const AdminSubTab({
    required this.label,
    required this.route,
    this.badgeCount = 0,
    this.icon,
    this.isActive = false,
  });

  final String label;
  final String route;
  final int badgeCount;
  final IconData? icon;
  final bool isActive;
}

/// Horizontally scrollable sub-tab bar sitting beneath the admin header
/// (desktop/tablet) or app bar (mobile). Keeps every primary section's
/// sub-views one tap away without cluttering the left sidebar.
class AdminSubTabBar extends StatelessWidget {
  const AdminSubTabBar({
    super.key,
    required this.tabs,
    required this.onSelect,
  });

  final List<AdminSubTab> tabs;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final tab in tabs)
              _SubTabButton(
                tab: tab,
                scheme: scheme,
                onTap: () => onSelect(tab.route),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubTabButton extends StatelessWidget {
  const _SubTabButton({
    required this.tab,
    required this.scheme,
    required this.onTap,
  });

  final AdminSubTab tab;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = tab.isActive;
    final fg = active ? scheme.onSurface : scheme.onSurfaceVariant;
    final showBadge = tab.badgeCount > 0;

    return Semantics(
      button: true,
      selected: active,
      label: showBadge ? '${tab.label}, ${tab.badgeCount}' : tab.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.secondary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab.icon != null) ...[
                Icon(
                  tab.icon,
                  size: 16,
                  color: active ? AppColors.secondary : fg,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.secondary.withAlpha(32)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tab.badgeCount}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.secondary : fg,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
