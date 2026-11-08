import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import 'revenue_kpi_card.dart';

/// Phase B (G1): the dashboard's KPI cards, extracted from
/// [OwnerDashboardView] so the view stays under the 250-line cap.
/// Every number is passed in from the real dashboard data.
class DashboardKpis extends StatelessWidget {
  final int totalRevenue;
  final String growthLabel;
  final int activeCount;
  final int completedCount;
  final String settleLabel;
  final int waitingCount;
  final int fleetAvailable;
  final int fleetTotal;

  const DashboardKpis({
    super.key,
    required this.totalRevenue,
    required this.growthLabel,
    required this.activeCount,
    required this.completedCount,
    required this.settleLabel,
    required this.waitingCount,
    required this.fleetAvailable,
    required this.fleetTotal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        RevenueKpiCard(
          title: l10n.dashboardGrossRevenue,
          amount: 'Rs. $totalRevenue',
          changeLabel: growthLabel,
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RevenueKpiCard(
                title: l10n.dashboardActiveOnRent,
                amount: l10n.dashboardCarsCount(activeCount),
                changeLabel: l10n.dashboardOnTheRoad,
                icon: Icons.directions_car_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RevenueKpiCard(
                title: l10n.dashboardCompletedTrips,
                amount: l10n.dashboardFinishedCount(completedCount),
                changeLabel: settleLabel,
                icon: Icons.task_alt_rounded,
                color: AppColors.accentSuccess,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RevenueKpiCard(
                title: l10n.dashboardRequestsWaiting,
                amount: '$waitingCount',
                changeLabel: l10n.dashboardNeedsReview,
                icon: Icons.inbox_rounded,
                color: AppColors.warning,
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
      ],
    );
  }
}
