import '../../domain/entities/cash_closing_entity.dart';

class CashClosingModel extends CashClosingEntity {
  const CashClosingModel({
    required super.closingId,
    required super.shopId,
    required super.date,
    required super.openingCash,
    required super.expectedCash,
    required super.countedCash,
    required super.difference,
    super.note,
    required super.createdAt,
  });

  factory CashClosingModel.fromEntity(CashClosingEntity e) {
    return CashClosingModel(
      closingId: e.closingId,
      shopId: e.shopId,
      date: e.date,
      openingCash: e.openingCash,
      expectedCash: e.expectedCash,
      countedCash: e.countedCash,
      difference: e.difference,
      note: e.note,
      createdAt: e.createdAt,
    );
  }

  factory CashClosingModel.fromMap(Map<String, dynamic> map) {
    return CashClosingModel(
      closingId: map['closingId'] ?? '',
      shopId: map['shopId'] ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ??
          DateTime.now(),
      openingCash: map['openingCash'] ?? 0,
      expectedCash: map['expectedCash'] ?? 0,
      countedCash: map['countedCash'] ?? 0,
      difference: map['difference'] ?? 0,
      note: map['note'],
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'closingId': closingId,
      'shopId': shopId,
      'date': date.toIso8601String(),
      'openingCash': openingCash,
      'expectedCash': expectedCash,
      'countedCash': countedCash,
      'difference': difference,
      if (note != null) 'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
