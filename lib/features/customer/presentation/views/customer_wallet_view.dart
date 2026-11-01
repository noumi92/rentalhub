import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../widgets/wallet_transaction_tile.dart';

class CustomerWalletView extends StatelessWidget {
  final VoidCallback? onBack;

  const CustomerWalletView({super.key, this.onBack});

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
                'Wallet & Security Escrow',
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
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.midnightNavy, AppColors.royalNavy],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.midnightNavy.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Escrow & Advances',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLavender,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Rs. 15,000',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              _EscrowPill(
                                  label: 'Advances Paid', value: 'Rs. 5,000'),
                              _EscrowPill(
                                  label: 'Security Escrow', value: 'Rs. 10,000'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Transaction Ledger',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnightNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const WalletTransactionTile(
                      title: 'Advance Deposit - Honda Civic (RH-849201)',
                      date: 'Today, 2:30 PM',
                      amount: 2500,
                      isDebit: true,
                      status: 'Verified',
                    ),
                    const SizedBox(height: 8),
                    const WalletTransactionTile(
                      title: 'Refundable Security Deposit Released',
                      date: 'Yesterday, 6:00 PM',
                      amount: 10000,
                      isDebit: false,
                      status: 'Settled',
                    ),
                    const SizedBox(height: 8),
                    const WalletTransactionTile(
                      title: 'Advance Lock - Toyota Yaris (RH-849182)',
                      date: '28 Oct 2026',
                      amount: 1500,
                      isDebit: true,
                      status: 'Completed',
                    ),
                    const SizedBox(height: 8),
                    const WalletTransactionTile(
                      title: 'Advance Refund - Showroom Cancelled',
                      date: '24 Oct 2026',
                      amount: 2000,
                      isDebit: false,
                      status: 'Refunded',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EscrowPill extends StatelessWidget {
  final String label;
  final String value;

  const _EscrowPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textLavender)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

