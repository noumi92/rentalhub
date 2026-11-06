import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// G4: the dispute category chips. Extracted from [CustomerDisputeView]
/// so the view stays under the 250-line cap.
class DisputeCategoryChips extends StatelessWidget {
  const DisputeCategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: categories.map((cat) {
        final isSelected = cat == selected;
        return ChoiceChip(
          label: Text(cat),
          selected: isSelected,
          onSelected: (_) => onSelected(cat),
          selectedColor: AppColors.midnightNavy,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.midnightNavy,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
          side: BorderSide(
              color: isSelected ? AppColors.midnightNavy : AppColors.border),
        );
      }).toList(),
    );
  }
}
