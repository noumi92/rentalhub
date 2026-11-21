import '../../../../core/di/injection_container.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/data/services/booking_ledger_service.dart';
import '../../../finance/domain/entities/security_deposit_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../datasources/booking_remote_data_source.dart';

/// Worker B (cancel releases the deposit): the one place a
/// cancellation releases a held security deposit, shared by the
/// customer cancel screen and the owner triage cancel.
///
/// Rules (user decisions 2026-11-21):
/// * WHO: walk-in bookings — the shop owner may cancel them in
///   `approved` and `paid`. Online bookings are never owner-
///   cancelled (the customer cancels their own, `requested` /
///   `approved` only, as today).
/// * MONEY: the held Security is refunded IN FULL on cancel, no
///   deductions (a cancelled booking has no km / fuel / damage).
///   The advance is UNTOUCHED — it stays with the showroom.
///
/// Order: the status flip first, the release second and
/// best-effort — a ledger / release failure never blocks or rolls
/// back the cancellation itself (the existing `postOnce`
/// best-effort convention).
class BookingCancelService {
  const BookingCancelService._();

  /// The ledger event for a cancel release — distinct from the
  /// return-refund event (`deposit-refund`), so the two can never
  /// collide or double-post for one booking.
  static const String cancelRefundEvent = 'deposit-cancel-refund';

  /// A walk-in booking, with the same legacy backfill
  /// [BookingModel.fromMap] uses: [BookingEntity.origin] wins
  /// when present; older docs carry no origin, so a `walkin-…`
  /// customerId is a walk-in and anything else is online.
  static bool isWalkInBooking(BookingEntity booking) {
    return switch (booking.origin) {
      'walk_in' => true,
      'online' => false,
      _ => booking.customerId.startsWith('walkin-'),
    };
  }

  /// Whether the shop owner may cancel this booking: walk-in only,
  /// and only while it is `approved` or `paid` (before handover —
  /// an `active` booking's car is already out, and `requested`
  /// online-style triage is approve / reject, not cancel).
  static bool canOwnerCancel(BookingEntity booking) =>
      isWalkInBooking(booking) &&
      (booking.status == 'approved' || booking.status == 'paid');

  /// Releases the booking's held Security in full and posts the
  /// refund to the ledger. Returns the released record, or null
  /// when no deposit was held (no-op — no ledger entry). A second
  /// call for the same booking is a no-op: the release is
  /// idempotent and `postOnce` dedupes the ledger entry.
  ///
  /// The ledger posting uses the original deposit method when the
  /// booking knows it ([BookingEntity.depositPaymentMethod]) so
  /// the refund lands in the same account the Security was paid
  /// into; unknown falls back to the shop's default account, per
  /// [BookingLedgerService].
  static Future<SecurityDepositEntity?> releaseDepositOnCancel({
    required BookingEntity booking,
    SecurityDepositDataSource? deposits,
    BookingLedgerService? ledger,
  }) async {
    final ds = deposits ??
        (sl.isRegistered<SecurityDepositDataSource>()
            ? sl<SecurityDepositDataSource>()
            : null);
    if (ds == null) return null;
    final released =
        await ds.releaseOnCancel(bookingId: booking.bookingId);
    if (released == null) return null;
    final refund = released.netRefund ?? released.amount;
    if (refund <= 0) return released;
    try {
      final lg = ledger ??
          (sl.isRegistered<BookingLedgerService>()
              ? sl<BookingLedgerService>()
              : null);
      await lg?.postOnce(
        booking: booking,
        event: cancelRefundEvent,
        kind: 'expense',
        category: 'deposit_refund',
        amount: refund,
        paymentMethod: booking.depositPaymentMethod,
        note: 'Security refund for ${booking.bookingId}',
      );
    } catch (_) {
      // Best-effort: the release already landed; a ledger failure
      // must never surface as a cancel failure.
    }
    return released;
  }

  /// Cancels the booking: status first, then the best-effort
  /// deposit release. Throws only when the status update itself
  /// fails. The [reason] is stored on the booking's
  /// `rejectionReason`, the same field the customer cancel flow
  /// uses, so the detail screen and owner triage read it.
  static Future<BookingEntity> cancelBooking({
    required BookingEntity booking,
    String? reason,
    BookingRemoteDataSource? bookings,
    SecurityDepositDataSource? deposits,
    BookingLedgerService? ledger,
  }) async {
    final ds = bookings ?? sl<BookingRemoteDataSource>();
    final updated = await ds.updateBookingStatus(
      bookingId: booking.bookingId,
      status: 'cancelled',
      rejectionReason: reason,
    );
    try {
      await releaseDepositOnCancel(
        booking: updated,
        deposits: deposits,
        ledger: ledger,
      );
    } catch (_) {
      // Best-effort: the cancellation already landed.
    }
    return updated;
  }
}
