import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking_entity.dart';

/// Parses a stored date that may be an ISO string (what [toMap]
/// writes), a Firestore [Timestamp], or epoch milliseconds.
DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.bookingId,
    required super.customerId,
    required super.shopId,
    required super.vehicleId,
    required super.packageType,
    super.isWithDriver,
    required super.pickupTime,
    required super.returnTime,
    required super.totalAmount,
    super.advanceRequired,
    super.advancePaid,
    required super.remainingBalance,
    super.status,
    super.paymentProofUrl,
    super.transactionId,
    super.vehicleName,
    super.vehiclePlate,
    super.shopName,
    super.shopPhone,
    super.customerName,
    super.customerPhone,
    super.notes,
    super.customerCnic,
    super.guarantorName,
    super.guarantorCnic,
    super.guarantorPhone,
    super.rejectionReason,
    super.tripType,
    super.kmLimit,
    super.trackerCleared,
    super.fixedRouteId,
    super.fixedRouteSummary,
    super.outCityMode,
    super.outCityPerKmPkr,
    super.origin,
    super.proofSubmittedAt,
    super.selectedPaymentAccount,
    super.paymentDeadline,
    super.guarantorRelation,
    super.depositAmountPkr,
    super.discountAmountPkr,
    super.advancePaymentMethod,
    super.depositPaymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'shopId': shopId,
      'vehicleId': vehicleId,
      'packageType': packageType,
      'isWithDriver': isWithDriver,
      'pickupTime': pickupTime.toIso8601String(),
      'returnTime': returnTime.toIso8601String(),
      'totalAmount': totalAmount,
      'advanceRequired': advanceRequired,
      'advancePaid': advancePaid,
      'remainingBalance': remainingBalance,
      'status': status,
      'paymentProofUrl': paymentProofUrl,
      'transactionId': transactionId,
      'vehicleName': vehicleName,
      'vehiclePlate': vehiclePlate,
      'shopName': shopName,
      'shopPhone': shopPhone,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'notes': notes,
      if (customerCnic != null) 'customerCnic': customerCnic,
      if (guarantorName != null) 'guarantorName': guarantorName,
      if (guarantorCnic != null) 'guarantorCnic': guarantorCnic,
      if (guarantorPhone != null) 'guarantorPhone': guarantorPhone,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'tripType': tripType,
      if (kmLimit != null) 'kmLimit': kmLimit,
      'trackerCleared': trackerCleared,
      if (fixedRouteId != null) 'fixedRouteId': fixedRouteId,
      if (fixedRouteSummary != null) 'fixedRouteSummary': fixedRouteSummary,
      if (outCityMode != null) 'outCityMode': outCityMode,
      if (outCityPerKmPkr != null) 'outCityPerKmPkr': outCityPerKmPkr,
      if (origin != null) 'origin': origin,
      if (proofSubmittedAt != null)
        'proofSubmittedAt': proofSubmittedAt!.toIso8601String(),
      if (selectedPaymentAccount != null)
        'selectedPaymentAccount': selectedPaymentAccount,
      if (paymentDeadline != null)
        'paymentDeadline': paymentDeadline!.toIso8601String(),
      if (guarantorRelation != null) 'guarantorRelation': guarantorRelation,
      if (depositAmountPkr != null) 'depositAmountPkr': depositAmountPkr,
      if (discountAmountPkr != null) 'discountAmountPkr': discountAmountPkr,
      if (advancePaymentMethod != null)
        'advancePaymentMethod': advancePaymentMethod,
      if (depositPaymentMethod != null)
        'depositPaymentMethod': depositPaymentMethod,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final bId = id ?? (map['bookingId'] as String? ?? '');
    final customerId = (map['customerId'] as String?) ?? '';
    // Backfill: older docs carry no origin — walk-in bookings were
    // filed under a 'walkin-…' customerId, everything else is online.
    final origin = (map['origin'] as String?) ??
        (customerId.startsWith('walkin-') ? 'walk_in' : 'online');
    return BookingModel(
      bookingId: bId,
      customerId: customerId,
      shopId: (map['shopId'] as String?) ?? '',
      vehicleId: (map['vehicleId'] as String?) ?? '',
      packageType: (map['packageType'] as String?) ?? '24h',
      isWithDriver: (map['isWithDriver'] as bool?) ?? true,
      pickupTime: _parseDateTime(map['pickupTime']) ?? DateTime.now(),
      returnTime: _parseDateTime(map['returnTime']) ??
          DateTime.now().add(const Duration(days: 1)),
      totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
      advanceRequired: (map['advanceRequired'] as num?)?.toInt() ?? 1000,
      advancePaid: (map['advancePaid'] as num?)?.toInt() ?? 0,
      remainingBalance: (map['remainingBalance'] as num?)?.toInt() ?? 0,
      status: (map['status'] as String?) ?? 'requested',
      paymentProofUrl: map['paymentProofUrl'] as String?,
      transactionId: map['transactionId'] as String?,
      vehicleName: map['vehicleName'] as String?,
      vehiclePlate: map['vehiclePlate'] as String?,
      shopName: map['shopName'] as String?,
      shopPhone: map['shopPhone'] as String?,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      notes: map['notes'] as String?,
      customerCnic: map['customerCnic'] as String?,
      guarantorName: map['guarantorName'] as String?,
      guarantorCnic: map['guarantorCnic'] as String?,
      guarantorPhone: map['guarantorPhone'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      tripType: (map['tripType'] as String?) ?? 'in_city',
      kmLimit: (map['kmLimit'] as num?)?.toInt(),
      trackerCleared: (map['trackerCleared'] as bool?) ?? false,
      fixedRouteId: map['fixedRouteId'] as String?,
      fixedRouteSummary: map['fixedRouteSummary'] as String?,
      outCityMode: map['outCityMode'] as String?,
      outCityPerKmPkr: (map['outCityPerKmPkr'] as num?)?.toInt(),
      origin: origin,
      proofSubmittedAt: _parseDateTime(map['proofSubmittedAt']),
      selectedPaymentAccount: map['selectedPaymentAccount'] as String?,
      paymentDeadline: _parseDateTime(map['paymentDeadline']),
      guarantorRelation: map['guarantorRelation'] as String?,
      depositAmountPkr: (map['depositAmountPkr'] as num?)?.toDouble(),
      discountAmountPkr: (map['discountAmountPkr'] as num?)?.toDouble(),
      advancePaymentMethod: map['advancePaymentMethod'] as String?,
      depositPaymentMethod: map['depositPaymentMethod'] as String?,
    );
  }

  factory BookingModel.fromEntity(BookingEntity entity) {
    return BookingModel(
      bookingId: entity.bookingId,
      customerId: entity.customerId,
      shopId: entity.shopId,
      vehicleId: entity.vehicleId,
      packageType: entity.packageType,
      isWithDriver: entity.isWithDriver,
      pickupTime: entity.pickupTime,
      returnTime: entity.returnTime,
      totalAmount: entity.totalAmount,
      advanceRequired: entity.advanceRequired,
      advancePaid: entity.advancePaid,
      remainingBalance: entity.remainingBalance,
      status: entity.status,
      paymentProofUrl: entity.paymentProofUrl,
      transactionId: entity.transactionId,
      vehicleName: entity.vehicleName,
      vehiclePlate: entity.vehiclePlate,
      shopName: entity.shopName,
      shopPhone: entity.shopPhone,
      customerName: entity.customerName,
      customerPhone: entity.customerPhone,
      notes: entity.notes,
      customerCnic: entity.customerCnic,
      guarantorName: entity.guarantorName,
      guarantorCnic: entity.guarantorCnic,
      guarantorPhone: entity.guarantorPhone,
      rejectionReason: entity.rejectionReason,
      tripType: entity.tripType,
      kmLimit: entity.kmLimit,
      trackerCleared: entity.trackerCleared,
      fixedRouteId: entity.fixedRouteId,
      fixedRouteSummary: entity.fixedRouteSummary,
      outCityMode: entity.outCityMode,
      outCityPerKmPkr: entity.outCityPerKmPkr,
      origin: entity.origin,
      proofSubmittedAt: entity.proofSubmittedAt,
      selectedPaymentAccount: entity.selectedPaymentAccount,
      paymentDeadline: entity.paymentDeadline,
      guarantorRelation: entity.guarantorRelation,
      depositAmountPkr: entity.depositAmountPkr,
      discountAmountPkr: entity.discountAmountPkr,
      advancePaymentMethod: entity.advancePaymentMethod,
      depositPaymentMethod: entity.depositPaymentMethod,
    );
  }
}
