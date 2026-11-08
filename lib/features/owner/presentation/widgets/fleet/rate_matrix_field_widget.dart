import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class RateMatrixFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String kmCap;

  const RateMatrixFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.kmCap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kmCap,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                // #15: orange rate text — lighter secondaryDark in dark.
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.secondaryDark
                    : AppColors.secondary,
              ),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                prefixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

