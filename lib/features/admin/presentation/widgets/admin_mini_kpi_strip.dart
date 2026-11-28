import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// One compact read-only stat item rendered inside [AdminMiniKpiStrip].
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

/// Read-only flat metric summary bar shown at the top of admin screens.
/// Styled as a single subtle surface strip (never pill-shaped buttons)
/// so it cannot be confused with interactive filter chips.
class AdminMiniKpiStrip extends StatelessWidget {
  const AdminMiniKpiStrip({super.key, required this.items});

  final List<AdminMiniKpi> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 14,
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
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: item.muted
                        ? scheme.onSurfaceVariant
                        : (item.accentColor ?? scheme.onSurface),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
