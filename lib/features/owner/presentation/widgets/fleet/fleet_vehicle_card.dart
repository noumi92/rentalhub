import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../../features/discovery/presentation/views/widgets/vehicle_hero_card.dart'
    show vehicleHeroTag;
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../../core/utils/money_format.dart';

/// Simplified fleet card (2026-11-09, header rework round 4): the car
/// header lives ON the photo — the name, plate, one in-city daily
/// rate and the self-drive badge stack over the bottom gradient scrim
/// (white text, status chip beside the drive badge), so the photo
/// carries the whole identity. UNDER the photo there is exactly ONE
/// row: small orange icon buttons with short regular labels — Rates
/// (the per-package editor, 09b), Out-of-city rules (010b) and Edit
/// (the edit-details route, only when [onEditDetails] is provided).
/// The old price block and the two OutlinedButtons below the photo
/// are gone. Availability, calendar and price edits live on the
/// detail / editor screens, not here. Tapping the photo flies into
/// vehicle detail via the existing hero tag.
/// The photo is the vehicle's uploaded image when one exists (network
/// URL from cPanel, or a local file path on the owner's phone);
/// otherwise the old name-based asset fallback is kept so cars without
/// photos still show a sensible image.
class FleetVehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback onEditRates;
  final VoidCallback onOutCityRules;

  /// Opens the edit-details route (`/owner/vehicles/:id/edit`).
  /// Null in embeds that render the card without navigation — the
  /// Edit icon button is only shown when this is provided. Wired by
  /// the fleet view via [FleetBody]; Worker 4 owns that wiring.
  final VoidCallback? onEditDetails;

  /// RQ-F10 (O05/O30): the active booking's return date/time for an
  /// On-Rent car, loaded by the fleet view from the same shop
  /// bookings the fleet calendar reads. Null (no active booking
  /// found, or the car is not on rent) renders no line — never an
  /// invented date.
  final DateTime? rentedUntil;

  /// Tapping the photo opens the vehicle-detail route (the hero tag
  /// only works when the image is actually tappable). Null in tests
  /// or embeds that render the card without navigation.
  final VoidCallback? onTap;

  const FleetVehicleCard({
    super.key,
    required this.vehicle,
    required this.onEditRates,
    required this.onOutCityRules,
    this.onEditDetails,
    this.onTap,
    this.rentedUntil,
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
    // FG-8 (UI/UX audit 2026-11-15): maintenance is no longer the
    // rented orange — the detail view's three-way mapping:
    // maintenance on warningOnContainer amber, on-rent on orangeFill.
    final chipColor = vehicle.status == 'maintenance'
        ? AppColors.warningOnContainer
        : isAvailable
            ? AppColors.accentSuccessStrong
            : AppColors.orangeFill;
    // PW-20 (UI/UX audit 2026-11-15): the out-of-city signal — a
    // chip only when the vehicle has non-default out-city pricing
    // (per-km or fixed route); per-day / unset shows nothing.
    final outCityLabel = vehicle.outCityMode == 'perKm'
        ? l10n.fleetOutCityPerKm
        : vehicle.outCityMode == 'fixedRoute'
            ? l10n.fleetOutCityFixedRoute
            : null;
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The photo is tappable — it pushes the vehicle-detail
          // route (hero tag above). The icon-button row below stays
          // outside the tap area.
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
                  // The scrim deepens towards the bottom so the four
                  // stacked lines (name, rate, badges) stay readable
                  // on any photo.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.78),
                          ],
                          stops: const [0.30, 0.55, 0.80, 1.0],
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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PakistaniPlateWidget(plateNumber: vehicle.plateNumber, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.fleetDailyRate(formatRs(vehicle.rates.daily24)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(10)), child: Text(_statusLabel(l10n, vehicle.status), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white))),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.65))), child: Text(vehicle.isSelfDriveAvailable ? l10n.selfDriveHyphen : l10n.withDriver, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white))),
                            if (outCityLabel != null)
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.65))), child: Text(outCityLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white))),
                          ],
                        ),
                        // RQ-F10: the active booking's return date on
                        // On-Rent cards (same data source as the fleet
                        // calendar). No active booking → no line.
                        if (vehicle.status == 'rented' && rentedUntil != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.fleetOnRentUntil(DateFormat.yMMMd().format(rentedUntil!)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Exactly ONE row under the image: small orange icon
          // buttons with short regular labels (never bold).
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(child: _headerAction(context, icon: Icons.tune_rounded, label: l10n.vehicleDetailRatesTitle, onPressed: onEditRates)),
                const SizedBox(width: 8),
                Expanded(child: _headerAction(context, icon: Icons.route_rounded, label: l10n.outCityRulesTitle, onPressed: onOutCityRules)),
                if (onEditDetails != null) ...[
                  const SizedBox(width: 8),
                  Expanded(child: _headerAction(context, icon: Icons.edit_rounded, label: l10n.vehicleDetailEdit, onPressed: onEditDetails!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One eye-catching action: orange icon over a short regular
  /// (never bold) label on a pale orange container.
  Widget _headerAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    final brightness = Theme.of(context).brightness;
    final orange = AppColors.orangeTextFor(brightness);
    return Material(
      color: AppColors.orangeContainerFor(brightness),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: orange),
              const SizedBox(height: 2),
              Text(
                label,
                // FG-6 (UI/UX audit 2026-11-15): two lines, not one —
                // the Urdu out-of-city-rules label ellipsized in its
                // ~92 dp slot at 360 px with maxLines: 1.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
