import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class FuelOdometerInputWidget extends StatelessWidget {
  final TextEditingController odometerController;
  final String selectedFuel;
  final ValueChanged<String> onFuelSelected;
  final String title;

  const FuelOdometerInputWidget({
    super.key,
    required this.odometerController,
    required this.selectedFuel,
    required this.onFuelSelected,
    this.title = 'Vehicle Telemetry Inspection',
  });

  @override
  Widget build(BuildContext context) {
    const fuelLevels = ['1/4 (25%)', '2/4 (50%)', '3/4 (75%)', '4/4 (Full)'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.midnightNavy,
            ),
          ),
          const SizedBox(height: 12),
          const Text('Odometer Reading (KM):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.midnightNavy)),
          const SizedBox(height: 6),
          TextField(
            controller: odometerController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
            decoration: InputDecoration(
              hintText: 'e.g. 45200',
              suffixText: 'KM',
              suffixStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sunsetOrange),
              prefixIcon: const Icon(Icons.speed_rounded, color: AppColors.midnightNavy),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Fuel Level Gauge:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.midnightNavy)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fuelLevels.map((lvl) {
              final isSelected = selectedFuel == lvl;
              return ChoiceChip(
                label: Text(lvl),
                selected: isSelected,
                selectedColor: AppColors.sunsetOrange,
                backgroundColor: AppColors.backgroundLight,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.midnightNavy,
                ),
                onSelected: (_) => onFuelSelected(lvl),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

