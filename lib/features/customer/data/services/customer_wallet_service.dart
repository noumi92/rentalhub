import '../../../../../core/auth/signed_in_user.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/domain/entities/security_deposit_entity.dart';

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

/// Localized wording for the wallet's Security ledger entries. The
/// service builds entry titles as plain strings, so the caller
/// supplies the localized wording as functions (the customer wallet
/// view passes the AppLocalizations methods) and the service calls
/// them with the vehicle and booking. When no titles are supplied
/// (unit tests, non-widget callers) the English wording from
/// app_en.arb is used.
class WalletEntryTitles {
  const WalletEntryTitles({
    required this.securityHeld,
    required this.securityReleased,
    required this.securityReleasedOnCancel,
    required this.securityDeducted,
    required this.securityRefunded,
    required this.securityOwed,
  });

  /// The English wording from app_en.arb — keep in sync with the
  /// `walletEntrySecurity*` keys if those ever change. Static
  /// tear-offs, so this stays a compile-time constant.
  static const english = WalletEntryTitles(
    securityHeld: _enHeld,
    securityReleased: _enReleased,
    securityReleasedOnCancel: _enReleasedOnCancel,
    securityDeducted: _enDeducted,
    securityRefunded: _enRefunded,
    securityOwed: _enOwed,
  );

  final String Function(String vehicle, String booking) securityHeld;
  final String Function(String vehicle, String booking) securityReleased;
  final String Function(String vehicle, String booking)
      securityReleasedOnCancel;
  final String Function(String vehicle, String booking) securityDeducted;
  final String Function(String vehicle, String booking) securityRefunded;
  final String Function(String vehicle, String booking) securityOwed;

  static String _enHeld(String vehicle, String booking) =>
      'Security held — $vehicle ($booking)';
  static String _enReleased(String vehicle, String booking) =>
      'Security released — $vehicle ($booking)';
  static String _enReleasedOnCancel(String vehicle, String booking) =>
      'Security released on cancellation — $vehicle ($booking)';
  static String _enDeducted(String vehicle, String booking) =>
      'Security deduction — $vehicle ($booking)';
  static String _enRefunded(String vehicle, String booking) =>
      'Security refund — $vehicle ($booking)';
  static String _enOwed(String vehicle, String booking) =>
      'Security still owed — $vehicle ($booking)';
}

/// The Security section of a wallet: one customer's held Security
/// across their bookings, split by what happened to it. Computed
/// from the deposit records, so the customer wallet and the owner
/// per-customer Security view always agree.
class SecurityTotals {
  const SecurityTotals({
    this.held = 0,
    this.released = 0,
    this.deducted = 0,
    this.refunded = 0,
    this.owed = 0,
  });

  /// Currently held (status 'collected').
  final int held;

  /// Returned in full, at return or on cancellation
  /// (`netRefund ?? amount` per released record).
  final int released;

  /// Kept by the shop at settlement, capped at the amount held.
  final int deducted;

  /// Returned after deductions (`netRefund` per deducted record).
  final int refunded;

  /// Deductions above the amount held — the customer still owes
  /// this. Shown here only; it is NOT added to dues (open item b).
  final int owed;

  bool get hasActivity =>
      held > 0 || released > 0 || deducted > 0 || refunded > 0 || owed > 0;

  /// Totals over one customer's deposits, whatever the source —
  /// the customer wallet's per-booking read or the owner view's
  /// `getShopDeposits` list filtered by customer.
  factory SecurityTotals.fromDeposits(
      Iterable<SecurityDepositEntity> deposits) {
    var held = 0;
    var released = 0;
    var deducted = 0;
    var refunded = 0;
    var owed = 0;
    for (final d in deposits) {
      switch (d.status) {
        case 'collected':
          held += d.amount;
        case 'released':
          released += d.netRefund ?? d.amount;
        case 'deducted':
          deducted += d.deductedAmount ?? 0;
          refunded += d.netRefund ?? 0;
          owed += d.amountOwed ?? 0;
      }
    }
    return SecurityTotals(
      held: held,
      released: released,
      deducted: deducted,
      refunded: refunded,
      owed: owed,
    );
  }
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
    this.security = const SecurityTotals(),
  });

  final int advancesPaid;
  final int escrowHeld;
  final List<WalletLedgerEntry> entries; // newest first

  /// The Security section totals, computed from the same deposits
  /// as [entries] (see [SecurityTotals]).
  final SecurityTotals security;

  int get total => advancesPaid + escrowHeld;
}

class CustomerWalletService {
  CustomerWalletService({
    required BookingRemoteDataSource bookings,
    required SecurityDepositDataSource deposits,
    this.titles = WalletEntryTitles.english,
  })  : _bookings = bookings,
        _deposits = deposits;

  final BookingRemoteDataSource _bookings;
  final SecurityDepositDataSource _deposits;

  /// Localized Security entry wording (see [WalletEntryTitles]).
  final WalletEntryTitles titles;

