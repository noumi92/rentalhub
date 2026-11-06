import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// Phase B (G1): one ledger row on the owner dashboard, extracted
/// from [OwnerDashboardView]. The status chip is coloured by the
/// booking's real status instead of always green.
class DashboardLedgerItem extends StatelessWidget {
  final String bookingId;
  final String vehicleName;
  final String customerName;
  final int amount;
  final String status;

  const DashboardLedgerItem({
    super.key,
    required this.bookingId,
    required this.vehicleName,
    required this.customerName,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'completed'
        ? AppColors.emeraldGreen
        : status == 'active'
            ? AppColors.royalNavy
            : AppColors.sunsetOrange;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicleName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy)),
              const SizedBox(height: 2),
              Text('#$bookingId • $customerName',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. $amount',
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.midnightNavy)),
              const SizedBox(height: 2),
              Text(status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}
