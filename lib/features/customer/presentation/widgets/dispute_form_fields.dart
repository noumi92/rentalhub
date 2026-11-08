import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'dispute_category_chips.dart';
import '../../../../l10n/app_localizations.dart';

/// The dispute form fields, extracted from CustomerDisputeView so the
/// view stays under the 250-line cap: category chips, the booking
/// reference field, the description field, and the honest note about
/// review (no fixed resolution time).
class DisputeFormFields extends StatelessWidget {
  const DisputeFormFields({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.bookingIdController,
    required this.descriptionController,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final TextEditingController bookingIdController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.disputeSelectCategory,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DisputeCategoryChips(
          categories: categories,
          selected: selectedCategory,
          onSelected: onCategorySelected,
        ),
        const SizedBox(height: 16),
        Text(l10n.disputeBookingId,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: bookingIdController,
          decoration: InputDecoration(
            hintText: l10n.disputeBookingIdHint,
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.disputeDetailsLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                l10n.disputeDetailsHint,
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_rounded,
                  size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.disputeRecordedNote,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
