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
      ];
}
