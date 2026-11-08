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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.secondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary == null
                        ? 'Advances and deposits will appear here.'
                        : 'Advances Rs. ${summary!.advancesPaid} • '
                            'Escrow Rs. ${summary!.escrowHeld}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${summary?.total ?? 0}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
