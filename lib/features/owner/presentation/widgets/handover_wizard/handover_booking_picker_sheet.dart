import 'package:flutter/material.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/utils/current_shop.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// Item 9 (O26): the "Select booking manually" picker for the QR
/// scan view — the bookings actually ready for handover (approved
/// / paid) instead of a typed id. Extracted so the scan view stays
/// under the 250-line cap. Returns the picked booking id, or null.
class HandoverBookingPickerSheet {
  static Future<String?> show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) =>
            FutureBuilder<List<BookingEntity>>(
          future: sl<BookingRemoteDataSource>()
              .getShopBookings(currentShopId()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final ready = (snapshot.data ?? [])
                .where((b) => b.status == 'approved' || b.status == 'paid')
                .toList();
            if (ready.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.handoverWizardNoReadyBookings,
                      textAlign: TextAlign.center),
                ),
              );
            }
            return ListView.builder(
              controller: scrollController,
              itemCount: ready.length,
              itemBuilder: (context, index) {
                final booking = ready[index];
                return ListTile(
                  leading: const Icon(Icons.directions_car_rounded),
                  title: Text(booking.vehicleName ?? l10n.summaryVehicle),
                  subtitle: Text(
                      '${booking.customerName ?? l10n.requestsCustomerFallback} • #${booking.bookingId}'),
                  onTap: () => Navigator.of(sheetContext).pop(
                        booking.bookingId,
                      ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
