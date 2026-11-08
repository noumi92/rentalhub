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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text('Odometer Reading (KM):', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: odometerController,
            keyboardType: TextInputType.number,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: 'e.g. 45200',
              suffixText: 'KM',
              suffixStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.secondary),
              prefixIcon: const Icon(Icons.speed_rounded),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text('Fuel Level Gauge:', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fuelLevels.map((lvl) {
              final isSelected = selectedFuel == lvl;
              return ChoiceChip(
                label: Text(lvl),
                selected: isSelected,
                selectedColor: AppColors.secondary,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
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

