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
  final String status; // 'requested' | 'approved' | 'payment_submitted' | 'paid' | 'active' | 'completed' | 'rejected' | 'cancelled'
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
      ];
}
