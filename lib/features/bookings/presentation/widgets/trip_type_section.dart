import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
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
    this.outCityMode,
    this.outCityPerKmPkr,
    this.outCityDailyPkr,
  });

  final bool isOutOfCity;
  final ValueChanged<bool> onChanged;
  final List<FixedRouteEntity> fixedRoutes;
  final FixedRouteEntity? selectedRoute;
  final ValueChanged<FixedRouteEntity?> onRouteSelected;

  /// CU-m17: the active out-of-city price basis, from the vehicle
  /// fields the picker already has — the section must state it
  /// instead of leaving the customer to discover it in the summary
  /// bar. `outCityDailyPkr` is the resolved daily rate
  /// (`rates.outOfCityDaily ?? rates.daily24`).
  final String? outCityMode;
  final int? outCityPerKmPkr;
  final int? outCityDailyPkr;

  /// CU-m17: the out-of-city price basis line for the current mode,
  /// or null when no vehicle field states one.
  String? _outCityPricingLine(AppLocalizations l10n) {
    if (outCityMode == 'perKm' &&
        outCityPerKmPkr != null &&
        outCityPerKmPkr! > 0) {
      return l10n.tripOutCityPerKmLine(
          l10n.amountRs(formatRs(outCityPerKmPkr!)));
    }
    if (outCityMode == 'fixedRoute') {
      return l10n.tripOutCityFixedRouteLine;
    }
    if (outCityDailyPkr != null && outCityDailyPkr! > 0) {
      return l10n.tripOutCityPerDayLine(
          l10n.amountRs(formatRs(outCityDailyPkr!)));
    }
    return null;
  }

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
                    fontWeight: FontWeight.w500,
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
                    fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w500, color: AppColors.orangeTextFor(Theme.of(context).brightness)),
          ),
          // CU-m17: the active out-of-city price basis, in the
          // section itself — never invent a rate: each branch only
          // renders when its vehicle field is present.
          if (_outCityPricingLine(l10n) != null) ...[
            const SizedBox(height: 6),
            Text(
              _outCityPricingLine(l10n)!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ,
            ),
          ],
          if (fixedRoutes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(l10n.tripFixedRoutes,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fixedRoutes.map((r) {
                final selected = selectedRoute?.routeId == r.routeId;
                return ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text(l10n.fixedRouteChip(
                      r.destinationCity, formatRs(r.fixedPricePkr))),
                  selected: selected,
                  // CU-M1: white on #F95700 fails AA — the selected
                  // chip uses the darker orangeFill (5.18:1).
                  selectedColor: AppColors.orangeFill,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
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
