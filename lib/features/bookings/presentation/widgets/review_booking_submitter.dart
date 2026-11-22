import 'package:flutter/material.dart';

import '../../../../core/auth/signed_in_user.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../admin/data/repositories/platform_settings_repository.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../domain/entities/booking_entity.dart';
import '../../utils/unverified_shop_gate.dart';

/// The review screen's submit flow, extracted so
/// [ReviewBookingRequestView] stays under the 250-line view cap.
///
/// Returns the created booking, or null when the request was blocked
/// (unverified shop with bookings disabled) or failed — the message
/// is already shown in both cases, so the caller only wires the
/// success callback.
class ReviewBookingSubmitter {
  final UnverifiedShopBookingGate? bookingGate;

  const ReviewBookingSubmitter({this.bookingGate});

  UnverifiedShopBookingGate _defaultGate() {
    try {
      if (sl.isRegistered<PlatformSettingsRepository>()) {
        return UnverifiedShopBookingGate(
            settings: sl<PlatformSettingsRepository>());
      }
    } catch (_) {}
    return UnverifiedShopBookingGate();
  }

  /// CU-M12: the fields a draft must carry to be submittable at all.
  /// Shared with [ReviewBookingRequestView], which shows the error
  /// state for an incomplete draft before the button can fire.
  static bool isDraftComplete(Map<String, dynamic> draft) {
    final shopId = draft['shopId'] as String?;
    final vehicleId = draft['carId'] as String?;
    return shopId != null &&
        shopId.isNotEmpty &&
        vehicleId != null &&
        vehicleId.isNotEmpty &&
        draft['totalAmount'] is int &&
        draft['advanceRequired'] is int &&
        draft['pickupTime'] is DateTime &&
        draft['returnTime'] is DateTime;
  }

  Future<BookingEntity?> submit({
    required BuildContext context,
    required Map<String, dynamic> draft,
    required bool? shopIsVerified,
    required String notes,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // CU-M12: a missing/malformed draft is an error, never a booking
    // with invented values. The old fallbacks ('shop-default',
    // 'car-default', total 5000, advance 1000, pickup now) created
    // real bookings with wrong money and a fake plate.
    if (!isDraftComplete(draft)) {
      if (context.mounted) {
        AppFeedback.showError(context, l10n.reviewDraftMissing);
      }
      return null;
    }
    final shopId = draft['shopId'] as String;
    final vehicleId = draft['carId'] as String;
    final totalAmount = draft['totalAmount'] as int;
    final advanceRequired = draft['advanceRequired'] as int;
    final pickupTime = draft['pickupTime'] as DateTime;
    final returnTime = draft['returnTime'] as DateTime;
    // Customer rework (Worker E): an unverified shop may only be
    // booked while the platform allows it. Verified shops and a
    // missing/unreadable setting always proceed.
    final gate = bookingGate ?? _defaultGate();
    final allowed = await gate.isBookingAllowed(
      shopId: shopId,
      shopIsVerified: shopIsVerified,
    );
    if (!allowed) {
      if (context.mounted) {
        AppFeedback.showError(
            context, l10n.admin2_unverifiedBookingsDisabled);
      }
      return null;
    }
    try {
      // CU-M12 / CU-m3: the request is filed under the signed-in
      // customer's own record (name, phone, CNIC) when one exists.
      // A signed-out caller cannot submit — the old 'cust-101' /
      // 'Valued Customer' / '+923001234567' placeholders filed real
      // bookings under a shared fake identity.
      final user = SignedInUser.current();
      if (user == null) {
        if (context.mounted) {
          AppFeedback.showError(context, l10n.reviewSignInRequired);
        }
        return null;
      }
      String customerId = user.uid;
      String? customerName = user.displayName;
      String? customerPhone = user.phoneNumber;
      String? customerCnic;
      try {
        if (sl.isRegistered<CustomerRemoteDataSource>()) {
          final record =
              await sl<CustomerRemoteDataSource>().getCustomerById(user.uid);
          if (record != null) {
            customerName = record.name;
            customerPhone = record.phone;
            customerCnic = record.cnic;
          }
        }
      } catch (_) {}

      final booking =
          await sl<BookingRemoteDataSource>().createBookingRequest(
        customerId: customerId,
        shopId: shopId,
        vehicleId: vehicleId,
        packageType: draft['packageType'] as String? ?? '24h',
        isWithDriver: draft['isWithDriver'] as bool? ?? false,
        pickupTime: pickupTime,
        returnTime: returnTime,
        totalAmount: totalAmount,
        advanceRequired: advanceRequired,
        vehicleName: draft['carName'] as String?,
        vehiclePlate: draft['plateNumber'] as String?,
        shopName: draft['shopName'] as String?,
        shopPhone: draft['shopPhone'] as String?,
        customerName: customerName,
        customerPhone: customerPhone,
        customerCnic: customerCnic,
        origin: 'online',
        tripType: draft['tripType'] as String? ?? 'in_city',
        kmLimit: draft['kmLimit'] as int?,
        fixedRouteId: draft['fixedRouteId'] as String?,
        fixedRouteSummary: draft['fixedRouteSummary'] as String?,
        outCityMode: draft['outCityMode'] as String?,
        outCityPerKmPkr: draft['outCityPerKmPkr'] as int?,
        depositAmountPkr: (draft['securityDepositPkr'] as num?)?.toDouble(),
        notes: notes,
      );
      if (context.mounted) {
        AppFeedback.showSuccess(context, l10n.reviewSent);
      }
      return booking;
    } catch (e) {
      // CU-m9: the user sees a generic failure message; the raw
      // error goes to the debug log only, never to the screen.
      debugPrint('ReviewBookingSubmitter: submit failed: $e');
      if (context.mounted) {
        AppFeedback.showError(context, l10n.reviewSubmitFailed);
      }
      return null;
    }
  }
}
