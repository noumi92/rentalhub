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
      backgroundColor: AppColors.backgroundLight,
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
              titleWidget: const Text(
                'Showroom Payment Accounts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
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
                        color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                AppColors.emeraldGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: AppColors.emeraldGreen, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Reservation Request Approved!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.midnightNavy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Transfer Rs. ${booking.advanceRequired} to lock your vehicle.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.sunsetOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Direct Transfer Channels',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnightNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pay to the verified showroom accounts below and capture a screenshot of your transfer.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
          final rawAccounts = data['bankAccounts'] as List<dynamic>?;
          if (rawAccounts != null && rawAccounts.isNotEmpty) {
            return Column(
              children: rawAccounts.map((a) {
                final acc = a as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PaymentAccountCard(
                    methodTitle: acc['bankName'] ?? 'Bank Transfer',
                    accountTitle: acc['accountTitle'] ?? 'RentalHub Verified',
                    accountNumber: acc['accountNumber'] ?? '',
                    iban: acc['iban'],
                    brandColor: AppColors.royalNavy,
                    icon: Icons.account_balance_rounded,
                  ),
                );
              }).toList(),
            );
          }
        }
        return Column(
          children: const [
            PaymentAccountCard(
              methodTitle: 'JazzCash Mobile Account',
              accountTitle: 'Al-Falah Rent a Car',
              accountNumber: '03001234567',
              brandColor: Color(0xFFED1C24),
              icon: Icons.phone_android_rounded,
            ),
            SizedBox(height: 12),
            PaymentAccountCard(
              methodTitle: 'EasyPaisa Wallet',
              accountTitle: 'Al-Falah Rent a Car',
              accountNumber: '03451234567',
              brandColor: Color(0xFF00A859),
              icon: Icons.account_balance_wallet_rounded,
            ),
            SizedBox(height: 12),
            PaymentAccountCard(
              methodTitle: 'Bank Meezan Islamic',
              accountTitle: 'Al Falah Motors Private Limited',
              accountNumber: '02010108920192',
              iban: 'PK45MEZN0002010108920192',
              brandColor: Color(0xFF020246),
              icon: Icons.account_balance_rounded,
            ),
          ],
        );
      },
    );
  }
}
