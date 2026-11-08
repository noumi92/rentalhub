import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import  '../../../../finance/domain/entities/finance_account_entity.dart';
import  '../../../../finance/domain/entities/finance_transfer_entity.dart';
import '../../../../../core/utils/money_format.dart';

/// Phase B (H1/H2): the ledger — every income and expense, newest
/// first, with the account and category it was posted to.
class FinanceLedgerSection extends StatefulWidget {
  final List<FinanceTransferEntity> transfers;
  final List<FinanceAccountEntity> accounts;
  final VoidCallback onAddTransfer;

  const FinanceLedgerSection({
    super.key,
    required this.transfers,
    required this.accounts,
    required this.onAddTransfer,
  });

  @override
  State<FinanceLedgerSection> createState() => _FinanceLedgerSectionState();
}

class _FinanceLedgerSectionState extends State<FinanceLedgerSection> {
  static const _pageSize = 20;
  bool _showAll = false;

  List<FinanceTransferEntity> get _visible => _showAll
      ? widget.transfers
      : widget.transfers.take(_pageSize).toList();

  String _accountName(AppLocalizations l10n, String accountId) {
    return widget.accounts
            .where((a) => a.accountId == accountId)
            .firstOrNull
            ?.name ??
        l10n.financeAccountFallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transfers = widget.transfers;
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
              onPressed: widget.onAddTransfer,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transfers.isEmpty)
          Text(l10n.financeLedgerEmpty,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ..._visible.map((t) {
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
                  l10n.financeLedgerAmount(isIncome ? '+' : '−', formatRs(t.amountPkr)),
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
        // Audit §24: the ledger was silently capped at 20 with no
        // count and no way to see the rest. The button label carries
        // the total, and expands the full list in place.
        if (transfers.length > _pageSize && !_showAll)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text(l10n.disputesFilterAll(transfers.length)),
            ),
          ),
      ],
    );
  }
}

/// Stored ledger category codes mapped to localized labels — the
/// stored value itself is never changed.
String _categoryLabel(AppLocalizations l10n, String category) => {'rent': l10n.financeCategoryRent, 'deposit': l10n.addVehicleReviewDeposit, 'other': l10n.blacklistReasonOther, 'fuel': l10n.financeCategoryFuel, 'maintenance': l10n.fleetFilterMaintenance, 'salary': l10n.financeCategorySalary, 'partner_share': l10n.financeCategoryPartnerShare, 'deposit_refund': l10n.financeCategoryDepositRefund}[category] ?? category;
