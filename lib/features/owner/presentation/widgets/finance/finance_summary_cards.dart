import 'package:flutter/material.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Audit impl (O34): the accounts summary as three separate cards
/// — earnings, expenses, net — instead of one combined net figure.
class FinanceSummaryCards extends StatelessWidget {
  final int earnings;
  final int expenses;

  const FinanceSummaryCards({
    super.key,
    required this.earnings,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final net = earnings - expenses;
    return Row(
      children: [
        Expanded(
          child: _card(context, l10n.financeSummaryEarnings,
              l10n.amountRs(formatRs(earnings)), Colors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _card(context, l10n.financeSummaryExpenses,
              l10n.amountRs(formatRs(expenses)), Colors.red),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _card(context, l10n.financeSummaryNet,
              l10n.amountRs(formatRs(net)),
              Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget _card(
      BuildContext context, String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  )),
        ],
      ),
    );
  }
}
