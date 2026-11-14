import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// The stored category stays English (it is written to the dispute
/// record, which the owner's inbox reads); only the chip label is
/// localized.
String disputeCategoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'Deposit Withheld':
      return l10n.disputeDepositWithheld;
    case 'Unfair Damage Penalty':
      return l10n.disputeDamagePenalty;
    case 'Showroom Overcharge':
      return l10n.disputeOvercharge;
    case 'Vehicle Breakdown Delay':
      return l10n.disputeBreakdown;
    case 'Rude / Unprofessional Staff':
      return l10n.disputeRudeStaff;
    default:
      return category;
  }
}

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
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: categories.map((cat) {
        final isSelected = cat == selected;
        return ChoiceChip(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          label: Text(disputeCategoryLabel(l10n, cat)),
          selected: isSelected,
          onSelected: (_) => onSelected(cat),
          selectedColor: AppColors.primary,
          labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface),
          side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).dividerColor),
        );
      }).toList(),
    );
  }
}
