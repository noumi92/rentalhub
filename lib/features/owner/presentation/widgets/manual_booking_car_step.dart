import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../services/walk_in_booking_service.dart';
import 'manual_booking_package_selector.dart';
import 'manual_booking_radio_dot.dart';
import 'manual_booking_schedule_section.dart';

/// O22: step 2 — car + package. Cars are a radio list with
/// Available / On Rent / Maintenance badges (a car in maintenance
/// cannot be picked); the chosen car is checked against existing
/// bookings for the picked window ("Car is free for this time",
/// the triage availability precedent extended to a time window).
/// Packages, drive mode, out-of-city extras and the schedule (Start
/// "Now" + auto Return) reuse the existing selector + schedule widgets.
/// [onAvailabilityChanged] reports the check (null = not checked yet)
/// so the wizard can block Next when the car is booked for the window.
class ManualBookingCarStep extends StatefulWidget {
  const ManualBookingCarStep({
    super.key,
    required this.isLoadingVehicles,
    required this.vehiclesError,
    required this.onRetryLoad,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleChanged,
    required this.selectedPackage,
    required this.onPackageChanged,
    required this.isWithDriver,
    required this.onDriverModeChanged,
    required this.isOutOfCity,
    required this.pickupTime,
    required this.returnTime,
    required this.onPickupChanged,
    required this.onReturnChanged,
    required this.onTripTypeChanged,
    this.selectedFixedRoute,
    this.onFixedRouteChanged,
    required this.onAvailabilityChanged,
    this.existingBookings,
    this.driverRatePerDayPkr,
  });

  final bool isLoadingVehicles;
  final String? vehiclesError;
  final VoidCallback onRetryLoad;
  final List<VehicleEntity> vehicles;
  final VehicleEntity? selectedVehicle;
  final ValueChanged<VehicleEntity?> onVehicleChanged;
  final VehiclePackageEntity? selectedPackage;
  final ValueChanged<VehiclePackageEntity?> onPackageChanged;
  final bool isWithDriver;
  final ValueChanged<bool> onDriverModeChanged;
  final bool isOutOfCity;
  final DateTime pickupTime;
  final DateTime returnTime;
  final ValueChanged<DateTime> onPickupChanged;
  final ValueChanged<DateTime> onReturnChanged;
  final ValueChanged<bool> onTripTypeChanged;
  final FixedRouteEntity? selectedFixedRoute;
  final ValueChanged<FixedRouteEntity?>? onFixedRouteChanged;
  final ValueChanged<bool?> onAvailabilityChanged;

  /// Test override: check against these bookings, not Firestore.
  final List<BookingEntity>? existingBookings;

  /// Worker A (2026-11-21): the shop's booking-settings driver rate (Rs/day), threaded to the package selector. Null charges Rs. 0 — the vehicle's stored surcharge is never read.
  final int? driverRatePerDayPkr;

  @override
  State<ManualBookingCarStep> createState() => _ManualBookingCarStepState();
}

class _ManualBookingCarStepState extends State<ManualBookingCarStep> {
  bool? _free;
  String _checkKey = '';

  @override
  void initState() {
    super.initState();
    _maybeCheckFree();
  }

  @override
  void didUpdateWidget(covariant ManualBookingCarStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeCheckFree();
  }

  Future<void> _maybeCheckFree() async {
    final v = widget.selectedVehicle;
    if (v == null) {
      if (_free != null) {
        setState(() => _free = null);
        widget.onAvailabilityChanged(null);
      }
      return;
    }
    final key = '${v.vehicleId}|${widget.pickupTime.toIso8601String()}|${widget.returnTime.toIso8601String()}';
    if (key == _checkKey) return;
    _checkKey = key;
    final free = await WalkInBookingService.isVehicleFree(
      shopId: currentShopId(),
      vehicleId: v.vehicleId,
      pickup: widget.pickupTime,
      returnTime: widget.returnTime,
      existingBookings: widget.existingBookings,
    );
    if (!mounted) return;
    setState(() => _free = free);
    widget.onAvailabilityChanged(free);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isLoadingVehicles) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Flexible(child: Text(l10n.manualBookingLoadingVehicles, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );
    }
    if (widget.vehiclesError != null) {
      return ManualBookingLoadErrorCard(message: l10n.fleetLoadError(widget.vehiclesError!), onRetry: widget.onRetryLoad);
    }
    if (widget.vehicles.isEmpty) {
      return Text(l10n.manualBookingNoPackages, style: Theme.of(context).textTheme.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.vehicles.map((v) => _carRow(context, l10n, v)),
        if (widget.selectedVehicle != null && _free != null) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _free!
                  ? AppColors.successContainerFor(Theme.of(context).brightness)
                  : AppColors.errorContainerFor(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(_free! ? Icons.check_circle_rounded : Icons.block_rounded, size: 18,
                    color: _free!
                        ? AppColors.successTextFor(Theme.of(context).brightness)
                        : AppColors.dangerTextFor(Theme.of(context).brightness)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_free! ? l10n.manualBookingCarFree : l10n.manualBookingCarBusy,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _free!
                              ? AppColors.successTextFor(Theme.of(context).brightness)
                              : AppColors.dangerTextFor(Theme.of(context).brightness))),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        ManualBookingPackageSelector(
          vehicle: widget.selectedVehicle,
          selectedPackage: widget.selectedPackage,
          onPackageChanged: widget.onPackageChanged,
          isWithDriver: widget.isWithDriver,
          onDriverModeChanged: widget.onDriverModeChanged,
          isOutOfCity: widget.isOutOfCity,
          pickup: widget.pickupTime,
          returnTime: widget.returnTime,
          selectedFixedRoute: widget.selectedFixedRoute,
          onFixedRouteChanged: widget.onFixedRouteChanged, driverRatePerDayPkr: widget.driverRatePerDayPkr,
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => widget.onPickupChanged(DateTime.now()),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(l10n.manualBookingStartNow),
          ),
        ),
        ManualBookingScheduleSection(
          pickupTime: widget.pickupTime,
          returnTime: widget.returnTime,
          onPickupChanged: widget.onPickupChanged,
          onReturnChanged: widget.onReturnChanged,
          isOutOfCity: widget.isOutOfCity,
          onTripTypeChanged: widget.onTripTypeChanged,
        ),
      ],
    );
  }

  Widget _carRow(BuildContext context, AppLocalizations l10n, VehicleEntity v) {
    final brightness = Theme.of(context).brightness;
    final selected = widget.selectedVehicle?.vehicleId == v.vehicleId;
    final maintenance = v.status == 'maintenance';
    final (badgeLabel, badgeFg, badgeBg) = switch (v.status) {
      'rented' => (l10n.manualBookingCarOnRent, AppColors.warningTextFor(brightness), AppColors.warningContainerFor(brightness)),
      'maintenance' => (l10n.manualBookingCarMaintenance, Theme.of(context).colorScheme.onSurfaceVariant, Theme.of(context).colorScheme.surfaceContainerHighest),
      _ => (l10n.manualBookingCarAvailable, AppColors.successTextFor(brightness), AppColors.successContainerFor(brightness)),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: maintenance ? null : () => widget.onVehicleChanged(v),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.orangeFill : Theme.of(context).dividerColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              ManualBookingRadioDot(selected: selected, enabled: !maintenance),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${v.make} ${v.model} ${v.year}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(v.plateNumber, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                child: Text(badgeLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: badgeFg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
