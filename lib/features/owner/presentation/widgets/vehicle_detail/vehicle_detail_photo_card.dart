import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../discovery/presentation/views/widgets/vehicle_hero_card.dart'
    show vehicleHeroTag;
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Showroom redesign (Phase 2, 2026-11-16): the vehicle-detail photo
/// card, extracted from [OwnerVehicleDetailView] so the view stays
/// under the 250-line cap. Unchanged visually — the rounded photo
/// with the daily rate, the status chip and the self-drive badge over
/// the bottom gradient scrim (the header rework of 2026-11-09). The
/// name/plate stay in the app bar, not repeated on the photo.
class VehicleDetailPhotoCard extends StatelessWidget {
  final VehicleEntity vehicle;

  const VehicleDetailPhotoCard({super.key, required this.vehicle});

  String _assetFor(VehicleEntity v) {
    final nameLower = v.displayName.toLowerCase();
    if (nameLower.contains('civic')) return 'assets/images/honda_civic_hero.png';
    if (nameLower.contains('corolla') || nameLower.contains('yaris')) return 'assets/images/toyota_corolla.png';
    return 'assets/images/white_sedan_hero.png';
  }

  Widget _photo(VehicleEntity v) {
    final imageUrl = v.imageUrl;
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return Image.network(imageUrl, width: double.infinity, height: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset(_assetFor(v), width: double.infinity, height: 210, fit: BoxFit.cover));
    }
    if (imageUrl != null && (imageUrl.startsWith('/') || imageUrl.contains(r'\'))) {
      return Image.file(File(imageUrl), width: double.infinity, height: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset(_assetFor(v), width: double.infinity, height: 210, fit: BoxFit.cover));
    }
    return Image.asset(_assetFor(v), width: double.infinity, height: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 210));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    // OW-M7: the status is mapped explicitly (available / on-rent /
    // maintenance) with the fleet card's label map — the old boolean
    // labelled a maintenance car "On Rent". Maintenance sits on the
    // amber-800 fill (white text ~7.5:1), not the on-rent orange.
    final (statusLabel, statusColor) = v.status == 'available' ? (l10n.available, AppColors.accentSuccessStrong) : v.status == 'maintenance' ? (l10n.fleetFilterMaintenance, AppColors.warningOnContainer) : (l10n.fleetOnRent, AppColors.orangeFill);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // OW-m15: the photo carries the fleet card's hero tag, so
            // the shared-element transition actually runs.
            Hero(tag: vehicleHeroTag(v.vehicleId), child: _photo(v)),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0.45), Colors.black.withValues(alpha: 0.78)], stops: const [0.30, 0.55, 0.80, 1.0])))),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.fleetDailyRate(formatRs(v.rates.daily24)), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)), child: Text(statusLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white))),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.65))), child: Text(v.isSelfDriveAvailable ? l10n.selfDriveHyphen : l10n.withDriver, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white))),
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
}
