import 'package:flutter/material.dart';

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

  String _accountName(String accountId) {
    return accounts
            .where((a) => a.accountId == accountId)
            .firstOrNull
            ?.name ??
        'Account';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ledger',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnightNavy)),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add entry'),
              onPressed: onAddTransfer,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transfers.isEmpty)
          const Text('No entries yet — record your first income or expense.',
              style: TextStyle(color: AppColors.textMuted)),
        ...transfers.take(20).map((t) {
          final isIncome = t.kind == 'income';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.category,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.midnightNavy)),
                      Text(
                          '${_accountName(t.accountId)} • ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}${t.note != null ? ' • ${t.note}' : ''}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '−'} Rs. ${t.amountPkr}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isIncome
                          ? AppColors.emeraldGreen
                          : AppColors.crimsonRed),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
