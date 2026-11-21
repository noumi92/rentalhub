import 'package:equatable/equatable.dart';

/// Phase B (F2): one held security deposit, from the moment the car
/// leaves with the customer until the return settlement releases or
/// deducts it. Written at handover (collected) and settled at
/// return — before this phase the collection had no writer at all,
/// so the money trail simply did not exist.
class SecurityDepositEntity extends Equatable {
  final String depositId; // the booking id
  final String bookingId;
  final String customerId;
  final String shopId;
  final int amount;
  final String status; // 'collected' | 'released' | 'deducted'
  final DateTime? collectedAt;
  final DateTime? releasedAt;
  final DateTime? deductedAt;

  /// Settlement detail, filled in at return.
  final int? totalKmDriven;
  final int? excessKm;
  final int? excessKmCharge;
  final int? fuelDeficit;
  final int? damageCharge;
  final int? overtimeFee;
  final int? deductedAmount;
  final int? netRefund;
  /// Item 2: what the customer still owes when the deductions
  /// exceed the amount held (totalDeductions − amount, never
  /// negative). [deductedAmount] is capped at [amount] — the excess
  /// lives here, not in the deducted total — so the finance summary
  /// and the customer wallet never show a deduction larger than
  /// the deposit that was actually held.
  final int? amountOwed;
  final List<String> returnDamageNotes;

  /// Worker B (cancel releases the deposit): why a 'released'
  /// record was released — 'cancel' when the booking was cancelled
  /// (full refund, no deductions), 'return' when settled at return.
  /// Null on older records (pre-cancel-release), which the wallet
  /// treats as return-releases.
  final String? releaseReason;

  const SecurityDepositEntity({
    required this.depositId,
    required this.bookingId,
    required this.customerId,
    required this.shopId,
    required this.amount,
    this.status = 'collected',
    this.collectedAt,
    this.releasedAt,
    this.deductedAt,
    this.totalKmDriven,
    this.excessKm,
    this.excessKmCharge,
    this.fuelDeficit,
    this.damageCharge,
    this.overtimeFee,
    this.deductedAmount,
    this.netRefund,
    this.amountOwed,
    this.returnDamageNotes = const [],
    this.releaseReason,
  });

  SecurityDepositEntity copyWith({
    String? status,
    DateTime? releasedAt,
    DateTime? deductedAt,
    int? totalKmDriven,
    int? excessKm,
    int? excessKmCharge,
    int? fuelDeficit,
    int? damageCharge,
    int? overtimeFee,
    int? deductedAmount,
    int? netRefund,
    int? amountOwed,
    List<String>? returnDamageNotes,
    String? releaseReason,
  }) {
    return SecurityDepositEntity(
      depositId: depositId,
      bookingId: bookingId,
      customerId: customerId,
      shopId: shopId,
      amount: amount,
      status: status ?? this.status,
      collectedAt: collectedAt,
      releasedAt: releasedAt ?? this.releasedAt,
      deductedAt: deductedAt ?? this.deductedAt,
      totalKmDriven: totalKmDriven ?? this.totalKmDriven,
      excessKm: excessKm ?? this.excessKm,
      excessKmCharge: excessKmCharge ?? this.excessKmCharge,
      fuelDeficit: fuelDeficit ?? this.fuelDeficit,
      damageCharge: damageCharge ?? this.damageCharge,
      overtimeFee: overtimeFee ?? this.overtimeFee,
      deductedAmount: deductedAmount ?? this.deductedAmount,
      netRefund: netRefund ?? this.netRefund,
      amountOwed: amountOwed ?? this.amountOwed,
      returnDamageNotes: returnDamageNotes ?? this.returnDamageNotes,
      releaseReason: releaseReason ?? this.releaseReason,
    );
  }

  @override
  List<Object?> get props => [
        depositId,
        bookingId,
        customerId,
        shopId,
        amount,
        status,
        collectedAt,
        releasedAt,
        deductedAt,
        totalKmDriven,
        excessKm,
        excessKmCharge,
        fuelDeficit,
        damageCharge,
        overtimeFee,
        deductedAmount,
        netRefund,
        amountOwed,
        returnDamageNotes,
        releaseReason,
      ];
}
