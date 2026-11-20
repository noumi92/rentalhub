import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// The selected-state dot for the walk-in radio lists (cars,
/// customers). The `Radio` widget's `groupValue`/`onChanged` are
/// deprecated in favour of `RadioGroup`, but these lists need
/// per-row tap handling (maintenance / blacklist refusal) in one
/// place, so a plain dot is used instead.
class ManualBookingRadioDot extends StatelessWidget {
  const ManualBookingRadioDot({
    super.key,
    required this.selected,
    required this.enabled,
  });

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = !enabled
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
        : selected
            ? AppColors.orangeFill
            : colorScheme.onSurfaceVariant;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            )
          : null,
    );
  }
}
