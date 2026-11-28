import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import 'vehicle_specs_capacity_widget.dart';

class VehicleSpecsStepWidget extends StatelessWidget {
  final String selectedMake;
  final ValueChanged<String> onMakeChanged;
  final List<String> makes;

  final String selectedModel;
  final ValueChanged<String> onModelChanged;

  final int selectedYear;
  final ValueChanged<int> onYearChanged;

  final String color;
  final ValueChanged<String> onColorChanged;

  final String category;
  final ValueChanged<String> onCategoryChanged;
  final List<String> categories;

  final TextEditingController plateController;
  final VoidCallback onPlateChanged;

  final bool isAutomatic;
  final ValueChanged<bool> onTransmissionChanged;

  final String fuelType;
  final ValueChanged<String> onFuelTypeChanged;

  // Requirement 3: Vehicle capacity, AC & Extra features
  final int seats;
  final ValueChanged<int> onSeatsChanged;

  final Set<String> selectedFeatures;
  final ValueChanged<String> onFeatureToggled;

  const VehicleSpecsStepWidget({
    super.key,
    required this.selectedMake,
    required this.onMakeChanged,
    required this.makes,
    required this.selectedModel,
    required this.onModelChanged,
    required this.selectedYear,
    required this.onYearChanged,
    required this.color,
    required this.onColorChanged,
    required this.category,
    required this.onCategoryChanged,
    required this.categories,
    required this.plateController,
    required this.onPlateChanged,
    required this.isAutomatic,
    required this.onTransmissionChanged,
    required this.fuelType,
    required this.onFuelTypeChanged,
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
        // Brand / Make Dropdown
        Text(l10n.addVehicleMakeBrand,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              value: selectedMake,
              isExpanded: true,
              items: makes
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m,
                          style: const TextStyle(fontWeight: FontWeight.w600))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onMakeChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Model Variant
        Text(l10n.addVehicleModelVariant,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: selectedModel,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: l10n.addVehicleModelHint,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: onModelChanged,
        ),
        const SizedBox(height: 14),

        // Year & Color Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.addVehicleManufacturingYear,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Theme.of(context).dividerColor)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        value: selectedYear,
                        isExpanded: true,
                        items: List.generate(15, (i) => 2025 - i)
                            .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text('$y',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onYearChanged(v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.addVehicleExteriorColor,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: color,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    onChanged: onColorChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Body Category Pills
        Text(l10n.addVehicleBodyCategory,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((c) {
            final isSelected = category == c;
            return ChoiceChip(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              label: Text(c),
              selected: isSelected,
              selectedColor: AppColors.secondary,
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500),
              onSelected: (_) => onCategoryChanged(c),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Registration Number & Plate Preview
        Text(l10n.addVehicleRegistrationNumber,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: plateController,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: 'e.g. LEA-23-4567',
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => onPlateChanged(),
              ),
            ),
            const SizedBox(width: 12),
            // Audit §5: no sample plate as a preview — an empty plate
            // shows a dash until one is entered.
            PakistaniPlateWidget(
              plateNumber: plateController.text.trim().isEmpty
                  ? '—'
                  : plateController.text.trim(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Transmission & Fuel Type
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.addVehicleTransmission,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Theme.of(context).dividerColor)),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => onTransmissionChanged(true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                  color: isAutomatic
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(l10n.addVehicleAutomatic,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: isAutomatic
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => onTransmissionChanged(false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                  color: !isAutomatic
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(l10n.addVehicleManual,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: !isAutomatic
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.addVehicleFuelType,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Theme.of(context).dividerColor)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        value: fuelType,
                        isExpanded: true,
                        items: ['Petrol', 'Diesel', 'Hybrid', 'Electric']
                            .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onFuelTypeChanged(v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        VehicleCapacityStepWidget(
          seats: seats,
          onSeatsChanged: onSeatsChanged,
          selectedFeatures: selectedFeatures,
          onFeatureToggled: onFeatureToggled,
        ),
      ],
    );
  }
}
