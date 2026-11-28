import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/services/booking_cancel_service.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/utils/booking_next_step.dart';
import 'booking_waiting_line.dart';

/// The status-driven actions for one triage card, extracted from
/// [RequestTriageCard] so the card stays under the 250-line cap.
/// Phase B (D1): the actions depend on where the booking is in the
/// pipeline — only new requests can be approved or declined; a
/// submitted proof is verified on the detail screen; an approved
/// booking just waits for payment. Item 2 rebuilds this on the
/// shared resolver ([resolveOwnerNextStep]) so the card and the
/// detail can never disagree about what comes next:
/// * `requested` — Approve (primary) + Decline.
/// * `approved` — NO primary CTA, the waiting line instead
///   ([BookingWaitingPaymentLine]); walk-in keeps Cancel.
/// * `payment_submitted` — Verify Payment Proof (unchanged).
/// * `paid` — Start Handover, to the handover screen; walk-in
///   keeps Cancel as a secondary.
/// * `active` — Proceed to Return & Settlement, via the return
///   landing (never straight to inspection).
/// * `disputed` — View / Resolve Dispute, opening that booking's
///   dispute sheet in the owner's disputes centre.
/// * `completed` — Rate customer, to the owner rating view for
///   that booking (the return flow lands on All Bookings and
///   never routes here, so this is the only post-return entry
///   point to rate the customer).
/// * `rejected` / `cancelled` — terminal, nothing.
/// Navigation steps push their route from here (the card is pure
/// display + callbacks, and the route carries the booking id), so
/// no card or list-body change was needed to wire them.
class RequestTriageActions extends StatelessWidget {
  const RequestTriageActions({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
    this.onVerifyProof,
    this.onRecordPayment,
    this.onCancel,
    this.isProcessing = false,
    this.showActions = true,
  });

  final BookingEntity booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onVerifyProof;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onCancel;
  final bool isProcessing;
  final bool showActions;

  bool get _isWalkIn => booking.origin == 'walk_in';

  bool get _canAddWalkInPayment =>
      showActions &&
      _isWalkIn &&
      onRecordPayment != null &&
      booking.remainingBalance > 0;

  /// Worker B adds the owner cancel for walk-in `approved` /
  /// `paid` bookings (see [BookingCancelService.canOwnerCancel]) —
  /// online bookings never render a cancel action.
  bool get _showCancel =>
      showActions &&
      onCancel != null &&
      BookingCancelService.canOwnerCancel(booking);

  /// The deep-link target for a navigation step. Disputes carry
  /// the booking id so the centre opens that booking's sheet.
  void _goNextStep(BuildContext context, BookingNextStep step) {
    final dest = step.destination(booking);
    if (dest == null) return;
    if (step.kind == BookingNextStepKind.viewDispute) {
      context.push(
          '$dest?bookingId=${Uri.encodeComponent(booking.bookingId)}');
    } else {
      context.push(dest);
    }
  }

  IconData _iconFor(BookingNextStepKind kind) => switch (kind) {
        BookingNextStepKind.startHandover => Icons.key_rounded,
        BookingNextStepKind.returnSettlement =>
          Icons.keyboard_return_rounded,
        BookingNextStepKind.viewDispute => Icons.report_problem_outlined,
        BookingNextStepKind.rateCustomer => Icons.star_rate_rounded,
        _ => Icons.arrow_forward_rounded,
      };

  Widget _cancelButton(BuildContext context, AppLocalizations l10n) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = resolveOwnerNextStep(booking);
    switch (step.kind) {
      case BookingNextStepKind.verifyProof:
        if (!showActions) return const SizedBox.shrink();
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isProcessing ? null : onVerifyProof,
            icon: const Icon(Icons.fact_check_rounded, size: 18),
            label: Text(l10n.requestsVerifyProof),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      case BookingNextStepKind.approve:
        if (!showActions) return const SizedBox.shrink();
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
      case BookingNextStepKind.recordPayment:
        if (!showActions) return const SizedBox.shrink();
        final handoverRoute = RouteNames.ownerHandover
            .replaceFirst(':id', booking.bookingId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : onRecordPayment,
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: Text(l10n.walkInAddPayment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    isProcessing ? null : () => context.push(handoverRoute),
                icon: const Icon(Icons.key_rounded, size: 18),
                label: Text(l10n.bookingConfirmedStartHandover),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (_showCancel) ...[
              const SizedBox(height: 10),
              _cancelButton(context, l10n),
            ],
          ],
        );
      case BookingNextStepKind.startHandover:
      case BookingNextStepKind.returnSettlement:
      case BookingNextStepKind.viewDispute:
      case BookingNextStepKind.rateCustomer:
        if (!showActions) return const SizedBox.shrink();
        final showSecondaryPay = _canAddWalkInPayment &&
            (step.kind == BookingNextStepKind.startHandover ||
                step.kind == BookingNextStepKind.returnSettlement ||
                step.kind == BookingNextStepKind.rateCustomer);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    isProcessing ? null : () => _goNextStep(context, step),
                icon: Icon(_iconFor(step.kind), size: 18),
                label: Text(step.label(l10n, booking)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            if (showSecondaryPay) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onRecordPayment,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(step.kind == BookingNextStepKind.rateCustomer
                      ? l10n.walkInCollectDues
                      : l10n.walkInAddPayment),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            if (_showCancel) ...[
              const SizedBox(height: 10),
              _cancelButton(context, l10n),
            ],
          ],
        );
      case BookingNextStepKind.none:
        // `approved` waits for payment (no primary CTA); the
        // terminal statuses (`rejected` / `cancelled`) render
        // nothing — `completed` resolves to `rateCustomer`
        // above, so it never reaches this branch.
        if (booking.status != 'approved') {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookingWaitingPaymentLine(booking: booking),
            if (_showCancel) ...[
              const SizedBox(height: 10),
              _cancelButton(context, l10n),
            ],
          ],
        );
      default:
        // Customer-only kinds never resolve for the owner.
        return const SizedBox.shrink();
    }
  }
}
