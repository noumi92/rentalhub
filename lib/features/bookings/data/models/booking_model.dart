import '../../domain/entities/booking_entity.dart';

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
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final bId = id ?? (map['bookingId'] as String? ?? '');
    return BookingModel(
      bookingId: bId,
      customerId: (map['customerId'] as String?) ?? '',
      shopId: (map['shopId'] as String?) ?? '',
      vehicleId: (map['vehicleId'] as String?) ?? '',
      packageType: (map['packageType'] as String?) ?? '24h',
      isWithDriver: (map['isWithDriver'] as bool?) ?? true,
      pickupTime: map['pickupTime'] != null
          ? DateTime.tryParse(map['pickupTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      returnTime: map['returnTime'] != null
          ? DateTime.tryParse(map['returnTime'].toString()) ??
              DateTime.now().add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
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
    );
  }
}
