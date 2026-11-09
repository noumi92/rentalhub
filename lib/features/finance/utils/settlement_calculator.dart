/// Phase B (F1): the return settlement, as pure arithmetic so it can
/// be unit-tested without a widget. Every input comes from real
/// data — the booking's km limit, the vehicle's per-km rate, the
/// return fuel reading — never from hardcoded view defaults.
class SettlementBreakdown {
  final int totalKmDriven;
  final int excessKm;
  final int excessKmCharge;
  final int fuelDeficit;
  final int damageCharge;
  final int overtimeHours;
  final int overtimeFee;
  /// Audit item 6 (O28): manually recorded extra charges, folded
  /// into the deductions — never silently dropped.
  final int extraCharges;
  final int totalDeductions;
  final int netRefund;

  const SettlementBreakdown({
    required this.totalKmDriven,
    required this.excessKm,
    required this.excessKmCharge,
    required this.fuelDeficit,
    required this.damageCharge,
    required this.overtimeHours,
    required this.overtimeFee,
    this.extraCharges = 0,
    required this.totalDeductions,
    required this.netRefund,
  });
}

/// Gap (c): the per-km fare reconciliation at return, as pure
/// arithmetic. A per-km-mode trip is estimated at booking time
/// (days × stored km/day × rate + driver allowance × days + night
/// stay); the final fare settles on the ACTUAL km driven
/// (return odometer − pickup odometer, from the handover record).
/// The difference is what the customer still owes ([extraDue]) or
/// is owed back ([refundDue]) — never both. This is a rent
/// reconciliation, not a deposit deduction: it never changes
/// [SettlementBreakdown] / the deposit refund.
class PerKmSettlement {
  final int actualKm;
  final int perKmRate;
  final int driverAllowance;
  final int nightStay;
  final int actualFare;
  final int estimatedFare;
  final int extraDue;
  final int refundDue;

  const PerKmSettlement({
    required this.actualKm,
    required this.perKmRate,
    required this.driverAllowance,
    required this.nightStay,
    required this.actualFare,
    required this.estimatedFare,
    required this.extraDue,
    required this.refundDue,
  });
}

class SettlementCalculator {
  /// The shop's standard fuel top-up charges, by the fuel gauge the
  /// owner records at return. These are the shop's own rates (the
  /// same values the old view hardcoded inline); they live here so
  /// every settlement uses the same numbers.
  static const int fuelDeficitQuarter = 1500; // 3/4 (75%)
  static const int fuelDeficitHalf = 3000; // 2/4 (50%)
  static const int fuelDeficitNearEmpty = 4500; // 1/4 (25%)

  static int fuelDeficitFor(String fuelLevel) {
    switch (fuelLevel) {
      case '3/4 (75%)':
        return fuelDeficitQuarter;
      case '2/4 (50%)':
        return fuelDeficitHalf;
      case '1/4 (25%)':
        return fuelDeficitNearEmpty;
      default:
        return 0; // 4/4 (Full) — the "Same to Same" policy, met.
    }
  }

  static SettlementBreakdown calculate({
    required int totalKmDriven,
    required int kmAllowance,
    required int extraKmPkr,
    required String fuelLevel,
    int damageCharge = 0,
    int overtimeHours = 0,
    required int extraHourPkr,
    required int securityDeposit,
    int extraCharges = 0,
  }) {
    final excessKm = (totalKmDriven - kmAllowance).clamp(0, 1 << 30);
    final excessKmCharge = excessKm * extraKmPkr;
    final fuelDeficit = fuelDeficitFor(fuelLevel);
    final overtimeFee = overtimeHours * extraHourPkr;
    final totalDeductions =
        excessKmCharge + fuelDeficit + damageCharge + overtimeFee + extraCharges;
    final netRefund = (securityDeposit - totalDeductions).clamp(0, 1 << 30);
    return SettlementBreakdown(
      totalKmDriven: totalKmDriven,
      excessKm: excessKm,
      excessKmCharge: excessKmCharge,
      fuelDeficit: fuelDeficit,
      damageCharge: damageCharge,
      overtimeHours: overtimeHours,
      overtimeFee: overtimeFee,
      extraCharges: extraCharges,
      totalDeductions: totalDeductions,
      netRefund: netRefund,
    );
  }

  /// Gap (c): the per-km fare on actual km. The actual fare uses
  /// the SAME components as the booking-time estimate — actual km ×
  /// the booked per-km rate, plus the driver allowance per day (only
  /// with-driver trips), plus the night stay already in the estimate
  /// — so the comparison with [estimatedFare] (the booked total) is
  /// apples-to-apples. A shorter-than-estimated trip refunds the
  /// difference; a longer one charges it. Negative km clamp to 0.
  static PerKmSettlement calculatePerKm({
    required int actualKm,
    required int perKmRate,
    int driverAllowancePerDay = 0,
    required int days,
    bool isWithDriver = true,
    int nightStayTotal = 0,
    required int estimatedFare,
  }) {
    final km = actualKm.clamp(0, 1 << 30);
    final driverAllowance =
        isWithDriver ? driverAllowancePerDay * days.clamp(1, 1 << 30) : 0;
    final actualFare = km * perKmRate + driverAllowance + nightStayTotal;
    final difference = actualFare - estimatedFare;
    return PerKmSettlement(
      actualKm: km,
      perKmRate: perKmRate,
      driverAllowance: driverAllowance,
      nightStay: nightStayTotal,
      actualFare: actualFare,
      estimatedFare: estimatedFare,
      extraDue: difference.clamp(0, 1 << 30),
      refundDue: (-difference).clamp(0, 1 << 30),
    );
  }
}
