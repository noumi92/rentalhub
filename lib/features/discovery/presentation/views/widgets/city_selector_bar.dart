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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: majorCities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = majorCities[index];
          final isSelected = selectedCity == city['name'];
          return ChoiceChip(
            label: Text(city['name'] as String),
            selected: isSelected,
            selectedColor: AppColors.sunsetOrange,
            backgroundColor: AppColors.backgroundLight,
            side: BorderSide(
              color: isSelected ? AppColors.sunsetOrange : AppColors.border,
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.midnightNavy,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
            onSelected: (_) => onSelectCity(city),
          );
        },
      ),
    );
  }
}

