import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/utils/package_pricing.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'manual_booking_package_selector.dart';
import 'operations/booking_fare_breakdown.dart';

/// The fare summary of the manual-booking confirm step (O17 p.7):
/// vehicle + customer, pickup/return, package + trip type, daily rate
/// × days, total, advance required and the live remaining balance.
/// Extracted from [OwnerManualBookingConfirmView] so the view stays
/// under the 250-line cap.
class ManualBookingFareSummary extends StatelessWidget {
  const ManualBookingFareSummary({
    super.key,
    required this.vehicle,
    required this.package,
    required this.isWithDriver,
    required this.isOutOfCity,
    required this.pickupTime,
    required this.returnTime,
    required this.customerName,
    required this.advanceReceived,
    this.fixedRoute,
    this.driverRatePerDayPkr,
  });

  final VehicleEntity vehicle;
  final VehiclePackageEntity package;
  final bool isWithDriver;
  final bool isOutOfCity;
  final DateTime pickupTime;
  final DateTime returnTime;
  final String customerName;
  final int advanceReceived;
  /// 09b §2: the fixed route chosen for this out-of-city trip.
  final FixedRouteEntity? fixedRoute;

  /// Worker A (2026-11-21): the shop's booking-settings driver
  /// rate (Rs/day). Null (unset) charges Rs. 0.
  final int? driverRatePerDayPkr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');
    final unit = ManualBookingPackageSelector.unitFor(
      vehicle: vehicle,
      package: package,
      isWithDriver: isWithDriver,
      isOutOfCity: isOutOfCity,
      fixedRoute: fixedRoute,
      driverRatePerDayPkr: driverRatePerDayPkr,
    );
    final total = ManualBookingPackageSelector.totalFor(
      vehicle: vehicle,
      package: package,
      isWithDriver: isWithDriver,
      isOutOfCity: isOutOfCity,
      pickup: pickupTime,
      returnTime: returnTime,
      fixedRoute: fixedRoute,
      driverRatePerDayPkr: driverRatePerDayPkr,
    );
    final days = dayCountBetween(pickupTime, returnTime);
    final advanceRequired =
        PackagePricing.advanceFor(vehicle: vehicle, total: total);
    final isDaily = package.label == '24h';
    final isWeekly = package.label == 'Weekly';
    final route = fixedRoute;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _row(context, l10n.summaryVehicle,
                '${vehicle.make} ${vehicle.model}'),
            _row(context, l10n.requestsCustomerFallback, customerName),
            _row(context, l10n.bookingFarePickup,
                dateFormat.format(pickupTime)),
            _row(context, l10n.bookingFareReturn,
                dateFormat.format(returnTime)),
            _row(
                context,
                l10n.packageLabel,
                isOutOfCity
                    ? '${package.label} • ${l10n.outOfCityHyphen}'
                    : '${package.label} • ${l10n.inCityHyphen}'),
            // 09b §2: the chosen fixed route, and the per-km estimate
            // note (final total settles on actual km at return).
            if (isOutOfCity && route != null)
              _row(context, l10n.outCityFixedRouteLabel,
                  route.displayName),
            if (isOutOfCity && vehicle.outCityMode == 'perKm')
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                    l10n.farePerKmEstimate(
                        days * (vehicle.outOfCityKmPerDay ?? kDefaultOutCityKmPerDay)),
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            _row(
                context,
                isDaily
                    ? l10n.bookingFareDailyRate
                    : l10n.bookingFarePackagePrice,
                l10n.amountRs(formatRs(unit))),
            if (isDaily || isWeekly)
              _row(context, l10n.bookingFareDailyRateTimes(days),
                  l10n.amountRs(formatRs(total))),
            const Divider(height: 20),
            _row(context, l10n.bookingFareTotal,
                l10n.amountRs(formatRs(total)),
                bold: true),
            _row(context, l10n.bookingFareAdvanceRequired,
                l10n.amountRs(formatRs(advanceRequired))),
            _row(context, l10n.bookingFareRemaining,
                l10n.amountRs(formatRs(total - advanceReceived)),
                bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w500 : FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
