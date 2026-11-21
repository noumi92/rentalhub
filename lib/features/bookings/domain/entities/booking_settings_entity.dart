import 'package:equatable/equatable.dart';

/// Worker A (2026-11-21): one shop's booking settings, stored as
/// the single document `booking_settings/{shopId}`. The driver rate
/// is SHOP-SCOPED: one per-day rupee rate for the whole shop, set
/// here in booking general settings. It REPLACES the per-vehicle
/// `withDriverSurchargePkr` for pricing — that field stays on the
/// vehicle only for backward compatibility with existing documents
/// and is no longer read by any pricing path. Null means unset: a
/// trip with a driver adds no extra charge.
class BookingSettingsEntity extends Equatable {
  final String shopId;
  final int? driverRatePerDayPkr;

  const BookingSettingsEntity({
    required this.shopId,
    this.driverRatePerDayPkr,
  });

  BookingSettingsEntity copyWith({
    String? shopId,
    int? driverRatePerDayPkr,
    bool clearDriverRate = false,
  }) {
    return BookingSettingsEntity(
      shopId: shopId ?? this.shopId,
      driverRatePerDayPkr:
          clearDriverRate ? null : driverRatePerDayPkr ?? this.driverRatePerDayPkr,
    );
  }

  @override
  List<Object?> get props => [shopId, driverRatePerDayPkr];
}
