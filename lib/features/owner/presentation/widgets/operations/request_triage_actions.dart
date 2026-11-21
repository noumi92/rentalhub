import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/services/booking_cancel_service.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// The status-driven actions for one triage card, extracted from
/// [RequestTriageCard] so the card stays under the 250-line cap.
/// Phase B (D1): the actions depend on where the booking is in the
/// pipeline — only new requests can be approved or declined; a
/// submitted proof is verified on the detail screen; an approved
/// booking just waits for payment. Worker B adds the owner cancel
/// for walk-in `approved` / `paid` bookings (see
/// [BookingCancelService.canOwnerCancel]) — online bookings never
/// render a cancel action.
class RequestTriageActions extends StatelessWidget {
  const RequestTriageActions({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
    this.onVerifyProof,
    this.onCancel,
    this.isProcessing = false,
    this.showActions = true,
  });

  final BookingEntity booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onVerifyProof;
  final VoidCallback? onCancel;
  final bool isProcessing;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (booking.status == 'payment_submitted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isProcessing ? null : onVerifyProof,
          icon: const Icon(Icons.fact_check_rounded, size: 18),
          label: Text(l10n.requestsVerifyProof),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    if (booking.status == 'requested' && showActions) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isProcessing ? null : onReject,
              style: OutlinedButton.styleFrom(
                // §9: theme danger tokens, not raw red shades.
                foregroundColor: AppColors.dangerTextFor(
                    Theme.of(context).brightness),
                side:
                    BorderSide(color: Theme.of(context).colorScheme.error),
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(l10n.requestsDecline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isProcessing ? null : onApprove,
              style: ElevatedButton.styleFrom(
                // §9: white on accentSuccess #10B981 is ~2.5:1;
                // accentSuccessStrong #047857 is 5.48:1.
                backgroundColor: AppColors.accentSuccessStrong,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(l10n.requestsApprovePay),
            ),
          ),
        ],
      );
    }
    if (showActions &&
        onCancel != null &&
        BookingCancelService.canOwnerCancel(booking)) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isProcessing ? null : onCancel,
          icon: const Icon(Icons.cancel_outlined),
          label: Text(l10n.cancelBooking),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                AppColors.dangerTextFor(Theme.of(context).brightness),
            side: BorderSide(color: Theme.of(context).colorScheme.error),
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
