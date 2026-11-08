import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class WalletTransactionTile extends StatelessWidget {
  final String title;
  final String date;
  final int amount;
  final bool isDebit;
  final String status;

  const WalletTransactionTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.isDebit,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDebit ? AppColors.accentDanger : AppColors.accentSuccess)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isDebit ? AppColors.dangerTextFor(Theme.of(context).brightness) : AppColors.successTextFor(Theme.of(context).brightness),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? "-" : "+"} Rs. $amount',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: isDebit ? AppColors.dangerTextFor(Theme.of(context).brightness) : AppColors.successTextFor(Theme.of(context).brightness)),
              ),
              Text(
                status,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

