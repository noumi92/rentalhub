import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import 'needs_review_card.dart';
import 'revenue_kpi_card.dart';

/// Phase B (G1): the dashboard's KPI cards, extracted from
/// [OwnerDashboardView] so the view stays under the 250-line cap.
/// Every number is passed in from the real dashboard data.
///
/// Phase 1 showroom redesign: the two separate revenue cards are
/// one unified [DualMetricRevenueCard] (Today's Earnings | Monthly
/// Revenue). [totalRevenue] is now the CURRENT month's revenue (see
/// `monthRevenue` in dashboard_booking_stats.dart) — the old
/// "Gross Revenue (This Month)" label showed the all-time total.
/// The Active Rentals card moved out: [ActiveRentalsTodayCard]
/// renders below the quick actions in the view, so [activeCount] is
/// kept only so existing call sites keep compiling.
class DashboardKpis extends StatelessWidget {
  final int totalRevenue;
  final int todayEarnings;
  final String growthLabel;
  final KpiTrend growthTrend;
  final int activeCount;
  final int completedCount;
  final String settleLabel;
  final int waitingCount;
  final int fleetAvailable;
  final int fleetTotal;

  /// FG-1 (UI/UX audit 2026-11-15): the waiting split (new requests
  /// vs proofs), the oldest-wait label, and the triage destination
  /// for the decision card + the waiting KPI itself.
  final int newCount;
  final int proofCount;
  final String? oldestWaitLabel;
  final VoidCallback? onWaitingTap;

  const DashboardKpis({
    super.key,
    required this.totalRevenue,
    this.todayEarnings = 0,
    required this.growthLabel,
    this.growthTrend = KpiTrend.neutral,
    required this.activeCount,
    required this.completedCount,
    required this.settleLabel,
    required this.waitingCount,
    required this.fleetAvailable,
    required this.fleetTotal,
    this.newCount = 0,
    this.proofCount = 0,
    this.oldestWaitLabel,
    this.onWaitingTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // FG-1 (UI/UX audit 2026-11-15): the decision is the first
        // read — the "Needs review" card sits above the revenue
        // cards whenever anything is waiting. It only renders with
        // a real destination — never a dead tap.
        if (waitingCount > 0 && onWaitingTap != null) ...[
          NeedsReviewCard(
            waitingCount: waitingCount,
            newCount: newCount,
            proofCount: proofCount,
            oldestWaitLabel: oldestWaitLabel,
            onTap: onWaitingTap!,
          ),
          const SizedBox(height: 12),
        ],
        // Phase 1: one unified dual-metric card — today's earnings
        // beside the real current-month revenue, with the growth
        // trend on the month side only.
        DualMetricRevenueCard(
          todayAmount: l10n.amountRs(formatRs(todayEarnings)),
          monthAmount: l10n.amountRs(formatRs(totalRevenue)),
          growthLabel: growthLabel,
          growthTrend: growthTrend,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RevenueKpiCard(
                title: l10n.dashboardCompletedTrips,
                amount: l10n.dashboardFinishedCount(completedCount),
                changeLabel: settleLabel,
                icon: Icons.task_alt_rounded,
                color: AppColors.accentSuccess,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RevenueKpiCard(
                title: l10n.dashboardFleet,
                amount: '$fleetAvailable / $fleetTotal',
                changeLabel: l10n.dashboardAvailableTotal,
                icon: Icons.local_taxi_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        RevenueKpiCard(
          title: l10n.dashboardRequestsWaiting,
          amount: '$waitingCount',
          // FG-1: the count is split — "2 new · 1 proof" —
          // instead of the lumped "Needs your review".
          changeLabel: waitingCount > 0
              ? l10n.dashboardNeedsReviewSplit(newCount, proofCount)
              : l10n.dashboardNeedsReview,
          icon: Icons.inbox_rounded,
          color: AppColors.warning,
          onTap: onWaitingTap,
        ),
      ],
    );
  }
}

/// Phase 1 showroom redesign: the "Active Rentals Today" live card,
/// rendered at the bottom of the action area — below the quick
/// actions in the view — instead of inside the KPI rows above.
/// The count comes from the same live bookings stream as the rest
/// of the dashboard, so it stays live while the dashboard is open.
class ActiveRentalsTodayCard extends StatelessWidget {
  final int activeCount;

  const ActiveRentalsTodayCard({
    super.key,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RevenueKpiCard(
      title: l10n.dashboardActiveRentalsToday,
      amount: l10n.dashboardCarsCount(activeCount),
      changeLabel: l10n.dashboardOnTheRoad,
      icon: Icons.directions_car_rounded,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
