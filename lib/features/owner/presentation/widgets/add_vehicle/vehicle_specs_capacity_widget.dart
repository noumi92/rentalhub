import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../constants/owner_vehicle_constants.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Seating capacity, AC switch and extra-features chips of the
/// add-vehicle specs step. Extracted from [VehicleSpecsStepWidget]
/// (audit §5: that file was 513 lines — extract, do not grow it).
class VehicleCapacityStepWidget extends StatelessWidget {
  final int seats;
  final ValueChanged<int> onSeatsChanged;
  final bool hasAc;
  final ValueChanged<bool> onAcChanged;
  final Set<String> selectedFeatures;
  final ValueChanged<String> onFeatureToggled;

  const VehicleCapacityStepWidget({
    super.key,
    required this.seats,
    required this.onSeatsChanged,
    required this.hasAc,
    required this.onAcChanged,
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
        ?.copyWith(fontWeight: FontWeight.w800)),
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
                fontWeight: FontWeight.w700,
              ),
          onSelected: (_) => onSeatsChanged(s),
        ),
      );
    }).toList(),
  ),
),
const SizedBox(height: 16),

// Requirement 3: Air Conditioning (AC) Switch
Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: AppCardDecoration.shadow(context)
  ),
  child: Row(
    children: [
      const Icon(Icons.ac_unit_rounded, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addVehicleAcTitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(l10n.addVehicleAcSubtitle,
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Switch(
        value: hasAc,
        activeThumbColor: AppColors.secondary,
        onChanged: onAcChanged,
      ),
    ],
  ),
),
const SizedBox(height: 16),

// Requirement 3: Extra Features (Shown in Car Details page)
Text(l10n.addVehicleExtraFeatures,
    style: Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(fontWeight: FontWeight.w800)),
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
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
      onSelected: (_) => onFeatureToggled(f),
    );
  }).toList(),
),

      ],
    );
  }
}
