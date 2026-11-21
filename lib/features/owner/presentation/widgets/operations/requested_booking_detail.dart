import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/utils/booking_next_step.dart';
import 'approve_booking_sheet.dart';
import 'booking_fare_breakdown.dart';
import 'booking_request_checklist.dart';
import 'confirm_terms_step.dart';
import 'request_detail_checks.dart';
import 'request_reject_dialog.dart';
import 'request_triage_card.dart';

/// §10: the requested-state detail for a booking that has not been
/// approved yet. The old accounts view showed every non-proof booking
/// as "Reservation Request Approved!" with an Upload-proof CTA —
///
/// proof before approval, wrong order. This renders the booking
/// summary with the same Approve / Reject actions as the triage card
/// (same data-source calls, same rejection-reason dialog), and reports
/// the approved booking back so the caller can flip to the payment
/// accounts view. A rejection navigates to All Bookings
/// (navigate-back rule, 2026-11-21).
class RequestedBookingDetail extends StatefulWidget {
  const RequestedBookingDetail({
    super.key,
    required this.booking,
    required this.onApproved,
    this.showActions = true,
    this.firestore,
  });

  final BookingEntity booking;
  final ValueChanged<BookingEntity> onApproved;

  /// False when the viewer is not the shop owner (e.g. a customer
  /// reaching this shared view from the payment-proof route): the
  /// summary renders, but no owner Approve/Reject actions.
  final bool showActions;
  /// Injectable Firestore for the approve sheet (tests only).
  final FirebaseFirestore? firestore;

  @override
  State<RequestedBookingDetail> createState() =>
      _RequestedBookingDetailState();
}

class _RequestedBookingDetailState extends State<RequestedBookingDetail> {
  bool _processing = false;

  /// O18: approving opens the approve sheet (account + terms)
  /// instead of a one-tap status flip; the sheet writes status +
  /// account + deadline and reports back.
  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context)!;
    await showApproveBookingSheet(
      context,
      booking: widget.booking,
      firestore: widget.firestore,
      onApproved: (updated) {
        if (!mounted) return;
        AppFeedback.showSuccess(
            context, l10n.requestsApproved(updated.bookingId));
        widget.onApproved(updated);
      },
    );
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showRequestRejectDialog(context);
    if (reason == null || !mounted) return;
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
        // Navigate-back rule (2026-11-21): after the reject save,
        // go to All Bookings — the rejected booking is not in the
        // Proof bucket the list defaults to.
        goToAllOwnerBookings(context);
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
                        ?.copyWith(fontWeight: FontWeight.w500),
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
          const SizedBox(height: 12),
          // O17: the customer note, stored on the booking — shown
          // verbatim, never summarised or invented. Hidden when the
          // booking carries no note.
          if ((widget.booking.notes ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.requestsCustomerNote,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.booking.notes!.trim(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          if ((widget.booking.notes ?? '').trim().isNotEmpty)
            const SizedBox(height: 12),
          // O17: the live blacklist re-check for this customer's
          // CNIC. Renders nothing when the booking has no CNIC or
          // the list cannot be read.
          RequestBlacklistLine(cnic: widget.booking.customerCnic),
          const SizedBox(height: 12),
          // Audit §5 item 2 (O15): the fare breakdown — daily rate ×
          // days, advance paid / remaining, dates + times, trip tag.
          BookingFareBreakdown(booking: widget.booking),
          if (widget.showActions) ...[
            const SizedBox(height: 12),
            // Audit §5 item 16 (O15 variant): the pre-accept
            // checklist, shown before Accept.
            BookingRequestChecklist(booking: widget.booking),
            const SizedBox(height: 12),
            // Audit §5 item 16 (O16 p.6): the Confirm Terms step —
            // all four items ticked, then Confirm Booking accepts.
            ConfirmTermsStep(onConfirm: _approve),
            const SizedBox(height: 12),
            // Audit §5 item 16 (O17 p.6): convert the request into a
            // manual entry, prefilled with its customer / car / dates.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _convertToManual(context),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(l10n.bookingConvertToManual),
              ),
            ),
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

  void _convertToManual(BuildContext context) {
    final booking = widget.booking;
    final params = <String, String>{};
    if ((booking.customerName ?? '').isNotEmpty) {
      params['name'] = booking.customerName!;
    }
    if ((booking.customerPhone ?? '').isNotEmpty) {
      params['phone'] = booking.customerPhone!;
    }
    if ((booking.customerCnic ?? '').isNotEmpty) {
      params['cnic'] = booking.customerCnic!;
    }
    params['vehicle'] = booking.vehicleId;
    params['pickup'] = booking.pickupTime.toIso8601String();
    params['return'] = booking.returnTime.toIso8601String();
    params['tripType'] = booking.tripType;
    // Registrar: the manual-booking route reads vehicle / pickup /
    // return / tripType from these query params (see
    // audit_impl_manifest_worker_a.md).
    context.push(Uri(
      path: RouteNames.ownerManualBooking,
      queryParameters: params,
    ).toString());
  }
}
