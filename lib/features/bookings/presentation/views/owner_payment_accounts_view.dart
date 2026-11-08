import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/payment_account_card.dart';
import '../../../../l10n/app_localizations.dart';

class OwnerPaymentAccountsView extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onProceedToUploadProof;
  final VoidCallback? onBack;

  const OwnerPaymentAccountsView({
    super.key,
    required this.booking,
    this.onProceedToUploadProof,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: onBack != null
                  ? IconButton(
                      tooltip: l10n.back,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: Text(
                l10n.paymentAccountsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                AppColors.accentSuccess.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              color: AppColors.successTextFor(
                                  Theme.of(context).brightness),
                              size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.paymentApprovedTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.paymentTransferToLock(booking.advanceRequired),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.paymentAccountsDirect,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.paymentPayHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    _buildDynamicAccountsList(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: l10n.paymentUploadProof,
                icon: Icons.upload_file_rounded,
                onPressed: () async {
                  onProceedToUploadProof?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getShopData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('shops')
          .doc(booking.shopId)
          .get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  Widget _buildDynamicAccountsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getShopData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // E2: shared loading state (the FutureBuilder used to
          // render the empty state while still loading).
          return  AppLoadingState(
            message: l10n.paymentLoading,
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          // D1: the shop doc stores accounts under `bank_accounts`
          // (ShopModel.toMap), shaped by the owner onboarding — wallets
          // {'type': 'jazzcash'|'easypaisa', 'account', 'title'} and
          // banks {'type': 'bank', 'bank_name', 'iban', 'title'}. The
          // old code read a `bankAccounts` field with different keys,
          // so it never found the shop's real accounts.
          final rawAccounts = data['bank_accounts'] as List<dynamic>?;
          if (rawAccounts != null && rawAccounts.isNotEmpty) {
            return Column(
              children: rawAccounts.map((a) {
                final acc = a as Map<String, dynamic>;
                final type = (acc['type'] as String? ?? 'bank').toLowerCase();
                final isWallet = type == 'jazzcash' || type == 'easypaisa';
                final methodTitle = isWallet
                    ? (type == 'jazzcash' ? l10n.paymentJazzcash : l10n.paymentEasypaisa)
                    : (acc['bank_name'] as String? ?? l10n.paymentBankTransfer);
                // Banks only store an IBAN (no separate account number);
                // wallets store the mobile number.
                final number = isWallet
                    ? (acc['account'] as String? ?? '')
                    : (acc['iban'] as String? ?? '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PaymentAccountCard(
                    methodTitle: methodTitle,
                    accountTitle:
                        acc['title'] as String? ?? l10n.paymentVerified,
                    accountNumber: number,
                    iban: null,
                    brandColor: isWallet
                        ? AppColors.successTextFor(Theme.of(context).brightness)
                        : Theme.of(context).colorScheme.onSurface,
                    icon: isWallet
                        ? Icons.account_balance_wallet_rounded
                        : Icons.account_balance_rounded,
                  ),
                );
              }).toList(),
            );
          }
        }
        // Phase B (D1): when the shop has not configured any payment
        // accounts, say so — never show another shop's accounts as
        // if they were this shop's.
        // E2: shared empty state.
        return  AppEmptyState(
          title: l10n.paymentNoAccounts,
          message:
              l10n.paymentAddAccountsNote,
          icon: Icons.account_balance_rounded,
        );
      },
    );
  }
}
