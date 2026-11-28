import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Editorial, non-button KPI stat tile for the Admin Dashboard.
/// Uses a flat tinted surface with a subtle left accent bar and crisp
/// typography so it clearly reads as a metric rather than a button.
class AdminKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String changeLabel;
  final IconData icon;
  final Color accentColor;

  const AdminKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.changeLabel,
    required this.icon,
    this.accentColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: BorderDirectional(
          start: BorderSide(color: accentColor, width: 3.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displayLarge?.copyWith(
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (changeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              changeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
