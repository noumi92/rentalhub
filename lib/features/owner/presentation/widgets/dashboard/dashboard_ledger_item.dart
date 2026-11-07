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
        ? AppColors.accentSuccess
        : status == 'active'
            ? AppColors.primary
            : AppColors.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicleName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  )),
              const SizedBox(height: 2),
              Text('#$bookingId • $customerName',
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. $amount',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  )),
              const SizedBox(height: 2),
              Text(status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
