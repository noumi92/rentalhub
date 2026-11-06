import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';

/// Phase B (B3): the In-City / Out-of-City toggle of the booking
/// picker, with the tracker-clearance note and the shop's fixed
/// routes as one-tap destinations. Extracted from
/// [RentPackagePickerView] so the view stays under the 250-line cap.
class TripTypeSection extends StatelessWidget {
  const TripTypeSection({
    super.key,
    required this.isOutOfCity,
    required this.onChanged,
    required this.fixedRoutes,
    required this.selectedRoute,
    required this.onRouteSelected,
  });

  final bool isOutOfCity;
  final ValueChanged<bool> onChanged;
  final List<FixedRouteEntity> fixedRoutes;
  final FixedRouteEntity? selectedRoute;
  final ValueChanged<FixedRouteEntity?> onRouteSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('In-City'),
                selected: !isOutOfCity,
                selectedColor: AppColors.royalNavy,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOutOfCity
                        ? AppColors.midnightNavy
                        : Colors.white),
                onSelected: (_) => onChanged(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('Out-of-City'),
                selected: isOutOfCity,
                selectedColor: AppColors.royalNavy,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOutOfCity
                        ? Colors.white
                        : AppColors.midnightNavy),
                onSelected: (_) => onChanged(true),
              ),
            ),
          ],
        ),
        if (isOutOfCity) ...[
          const SizedBox(height: 10),
          const Text(
            'Tracker clearance required — the shop confirms it before pickup.',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sunsetOrange),
          ),
          if (fixedRoutes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Fixed routes from this shop',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnightNavy)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fixedRoutes.map((r) {
                final selected = selectedRoute?.routeId == r.routeId;
                return ChoiceChip(
                  label:
                      Text('${r.destinationCity} • Rs. ${r.fixedPricePkr}'),
                  selected: selected,
                  selectedColor: AppColors.sunsetOrange,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : AppColors.midnightNavy),
                  onSelected: (_) =>
                      onRouteSelected(selected ? null : r),
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }
}