  /// The signed-in customer's uid, or null when nobody is signed in.
  /// AC-8: this NEVER falls back to a placeholder uid — a signed-out
  /// wallet must never read another customer's bookings and deposits.
  /// Uses the [SignedInUser] seam, so widget tests exercise the
  /// signed-in path via `SignedInUser.override` (same pattern as the
  /// bookings view) without reintroducing a fallback in production.
  static String? currentUid() => SignedInUser.current()?.uid;

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
    final deposits = <SecurityDepositEntity>[];

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
      deposits.add(deposit);
      if (deposit.status == 'collected') escrowHeld += deposit.amount;
      entries.addAll(securityEntriesFor(
        deposit: deposit,
        vehicle: b.vehicleName ?? 'Rental Car',
        bookingId: b.bookingId,
        pickupTime: b.pickupTime,
        returnTime: b.returnTime,
        titles: titles,
      ));
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return CustomerWalletSummary(
      advancesPaid: advancesPaid,
      escrowHeld: escrowHeld,
      security: SecurityTotals.fromDeposits(deposits),
      entries: entries,
    );
  }

  /// One deposit's ledger entries — the shared rule behind the
  /// customer wallet and the owner per-customer Security view, so
  /// both word the same deposit the same way. A collected deposit
  /// is one Held entry; a released deposit is one Released entry
  /// (cancel-releases worded distinctly from return-releases, via
  /// [SecurityDepositEntity.releaseReason]); a deducted deposit is
  /// a Deduction entry, a Refund entry when anything comes back,
  /// and a Still-owed entry when the deductions exceed the amount
  /// held.
  static List<WalletLedgerEntry> securityEntriesFor({
    required SecurityDepositEntity deposit,
    required String vehicle,
    required String bookingId,
    required DateTime pickupTime,
    required DateTime returnTime,
    required WalletEntryTitles titles,
  }) {
    final entries = <WalletLedgerEntry>[];
    if (deposit.status == 'collected') {
      entries.add(WalletLedgerEntry(
        title: titles.securityHeld(vehicle, bookingId),
        date: deposit.collectedAt ?? pickupTime,
        dateLabel: deposit.collectedAt != null
            ? 'Collected ${_shortDate(deposit.collectedAt!)}'
            : 'Pickup ${_shortDate(pickupTime)}',
        amount: deposit.amount,
        isDebit: true,
        status: 'Held',
      ));
    } else if (deposit.status == 'released') {
      // Worker B: a cancel-release is a full refund with no return
      // inspection — word it distinctly from a return-release.
      // Older records carry no releaseReason (null); they are
      // return-settlements, so they take the return wording.
      final cancelled = deposit.releaseReason == 'cancel';
      entries.add(WalletLedgerEntry(
        title: cancelled
            ? titles.securityReleasedOnCancel(vehicle, bookingId)
            : titles.securityReleased(vehicle, bookingId),
        date: deposit.releasedAt ?? returnTime,
        dateLabel: deposit.releasedAt != null
            ? 'Released ${_shortDate(deposit.releasedAt!)}'
            : 'Return ${_shortDate(returnTime)}',
        amount: deposit.netRefund ?? deposit.amount,
        isDebit: false,
        status: 'Released',
      ));
    } else if (deposit.status == 'deducted') {
      final deducted = deposit.deductedAmount ?? 0;
      if (deducted > 0) {
        entries.add(WalletLedgerEntry(
          title: titles.securityDeducted(vehicle, bookingId),
          date: deposit.deductedAt ?? returnTime,
          dateLabel: deposit.deductedAt != null
              ? 'Settled ${_shortDate(deposit.deductedAt!)}'
              : 'Return ${_shortDate(returnTime)}',
          amount: deducted,
          isDebit: true,
          status: 'Deducted',
        ));
      }
      final refund = deposit.netRefund ?? 0;
      if (refund > 0) {
        entries.add(WalletLedgerEntry(
          title: titles.securityRefunded(vehicle, bookingId),
          date: deposit.deductedAt ?? returnTime,
          dateLabel: deposit.deductedAt != null
              ? 'Settled ${_shortDate(deposit.deductedAt!)}'
              : 'Return ${_shortDate(returnTime)}',
          amount: refund,
          isDebit: false,
          status: 'Refunded',
        ));
      }
      // The excess over the amount held is still owed by the
      // customer — it was invisible in the wallet until now.
      // Display only: it is NOT added to dues (open item b).
      final owed = deposit.amountOwed ?? 0;
      if (owed > 0) {
        entries.add(WalletLedgerEntry(
          title: titles.securityOwed(vehicle, bookingId),
          date: deposit.deductedAt ?? returnTime,
          dateLabel: deposit.deductedAt != null
              ? 'Settled ${_shortDate(deposit.deductedAt!)}'
              : 'Return ${_shortDate(returnTime)}',
          amount: owed,
          isDebit: true,
          status: 'Owed',
        ));
      }
    }
    return entries;
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
