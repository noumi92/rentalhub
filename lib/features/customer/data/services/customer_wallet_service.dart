import 'package:firebase_auth/firebase_auth.dart';

import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';

/// One line in the customer's wallet ledger.
class WalletLedgerEntry {
  const WalletLedgerEntry({
    required this.title,
    required this.date,
    required this.dateLabel,
    required this.amount,
    required this.isDebit,
    required this.status,
  });

  final String title;
  // The event's real date — the deposit's own timestamp, or the trip's
  // pickup date for an advance (bookings carry no payment timestamp,
  // so the label says "Pickup" rather than pretending to be a pay date).
  final DateTime date;
  final String dateLabel;
  final int amount;
  final bool isDebit;
  final String status;
}

/// F1: the customer's real money — advances actually paid on their
/// bookings plus the security deposits held on those bookings. This is
/// NOT the shop's finance ledger (owner H); the shop's ledger is never
/// shown here.
class CustomerWalletSummary {
  const CustomerWalletSummary({
    required this.advancesPaid,
    required this.escrowHeld,
    required this.entries,
  });

  final int advancesPaid;
  final int escrowHeld;
  final List<WalletLedgerEntry> entries; // newest first

  int get total => advancesPaid + escrowHeld;
}

class CustomerWalletService {
  CustomerWalletService({
    required BookingRemoteDataSource bookings,
    required SecurityDepositDataSource deposits,
  })  : _bookings = bookings,
        _deposits = deposits;

  final BookingRemoteDataSource _bookings;
  final SecurityDepositDataSource _deposits;

  static String currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'cust-101';
    } catch (_) {
      return 'cust-101';
    }
  }

  Future<CustomerWalletSummary> load(String uid) async {
    final bookings = await _bookings.getCustomerBookings(uid);
    return _build(bookings);
  }

  /// Live updates (Item 2): the same summary, re-computed on every
  /// booking change — a submit, an owner approve / payment verify,
  /// or a queued write landing all flow into the wallet without a
  /// manual reload. Deposits are still read one-time per emission
  /// (they have no booking-style live feed yet). Built on `asyncMap`
  /// (not `await for`): cancelling the subscription must unwind,
  /// and an `await for` over the change feed never completes its
  /// cancel.
  Stream<CustomerWalletSummary> watch(String uid) =>
      _bookings.streamCustomerBookings(uid).asyncMap(_build);

  Future<CustomerWalletSummary> _build(
      List<BookingEntity> bookings) async {
    var advancesPaid = 0;
    var escrowHeld = 0;
    final entries = <WalletLedgerEntry>[];

    for (final b in bookings) {
      if (b.advancePaid > 0) {
        advancesPaid += b.advancePaid;
        entries.add(WalletLedgerEntry(
          title: 'Advance paid — ${b.vehicleName ?? 'Rental Car'} '
              '(${b.bookingId})',
          date: b.pickupTime,
          dateLabel: 'Pickup ${_shortDate(b.pickupTime)}',
          amount: b.advancePaid,
          isDebit: true,
          status: b.status == 'completed' ? 'Completed' : 'Paid',
        ));
      }
      final deposit = await _deposits.getByBookingId(b.bookingId);
      if (deposit == null) continue;
      final vehicle = b.vehicleName ?? 'Rental Car';
      if (deposit.status == 'collected') {
        escrowHeld += deposit.amount;
        entries.add(WalletLedgerEntry(
          title: 'Security deposit held — $vehicle (${b.bookingId})',
          date: deposit.collectedAt ?? b.pickupTime,
          dateLabel: deposit.collectedAt != null
              ? 'Collected ${_shortDate(deposit.collectedAt!)}'
              : 'Pickup ${_shortDate(b.pickupTime)}',
          amount: deposit.amount,
          isDebit: true,
          status: 'Held',
        ));
      } else if (deposit.status == 'released') {
        entries.add(WalletLedgerEntry(
          title: 'Security deposit released — $vehicle (${b.bookingId})',
          date: deposit.releasedAt ?? b.returnTime,
          dateLabel: deposit.releasedAt != null
              ? 'Released ${_shortDate(deposit.releasedAt!)}'
              : 'Return ${_shortDate(b.returnTime)}',
          amount: deposit.netRefund ?? deposit.amount,
          isDebit: false,
          status: 'Released',
        ));
      } else if (deposit.status == 'deducted') {
        final deducted = deposit.deductedAmount ?? 0;
        if (deducted > 0) {
          entries.add(WalletLedgerEntry(
            title: 'Deposit deduction — $vehicle (${b.bookingId})',
            date: deposit.deductedAt ?? b.returnTime,
            dateLabel: deposit.deductedAt != null
                ? 'Settled ${_shortDate(deposit.deductedAt!)}'
                : 'Return ${_shortDate(b.returnTime)}',
            amount: deducted,
            isDebit: true,
            status: 'Deducted',
          ));
        }
        final refund = deposit.netRefund ?? 0;
        if (refund > 0) {
          entries.add(WalletLedgerEntry(
            title: 'Deposit refund — $vehicle (${b.bookingId})',
            date: deposit.deductedAt ?? b.returnTime,
            dateLabel: deposit.deductedAt != null
                ? 'Settled ${_shortDate(deposit.deductedAt!)}'
                : 'Return ${_shortDate(b.returnTime)}',
            amount: refund,
            isDebit: false,
            status: 'Refunded',
          ));
        }
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return CustomerWalletSummary(
      advancesPaid: advancesPaid,
      escrowHeld: escrowHeld,
      entries: entries,
    );
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
