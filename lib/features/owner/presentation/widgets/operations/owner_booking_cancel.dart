import 'package:flutter/material.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../../bookings/data/services/booking_cancel_service.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import 'request_reject_dialog.dart';

/// The owner reject, moved out of [OwnerBookingRequestsView] so the
/// view stays under the 250-line cap — same dialog, same status
/// write, same feedback, verbatim behaviour. Returns the updated
/// booking, or null when the owner backed out or the write failed.
/// A rejected booking stays in the list under the Rejected tab
/// (the caller swaps the row in) instead of vanishing.
Future<BookingEntity?> rejectBookingRequest(
  BuildContext context,
  BookingEntity booking,
) async {
  // Phase B (D3): a rejection always carries a reason — the
  // customer sees it and knows what to fix.
  final l10n = AppLocalizations.of(context)!;
  final reason = await showRequestRejectDialog(context);
  if (reason == null || !context.mounted) return null;
  try {
    final updated = await sl<BookingRemoteDataSource>().updateBookingStatus(
      bookingId: booking.bookingId,
      status: 'rejected',
      rejectionReason: reason,
    );
    if (context.mounted) {
      AppFeedback.showInfo(context, l10n.requestsRejected(booking.bookingId));
    }
    return updated;
  } catch (_) {
    if (context.mounted) {
      AppFeedback.showError(context, l10n.shopSaveError);
    }
    return null;
  }
}

/// Worker B (cancel releases the deposit): the owner cancel for a
/// walk-in booking, mirroring the reject-reason dialog pattern —
/// a cancellation always carries a reason, stored on the booking's
/// `rejectionReason` so the customer sees it. Returns the trimmed
/// reason, or null when the owner backs out / leaves it blank.
Future<String?> showBookingCancelDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final reasonController = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.cancelTitle),
      content: TextField(
        controller: reasonController,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: l10n.cancelReasonLabel,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(reasonController.text.trim()),
          child: Text(l10n.cancelConfirm),
        ),
      ],
    ),
  );
  if (reason == null || reason.isEmpty) return null;
  return reason;
}

/// The owner cancel flow for one walk-in booking: confirm with a
/// reason, then cancel (status first, Security release best-
/// effort — see [BookingCancelService]). Returns the updated
/// booking, or null when the owner backed out or the cancel
/// failed. Guards on [BookingCancelService.canOwnerCancel] so an
/// online booking can never reach the status flip from here.
Future<BookingEntity?> cancelWalkInBooking(
  BuildContext context,
  BookingEntity booking,
) async {
  if (!BookingCancelService.canOwnerCancel(booking)) return null;
  final l10n = AppLocalizations.of(context)!;
  final reason = await showBookingCancelDialog(context);
  if (reason == null || !context.mounted) return null;
  try {
    final updated = await BookingCancelService.cancelBooking(
      booking: booking,
      reason: reason,
    );
    if (context.mounted) {
      AppFeedback.showInfo(context, l10n.cancelDone);
    }
    return updated;
  } catch (e) {
    if (context.mounted) {
      AppFeedback.showError(context, l10n.cancelFailedGeneric);
    }
    return null;
  }
}
