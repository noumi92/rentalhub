import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Audit impl (O34): the finance hub's tab row (Overview /
/// Transactions / Reports) and period selector (This month / Last
/// month / All time). Extracted from [OwnerFinanceView] so the view
/// stays under the 250-line cap.
class FinanceHubHeader extends StatelessWidget {
  final String tab;
  final String period;
  final ValueChanged<String> onTabChanged;
  final ValueChanged<String> onPeriodChanged;

  const FinanceHubHeader({
    super.key,
    required this.tab,
    required this.period,
    required this.onTabChanged,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.financeTabOverview),
              selected: tab == 'overview',
              onSelected: (_) => onTabChanged('overview'),
            ),
            ChoiceChip(
              label: Text(l10n.financeTabTransactions),
              selected: tab == 'transactions',
              onSelected: (_) => onTabChanged('transactions'),
            ),
            ChoiceChip(
              label: Text(l10n.financeTabReports),
              selected: tab == 'reports',
              onSelected: (_) => onTabChanged('reports'),
            ),
          ],
        ),
        DropdownButton<String>(
          dropdownColor: Theme.of(context).colorScheme.surface,
          value: period,
          items: [
            DropdownMenuItem(
                value: 'this_month', child: Text(l10n.financeThisMonth)),
            DropdownMenuItem(
                value: 'last_month', child: Text(l10n.financeLastMonth)),
            DropdownMenuItem(
                value: 'all', child: Text(l10n.financeAllTime)),
          ],
          onChanged: (v) => onPeriodChanged(v ?? 'this_month'),
        ),
      ],
    );
  }
}
