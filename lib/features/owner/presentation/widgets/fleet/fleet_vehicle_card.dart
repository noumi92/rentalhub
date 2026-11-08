import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../../features/discovery/presentation/views/widgets/vehicle_hero_card.dart'
    show vehicleHeroTag;
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Phase B (B1) + #13: fleet card for a real [VehicleEntity], rebuilt
/// image-led on the [VehicleHeroCard] pattern — a full-width hero photo
/// on top with a gradient overlay carrying the name, plate and status
/// chip, the price row below, and availability / rates / calendar as
/// clear action buttons. Tapping the photo flies into vehicle detail
/// via the existing hero tag. The old hardcoded light strip
/// (Color(0xFFF8FAFC), near-white in dark mode) is gone — the card
/// below the photo uses the theme surface.
/// The photo is the vehicle's uploaded image when one exists (network
/// URL from cPanel, or a local file path on the owner's phone);
/// otherwise the old name-based asset fallback is kept so cars without
/// photos still show a sensible image.
class FleetVehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onEditRates;
  final VoidCallback onViewCalendar;

  const FleetVehicleCard({
    super.key,
    required this.vehicle,
    required this.onToggleAvailability,
    required this.onEditRates,
    required this.onViewCalendar,
  });

  Widget _carImage(VehicleEntity v) {
    final imageUrl = v.imageUrl;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetImage(_assetFor(v)),
      );
    }
    if (imageUrl != null &&
        (imageUrl.startsWith('/') || imageUrl.contains(r'\'))) {
      return Image.file(
        File(imageUrl),
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetImage(_assetFor(v)),
      );
    }
    return _assetImage(_assetFor(v));
  }

  Widget _assetImage(String asset) => Image.asset(asset, width: double.infinity, height: 190, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/images/white_sedan_hero.png', width: double.infinity, height: 190, fit: BoxFit.cover));

  String _assetFor(VehicleEntity v) {
    final nameLower = v.displayName.toLowerCase();
    if (nameLower.contains('civic')) {
      return 'assets/images/honda_civic_hero.png';
    } else if (nameLower.contains('corolla') || nameLower.contains('yaris')) {
      return 'assets/images/toyota_corolla.png';
    } else if (nameLower.contains('sportage') || nameLower.contains('br-v')) {
      return 'assets/images/red_civic.png';
    }
    return 'assets/images/white_sedan_hero.png';
  }

  /// The stored status code stays as-is; only the displayed label
  /// is localized.
  String _statusLabel(AppLocalizations l10n, String status) => {'available': l10n.available, 'rented': l10n.fleetOnRent, 'maintenance': l10n.fleetFilterMaintenance}[status] ?? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAvailable = vehicle.status == 'available';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // #15: the non-available status is small text — the light orange
    // is weak on a dark surface, so dark mode uses secondaryDark.
    final statusColor = isAvailable ? AppColors.successTextFor(Theme.of(context).brightness) : (isDark ? AppColors.secondaryDark : AppColors.secondary);
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: vehicleHeroTag(vehicle.vehicleId),
                  child: _carImage(vehicle),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PakistaniPlateWidget(plateNumber: vehicle.plateNumber, isCompact: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.fleetVehicleSpecs(vehicle.transmission, vehicle.fuelType, vehicle.seats),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              _statusLabel(l10n, vehicle.status),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.fleetDailySelfDriveRate, style: Theme.of(context).textTheme.labelSmall),
                      Text(l10n.fleetDailyRate(vehicle.rates.daily24), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Text(
                  isAvailable ? l10n.available : _statusLabel(l10n, vehicle.status),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: statusColor),
                ),
                Switch(
                  value: isAvailable,
                  activeThumbColor: AppColors.accentSuccess,
                  onChanged: onToggleAvailability,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(icon: const Icon(Icons.tune_rounded, size: 18), label: Text(l10n.fleetEditRatesTooltip), onPressed: onEditRates),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(icon: const Icon(Icons.calendar_month_rounded, size: 18), label: Text(l10n.fleetCalendarTooltip), onPressed: onViewCalendar),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
