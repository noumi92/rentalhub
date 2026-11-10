import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/firestore_service.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../trust/data/datasources/kyc_remote_data_source.dart';
import '../../../trust/domain/entities/kyc_document_entity.dart';
import 'customer_wallet_service.dart';

/// Customer rework (Worker C): everything the rebuilt customer Home
/// screen shows, loaded from the real repositories — bookings, wallet,
/// KYC submission and trust score. Nothing here invents a number:
/// a value that could not be loaded stays null and the Home screen
/// renders it as '—'; a bookings load failure is reported through
/// [CustomerHomeData.bookingsFailed] so the screen can offer a retry
/// instead of pretending the customer has no bookings.
class CustomerHomeData {
  const CustomerHomeData({
    required this.bookings,
    this.walletTotal,
    this.kyc,
    this.trustScore,
    this.bookingsFailed = false,
  });

  /// All of the customer's bookings, newest pickup first.
  final List<BookingEntity> bookings;

  /// Advances paid + security deposits held, from
  /// [CustomerWalletService]. Null when the wallet could not be
  /// loaded — the KPI shows '—', never a guessed Rs. 0.
  final int? walletTotal;

  /// The KYC submission from `kyc_documents/{uid}`. Null when the
  /// customer has not submitted anything yet.
  final KycDocumentEntity? kyc;

  /// The `trust_score` on the customer's `users` doc. Null when the
  /// doc has no score — shown as '—', never the model's 5.0 default.
  final double? trustScore;

  final bool bookingsFailed;

  /// Paid or on the road — the bookings view's own "Active" tab uses
  /// the same two statuses.
  int get activeBookings => bookings
      .where((b) => b.status == 'paid' || b.status == 'active')
      .length;

  /// Trips actually taken.
  int get totalTrips =>
      bookings.where((b) => b.status == 'completed').length;

  /// Most recent first, capped at three for the Home list.
  List<BookingEntity> get recentBookings {
    final sorted = List<BookingEntity>.of(bookings)
      ..sort((a, b) => b.pickupTime.compareTo(a.pickupTime));
    return sorted.take(3).toList();
  }

  /// Approved but the advance is still unpaid and the pickup time
  /// has already passed — the payment is overdue, not merely due.
  List<BookingEntity> get overduePayments {
    final now = DateTime.now();
    return bookings
        .where((b) =>
            b.status == 'approved' &&
            b.remainingBalance > 0 &&
            b.pickupTime.isBefore(now))
        .toList();
  }

  /// Approved with the advance still unpaid and the pickup still
  /// ahead — payment due, not yet overdue.
  List<BookingEntity> get paymentsDue {
    final now = DateTime.now();
    return bookings
        .where((b) =>
            b.status == 'approved' &&
            b.remainingBalance > 0 &&
            !b.pickupTime.isBefore(now))
        .toList();
  }

  /// The next handover: the soonest future pickup among paid/active
  /// bookings. Null when nothing is coming up.
  BookingEntity? get nextHandover {
    final now = DateTime.now();
    final upcoming = bookings
        .where((b) =>
            (b.status == 'paid' || b.status == 'active') &&
            b.pickupTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.pickupTime.compareTo(b.pickupTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// True when an approved booking needs its advance paid — overdue
  /// or due — regardless of pickup time.
  bool isPaymentOutstanding(BookingEntity booking) =>
      booking.status == 'approved' && booking.remainingBalance > 0;

  /// True when the approved booking's pickup has passed with the
  /// advance still unpaid.
  bool isPaymentOverdue(BookingEntity booking) =>
      isPaymentOutstanding(booking) &&
      booking.pickupTime.isBefore(DateTime.now());
}

class CustomerHomeService {
  CustomerHomeService({
    required this.bookings,
    required this.wallet,
    required this.kyc,
    required this.users,
  });

  final BookingRemoteDataSource bookings;
  final CustomerWalletService wallet;
  final KycRemoteDataSource kyc;
  final FirestoreService users;

  /// Resolves the real service from the locator, or null when any
  /// dependency is not registered (widget tests, where the view is
  /// given a fake service instead) — the Home screen then renders
  /// honest empty states instead of throwing.
  static CustomerHomeService? resolve() {
    if (!sl.isRegistered<BookingRemoteDataSource>() ||
        !sl.isRegistered<SecurityDepositDataSource>() ||
        !sl.isRegistered<KycRemoteDataSource>() ||
        !sl.isRegistered<FirestoreService>()) {
      return null;
    }
    final bookingsDs = sl<BookingRemoteDataSource>();
    return CustomerHomeService(
      bookings: bookingsDs,
      wallet: CustomerWalletService(
        bookings: bookingsDs,
        deposits: sl<SecurityDepositDataSource>(),
      ),
      kyc: sl<KycRemoteDataSource>(),
      users: sl<FirestoreService>(),
    );
  }

  Future<CustomerHomeData> load(String uid) async {
    var bookings = <BookingEntity>[];
    var bookingsFailed = false;
    try {
      bookings = await this.bookings.getCustomerBookings(uid);
    } catch (_) {
      bookingsFailed = true;
    }
    int? walletTotal;
    try {
      walletTotal = (await wallet.load(uid)).total;
    } catch (_) {}
    KycDocumentEntity? kycDoc;
    try {
      kycDoc = await kyc.getKyc(uid);
    } catch (_) {}
    double? trustScore;
    try {
      // The raw doc, not UserModel: its fromMap defaults a missing
      // trust_score to 5.0, which would invent a perfect score for
      // a customer who has none yet.
      final doc = await users.getDocument('users', uid);
      trustScore = (doc?['trust_score'] as num?)?.toDouble();
    } catch (_) {}
    return CustomerHomeData(
      bookings: bookings,
      walletTotal: walletTotal,
      kyc: kycDoc,
      trustScore: trustScore,
      bookingsFailed: bookingsFailed,
    );
  }
}
