import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
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
    return Column(
      children: [
        RevenueKpiCard(
          title: 'Gross Revenue (This Month)',
          amount: 'Rs. $totalRevenue',
          changeLabel: growthLabel,
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.sunsetOrange,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RevenueKpiCard(
                title: 'Active on Rent',
                amount: '$activeCount Cars',
                changeLabel: 'On the road',
                icon: Icons.directions_car_rounded,
                color: AppColors.royalNavy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RevenueKpiCard(
                title: 'Completed Trips',
                amount: '$completedCount Finished',
                changeLabel: settleLabel,
                icon: Icons.task_alt_rounded,
                color: AppColors.emeraldGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RevenueKpiCard(
                title: 'Requests Waiting',
                amount: '$waitingCount',
                changeLabel: 'Needs your review',
                icon: Icons.inbox_rounded,
                color: AppColors.amberGold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RevenueKpiCard(
                title: 'Fleet',
                amount: '$fleetAvailable / $fleetTotal',
                changeLabel: 'Available / total cars',
                icon: Icons.local_taxi_rounded,
                color: AppColors.midnightNavy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
