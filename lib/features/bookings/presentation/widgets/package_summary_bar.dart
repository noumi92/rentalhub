import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/money_format.dart';

/// The bottom summary bar of the booking picker: total, advance due,
/// security deposit and the Continue button. Extracted from
/// [RentPackagePickerView] so the view stays under the 250-line cap.
class PackageSummaryBar extends StatelessWidget {
  const PackageSummaryBar({
    super.key,
    required this.total,
    required this.advance,
    required this.deposit,
    required this.onContinue,
  });

  final int total;
  final int advance;
  final int? deposit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.packageTotal(formatRs(total)),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                Text(l10n.packageAdvanceDue(formatRs(advance)),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.orangeTextFor(Theme.of(context).brightness))),
                if (deposit != null)
                  Text(l10n.packageSecurityDeposit(formatRs(deposit ?? 0)),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: DebouncedButton(
              text: l10n.packageContinue,
              icon: Icons.arrow_forward_rounded,
              onPressed: () async => onContinue(),
            ),
          ),
        ],
      ),
    );
  }
}
