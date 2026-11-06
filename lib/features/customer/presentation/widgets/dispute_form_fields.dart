import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'dispute_category_chips.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Dispute Category',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.midnightNavy)),
        const SizedBox(height: 8),
        DisputeCategoryChips(
          categories: categories,
          selected: selectedCategory,
          onSelected: onCategorySelected,
        ),
        const SizedBox(height: 16),
        const Text('Booking ID / Reference',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.midnightNavy)),
        const SizedBox(height: 6),
        TextField(
          controller: bookingIdController,
          decoration: InputDecoration(
            hintText: 'E.g. RH-849201',
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Detailed Explanation',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.midnightNavy)),
        const SizedBox(height: 6),
        TextField(
          controller: descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Describe what happened with dates, amounts, and showroom staff names...',
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lavenderMist,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.shield_rounded,
                  size: 18, color: AppColors.royalNavy),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your dispute is recorded and shared with the showroom for review. There is no fixed resolution time yet.',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.midnightNavy),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
