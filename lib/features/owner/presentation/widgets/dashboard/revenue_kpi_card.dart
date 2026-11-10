import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

/// Audit fix (§2, KPI "change" indicator): the direction of a KPI
/// change is data, not decoration. [KpiTrend.up] is the only trend
/// that shows an up arrow in green; [KpiTrend.down] shows a down
/// arrow in the danger colour; [KpiTrend.neutral] — labels like
/// "Needs review" or "Available/Total" that are not a change at all —
/// shows no icon and an `onSurfaceVariant` label. Never render an up
/// arrow in green for a negative or neutral label.
enum KpiTrend { up, down, neutral }

class RevenueKpiCard extends StatelessWidget {
  final String title;
  final String amount;
  final String changeLabel;
  final IconData icon;
  final Color color;
  final KpiTrend trend;

  const RevenueKpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.changeLabel,
    required this.icon,
    this.color = AppColors.secondary,
    this.trend = KpiTrend.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final (IconData?, Color) trendStyle = switch (trend) {
      KpiTrend.up => (
          Icons.trending_up_rounded,
          AppColors.successTextFor(brightness),
        ),
      KpiTrend.down => (
          Icons.trending_down_rounded,
          AppColors.dangerTextFor(brightness),
        ),
      KpiTrend.neutral => (
          null,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };
    final trendIcon = trendStyle.$1;
    final trendColor = trendStyle.$2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (trendIcon != null) ...[
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(changeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: trendColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
