import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import 'request_triage_card.dart';

/// §10: the requested-state detail for a booking that has not been
/// approved yet. The old accounts view showed every non-proof booking
/// as "Reservation Request Approved!" with an Upload-proof CTA —
///
/// proof before approval, wrong order. This renders the booking
/// summary with the same Approve / Reject actions as the triage card
/// (same data-source calls, same rejection-reason dialog), and reports
/// the approved booking back so the caller can flip to the payment
/// accounts view. A rejection pops back to triage.
class RequestedBookingDetail extends StatefulWidget {
  const RequestedBookingDetail({
    super.key,
    required this.booking,
    required this.onApproved,
    this.showActions = true,
  });

  final BookingEntity booking;
  final ValueChanged<BookingEntity> onApproved;

  /// False when the viewer is not the shop owner (e.g. a customer
  /// reaching this shared view from the payment-proof route): the
  /// summary renders, but no owner Approve/Reject actions.
  final bool showActions;

  @override
  State<RequestedBookingDetail> createState() =>
      _RequestedBookingDetailState();
}

class _RequestedBookingDetailState extends State<RequestedBookingDetail> {
  bool _processing = false;

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _processing = true);
    try {
      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(
          bookingId: widget.booking.bookingId, status: 'approved');
      if (mounted) {
        AppFeedback.showSuccess(
            context, l10n.requestsApproved(widget.booking.bookingId));
        widget.onApproved(widget.booking.copyWith(status: 'approved'));
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
            context, l10n.requestsApprovalFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.requestsRejectTitle),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.requestsRejectReasonLabel,
            hintText: l10n.requestsRejectReasonHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(reasonController.text.trim()),
            child: Text(l10n.requestsRejectButton),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() => _processing = true);
    try {
      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(
        bookingId: widget.booking.bookingId,
        status: 'rejected',
        rejectionReason: reason,
      );
      if (mounted) {
        AppFeedback.showInfo(
            context, l10n.requestsRejected(widget.booking.bookingId));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, l10n.requestsDeclineFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The triage card is the summary (vehicle, customer, phone,
          // package, amount) and carries the Approve / Decline
          // actions; the banner above it only frames the decision.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.requestsAwaitingReview(1),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RequestTriageCard(
            booking: widget.booking,
            isProcessing: _processing,
            showActions: widget.showActions,
            onApprove: _approve,
            onReject: _reject,
          ),
          if (widget.showActions) ...[
            const SizedBox(height: 16),
            // The card's buttons are the actions; this pinned CTA is the
            // same approve for owners who scroll past the card.
            DebouncedButton(
              text: l10n.requestsApprovePay,
              icon: Icons.check_circle_rounded,
              backgroundColor: AppColors.accentSuccessStrong,
              isLoading: _processing,
              onPressed: _approve,
            ),
          ],
        ],
      ),
    );
  }
}
