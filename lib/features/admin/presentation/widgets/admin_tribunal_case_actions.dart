import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_people_data_source.dart';

/// Phase 3 (3.6a) — the actions on one tribunal case, extracted from
/// [AdminBlacklistTribunalView] so the view stays under the 250-line
/// cap: "View customer" (the tribunal-to-customer link) and the
/// appeal decision ("Decide appeal" only when an appeal actually
/// exists, otherwise "Review flag"). On a phone the two stack
/// full-width; on desktop they sit at the end of the row.
class AdminTribunalCaseActions extends StatelessWidget {
  const AdminTribunalCaseActions({
    super.key,
    required this.record,
    required this.compact,
    required this.onViewCustomer,
    required this.onDecideAppeal,
  });

  final AdminBlacklistRecord record;
  final bool compact;
  final VoidCallback onViewCustomer;
  final VoidCallback onDecideAppeal;

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final viewCustomer = OutlinedButton(
      onPressed: onViewCustomer,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(l10n.admin2_tribunalViewCustomer,
          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
    );
    final decideAppeal = OutlinedButton(
      onPressed: onDecideAppeal,
      style: OutlinedButton.styleFrom(
          foregroundColor:
              AppColors.successTextFor(Theme.of(context).brightness),
          minimumSize: const Size(0, 48)),
      child: Text(
          record.appealStatus == 'pending'
              ? l10n.admin2_tribunalDecideAppeal
              : l10n.admin2_tribunalReviewFlag,
          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          viewCustomer,
          const SizedBox(height: 8),
          decideAppeal,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        viewCustomer,
        const SizedBox(width: 8),
        decideAppeal,
      ],
    );
  }
}
