import 'package:equatable/equatable.dart';

/// Phase B (H1/H2): one line in the shop's ledger — money in or
/// money out. A transfer optionally tags a booking, a vehicle and
/// a customer, which is what makes the per-car P&L possible.
class FinanceTransferEntity extends Equatable {
  final String transferId;
  final String shopId;
  final String accountId;
  final String kind; // 'income' | 'expense'
  final String category; // e.g. 'rent', 'fuel', 'maintenance', 'salary', 'deposit_refund', 'other'
  final int amountPkr;
  final String? bookingId;
  final String? vehicleId;
  final String? customerId;
  final String? note;
  final DateTime createdAt;

  const FinanceTransferEntity({
    required this.transferId,
    required this.shopId,
    required this.accountId,
    required this.kind,
    required this.category,
    required this.amountPkr,
    this.bookingId,
    this.vehicleId,
    this.customerId,
    this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        transferId,
        shopId,
        accountId,
        kind,
        category,
        amountPkr,
        bookingId,
        vehicleId,
        customerId,
        note,
        createdAt,
      ];
}
