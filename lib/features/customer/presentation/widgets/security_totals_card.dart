import 'package:flutter/material.dart';

import '../../../../core/theme/card_decoration.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/customer_wallet_service.dart';

/// The Security section of a wallet: what Security is held, what was
/// released, what was deducted, what was refunded, and what the
/// customer still owes when deductions exceeded the amount held.
/// Shared by the customer wallet view and the owner per-customer
/// Security view, so both show the same totals. Only non-zero rows
/// render — a customer with only a held deposit sees just Held.
class SecurityTotalsCard extends StatelessWidget {
  const SecurityTotalsCard({super.key, required this.totals});

  final SecurityTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <(String, int)>[
      if (totals.held > 0) (l10n.walletSecurityHeld, totals.held),
      if (totals.released > 0)
        (l10n.walletSecurityReleased, totals.released),
      if (totals.deducted > 0)
        (l10n.walletSecurityDeducted, totals.deducted),
      if (totals.refunded > 0)
        (l10n.walletSecurityRefunded, totals.refunded),
      if (totals.owed > 0) (l10n.walletSecurityOwed, totals.owed),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.walletSecuritySection,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(rows[i].$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      const SizedBox(width: 8),
                      // E3: the amount scales down to fit instead of
                      // overflowing — at 200% text scale 'Rs. 150,000'
                      // is wider than the card at 360px. A money
                      // amount must stay fully visible, so it scales
                      // down rather than ellipsizing (same pattern as
                      // the triage card's fare row); no font size or
                      // text scale is reduced anywhere.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                              l10n.amountRs(formatRs(rows[i].$2)),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < rows.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
