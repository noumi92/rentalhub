import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// Phase B (G1): one ledger row on the owner dashboard, extracted
/// from [OwnerDashboardView]. The status chip is coloured by the
/// booking's real status instead of always green.
class DashboardLedgerItem extends StatelessWidget {
  final String bookingId;
  final String vehicleName;
  final String customerName;
  final int amount;
  final String status;

  const DashboardLedgerItem({
    super.key,
    required this.bookingId,
    required this.vehicleName,
    required this.customerName,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    // Audit fix (§2 / C3): brightness-aware status colours, following
    // the successTextFor pattern already used for `completed`. The old
    // fall-through was AppColors.secondary orange at 11 sp (~3.2:1,
    // fails AA) for every non-completed, non-active status.
    final statusColor = switch (status) {
      'completed' || 'paid' || 'approved' =>
        AppColors.successTextFor(brightness),
      'active' => scheme.primary,
      'requested' || 'payment_submitted' =>
        AppColors.orangeTextFor(brightness),
      'rejected' || 'cancelled' => AppColors.dangerTextFor(brightness),
      _ => scheme.onSurfaceVariant,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        // Audit fix (§2): the hardcoded light border stayed pale grey
        // in dark mode — use the theme outline instead.
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicleName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 2),
                Text('#$bookingId • $customerName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // C5: grouped thousands — "Rs. 125,000". (amountRs takes
              // an int, so the formatted string goes inline — see
              // dashboard_kpis.dart.)
              Text(l10n.amountRs(formatRs(amount)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
              const SizedBox(height: 2),
              // The stored status code stays as-is; only the
              // displayed label is localized (no upper-casing: Urdu
              // has no case, and the label reads as a word, not a code).
              Text(_statusLabel(l10n, status),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

/// The stored status code stays as-is; only the displayed label is
/// localized. Unknown codes fall back to the raw code.
String _statusLabel(AppLocalizations l10n, String status) => {'requested': l10n.requestsStatusRequested, 'payment_submitted': l10n.statusProofSubmitted, 'approved': l10n.statusApproved, 'paid': l10n.statusPaid, 'active': l10n.active, 'completed': l10n.statusCompleted, 'rejected': l10n.statusRejected, 'cancelled': l10n.statusCancelled}[status] ?? status;
