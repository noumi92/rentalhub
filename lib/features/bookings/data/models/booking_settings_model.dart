import '../../domain/entities/booking_settings_entity.dart';

class BookingSettingsModel extends BookingSettingsEntity {
  const BookingSettingsModel({
    required super.shopId,
    super.driverRatePerDayPkr,
  });

  factory BookingSettingsModel.fromEntity(BookingSettingsEntity e) {
    return BookingSettingsModel(
      shopId: e.shopId,
      driverRatePerDayPkr: e.driverRatePerDayPkr,
    );
  }

  factory BookingSettingsModel.fromMap(Map<String, dynamic> map) {
    return BookingSettingsModel(
      shopId: map['shopId'] ?? '',
      driverRatePerDayPkr: (map['driverRatePerDayPkr'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'driverRatePerDayPkr': driverRatePerDayPkr,
    };
  }
}
