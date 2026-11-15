import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
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
  /// PW-3: retained for callers but NO LONGER TRUNCATES — every
  /// configured account renders with its own copy button, so the
  /// payer never has to memorise and retype a long account number.
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
          return (method: methodTitle, number: number);
        }).where((a) => a.number.isNotEmpty).toList();
        // PW-3: all configured accounts, never first-only — the
        // singleLine flag is kept for callers but does not truncate.
        final shown = accounts;
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.paymentProofPayTo(
                            '${account.method} ${account.number}'.trim()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.successTextFor(
                                  Theme.of(context).brightness),
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: l10n.paymentCopyNumber,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: account.number));
                        if (context.mounted) {
                          AppFeedback.showSuccess(context,
                              l10n.paymentCopied(account.method));
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
