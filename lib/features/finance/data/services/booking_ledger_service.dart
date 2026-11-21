import '../../../bookings/domain/entities/booking_entity.dart';
import '../datasources/finance_account_data_source.dart';
import '../datasources/finance_transfer_data_source.dart';
import '../../domain/entities/finance_transfer_entity.dart';

/// Financial audit (2026-11-20): the single choke point that posts
/// booking cash to the ledger. Before this, NO booking money ever
/// reached `finance_transfers` — advances, handover balances,
/// return collections and refunds lived only on the booking /
/// settlement docs, so account balances and cash closing missed
/// real cash and the P&L counted booking revenue with no cash
/// behind it.
///
/// Every posting is idempotent: the transfer id is deterministic
/// (`LEDGER-<bookingId>-<event>`), so a retry, an offline-queue
/// replay or a second call site merge-sets the same doc instead of
/// doubling the entry. [postAdvance] upserts (the advance is one
/// event whose amount firms up — partial then full — and the
/// booking only ever stores the latest absolute); every other
/// event posts once and skips when its id already exists.
///
/// The account is resolved from the payment method (cash → the
/// cash account, bank_transfer → bank, jazzcash / easypaisa →
/// their wallet accounts), falling back to the shop's default
/// account. A booking with no known method (an online advance
/// paid into the owner's assigned account) posts to the default
/// account with the destination account number in the note, so
/// the owner can still reconcile it.
class BookingLedgerService {
  final FinanceTransferDataSource transfers;
  final FinanceAccountDataSource accounts;

  const BookingLedgerService({
    required this.transfers,
    required this.accounts,
  });

  /// The deterministic id for one cash event of one booking.
  static String transferIdFor(String bookingId, String event) =>
      'LEDGER-$bookingId-$event';

  /// 'bank' (the manual sheet's spelling) and 'bank_transfer'
  /// (the booking / handover spelling) are the same method.
  static String? normalizeMethod(String? method) {
    if (method == null) return null;
    if (method == 'bank') return 'bank_transfer';
    return method;
  }

  /// The account type a payment method lands in. Null when the
  /// method is unknown — the caller then takes the default.
  static String? accountTypeForMethod(String? method) {
    switch (normalizeMethod(method)) {
      case 'cash':
        return 'cash';
      case 'bank_transfer':
        return 'bank';
      case 'jazzcash':
        return 'jazzcash';
      case 'easypaisa':
        return 'easypaisa';
      default:
        return null;
    }
  }

  Future<String> _accountIdFor(String shopId, String? method) async {
    final list = await accounts.getShopAccounts(shopId);
    final want = accountTypeForMethod(method);
    if (want != null) {
      for (final a in list) {
        if (a.type == want) return a.accountId;
      }
    }
    for (final a in list) {
      if (a.isDefault) return a.accountId;
    }
    return list.first.accountId;
  }

  /// The advance for a booking — upserted under
  /// `LEDGER-<bookingId>-advance`, so a partial advance followed
  /// by the full verification still leaves exactly one entry for
  /// the latest absolute amount. Returns null when there is
  /// nothing to post (amount ≤ 0).
  Future<FinanceTransferEntity?> postAdvance({
    required BookingEntity booking,
    required int amount,
    String? method,
    String? selectedPaymentAccount,
  }) async {
    if (amount <= 0) return null;
    final accountId = await _accountIdFor(
      booking.shopId,
      method ?? booking.advancePaymentMethod,
    );
    final note = selectedPaymentAccount != null &&
            selectedPaymentAccount.isNotEmpty
        ? 'Advance for ${booking.bookingId} • paid into $selectedPaymentAccount'
        : 'Advance for ${booking.bookingId}';
    return transfers.addTransfer(
      transferId: transferIdFor(booking.bookingId, 'advance'),
      shopId: booking.shopId,
      accountId: accountId,
      kind: 'income',
      category: 'advance',
      amountPkr: amount,
      bookingId: booking.bookingId,
      vehicleId: booking.vehicleId,
      customerId: booking.customerId,
      note: note,
      paymentMethod: normalizeMethod(method ?? booking.advancePaymentMethod),
    );
  }

  /// One cash event, posted at most once: when a transfer with
  /// this id already exists the existing entry is returned and
  /// nothing new is written. Returns null when there is nothing
  /// to post (amount ≤ 0).
  Future<FinanceTransferEntity?> postOnce({
    required BookingEntity booking,
    required String event,
    required String kind,
    required String category,
    required int amount,
    String? paymentMethod,
    String? note,
  }) async {
    if (amount <= 0) return null;
    final id = transferIdFor(booking.bookingId, event);
    if (await transfers.transferExists(id)) {
      final existing = await transfers.getShopTransfers(booking.shopId);
      for (final t in existing) {
        if (t.transferId == id) return t;
      }
      return null;
    }
    final accountId =
        await _accountIdFor(booking.shopId, paymentMethod);
    return transfers.addTransfer(
      transferId: id,
      shopId: booking.shopId,
      accountId: accountId,
      kind: kind,
      category: category,
      amountPkr: amount,
      bookingId: booking.bookingId,
      vehicleId: booking.vehicleId,
      customerId: booking.customerId,
      note: note ?? '$category for ${booking.bookingId}',
      paymentMethod: normalizeMethod(paymentMethod),
    );
  }

  /// Dues collected later (Item 6, 2026-11-21): the customer pays
  /// a remaining balance after the trip, from the dues screen.
  /// Upserted — NOT [postOnce] — under `LEDGER-<bookingId>-dues`:
  /// a due is one logical event whose amount firms up (a partial
  /// payment followed by the rest), exactly like the advance in
  /// [postAdvance]. [postOnce] would skip every payment after the
  /// first, so the rest of a split payment would never reach the
  /// ledger. The cumulative amount keeps exactly one entry per
  /// booking, and the id can never collide with 'advance' /
  /// 'balance' / 'rent-return' / 'extra-fare' / 'deposit' /
  /// 'deposit-refund' / 'owed'. Returns null when there is nothing
  /// to post (amount ≤ 0). The entry carries the latest payment's
  /// method and account — a split across methods attributes the
  /// cumulative total to the latest one.
  Future<FinanceTransferEntity?> postDues({
    required BookingEntity booking,
    required int amount,
    String? paymentMethod,
  }) async {
    if (amount <= 0) return null;
    final id = transferIdFor(booking.bookingId, 'dues');
    final existing = (await transfers.getShopTransfers(booking.shopId))
        .where((t) => t.transferId == id)
        .firstOrNull;
    final total = (existing?.amountPkr ?? 0) + amount;
    final accountId = await _accountIdFor(booking.shopId, paymentMethod);
    return transfers.addTransfer(
      transferId: id,
      shopId: booking.shopId,
      accountId: accountId,
      kind: 'income',
      category: 'rent',
      amountPkr: total,
      bookingId: booking.bookingId,
      vehicleId: booking.vehicleId,
      customerId: booking.customerId,
      note: 'Dues collected for ${booking.bookingId}',
      paymentMethod: normalizeMethod(paymentMethod),
    );
  }
}
