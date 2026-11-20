import 'package:flutter/material.dart';

import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// O18 terms summary shown in the approve sheet: advance now,
/// remaining at pickup, refundable deposit at pickup, and the
/// 30-minute payment deadline (display-only — no auto-cancel).
/// The deposit comes from the vehicle's `securityDepositPkr` and is
/// omitted when unknown, never invented.
class ApproveTermsSummary extends StatelessWidget {
  const ApproveTermsSummary({
    super.key,
    required this.booking,
    required this.depositPkr,
    required this.deadline,
  });

  final BookingEntity booking;
  final int? depositPkr;
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(deadline));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.approveAssignTermsTitle,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _TermRow(
          label: l10n.approveAssignAdvanceNow(
              l10n.amountRs(formatRs(booking.advanceRequired))),
        ),
        _TermRow(
          label: l10n.approveAssignRemainingPickup(
              l10n.amountRs(formatRs(booking.remainingBalance))),
        ),
        if (depositPkr != null)
          _TermRow(
            label: l10n.approveAssignDepositPickup(
                l10n.amountRs(formatRs(depositPkr!))),
          ),
        _TermRow(label: l10n.approveAssignDeadline(time)),
        Text(
          l10n.approveAssignNoAutoCancel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
