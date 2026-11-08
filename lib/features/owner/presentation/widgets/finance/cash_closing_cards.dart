import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import  '../../../../finance/domain/entities/cash_closing_entity.dart';

/// Phase B (H5): the cash-closing summary card and one past
/// closing row, extracted from [OwnerCashClosingView] so the view
/// stays under the 250-line cap.
class CashClosingSummaryCard extends StatelessWidget {
  final int expectedCash;
  final int openingCash;
  final int difference;

  const CashClosingSummaryCard({
    super.key,
    required this.expectedCash,
    required this.openingCash,
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expected in till today',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          Text('Rs. $expectedCash',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 4),
          Text('Opening Rs. $openingCash • Difference Rs. $difference',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class CashClosingRow extends StatelessWidget {
  final CashClosingEntity closing;

  const CashClosingRow({super.key, required this.closing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${closing.date.day}/${closing.date.month}/${closing.date.year}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
              'Counted Rs. ${closing.countedCash} • Diff Rs. ${closing.difference}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: closing.difference == 0
                      ? AppColors.successTextFor(Theme.of(context).brightness)
                      : AppColors.dangerTextFor(Theme.of(context).brightness),
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
