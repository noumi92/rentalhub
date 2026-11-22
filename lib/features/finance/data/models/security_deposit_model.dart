import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/security_deposit_entity.dart';

class SecurityDepositModel extends SecurityDepositEntity {
  const SecurityDepositModel({
    required super.depositId,
    required super.bookingId,
    required super.customerId,
    required super.shopId,
    required super.amount,
    super.status,
    super.collectedAt,
    super.releasedAt,
    super.deductedAt,
    super.totalKmDriven,
    super.excessKm,
    super.excessKmCharge,
    super.fuelDeficit,
    super.damageCharge,
    super.overtimeFee,
    super.deductedAmount,
    super.netRefund,
    super.amountOwed,
    super.returnDamageNotes,
    super.releaseReason,
  });

  factory SecurityDepositModel.fromEntity(SecurityDepositEntity e) {
    return SecurityDepositModel(
      depositId: e.depositId,
      bookingId: e.bookingId,
      customerId: e.customerId,
      shopId: e.shopId,
      amount: e.amount,
      status: e.status,
      collectedAt: e.collectedAt,
      releasedAt: e.releasedAt,
      deductedAt: e.deductedAt,
      totalKmDriven: e.totalKmDriven,
      excessKm: e.excessKm,
      excessKmCharge: e.excessKmCharge,
      fuelDeficit: e.fuelDeficit,
      damageCharge: e.damageCharge,
      overtimeFee: e.overtimeFee,
      deductedAmount: e.deductedAmount,
      netRefund: e.netRefund,
      amountOwed: e.amountOwed,
      returnDamageNotes: e.returnDamageNotes,
      releaseReason: e.releaseReason,
    );
  }

  factory SecurityDepositModel.fromMap(Map<String, dynamic> map) {
    DateTime? date(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }
    return SecurityDepositModel(
      depositId: map['depositId'] ?? map['bookingId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      customerId: map['customerId'] ?? '',
      shopId: map['shopId'] ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'collected',
      collectedAt: date(map['collectedAt']),
      releasedAt: date(map['releasedAt']),
      deductedAt: date(map['deductedAt']),
      totalKmDriven: (map['totalKmDriven'] as num?)?.toInt(),
      excessKm: (map['excessKm'] as num?)?.toInt(),
      excessKmCharge: (map['excessKmCharge'] as num?)?.toInt(),
      fuelDeficit: (map['fuelDeficit'] as num?)?.toInt(),
      damageCharge: (map['damageCharge'] as num?)?.toInt(),
      overtimeFee: (map['overtimeFee'] as num?)?.toInt(),
      deductedAmount: (map['deductedAmount'] as num?)?.toInt(),
      netRefund: (map['netRefund'] as num?)?.toInt(),
      amountOwed: (map['amountOwed'] as num?)?.toInt(),
      returnDamageNotes:
          List<String>.from(map['returnDamageNotes'] ?? const []),
      releaseReason: map['releaseReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    String? iso(DateTime? d) => d?.toIso8601String();
    return {
      'depositId': depositId,
      'bookingId': bookingId,
      'customerId': customerId,
      'shopId': shopId,
      'amount': amount,
      'status': status,
      if (collectedAt != null) 'collectedAt': iso(collectedAt),
      if (releasedAt != null) 'releasedAt': iso(releasedAt),
      if (deductedAt != null) 'deductedAt': iso(deductedAt),
      if (totalKmDriven != null) 'totalKmDriven': totalKmDriven,
      if (excessKm != null) 'excessKm': excessKm,
      if (excessKmCharge != null) 'excessKmCharge': excessKmCharge,
      if (fuelDeficit != null) 'fuelDeficit': fuelDeficit,
      if (damageCharge != null) 'damageCharge': damageCharge,
      if (overtimeFee != null) 'overtimeFee': overtimeFee,
      if (deductedAmount != null) 'deductedAmount': deductedAmount,
      if (netRefund != null) 'netRefund': netRefund,
      if (amountOwed != null) 'amountOwed': amountOwed,
      if (returnDamageNotes.isNotEmpty)
        'returnDamageNotes': returnDamageNotes,
      if (releaseReason != null) 'releaseReason': releaseReason,
    };
  }
}
