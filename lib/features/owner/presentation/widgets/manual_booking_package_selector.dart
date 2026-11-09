import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'operations/booking_fare_breakdown.dart';

/// The vehicle dropdown of the walk-in booking wizard. Extracted from
/// [OwnerManualBookingView] so the view stays under the 250-line cap.
class ManualBookingVehicleDropdown extends StatelessWidget {
  const ManualBookingVehicleDropdown({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onChanged,
  });

  final List<VehicleEntity> vehicles;
  final VehicleEntity? selectedVehicle;
  final ValueChanged<VehicleEntity?> onChanged;

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VehicleEntity>(
          dropdownColor: Theme.of(context).colorScheme.surface,
          isExpanded: true,
          value: selectedVehicle,
          hint: Text(l10n.manualBookingSelectVehicleHint),
          items: vehicles.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text('${v.make} ${v.model} (${v.year}) - ${v.plateNumber}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// The package selector of the walk-in booking wizard: one chip per
/// enabled package of the chosen vehicle, with the computed total
/// (package price + with-driver surcharge) shown below. Extracted from
/// [OwnerManualBookingView] so the view stays under the 250-line cap.
/// Phase B (B2): the counter total comes from the vehicle's package,
/// not from a typed number.
class ManualBookingPackageSelector extends StatelessWidget {
  const ManualBookingPackageSelector({
    super.key,
    required this.vehicle,
    required this.selectedPackage,
    required this.onPackageChanged,
    required this.isWithDriver,
    required this.onDriverModeChanged,
    this.isOutOfCity = false,
    this.pickup,
    this.returnTime,
  });

  final VehicleEntity? vehicle;
  final VehiclePackageEntity? selectedPackage;
  final ValueChanged<VehiclePackageEntity> onPackageChanged;
  final bool isWithDriver;
  final ValueChanged<bool> onDriverModeChanged;

  /// Audit §5 item 1: the trip type and the picked dates drive the
  /// displayed total, exactly as they drive the booked total.
  final bool isOutOfCity;
  final DateTime? pickup;
  final DateTime? returnTime;

  /// The single-unit price of a package: the package price (scaled
  /// by the out-of-city ratio when the trip leaves the city — the
  /// same ratio the customer picker applies in
  /// `PackageTierList.optionsFor`) plus the with-driver surcharge.
  /// [totalFor] multiplies this by days/weeks; [unitFor] is the
  /// per-day (or per-week) rate the fare summary shows.
  static int unitFor({
    required VehicleEntity? vehicle,
    required VehiclePackageEntity? package,
    required bool isWithDriver,
    bool isOutOfCity = false,
  }) {
    if (vehicle == null || package == null) return 0;
    var unit = package.pricePkr;
    if (isOutOfCity && vehicle.rates.daily24 > 0) {
      final outDaily =
          vehicle.rates.outOfCityDaily ?? vehicle.rates.daily24;
      unit = (unit * outDaily / vehicle.rates.daily24).round();
    }
    if (!isWithDriver) return unit;
    final perDay = vehicle.withDriverSurchargePkr ?? 0;
    final surcharge = package.hours >= 24
        ? perDay * (package.hours ~/ 24)
        : (perDay * package.hours / 24).round();
    return unit + surcharge;
  }

  /// The counter total for a package, shared with the view that creates
  /// the booking so the displayed total and the booked total never drift.
  /// Audit §5 item 1: with pickup/return dates the total is day-aware
  /// — a 24h package costs the unit price per day, a Weekly package
  /// per week; hourly packages stay a single unit. Without dates the
  /// old single-unit total is returned, so existing callers are
  /// unaffected.
  static int totalFor({
    required VehicleEntity? vehicle,
    required VehiclePackageEntity? package,
    required bool isWithDriver,
    bool isOutOfCity = false,
    DateTime? pickup,
    DateTime? returnTime,
  }) {
    final unit = unitFor(
      vehicle: vehicle,
      package: package,
      isWithDriver: isWithDriver,
      isOutOfCity: isOutOfCity,
    );
    if (unit == 0 || package == null || pickup == null || returnTime == null) {
      return unit;
    }
    final days = dayCountBetween(pickup, returnTime);
    if (package.label == '24h') return unit * days;
    if (package.label == 'Weekly') return unit * ((days + 6) ~/ 7);
    // Audit §5 (Monthly): one unit per 30-day block, like Weekly.
    if (package.label == 'Monthly') return unit * ((days + 29) ~/ 30);
    return unit;
  }

  /// Phase B (D2): the return time follows the chosen package — a
  /// 6-hour package returns in 6 hours, a weekly one in 7 days.
  static DateTime returnTimeFor({
    required DateTime pickup,
    required VehiclePackageEntity package,
  }) {
    return pickup.add(Duration(hours: package.hours));
  }

  int get _total => totalFor(
        vehicle: vehicle,
        package: selectedPackage,
        isWithDriver: isWithDriver,
        isOutOfCity: isOutOfCity,
        pickup: pickup,
        returnTime: returnTime,
      );

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final vehicle = this.vehicle;
    if (vehicle == null) {
      return Text(l10n.manualBookingSelectVehicleFirst,
          style: Theme.of(context).textTheme.bodySmall);
    }
    final packages = vehicle.enabledPackages;
    if (packages.isEmpty) {
      return Text(l10n.manualBookingNoPackages,
          style: Theme.of(context).textTheme.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packages.map((p) {
            final selected = selectedPackage?.label == p.label;
            return ChoiceChip(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              // C5: grouped amount via the String-typed {price}
              // placeholder (rulebook §4.5).
              label: Text(l10n.manualBookingPackageChip(p.label, formatRs(p.pricePkr))),
              selected: selected,
              selectedColor: AppColors.orangeFill,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
              onSelected: (_) => onPackageChanged(p),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(l10n.withDriver,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            Switch(
              value: isWithDriver,
              activeThumbColor: AppColors.secondary,
              onChanged: onDriverModeChanged,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.manualBookingTotal(formatRs(_total)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Lightweight 3-step indicator for the walk-in booking wizard
/// (Customer / Vehicle+Package / Confirm). Display-only: the wizard
/// stays a single page; the indicator just shows where the owner is.
class ManualBookingStepIndicator extends StatelessWidget {
  const ManualBookingStepIndicator({super.key, required this.currentStep});

  /// 1-based step the owner is on (1..3).
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.manualBookingCustomerSection,
      l10n.manualBookingVehicleSection,
      l10n.manualBookingConfirmTitle,
    ];
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: i + 1 < currentStep
                      ? AppColors.accentSuccessStrong
                      : i + 1 == currentStep
                          ? AppColors.orangeFill
                          : colorScheme.surfaceContainerHighest,
                  child: i + 1 < currentStep
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: i + 1 == currentStep
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                              ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: i + 1 == currentStep
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: i + 1 == currentStep
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact load-failure card for the vehicle section: a visible error
/// with a retry, instead of the old silent empty dropdown (audit C4).
class ManualBookingLoadErrorCard extends StatelessWidget {
  const ManualBookingLoadErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.commonRetry),
          ),
        ],
      ),
    );
  }
}
