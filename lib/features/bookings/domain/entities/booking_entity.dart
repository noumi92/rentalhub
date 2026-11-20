import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String bookingId;
  final String customerId;
  final String shopId;
  final String vehicleId;
  final String packageType;
  final bool isWithDriver;
  final DateTime pickupTime;
  final DateTime returnTime;
  final int totalAmount;
  final int advanceRequired;
  final int advancePaid;
  final int remainingBalance;
  final String status; // 'requested' | 'approved' | 'payment_submitted' | 'paid' | 'active' | 'disputed' | 'completed' | 'rejected' | 'cancelled'
  final String? paymentProofUrl;
  final String? transactionId;
  final String? vehicleName;
  final String? vehiclePlate;
  final String? shopName;
  final String? shopPhone;
  final String? customerName;
  final String? customerPhone;
  final String? notes;

  /// Phase B (C1): the customer's CNIC, collected at booking time
  /// (walk-in) or from KYC (online). The customers list groups by it.
  final String? customerCnic;

  /// Phase B (C3): the booking's guarantor, picked in the walk-in
  /// flow from saved customers or added on the spot.
  final String? guarantorName;
  final String? guarantorCnic;
  final String? guarantorPhone;

  /// Phase B (D3): why the booking — or its payment proof — was
  /// rejected. Shown to the customer so they can fix and resubmit.
  final String? rejectionReason;

  /// Phase B (B3): trip type ('in_city' | 'out_of_city'), the km
  /// allowance for the trip (in-city: package km x days; out-of-city:
  /// outOfCityKmPerDay x days), and whether the shop cleared the
  /// tracker for an out-of-city trip.
  final String tripType;
  final int? kmLimit;
  final bool trackerCleared;

  /// Gap (b): the fixed route chosen for an out-of-city trip, and
  /// its denormalised display name (e.g. "Lahore → Islamabad") so
  /// detail / return / agreement screens can show the route without
  /// a lookup. Null on older bookings and on trips that were not
  /// priced by fixed route — never invented.
  final String? fixedRouteId;
  final String? fixedRouteSummary;

  /// Gap (b/c): the out-of-city pricing snapshot agreed at booking
  /// time — the vehicle's mode ('perDay' | 'perKm' | 'fixedRoute')
  /// and per-km rate (Rs/km) as they were when the trip was booked.
  /// The return settlement reads these first, so an owner editing
  /// the vehicle's rates mid-trip can never re-price a signed trip.
  /// Null on older bookings (the return flow then falls back to the
  /// vehicle's current rates).
  final String? outCityMode;
  final int? outCityPerKmPkr;

  /// Booking source ('online' | 'walk_in'). Older docs carry no
  /// value — [BookingModel.fromMap] backfills it from the
  /// customerId ('walkin-…' => 'walk_in', anything else 'online').
  final String? origin;

  /// When the customer submitted payment proof (set by
  /// updatePaymentProof). Null until a proof is submitted.
  final DateTime? proofSubmittedAt;

  /// Approve step: the payment account the owner chose for this
  /// booking and the deadline for the customer to pay into it.
  /// Null until the owner approves with an account selected.
  final String? selectedPaymentAccount;
  final DateTime? paymentDeadline;

  /// The guarantor's relationship to the customer (e.g. "Cousin").
  /// Null when no guarantor was picked or no relation recorded.
  final String? guarantorRelation;

  /// Deposit received for the booking (Rs). Null until a deposit
  /// is recorded; later workers write it.
  final double? depositAmountPkr;

  /// Discount given at the counter (Rs, walk-in step 3). Null when
  /// no discount was given; the booked total is already net of it.
  final double? discountAmountPkr;

  const BookingEntity({
    required this.bookingId,
    required this.customerId,
    required this.shopId,
    required this.vehicleId,
    required this.packageType,
    this.isWithDriver = true,
    required this.pickupTime,
    required this.returnTime,
    required this.totalAmount,
    this.advanceRequired = 1000,
    this.advancePaid = 0,
    required this.remainingBalance,
    this.status = 'requested',
    this.paymentProofUrl,
    this.transactionId,
    this.vehicleName,
    this.vehiclePlate,
    this.shopName,
    this.shopPhone,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.customerCnic,
    this.guarantorName,
    this.guarantorCnic,
    this.guarantorPhone,
    this.rejectionReason,
    this.tripType = 'in_city',
    this.kmLimit,
    this.trackerCleared = false,
    this.fixedRouteId,
    this.fixedRouteSummary,
    this.outCityMode,
    this.outCityPerKmPkr,
    this.origin,
    this.proofSubmittedAt,
    this.selectedPaymentAccount,
    this.paymentDeadline,
    this.guarantorRelation,
    this.depositAmountPkr,
    this.discountAmountPkr,
  });

  BookingEntity copyWith({
    String? status,
    int? advancePaid,
    String? paymentProofUrl,
    String? transactionId,
    String? vehicleName,
    String? vehiclePlate,
    String? shopName,
    String? shopPhone,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? customerCnic,
    String? guarantorName,
    String? guarantorCnic,
    String? guarantorPhone,
    String? rejectionReason,
    bool clearRejectionReason = false,
    String? tripType,
    int? kmLimit,
    bool? trackerCleared,
    String? fixedRouteId,
    String? fixedRouteSummary,
    String? outCityMode,
    int? outCityPerKmPkr,
    String? origin,
    DateTime? proofSubmittedAt,
    String? selectedPaymentAccount,
    DateTime? paymentDeadline,
    String? guarantorRelation,
    double? depositAmountPkr,
    double? discountAmountPkr,
  }) {
    return BookingEntity(
      bookingId: bookingId,
      customerId: customerId,
      shopId: shopId,
      vehicleId: vehicleId,
      packageType: packageType,
      isWithDriver: isWithDriver,
      pickupTime: pickupTime,
      returnTime: returnTime,
      totalAmount: totalAmount,
      advanceRequired: advanceRequired,
      advancePaid: advancePaid ?? this.advancePaid,
      remainingBalance: totalAmount - (advancePaid ?? this.advancePaid),
      status: status ?? this.status,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      transactionId: transactionId ?? this.transactionId,
      vehicleName: vehicleName ?? this.vehicleName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      shopName: shopName ?? this.shopName,
      shopPhone: shopPhone ?? this.shopPhone,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      customerCnic: customerCnic ?? this.customerCnic,
      guarantorName: guarantorName ?? this.guarantorName,
      guarantorCnic: guarantorCnic ?? this.guarantorCnic,
      guarantorPhone: guarantorPhone ?? this.guarantorPhone,
      rejectionReason: clearRejectionReason
          ? null
          : (rejectionReason ?? this.rejectionReason),
      tripType: tripType ?? this.tripType,
      kmLimit: kmLimit ?? this.kmLimit,
      trackerCleared: trackerCleared ?? this.trackerCleared,
      fixedRouteId: fixedRouteId ?? this.fixedRouteId,
      fixedRouteSummary: fixedRouteSummary ?? this.fixedRouteSummary,
      outCityMode: outCityMode ?? this.outCityMode,
      outCityPerKmPkr: outCityPerKmPkr ?? this.outCityPerKmPkr,
      origin: origin ?? this.origin,
      proofSubmittedAt: proofSubmittedAt ?? this.proofSubmittedAt,
      selectedPaymentAccount:
          selectedPaymentAccount ?? this.selectedPaymentAccount,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      guarantorRelation: guarantorRelation ?? this.guarantorRelation,
      depositAmountPkr: depositAmountPkr ?? this.depositAmountPkr,
      discountAmountPkr: discountAmountPkr ?? this.discountAmountPkr,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        customerId,
        shopId,
        vehicleId,
        packageType,
        isWithDriver,
        pickupTime,
        returnTime,
        totalAmount,
        advanceRequired,
        advancePaid,
        remainingBalance,
        status,
        paymentProofUrl,
        transactionId,
        vehicleName,
        vehiclePlate,
        shopName,
        shopPhone,
        customerName,
        customerPhone,
        notes,
        customerCnic,
        guarantorName,
        guarantorCnic,
        guarantorPhone,
        rejectionReason,
        tripType,
        kmLimit,
        trackerCleared,
        fixedRouteId,
        fixedRouteSummary,
        outCityMode,
        outCityPerKmPkr,
        origin,
        proofSubmittedAt,
        selectedPaymentAccount,
        paymentDeadline,
        guarantorRelation,
        depositAmountPkr,
        discountAmountPkr,
      ];
}
