import 'package:equatable/equatable.dart';

/// Phase B (H5): one day's cash closing — what the till should
/// hold, what the owner actually counted, and the difference.
/// The expected cash is computed from the cash account's transfers
/// for the day, never typed in.
class CashClosingEntity extends Equatable {
  final String closingId;
  final String shopId;
  final DateTime date;
  final int openingCash;
  final int expectedCash;
  final int countedCash;
  final int difference; // countedCash - expectedCash
  final String? note;
  final DateTime createdAt;

  const CashClosingEntity({
    required this.closingId,
    required this.shopId,
    required this.date,
    required this.openingCash,
    required this.expectedCash,
    required this.countedCash,
    required this.difference,
    this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        closingId,
        shopId,
        date,
        openingCash,
        expectedCash,
        countedCash,
        difference,
        note,
        createdAt,
      ];
}
