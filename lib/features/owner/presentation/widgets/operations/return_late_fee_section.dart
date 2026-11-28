import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// Editable late-fee card on the Return Settlement screen.
/// Shows whether the car came back on time or overdue, displays the
/// auto-calculated figure when the vehicle has an hourly rate, and
/// lets the owner enter, adjust, or waive the late fee in PKR.
class ReturnLateFeeSection extends StatelessWidget {
  final int overtimeHours;
  final int extraHourPkr;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ReturnLateFeeSection({
    super.key,
    required this.overtimeHours,
    required this.extraHourPkr,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isLate = overtimeHours > 0;
    final badgeBg = isLate
        ? AppColors.orangeContainerFor(brightness)
        : AppColors.successContainerFor(brightness);
    final badgeFg = isLate
        ? AppColors.orangeTextFor(brightness)
        : AppColors.successTextFor(brightness);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.returnLateFeeTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLate
                        ? l10n.returnLateFeeOverdueHours(overtimeHours)
                        : l10n.returnLateFeeOnTime,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: badgeFg,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (isLate && extraHourPkr > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${overtimeHours}h × ${l10n.amountRs(formatRs(extraHourPkr))} = ${l10n.amountRs(formatRs(overtimeHours * extraHourPkr))}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('return_late_fee_field'),
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: l10n.returnLateFeeLabel,
                hintText: l10n.returnLateFeeHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
