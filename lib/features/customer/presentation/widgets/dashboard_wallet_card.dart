import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/customer_wallet_service.dart';

/// E1/F1: the dashboard's wallet summary — the customer's real advances
/// paid and security escrow held (from the same wallet service the
/// wallet screen uses). Tapping it opens the wallet.
class DashboardWalletCard extends StatelessWidget {
  const DashboardWalletCard({
    super.key,
    required this.summary,
    this.onTap,
  });

  final CustomerWalletSummary? summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sunsetOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.sunsetOrange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wallet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary == null
                        ? 'Advances and deposits will appear here.'
                        : 'Advances Rs. ${summary!.advancesPaid} • '
                            'Escrow Rs. ${summary!.escrowHeld}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${summary?.total ?? 0}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.midnightNavy,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
