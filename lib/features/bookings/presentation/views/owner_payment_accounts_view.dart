import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/payment_account_card.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: Text(
                'Showroom Payment Accounts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
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
                          const Icon(Icons.verified_rounded,
                              color: AppColors.accentSuccess, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reservation Request Approved!',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Transfer Rs. ${booking.advanceRequired} to lock your vehicle.',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Direct Transfer Channels',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pay to the verified showroom accounts below and capture a screenshot of your transfer.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    _buildDynamicAccountsList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: 'Upload Payment Proof & Receipt',
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

  Widget _buildDynamicAccountsList() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getShopData(),
      builder: (context, snapshot) {
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
                final type =
                    (acc['type'] as String? ?? 'bank').toLowerCase();
                final isWallet =
                    type == 'jazzcash' || type == 'easypaisa';
                final methodTitle = isWallet
                    ? (type == 'jazzcash' ? 'JazzCash' : 'EasyPaisa')
                    : (acc['bank_name'] as String? ?? 'Bank Transfer');
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
                        acc['title'] as String? ?? 'RentalHub Verified',
                    accountNumber: number,
                    iban: null,
                    brandColor: isWallet
                        ? AppColors.accentSuccess
                        : AppColors.primary,
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
        return Column(
          children: [
            Icon(Icons.account_balance_rounded,
                size: 40, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text(
              'No payment accounts configured for this shop yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Add JazzCash, EasyPaisa or bank accounts in Shop Settings so customers know where to pay.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}
