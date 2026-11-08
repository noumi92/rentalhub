import 'package:flutter/material.dart';

import '../../../../core/widgets/app_state_views.dart';
import '../../data/services/customer_wallet_service.dart';
import 'wallet_transaction_tile.dart';
import '../../../../l10n/app_localizations.dart';

/// F1: the wallet's transaction ledger — the customer's real advances
/// and deposits, newest first. Extracted from [CustomerWalletView] so
/// the view stays under the 250-line cap.
class WalletLedger extends StatelessWidget {
  const WalletLedger({
    super.key,
    required this.isLoading,
    required this.entries,
    this.hasError = false,
    this.onRetry,
  });

  final bool isLoading;
  final List<WalletLedgerEntry> entries;

  /// E2: when the load failed, the ledger shows an error state with
  /// retry instead of an empty ledger.
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) {
      // E2: shared loading state.
      return  AppLoadingState(message: l10n.walletLoading);
    }
    if (hasError) {
      // E2: shared error state with retry.
      return AppErrorState(
        message:
            l10n.walletLoadError,
        onRetry: onRetry,
      );
    }
    if (entries.isEmpty) {
      // E2: shared empty state (was a bare l10n.walletNoActivity
      // text in a container).
      return  AppEmptyState(
        title: l10n.walletNoActivity,
        message: l10n.walletLedgerEmptyHint,
        icon: Icons.account_balance_wallet_outlined,
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
