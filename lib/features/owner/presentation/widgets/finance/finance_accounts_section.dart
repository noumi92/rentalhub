import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import  '../../../../finance/domain/entities/finance_account_entity.dart';
import  '../../../../finance/domain/entities/finance_transfer_entity.dart';
import  '../../../../finance/utils/finance_summary.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Phase B (H1): the shop's accounts with their live balances —
/// opening balance plus every transfer posted to the account.
class FinanceAccountsSection extends StatelessWidget {
  final List<FinanceAccountEntity> accounts;
  final List<FinanceTransferEntity> transfers;
  final VoidCallback onAddAccount;

  const FinanceAccountsSection({
    super.key,
    required this.accounts,
    required this.transfers,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.financeAccountsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.financeAddAccount),
              onPressed: onAddAccount,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Audit §24: with zero accounts the section used to render
        // only the header + "Add" button and blank space.
        if (accounts.isEmpty)
          Text(l10n.financeAccountsEmpty,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ...accounts.map((a) {
          final balance = FinanceSummary.accountBalance(a, transfers);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppCardDecoration.shadow(context)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    Text(_accountTypeLabel(l10n, a.type),
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                Text(l10n.amountRs(formatRs(balance)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Stored account-type codes mapped to localized labels — the stored
/// value itself is never changed.
String _accountTypeLabel(AppLocalizations l10n, String type) => {'cash': l10n.financeAccountTypeCash, 'bank': l10n.financeAccountTypeBank, 'jazzcash': l10n.financeAccountTypeJazzCash, 'easypaisa': l10n.financeAccountTypeEasyPaisa}[type] ?? type;
