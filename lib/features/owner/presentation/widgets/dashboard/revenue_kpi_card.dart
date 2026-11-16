import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../../l10n/app_localizations.dart';

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

  /// FG-1 (UI/UX audit 2026-11-15): when set, the whole card taps
  /// (the waiting KPI routes to triage). Null keeps the card inert.
  final VoidCallback? onTap;

  const RevenueKpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.changeLabel,
    required this.icon,
    this.color = AppColors.secondary,
    this.trend = KpiTrend.neutral,
    this.onTap,
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
    // Item 4: the accent colour is also the icon colour, on a 10%
    // tint of itself. The raw fills fail as icons in light mode
    // (accentSuccess 2.54:1, warning 2.15:1, vs the 3:1 non-text
    // minimum), so the icon uses the readable text variant; the tint
    // background keeps the raw colour.
    final iconColor = color == AppColors.accentSuccess
        ? AppColors.successTextFor(brightness)
        : color == AppColors.warning
            ? AppColors.warningTextFor(brightness)
            : color;
    final card = Container(
      padding: const EdgeInsets.all(16),
      // Phase 1 showroom redesign: the canonical card language —
      // 1 px borderSubtle, radius 16, elevation 1.5 — via
      // AppCardDecoration, never a hand-rolled BoxDecoration.
      decoration: AppCardDecoration.of(context),
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: trendColor)),
              ),
            ],
          ),
        ],
      ),
    );
    final tap = onTap;
    if (tap == null) return card;
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

/// Phase 1 showroom redesign: the unified dual-metric revenue card
/// — Today's Earnings | Monthly Revenue in one white card, the two
/// columns separated by a [VerticalDivider]. The monthly figure is
/// the real current-month revenue ([monthRevenue]); the growth
/// label/trend belong to the month column only (today has no
/// previous-day comparison, so its sublabel is just "Today").
class DualMetricRevenueCard extends StatelessWidget {
  final String todayAmount;
  final String monthAmount;
  final String growthLabel;
  final KpiTrend growthTrend;

  const DualMetricRevenueCard({
    super.key,
    required this.todayAmount,
    required this.monthAmount,
    required this.growthLabel,
    this.growthTrend = KpiTrend.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final (IconData?, Color) trendStyle = switch (growthTrend) {
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecoration.of(context),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _metric(
                context,
                l10n.dashboardTodayEarnings,
                todayAmount,
                l10n.dashboardToday,
                null,
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const VerticalDivider(width: 24, thickness: 1),
            Expanded(
              child: _metric(
                context,
                l10n.dashboardMonthlyRevenue,
                monthAmount,
                growthLabel,
                trendStyle.$1,
                trendStyle.$2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String title, String amount,
      String sublabel, IconData? trendIcon, Color sublabelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(amount, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (trendIcon != null) ...[
              Icon(trendIcon, size: 14, color: sublabelColor),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: sublabelColor)),
            ),
          ],
        ),
      ],
    );
  }
}
