import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import  '../../../../finance/domain/entities/security_deposit_entity.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Phase B (H4): the deposits the shop holds — what is still held,
/// what was refunded in full, and what was deducted at return.
class FinanceDepositsSection extends StatelessWidget {
  final List<SecurityDepositEntity> deposits;

  const FinanceDepositsSection({super.key, required this.deposits});

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final held = deposits.where((d) => d.status == 'collected').toList();
    final released = deposits.where((d) => d.status == 'released').toList();
    final deducted = deposits.where((d) => d.status == 'deducted').toList();
    final heldAmount =
        held.fold<int>(0, (total, d) => total + d.amount);
    // Financial audit (2026-11-20): a partially-deducted deposit
    // ('deducted' with a netRefund > 0) DID refund money, but the
    // refunded row only summed 'released' records — the partial
    // refund vanished from the summary while the ledger's
    // deposit_refund expense still showed it.
    final refundedAmount = released.fold<int>(
            0, (total, d) => total + (d.netRefund ?? d.amount)) +
        deducted.fold<int>(0, (total, d) => total + (d.netRefund ?? 0));
    final deductedAmount =
        deducted.fold<int>(0, (total, d) => total + (d.deductedAmount ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.financeSecurityDeposits,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppCardDecoration.shadow(context)
          ),
          child: Column(
            children: [
              _row(context, l10n, l10n.financeDepositsHeld, l10n.financeDepositsCount(held.length), heldAmount),
              const Divider(height: 16),
              _row(context, l10n, l10n.financeDepositsRefunded, l10n.financeDepositsCount(released.length),
                  refundedAmount),
              const Divider(height: 16),
              _row(context, l10n, l10n.financeDepositsDeducted, l10n.financeDepositsCount(deducted.length),
                  deductedAmount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, String label, String count, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audit 2026-11-15 DS-8: 13 sp is bodyMedium, 11 sp is
            // labelSmall — theme slots, not hardcoded sizes.
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(count,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        Text(l10n.amountRs(formatRs(amount)),
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
