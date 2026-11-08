import 'package:flutter/material.dart';

import  '../../../../finance/domain/entities/security_deposit_entity.dart';

/// Phase B (H4): the deposits the shop holds — what is still held,
/// what was refunded in full, and what was deducted at return.
class FinanceDepositsSection extends StatelessWidget {
  final List<SecurityDepositEntity> deposits;

  const FinanceDepositsSection({super.key, required this.deposits});

  @override
  Widget build(BuildContext context) {
    final held = deposits.where((d) => d.status == 'collected').toList();
    final released = deposits.where((d) => d.status == 'released').toList();
    final deducted = deposits.where((d) => d.status == 'deducted').toList();
    final heldAmount =
        held.fold<int>(0, (total, d) => total + d.amount);
    final refundedAmount =
        released.fold<int>(0, (total, d) => total + (d.netRefund ?? d.amount));
    final deductedAmount =
        deducted.fold<int>(0, (total, d) => total + (d.deductedAmount ?? 0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Security Deposits',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _row(context, 'Held now', '${held.length} deposits', heldAmount),
              const Divider(height: 16),
              _row(context, 'Refunded in full', '${released.length} deposits',
                  refundedAmount),
              const Divider(height: 16),
              _row(context, 'Deducted at return', '${deducted.length} deposits',
                  deductedAmount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String count, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800)),
            Text(count,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        Text('Rs. $amount',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                )),
      ],
    );
  }
}
