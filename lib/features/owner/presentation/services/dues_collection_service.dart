import '../../../../core/di/injection_container.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/services/booking_ledger_service.dart';

/// Item 6 (2026-11-21): the missing "dues paid later" step. Before
/// this, the dues screen could only remind the customer on
/// WhatsApp — money paid later had no path onto the booking or
/// into the ledger.
///
/// One call does both halves, in order:
/// 1. [BookingRemoteDataSource.recordBalanceCollected] — additive
///    and clamped to what is still owed, so the remaining balance
///    drops and the due clears (or shrinks, for a partial payment).
///    Awaited, not best-effort: a failed booking write fails the
///    collection rather than silently dropping money owed.
/// 2. [BookingLedgerService.postDues] — the cash posted to the
///    ledger exactly once, under the deterministic
///    `LEDGER-<bookingId>-dues` id, income/rent, into the account
///    for the payment method. Best-effort, like the return
///    settlement: a ledger failure never fails the collection it
///    describes.
///
/// The ledger posts exactly what the booking recorded: the
/// collected amount is the drop in the remaining balance, so an
/// overpayment (or a stale due) can never over-post the ledger.
class DuesCollectionService {
  static Future<BookingEntity> collectDue({
    required BookingEntity booking,
    required int amount,
    required String paymentMethod,
    BookingRemoteDataSource? bookingDataSource,
    BookingLedgerService? ledgerService,
  }) async {
    final ds = bookingDataSource ?? sl<BookingRemoteDataSource>();
    final before = await ds.getBookingById(booking.bookingId) ?? booking;
    final updated = await ds.recordBalanceCollected(
      bookingId: booking.bookingId,
      amount: amount,
    );
    final collected = before.remainingBalance - updated.remainingBalance;
    if (collected > 0) {
      try {
        final ledger = ledgerService ??
            (sl.isRegistered<BookingLedgerService>()
                ? sl<BookingLedgerService>()
                : null);
        await ledger?.postDues(
          booking: updated,
          amount: collected,
          paymentMethod: paymentMethod,
        );
      } catch (_) {}
    }
    return updated;
  }
}
