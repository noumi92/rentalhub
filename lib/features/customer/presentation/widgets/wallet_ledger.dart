import 'package:flutter/material.dart';

import '../../data/services/customer_wallet_service.dart';
import 'wallet_transaction_tile.dart';

/// F1: the wallet's transaction ledger — the customer's real advances
/// and deposits, newest first. Extracted from [CustomerWalletView] so
/// the view stays under the 250-line cap.
class WalletLedger extends StatelessWidget {
  const WalletLedger({
    super.key,
    required this.isLoading,
    required this.entries,
  });

  final bool isLoading;
  final List<WalletLedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
              SizedBox(height: 8),
              Text(
                'No wallet activity yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 4),
              Text(
                'Advances you pay and deposits you leave will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          WalletTransactionTile(
            title: entries[i].title,
            date: entries[i].dateLabel,
            amount: entries[i].amount,
            isDebit: entries[i].isDebit,
            status: entries[i].status,
          ),
          if (i < entries.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
