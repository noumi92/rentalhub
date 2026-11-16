import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/card_decoration.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Showroom redesign (Phase 2, 2026-11-16): the vehicle-detail rates
/// section, extracted from [OwnerVehicleDetailView] so the view stays
/// under the 250-line cap. One white card holds the "Rates & Pricing"
/// header, the 7 rate tiers in a 2-column grid, the security-deposit
/// row, and the Fare table / View estimated rates buttons. Nothing is
/// dropped — the old rate rows are the same seven packages, only
/// re-laid-out. Phone-test build 80: Manage rates no longer lives
/// here as a header pill — it moved into the feature-actions row
/// above the rates card, with Booking calendar and Edit Vehicle.
class VehicleDetailRatesGrid extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback onFareTable;
  final VoidCallback onEstimate;

  const VehicleDetailRatesGrid({
    super.key,
    required this.vehicle,
    required this.onFareTable,
    required this.onEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    return Container(
      decoration: AppCardDecoration.of(context),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phone-test build 80: the header is just the title now —
          // Manage rates moved into the feature-actions row above
          // (one row, all three actions), so this card no longer
          // carries its own pill.
          Text(l10n.vehicleDetailRatesPricing, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          // The 7 rate tiers in a 2-column grid. Each tile is a
          // border-only cell (no shadow — seven shadows in a grid
          // would look dirty); the label + amount scale down instead
          // of overflowing at large text scales.
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: v.effectivePackages.map((p) => _rateTile(context, p.label, l10n.amountRs(formatRs(p.pricePkr)))).toList(),
          ),
          if (v.securityDepositPkr != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(l10n.vehicleDetailDeposit, style: Theme.of(context).textTheme.bodyMedium)),
                const SizedBox(width: 8),
                Text(l10n.amountRs(formatRs(v.securityDepositPkr!)), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), icon: const Icon(Icons.table_rows_rounded, size: 18), label: Text(l10n.vehicleDetailFareTable), onPressed: onFareTable)),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), icon: const Icon(Icons.calculate_outlined, size: 18), label: Text(l10n.ratesViewEstimate), onPressed: onEstimate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateTile(BuildContext context, String label, String value) {
    // Phone-test build 81: `labelMedium` is the theme's grey
    // `onSurfaceVariant` — the tier labels rendered grey on the tile.
    // Explicit onSurface (light + dark legs) matches the card surface.
    final brightness = Theme.of(context).brightness;
    final labelColor = brightness == Brightness.dark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;
    return Container(
      decoration: AppCardDecoration.of(context, radius: 12, boxShadow: const []),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: labelColor)),
            const SizedBox(height: 2),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
