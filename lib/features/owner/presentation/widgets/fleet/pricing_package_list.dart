import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

import '../../../../fleet/domain/entities/vehicle_entity.dart';
import 'rate_matrix_field_widget.dart';

/// One editable row per rentable package: an on/off switch plus the
/// price field. Disabled packages are hidden from the booking picker
/// but keep their last price, so re-enabling them restores it.
/// Extracted from [OwnerRateMatrixView] so the view stays under the
/// 250-line cap.
class PricingPackageList extends StatelessWidget {
  const PricingPackageList({
    super.key,
    required this.packages,
    required this.onToggle,
    required this.priceController,
  });

  final List<VehiclePackageEntity> packages;
  final void Function(String label, bool enabled) onToggle;
  final TextEditingController Function(String label) priceController;

  // Package codes ('1h', 'Weekly', …) are stored data and stay as-is;
  // only the displayed titles are localized.
  static String _title(AppLocalizations l10n, String label) => {
        '1h': l10n.pricingPackage1h,
        '3h': l10n.pricingPackage3h,
        '6h': l10n.pricingPackage6h,
        '12h': l10n.pricingPackage12h,
        '24h': l10n.pricingPackage24h,
        'Weekly': l10n.pricingPackageWeekly,
      }[label] ?? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (int i = 0; i < packages.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: RateMatrixFieldWidget(
                  controller: priceController(packages[i].label),
                  label: _title(l10n, packages[i].label),
                  hint: 'Rs. ${packages[i].pricePkr}',
                  kmCap: l10n.pricingKmIncluded(packages[i].kmIncluded),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: packages[i].enabled,
                activeThumbColor: Colors.green,
                onChanged: (val) => onToggle(packages[i].label, val),
              ),
            ],
          ),
          if (i < packages.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
