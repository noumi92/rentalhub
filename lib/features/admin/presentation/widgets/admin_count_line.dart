import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';

/// Phase 3 (3.4) — the shared "Showing first N of M" line for the
/// admin lists that truncate: when the total is known and larger
/// than what is shown, the cap is stated instead of silent.
class AdminCountLine extends StatelessWidget {
  const AdminCountLine({super.key, required this.shown, this.total});

  final int shown;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final total = this.total;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          total != null && total > shown
              ? l10n.adminAuditShowingFirstOf(shown, total)
              : l10n.adminAuditShowing(shown),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
