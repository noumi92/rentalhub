import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                materialTapTargetSize: MaterialTapTargetSize.padded,
                label:  Text(l10n.inCityHyphen),
                selected: !isOutOfCity,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOutOfCity
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.white),
                onSelected: (_) => onChanged(false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                materialTapTargetSize: MaterialTapTargetSize.padded,
                label:  Text(l10n.outOfCityHyphen),
                selected: isOutOfCity,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOutOfCity
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface),
                onSelected: (_) => onChanged(true),
              ),
            ),
          ],
        ),
        if (isOutOfCity) ...[
          const SizedBox(height: 10),
          Text(
            l10n.tripTrackerNote,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.secondary),
          ),
          if (fixedRoutes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(l10n.tripFixedRoutes,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fixedRoutes.map((r) {
                final selected = selectedRoute?.routeId == r.routeId;
                return ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text('${r.destinationCity} • Rs. ${r.fixedPricePkr}'),
                  selected: selected,
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface),
                  onSelected: (_) => onRouteSelected(selected ? null : r),
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }
}
