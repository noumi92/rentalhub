import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';
import '../../constants/owner_vehicle_constants.dart';

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

  final bool hasAc;
  final ValueChanged<bool> onAcChanged;

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
    required this.hasAc,
    required this.onAcChanged,
    required this.selectedFeatures,
    required this.onFeatureToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand / Make Dropdown
        const Text('Make / Brand', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedMake,
              isExpanded: true,
              items: makes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
              onChanged: (v) {
                if (v != null) onMakeChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Model Variant
        const Text('Model Variant', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: TextFormField(
            initialValue: selectedModel,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            decoration: const InputDecoration(border: InputBorder.none, hintText: 'e.g. Corolla Altis 1.8 Grande'),
            onChanged: onModelChanged,
          ),
        ),
        const SizedBox(height: 14),

        // Year & Color Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manufacturing Year', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedYear,
                        isExpanded: true,
                        items: List.generate(15, (i) => 2025 - i).map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
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
                  const Text('Exterior Color', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: TextFormField(
                      initialValue: color,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                      onChanged: onColorChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Body Category Pills
        const Text('Body Category', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((c) {
            final isSelected = category == c;
            return ChoiceChip(
              label: Text(c),
              selected: isSelected,
              selectedColor: AppColors.sunsetOrange,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.midnightNavy, fontWeight: FontWeight.w700, fontSize: 12),
              onSelected: (_) => onCategoryChanged(c),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Registration Number & Plate Preview
        const Text('Vehicle Registration Number', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: plateController,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: 'e.g. LEA-23-4567',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => onPlateChanged(),
              ),
            ),
            const SizedBox(width: 12),
            PakistaniPlateWidget(
              plateNumber: plateController.text.trim().isEmpty ? 'LEA-23-4567' : plateController.text.trim(),
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
                  const Text('Transmission', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => onTransmissionChanged(true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: isAutomatic ? AppColors.midnightNavy : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                              child: Text('Automatic', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isAutomatic ? Colors.white : AppColors.textMuted)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => onTransmissionChanged(false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: !isAutomatic ? AppColors.midnightNavy : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                              child: Text('Manual', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: !isAutomatic ? Colors.white : AppColors.textMuted)),
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
                  const Text('Fuel Type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: fuelType,
                        isExpanded: true,
                        items: ['Petrol', 'Diesel', 'Hybrid', 'Electric'].map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
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

        // Requirement 3: Vehicle Seating Capacity
        const Text('Vehicle Seating Capacity', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: OwnerVehicleConstants.seatingCapacities.map((s) {
              final isSelected = seats == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$s Seats'),
                  selected: isSelected,
                  selectedColor: AppColors.sunsetOrange,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.midnightNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.ac_unit_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Air Conditioning (Full AC)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                    Text('Vehicle equipped with working chilled AC', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: hasAc,
                activeColor: AppColors.sunsetOrange,
                onChanged: onAcChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Requirement 3: Extra Features (Shown in Car Details page)
        const Text('Extra Features (Shown on Car Detail)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const SizedBox(height: 4),
        const Text('Select amenities included with this vehicle to attract more renters.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OwnerVehicleConstants.extraFeatures.map((f) {
            final isSelected = selectedFeatures.contains(f);
            return FilterChip(
              label: Text(f),
              selected: isSelected,
              selectedColor: AppColors.sunsetOrange,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.midnightNavy,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11.5,
              ),
              onSelected: (_) => onFeatureToggled(f),
            );
          }).toList(),
        ),
      ],
    );
  }
}
