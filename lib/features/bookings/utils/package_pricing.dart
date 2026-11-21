import '../../fleet/domain/entities/vehicle_entity.dart';
import '../presentation/widgets/package_tier_list.dart';

/// Phase B (B3): the pricing rules of the booking picker, shared by
/// the picker and its tests. Extracted from [RentPackagePickerView]
/// so the view stays under the 250-line cap.
class PackagePricing {
  /// With-driver surcharge for a tier: full daily surcharge per day
  /// (24h: one day, Weekly: seven), prorated for hourly tiers.
  /// Worker A (2026-11-21): the rate comes from the shop's booking
  /// settings ([driverRatePerDayPkr]); the per-vehicle
  /// `withDriverSurchargePkr` is no longer read by pricing. Null
  /// (unset) charges Rs. 0.
  static int driverSurchargeFor({
    required VehicleEntity? vehicle,
    required PackageTierOption tier,
    required bool isWithDriver,
    int? driverRatePerDayPkr,
  }) {
    if (!isWithDriver || vehicle == null) return 0;
    final perDay = driverRatePerDayPkr ?? 0;
    if (tier.hours >= 24) return perDay * (tier.hours ~/ 24);
    return (perDay * tier.hours / 24).round();
  }

  /// The total for a tier: the package price plus the driver
  /// surcharge, multiplied by the number of days for day packages
  /// and by the number of weeks for the weekly package.
  static int rateFor({
    required VehicleEntity? vehicle,
    required PackageTierOption tier,
    required int durationDays,
    required bool isWithDriver,
    int? driverRatePerDayPkr,
  }) {
    final unit =
        tier.price + driverSurchargeFor(vehicle: vehicle, tier: tier, isWithDriver: isWithDriver, driverRatePerDayPkr: driverRatePerDayPkr);
    if (vehicle != null) {
      if (tier.label == '24h') return unit * durationDays;
      if (tier.label == 'Weekly') {
        return unit * ((durationDays + 6) ~/ 7);
      }
      // Monthly is one price per 30-day block, like Weekly per week.
      if (tier.label == 'Monthly') {
        return unit * ((durationDays + 29) ~/ 30);
      }
      return unit;
    }
    if (tier.label == '24h') return tier.price * durationDays;
    return tier.price;
  }

  /// The advance: the vehicle's fixed advance when set, otherwise
  /// 25% of the total, clamped to Rs. 1,000–10,000.
  static int advanceFor({
    required VehicleEntity? vehicle,
    required int total,
  }) {
    final vehicleAdvance = vehicle?.advanceRequiredPkr;
    if (vehicleAdvance != null) return vehicleAdvance;
    return (total * 0.25).round().clamp(1000, 10000);
  }

  /// The km allowance for a booking: the package's included km
  /// (per day for day packages), or the out-of-city allowance when
  /// the trip goes out of the city.
  static int kmLimitFor({
    required PackageTierOption tier,
    required int durationDays,
  }) {
    final perDay = int.tryParse(tier.kmIncluded.split(' ').first) ?? 250;
    if (tier.hours >= 24) return perDay * durationDays;
    return perDay;
  }
}
