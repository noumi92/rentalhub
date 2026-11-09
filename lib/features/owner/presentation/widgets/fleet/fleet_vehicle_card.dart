import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../../features/discovery/presentation/views/widgets/vehicle_hero_card.dart'
    show vehicleHeroTag;
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../../core/utils/money_format.dart';

/// Simplified fleet card (2026-11-09): the old card carried an
/// availability switch, an "On Rent until" row and four actions
/// (Edit rates, Booking calendar, Edit Rent, Update Price) — too
/// much for a list item. The simple card is a hero photo with the
/// name, plate and status badge, one in-city daily price row, and
/// exactly two actions: "Rates" (the per-package editor, 09b) and
/// "Out-of-city rules" (the shared rules screen, 010b). Availability,
/// calendar, edit-rent and price edits live on the detail / editor
/// screens, not here. Tapping the photo flies into vehicle detail
/// via the existing hero tag. The old hardcoded light strip
/// (Color(0xFFF8FAFC), near-white in dark mode) is gone — the card
/// below the photo uses the theme surface.
/// The photo is the vehicle's uploaded image when one exists (network
/// URL from cPanel, or a local file path on the owner's phone);
/// otherwise the old name-based asset fallback is kept so cars without
/// photos still show a sensible image.
class FleetVehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback onEditRates;
  final VoidCallback onOutCityRules;

  /// Tapping the photo opens the vehicle-detail route (the hero tag
  /// only works when the image is actually tappable). Null in tests
  /// or embeds that render the card without navigation.
  final VoidCallback? onTap;

  const FleetVehicleCard({
    super.key,
    required this.vehicle,
    required this.onEditRates,
    required this.onOutCityRules,
    this.onTap,
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

  /// Only the two known model families map to a model photo; anything
  /// else gets the one neutral placeholder — never a wrong-model photo
  /// (a Sportage is not a red Civic).
  String _assetFor(VehicleEntity v) {
    final nameLower = v.displayName.toLowerCase();
    if (nameLower.contains('civic')) {
      return 'assets/images/honda_civic_hero.png';
    } else if (nameLower.contains('corolla') || nameLower.contains('yaris')) {
      return 'assets/images/toyota_corolla.png';
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
    // Audit §4: the status chip is small white text, so it sits on a
    // filled token — orangeFill #C2410C (white 5.18:1, both modes) for
    // non-available, accentSuccessStrong #047857 (white 5.48:1) for
    // available. Never white on #F95700 / #FF6D24 (~3:1).
    final chipColor = isAvailable ? AppColors.accentSuccessStrong : AppColors.orangeFill;
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
          // The photo is tappable — it pushes the vehicle-detail
          // route (hero tag above). The Rates / Out-of-city buttons
          // below stay outside the tap area.
          InkWell(
            onTap: onTap,
            child: SizedBox(
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
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            _statusLabel(l10n, vehicle.status),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.fleetDailySelfDriveRate, style: Theme.of(context).textTheme.labelSmall),
                Text(l10n.fleetDailyRate(formatRs(vehicle.rates.daily24)), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEditRates,
                    child: Text(l10n.fleetEditRatesTooltip),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOutCityRules,
                    child: Text(l10n.outCityRulesTitle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
