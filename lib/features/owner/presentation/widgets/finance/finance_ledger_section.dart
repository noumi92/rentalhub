import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import  '../../../../finance/domain/entities/finance_account_entity.dart';
import  '../../../../finance/domain/entities/finance_transfer_entity.dart';

/// Phase B (H1/H2): the ledger — every income and expense, newest
/// first, with the account and category it was posted to.
class FinanceLedgerSection extends StatelessWidget {
  final List<FinanceTransferEntity> transfers;
  final List<FinanceAccountEntity> accounts;
  final VoidCallback onAddTransfer;

  const FinanceLedgerSection({
    super.key,
    required this.transfers,
    required this.accounts,
    required this.onAddTransfer,
  });

  String _accountName(AppLocalizations l10n, String accountId) {
    return accounts
            .where((a) => a.accountId == accountId)
            .firstOrNull
            ?.name ??
        l10n.financeAccountFallback;
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.financeLedgerTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.financeAddEntry),
              onPressed: onAddTransfer,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transfers.isEmpty)
          Text(l10n.financeLedgerEmpty,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ...transfers.take(20).map((t) {
          final isIncome = t.kind == 'income';
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_categoryLabel(l10n, t.category),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                      Text(
                          '${_accountName(l10n, t.accountId)} • ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}${t.note != null ? ' • ${t.note}' : ''}',
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                Text(
                  l10n.financeLedgerAmount(isIncome ? '+' : '−', t.amountPkr),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isIncome
                          ? AppColors.successTextFor(Theme.of(context).brightness)
                          : AppColors.dangerTextFor(Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Stored ledger category codes mapped to localized labels — the
/// stored value itself is never changed.
String _categoryLabel(AppLocalizations l10n, String category) => {'rent': l10n.financeCategoryRent, 'deposit': l10n.addVehicleReviewDeposit, 'other': l10n.blacklistReasonOther, 'fuel': l10n.financeCategoryFuel, 'maintenance': l10n.fleetFilterMaintenance, 'salary': l10n.financeCategorySalary, 'partner_share': l10n.financeCategoryPartnerShare, 'deposit_refund': l10n.financeCategoryDepositRefund}[category] ?? category;
