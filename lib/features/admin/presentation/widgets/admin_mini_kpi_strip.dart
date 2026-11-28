import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// One compact stat pill rendered inside [AdminMiniKpiStrip].
class AdminMiniKpi {
  const AdminMiniKpi({
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.muted = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final bool muted;
}

/// Compact horizontal strip of KPI pills shown at the top of admin hub screens
/// (e.g. Shops & Fleet, Online Customers, Packages & Credits).
class AdminMiniKpiStrip extends StatelessWidget {
  const AdminMiniKpiStrip({super.key, required this.items});

  final List<AdminMiniKpi> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: item.muted
                    ? scheme.surfaceContainerHighest.withAlpha(140)
                    : scheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: item.accentColor?.withAlpha(90) ?? theme.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: 15,
                      color: item.muted
                          ? scheme.onSurfaceVariant
                          : (item.accentColor ?? AppColors.secondary),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      '${item.label}: ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: item.muted
                          ? scheme.onSurfaceVariant
                          : (item.accentColor ?? scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
