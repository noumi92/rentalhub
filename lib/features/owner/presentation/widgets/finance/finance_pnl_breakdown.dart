import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../../finance/utils/finance_summary.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Audit impl (O45): income and expense breakdowns by category for
/// the shown period — Rent / Advance / Other income, and Fuel /
/// Maintenance / Wash / Other expenses. Any category code outside
/// the named ones is folded into Other, so custom categories still
/// count. Extracted from [FinancePnLReport].
class FinancePnLBreakdown extends StatelessWidget {
  final List<FinanceTransferEntity> transfers;

  const FinancePnLBreakdown({super.key, required this.transfers});

  int _other(Map<String, int> totals, List<String> named) {
    var sum = 0;
    for (final entry in totals.entries) {
      if (!named.contains(entry.key)) sum += entry.value;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final income =
        FinanceSummary.categoryTotals(transfers, kind: 'income');
    final expense =
        FinanceSummary.categoryTotals(transfers, kind: 'expense');
    return Column(
      children: [
        _section(context, l10n, l10n.financePnlIncomeBreakdown, [
          (l10n.financeCategoryRent, income['rent'] ?? 0),
          (l10n.financeCategoryAdvance, income['advance'] ?? 0),
          (
            l10n.blacklistReasonOther,
            _other(income, const ['rent', 'advance'])
          ),
        ]),
        const SizedBox(height: 12),
        _section(context, l10n, l10n.financePnlExpenseBreakdown, [
          (l10n.financeCategoryFuel, expense['fuel'] ?? 0),
          (l10n.fleetFilterMaintenance, expense['maintenance'] ?? 0),
          (l10n.financeCategoryWash, expense['wash'] ?? 0),
          (
            l10n.blacklistReasonOther,
            _other(expense, const ['fuel', 'maintenance', 'wash'])
          ),
        ]),
      ],
    );
  }

  Widget _section(BuildContext context, AppLocalizations l10n, String title,
      List<(String, int)> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 4),
          for (final (label, amount) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  Text(l10n.amountRs(formatRs(amount)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
