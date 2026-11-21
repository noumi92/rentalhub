import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import 'vehicle_hero_card.dart' show vehicleHeroTag;
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../bookings/data/datasources/booking_settings_data_source.dart';
import 'vehicle_driver_rate_text.dart';
import 'vehicle_image_asset.dart';

/// Phase A (A1): one car card on the shop detail screen, extracted so the
/// view stays under the 250-line cap. Shows the owner's uploaded photo
/// when there is one, otherwise the asset illustration for the make/model.
class ShopVehicleCard extends StatelessWidget {
  const ShopVehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.settingsDataSource,
  });

  final VehicleEntity vehicle;
  final VoidCallback? onTap;

  /// Worker 3 (2026-11-21): test seam — forwarded to
  /// [VehicleDriverRateText], which loads the shop's booking-settings
  /// driver rate for the with-driver daily rate.
  final BookingSettingsDataSource? settingsDataSource;

  Widget _carImage(VehicleEntity v) {
    final url = v.imageUrl;
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        height: 130,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetImage(v),
      );
    }
    return _assetImage(v);
  }

  Widget _assetImage(VehicleEntity v) {
    // CU-M9: the make/model → asset mapping lives in one shared
    // helper now — Sportage/BR-V no longer render as a red Civic.
    return Image.asset(
      vehicleImageAsset(v.make, v.model),
      height: 130,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/white_sedan_hero.png',
        fit: BoxFit.contain,
      ),
    );
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
    // CU-M8: the pill colour follows the status — green when
    // available, neutral when rented, amber in maintenance — instead
    // of always wearing the green "available" look.
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      // CU-M2: cards carry no dark border.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Photo Preview
            Container(
              height: 130,
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // E2: the hero wraps the image widget itself
                  // (including its errorBuilder fallback); the
                  // matching Hero lives in [VehicleHeroCard] on the
                  // vehicle detail screen.
                  Hero(
                    tag: vehicleHeroTag(v.vehicleId),
                    child: _carImage(v),
                  ),
                  // Availability Pill (CU-M8: colour by status)
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
                        _statusLabel(AppLocalizations.of(context)!, v.status),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500, color: pillFg),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          v.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      PakistaniPlateWidget(
                        plateNumber: v.plateNumber,
                        isCompact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _specChip(context, Icons.event_seat_rounded,
                          l10n.vehicleSeats(v.seats)),
                      _specChip(
                          context, Icons.settings_rounded, v.transmission),
                      _specChip(
                          context, Icons.local_gas_station_rounded, v.fuelType),
                    ],
                  ),
                  const Divider(height: 18),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        l10n.vehicleSelfRate(formatRs(v.rates.daily24)),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      VehicleDriverRateText(
                        vehicle: v,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w500,
                                // CU-M1: white-on-orange small text
                                // was 3.29:1 — orangeTextFor is AA.
                                color: AppColors.orangeTextFor(brightness)),
                        settingsDataSource: settingsDataSource,
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

  Widget _specChip(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          // CU-m1: the hardcoded 11.5px drifted from the type scale —
          // labelSmall is the token for this size.
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
