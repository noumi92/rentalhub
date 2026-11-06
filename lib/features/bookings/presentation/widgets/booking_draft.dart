import 'package:flutter/material.dart';

import 'package_tier_list.dart';

/// Phase B (B3): builds the booking draft the picker hands to the
/// review screen. Extracted from [RentPackagePickerView] so the view
/// stays under the 250-line cap.
Map<String, dynamic> buildBookingDraft({
  required String carId,
  required String carName,
  required String plateNumber,
  required String shopId,
  required String shopName,
  required bool isWithDriver,
  required PackageTierOption tier,
  required int kmLimit,
  required int? securityDepositPkr,
  required String tripType,
  required String? fixedRouteId,
  required String? destinationCity,
  required DateTime pickupDate,
  required TimeOfDay pickupTime,
  required int durationDays,
  required int totalAmount,
  required int advanceRequired,
}) {
  final pickupDateTime = DateTime(
    pickupDate.year,
    pickupDate.month,
    pickupDate.day,
    pickupTime.hour,
    pickupTime.minute,
  );
  final returnDateTime = tier.hours >= 24
      ? pickupDateTime.add(Duration(days: durationDays))
      : pickupDateTime.add(Duration(hours: tier.hours));
  return {
    'carId': carId,
    'carName': carName,
    'plateNumber': plateNumber,
    'shopId': shopId,
    'shopName': shopName,
    'isWithDriver': isWithDriver,
    'packageType': tier.label,
    'packageLabel': tier.title,
    'packageHours': tier.hours,
    'kmIncluded': tier.kmIncluded,
    'securityDepositPkr': securityDepositPkr,
    'tripType': tripType,
    'kmLimit': kmLimit,
    'trackerCleared': false,
    'fixedRouteId': fixedRouteId,
    'destinationCity': destinationCity,
    'pickupTime': pickupDateTime,
    'returnTime': returnDateTime,
    'totalAmount': totalAmount,
    'advanceRequired': advanceRequired,
  };
}
