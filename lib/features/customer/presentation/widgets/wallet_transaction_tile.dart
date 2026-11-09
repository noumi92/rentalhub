import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
              color:
                  (isDebit ? AppColors.accentDanger : AppColors.accentSuccess)
                      .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isDebit
                  ? AppColors.dangerTextFor(Theme.of(context).brightness)
                  : AppColors.successTextFor(Theme.of(context).brightness),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // E3: the amount shrinks to fit instead of overflowing — at
          // 200% text scale '+ Rs. 450000' pushed the row 85px past the
          // edge. A money amount must stay fully visible, so it scales
          // down rather than ellipsizing.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.financeLedgerAmount(isDebit ? '-' : '+', formatRs(amount)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDebit
                            ? AppColors.dangerTextFor(
                                Theme.of(context).brightness)
                            : AppColors.successTextFor(
                                Theme.of(context).brightness)),
                  ),
                ),
                Text(
                  status,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
