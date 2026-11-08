import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class CitySelectorBar extends StatelessWidget {
  final List<Map<String, dynamic>> majorCities;
  final String selectedCity;
  final ValueChanged<Map<String, dynamic>> onSelectCity;

  const CitySelectorBar({
    super.key,
    required this.majorCities,
    required this.selectedCity,
    required this.onSelectCity,
  });

  @override
  Widget build(BuildContext context) {
    // E3: 48dp chip + 6dp vertical padding each side — the old
    // 48dp bar squeezed the city chips to 36dp.
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: majorCities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = majorCities[index];
          final isSelected = selectedCity == city['name'];
          return ChoiceChip(
            materialTapTargetSize: MaterialTapTargetSize.padded,
            label: Text(city['name'] as String),
            selected: isSelected,
            selectedColor: AppColors.secondary,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: isSelected
                  ? AppColors.secondary
                  : Theme.of(context).dividerColor,
            ),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface),
            onSelected: (_) => onSelectCity(city),
          );
        },
      ),
    );
  }
}
