import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../bookings/data/datasources/booking_settings_data_source.dart';
import 'vehicle_driver_rate_text.dart';
import 'vehicle_image_asset.dart';

/// B3: one car card on the shop's fleet screen, converted from MockVehicle
/// to the real [VehicleEntity]. Shows the owner's uploaded photo when
/// there is one, otherwise the asset illustration for the make/model.
class CustomerVehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback onTap;

  /// Worker 3 (2026-11-21): test seam — forwarded to
  /// [VehicleDriverRateText], which loads the shop's booking-settings
  /// driver rate for the with-driver daily rate.
  final BookingSettingsDataSource? settingsDataSource;

  const CustomerVehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    this.settingsDataSource,
  });

  // FG-2 (UI/UX audit 2026-11-15): the make/model → asset mapping
  // lives in the ONE shared helper now — the local _assetFor copy
  // mapped Sportage/BR-V to a red Civic. Never duplicate it here.
  Widget _carImage(VehicleEntity v) {
    final url = v.imageUrl;
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Image.asset(
          vehicleImageAsset(v.make, v.model),
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(vehicleImageAsset(v.make, v.model), fit: BoxFit.cover);
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'rented':
        return l10n.rentedOut;
      case 'maintenance':
        return l10n.inMaintenance;
      default:
        return l10n.available;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    final brightness = Theme.of(context).brightness;
    // FG-3 (UI/UX audit 2026-11-15): the availability pill, same
    // label + colour mapping as ShopVehicleCard (CU-M8) — green when
    // available, neutral when rented, amber in maintenance — over the
    // photo, so the fleet list states availability without a tap.
    final Color pillBg;
    final Color pillBorder;
    final Color pillFg;
    switch (v.status) {
      case 'rented':
        pillBg = Theme.of(context).colorScheme.surfaceContainerHighest;
        pillBorder = Theme.of(context).colorScheme.outlineVariant;
        pillFg = Theme.of(context).colorScheme.onSurfaceVariant;
      case 'maintenance':
        pillBg = AppColors.warningContainerFor(brightness);
        pillBorder = AppColors.warning.withValues(alpha: 0.35);
        pillFg = AppColors.warningOnContainerFor(brightness);
      default:
        pillBg = AppColors.successContainerFor(brightness);
        pillBorder = AppColors.successBorderFor(brightness);
        pillFg = AppColors.successOnContainerFor(brightness);
    }
    return Card(
      // Canonical borderless card look comes from AppTheme's
      // CardThemeData (elevation 3, soft shadow, no border) — the old
      // explicit elevation 0 + dividerColor side read as a dark
      // outline around every card.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _carImage(v),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: pillBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: pillBorder),
                        ),
                        child: Text(
                          _statusLabel(l10n, v.status),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w500, color: pillFg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${v.displayName} (${v.year})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PakistaniPlateWidget(
                        plateNumber: v.plateNumber,
                        isCompact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Wrap, not a fixed Row: at 360px / large text
                  // scale the three chips (seats, transmission, fuel)
                  // overflowed; they now flow onto a second line.
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _specChip(context,
                          Icons.event_seat_rounded, l10n.vehicleSeats(v.seats)),
                      _specChip(context,
                          Icons.settings_rounded, v.transmission),
                      _specChip(context, Icons.local_gas_station_rounded,
                          v.fuelType),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.vehicleSelfRate(formatRs(v.rates.daily24)),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: VehicleDriverRateText(
                          vehicle: v,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.orangeTextFor(Theme.of(context).brightness)),
                          maxLines: 1,
                          textAlign: TextAlign.end,
                          settingsDataSource: settingsDataSource,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
