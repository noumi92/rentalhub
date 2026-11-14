import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../constants/owner_vehicle_constants.dart';

/// Seating capacity and extra-features chips of the add-vehicle
/// specs step. Extracted from [VehicleSpecsStepWidget]
/// (audit §5: that file was 513 lines — extract, do not grow it).
/// OW-M4 (2026-11-13 audit): the AC switch is gone — no AC flag
/// exists on [VehicleEntity]/[VehicleModel], so the toggle was a dead
/// control (always on, never persisted) in both the add and edit
/// flows. It returns only with a real `hasAc` field.
class VehicleCapacityStepWidget extends StatelessWidget {
  final int seats;
  final ValueChanged<int> onSeatsChanged;
  final Set<String> selectedFeatures;
  final ValueChanged<String> onFeatureToggled;

  const VehicleCapacityStepWidget({
    super.key,
    required this.seats,
    required this.onSeatsChanged,
    required this.selectedFeatures,
    required this.onFeatureToggled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
// Requirement 3: Vehicle Seating Capacity
Text(l10n.addVehicleSeatingCapacity,
    style: Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(fontWeight: FontWeight.w500)),
const SizedBox(height: 6),
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: OwnerVehicleConstants.seatingCapacities.map((s) {
      final isSelected = seats == s;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          label: Text(l10n.addVehicleSeatsCount(s)),
          selected: isSelected,
          selectedColor: AppColors.secondary,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
          onSelected: (_) => onSeatsChanged(s),
        ),
      );
    }).toList(),
  ),
),
const SizedBox(height: 16),

// Requirement 3: Extra Features (Shown in Car Details page)
Text(l10n.addVehicleExtraFeatures,
    style: Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(fontWeight: FontWeight.w500)),
const SizedBox(height: 4),
Text(
    l10n.addVehicleExtraFeaturesHint,
    style: Theme.of(context).textTheme.labelSmall),
const SizedBox(height: 8),
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: OwnerVehicleConstants.extraFeatures.map((f) {
    final isSelected = selectedFeatures.contains(f);
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(f),
      selected: isSelected,
      selectedColor: AppColors.secondary,
      checkmarkColor: Colors.white,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
      onSelected: (_) => onFeatureToggled(f),
    );
  }).toList(),
),

      ],
    );
  }
}
