import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// O25: the booking-calendar origin split — Online bookings are navy,
/// Walk-in (manual) bookings are orange, per the Step 4B spec
/// (O25 day view: "Online" navy block, "Walk-in" orange block).
///
/// The origin lives on [BookingEntity.origin] ('online' | 'walk_in');
/// older docs carry no value, so a null origin falls back to the same
/// backfill [BookingModel.fromMap] uses: a 'walkin-…' customerId is a
/// walk-in, anything else is online. Keep the two in sync.
///
/// Contrast (white label on the fill): navy `primary` #1B1E5C is
/// ~13:1, `orangeFill` #C2410C is 5.18:1 (documented on the token),
/// and the dark navy leg `primaryOnDark` #252B7A stays above 4.5:1 —
/// all three are asserted in booking_calendar_day_view_test.dart.
class BookingCalendarOriginColors {
  const BookingCalendarOriginColors._();

  static const String online = 'online';
  static const String walkIn = 'walk_in';

  /// The booking's origin with the legacy backfill applied.
  static String originOf(BookingEntity booking) {
    return switch (booking.origin) {
      walkIn => walkIn,
      online => online,
      _ => booking.customerId.startsWith('walkin-') ? walkIn : online,
    };
  }

  static bool isWalkIn(BookingEntity booking) =>
      originOf(booking) == walkIn;

  /// The block fill for an origin. Walk-in uses the same AA fill in
  /// both themes (`orangeFill`); online uses the theme navy.
  static Color fillFor(Brightness brightness, String origin) {
    if (origin == walkIn) return AppColors.orangeFill;
    return brightness == Brightness.dark
        ? AppColors.primaryOnDark
        : AppColors.primary;
  }

  /// The block label colour — white on both fills, in both themes.
  static Color labelColorFor(Brightness brightness, String origin) =>
      Colors.white;
}
