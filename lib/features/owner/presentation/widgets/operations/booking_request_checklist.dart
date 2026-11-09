import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../../fleet/data/datasources/fleet_remote_data_source.dart';

/// Audit §5 item 16 (O15 variant): the pre-accept checklist — Customer
/// KYC, car availability, advance received — shown before Accept in
/// the requested detail. Every row is a real check, not a tick box
/// the owner asserts:
///
/// * KYC: a saved customer record for the booking CNIC that carries
///   both a face photo and a licence number (the app has no verified
///   flag — the admin reviews KYC manually, so "documents on file"
///   is the honest wording).
/// * Car available: the booked vehicle's live status is `available`.
/// * Advance received: the booking's paid advance covers the required
///   advance.
///
/// A check that cannot be loaded stays pending (grey) rather than
/// rendering a false tick or a false cross.
class BookingRequestChecklist extends StatefulWidget {
  const BookingRequestChecklist({super.key, required this.booking});

  final BookingEntity booking;

  @override
  State<BookingRequestChecklist> createState() =>
      _BookingRequestChecklistState();
}

class _BookingRequestChecklistState extends State<BookingRequestChecklist> {
  bool? _kycOnFile;
  bool? _carAvailable;

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    final booking = widget.booking;
    bool? kyc;
    bool? car;
    final cnic = booking.customerCnic;
    if (cnic != null &&
        cnic.trim().isNotEmpty &&
        sl.isRegistered<CustomerRemoteDataSource>()) {
      try {
        final customer = await sl<CustomerRemoteDataSource>()
            .getCustomerByCnic(booking.shopId, cnic);
        kyc = customer != null &&
            customer.profilePhotoUrl != null &&
            customer.licenseNumber != null;
      } catch (_) {
        kyc = null;
      }
    }
    if (sl.isRegistered<FleetRemoteDataSource>()) {
      try {
        final vehicle = await sl<FleetRemoteDataSource>()
            .getVehicleById(booking.vehicleId);
        car = vehicle?.status == 'available';
      } catch (_) {
        car = null;
      }
    }
    if (mounted) {
      setState(() {
        _kycOnFile = kyc;
        _carAvailable = car;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booking = widget.booking;
    final advanceReceived = booking.advanceRequired > 0 &&
        booking.advancePaid >= booking.advanceRequired;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingChecklistTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _row(context, l10n.bookingCheckKyc, _kycOnFile),
            _row(context, l10n.bookingCheckCar, _carAvailable),
            _row(context, l10n.bookingCheckAdvance, advanceReceived),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, bool? checked) {
    final isChecked = checked == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isChecked
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: isChecked
                ? AppColors.successTextFor(Theme.of(context).brightness)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isChecked ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
