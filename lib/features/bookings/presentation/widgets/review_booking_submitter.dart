import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  Future<BookingEntity?> submit({
    required BuildContext context,
    required Map<String, dynamic> draft,
    required bool? shopIsVerified,
    required String notes,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // Customer rework (Worker E): an unverified shop may only be
    // booked while the platform allows it. Verified shops and a
    // missing/unreadable setting always proceed.
    final gate = bookingGate ?? _defaultGate();
    final allowed = await gate.isBookingAllowed(
      shopId: draft['shopId'] as String? ?? 'shop-default',
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
      // C2: the request is filed under the signed-in customer's own
      // record (name, phone, CNIC) when one exists. The placeholder
      // identity below is only for a signed-out/demo flow — a real
      // customer never sees it.
      String customerId = 'cust-101';
      String customerName = 'Valued Customer';
      String customerPhone = '+923001234567';
      String? customerCnic;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          customerId = user.uid;
          customerName = user.displayName ?? customerName;
          customerPhone = user.phoneNumber ?? customerPhone;
          if (sl.isRegistered<CustomerRemoteDataSource>()) {
            final record =
                await sl<CustomerRemoteDataSource>().getCustomerById(user.uid);
            if (record != null) {
              customerName = record.name;
              customerPhone = record.phone;
              customerCnic = record.cnic;
            }
          }
        }
      } catch (_) {}

      final booking =
          await sl<BookingRemoteDataSource>().createBookingRequest(
        customerId: customerId,
        shopId: draft['shopId'] as String? ?? 'shop-default',
        vehicleId: draft['carId'] as String? ?? 'car-default',
        packageType: draft['packageType'] as String? ?? '24h',
        isWithDriver: draft['isWithDriver'] as bool? ?? false,
        pickupTime: draft['pickupTime'] as DateTime? ?? DateTime.now(),
        returnTime: draft['returnTime'] as DateTime? ??
            DateTime.now().add(const Duration(days: 1)),
        totalAmount: draft['totalAmount'] as int? ?? 5000,
        advanceRequired: draft['advanceRequired'] as int? ?? 1000,
        vehicleName: draft['carName'] as String?,
        vehiclePlate: draft['plateNumber'] as String?,
        shopName: draft['shopName'] as String?,
        customerName: customerName,
        customerPhone: customerPhone,
        customerCnic: customerCnic,
        tripType: draft['tripType'] as String? ?? 'in_city',
        kmLimit: draft['kmLimit'] as int?,
        fixedRouteId: draft['fixedRouteId'] as String?,
        fixedRouteSummary: draft['fixedRouteSummary'] as String?,
        outCityMode: draft['outCityMode'] as String?,
        outCityPerKmPkr: draft['outCityPerKmPkr'] as int?,
        notes: notes,
      );
      if (context.mounted) {
        AppFeedback.showSuccess(context, l10n.reviewSent);
      }
      return booking;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, l10n.reviewSubmitError(e.toString()));
      }
      return null;
    }
  }
}
