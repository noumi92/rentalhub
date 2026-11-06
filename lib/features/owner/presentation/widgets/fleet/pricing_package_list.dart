import 'package:flutter/material.dart';

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

  static const Map<String, String> _titles = {
    '1h': '1-Hour City Commute',
    '3h': '3-Hour Airport / Quick Trip',
    '6h': '6-Hour Express Rate',
    '12h': '12-Hour Half Day',
    '24h': 'In-City Daily (24h)',
    'Weekly': 'Weekly Package (7 Days)',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < packages.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: RateMatrixFieldWidget(
                  controller: priceController(packages[i].label),
                  label: _titles[packages[i].label] ?? packages[i].label,
                  hint: 'Rs. ${packages[i].pricePkr}',
                  kmCap: '${packages[i].kmIncluded} km included',
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
