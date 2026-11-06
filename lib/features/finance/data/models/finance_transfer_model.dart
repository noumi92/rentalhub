import '../../domain/entities/finance_transfer_entity.dart';

class FinanceTransferModel extends FinanceTransferEntity {
  const FinanceTransferModel({
    required super.transferId,
    required super.shopId,
    required super.accountId,
    required super.kind,
    required super.category,
    required super.amountPkr,
    super.bookingId,
    super.vehicleId,
    super.customerId,
    super.note,
    required super.createdAt,
  });

  factory FinanceTransferModel.fromEntity(FinanceTransferEntity e) {
    return FinanceTransferModel(
      transferId: e.transferId,
      shopId: e.shopId,
      accountId: e.accountId,
      kind: e.kind,
      category: e.category,
      amountPkr: e.amountPkr,
      bookingId: e.bookingId,
      vehicleId: e.vehicleId,
      customerId: e.customerId,
      note: e.note,
      createdAt: e.createdAt,
    );
  }

  factory FinanceTransferModel.fromMap(Map<String, dynamic> map) {
    return FinanceTransferModel(
      transferId: map['transferId'] ?? '',
      shopId: map['shopId'] ?? '',
      accountId: map['accountId'] ?? '',
      kind: map['kind'] ?? 'income',
      category: map['category'] ?? 'other',
      amountPkr: map['amountPkr'] ?? 0,
      bookingId: map['bookingId'],
      vehicleId: map['vehicleId'],
      customerId: map['customerId'],
      note: map['note'],
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transferId': transferId,
      'shopId': shopId,
      'accountId': accountId,
      'kind': kind,
      'category': category,
      'amountPkr': amountPkr,
      if (bookingId != null) 'bookingId': bookingId,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (customerId != null) 'customerId': customerId,
      if (note != null) 'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
