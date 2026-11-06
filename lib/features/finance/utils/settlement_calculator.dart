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
    required this.totalDeductions,
    required this.netRefund,
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
  }) {
    final excessKm = (totalKmDriven - kmAllowance).clamp(0, 1 << 30);
    final excessKmCharge = excessKm * extraKmPkr;
    final fuelDeficit = fuelDeficitFor(fuelLevel);
    final overtimeFee = overtimeHours * extraHourPkr;
    final totalDeductions =
        excessKmCharge + fuelDeficit + damageCharge + overtimeFee;
    final netRefund = (securityDeposit - totalDeductions).clamp(0, 1 << 30);
    return SettlementBreakdown(
      totalKmDriven: totalKmDriven,
      excessKm: excessKm,
      excessKmCharge: excessKmCharge,
      fuelDeficit: fuelDeficit,
      damageCharge: damageCharge,
      overtimeHours: overtimeHours,
      overtimeFee: overtimeFee,
      totalDeductions: totalDeductions,
      netRefund: netRefund,
    );
  }
}
