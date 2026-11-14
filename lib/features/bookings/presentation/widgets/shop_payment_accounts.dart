import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// The shop's real payment accounts, read from the shop doc's
/// `bank_accounts` field (same shape the accounts screen parses:
/// wallets `{'type': 'jazzcash'|'easypaisa', 'account', 'title'}` and
/// banks `{'type': 'bank', 'bank_name', 'iban', 'title'}`).
///
/// There is no per-booking assigned account on [BookingEntity], so the
/// screens that must name the account a proof was paid to show the
/// shop's configured accounts instead of guessing one. Renders
/// nothing when the shop has no accounts configured.
class ShopPaymentAccounts extends StatelessWidget {
  const ShopPaymentAccounts({
    super.key,
    required this.shopId,
    this.title,
    this.singleLine = false,
  });

  final String shopId;

  /// Optional heading rendered above the rows.
  final String? title;

  /// When true, only the first account renders, as one
  /// `paymentProofPayTo` line ("Pay to: JazzCash 0300-…").
  final bool singleLine;

  Future<Map<String, dynamic>?> _getShopData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getShopData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final rawAccounts =
            snapshot.data?['bank_accounts'] as List<dynamic>?;
        if (rawAccounts == null || rawAccounts.isEmpty) {
          return const SizedBox.shrink();
        }
        final accounts = rawAccounts
            .map((a) => a as Map<String, dynamic>)
            .map((acc) {
          final type = (acc['type'] as String? ?? 'bank').toLowerCase();
          final isWallet = type == 'jazzcash' || type == 'easypaisa';
          final methodTitle = isWallet
              ? (type == 'jazzcash'
                  ? l10n.paymentJazzcash
                  : l10n.paymentEasypaisa)
              : (acc['bank_name'] as String? ?? l10n.paymentBankTransfer);
          final number = isWallet
              ? (acc['account'] as String? ?? '')
              : (acc['iban'] as String? ?? '');
          return '$methodTitle $number'.trim();
        }).toList();
        final shown = singleLine ? accounts.take(1).toList() : accounts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
            ],
            for (final account in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  l10n.paymentProofPayTo(account),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.successTextFor(
                            Theme.of(context).brightness),
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}
