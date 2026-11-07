import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import  '../../../../finance/domain/entities/finance_account_entity.dart';
import  '../../../../finance/domain/entities/finance_transfer_entity.dart';
import  '../../../../finance/utils/finance_summary.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Accounts',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                )),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add account'),
              onPressed: onAddAccount,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...accounts.map((a) {
          final balance = FinanceSummary.accountBalance(a, transfers);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
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
                          color: AppColors.primary,
                        )),
                    Text(a.type,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                Text('Rs. $balance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    )),
              ],
            ),
          );
        }),
      ],
    );
  }
}
