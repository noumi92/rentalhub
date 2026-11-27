import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'admin_count_line.dart';

/// Phase 3 (3.4) — the line under the bookings header: while
/// searching it says how many matches there are (capped at 50),
/// otherwise the shared "Showing first N of M" line.
///
/// Extracted from the bookings view so the view stays under the
/// 250-line cap (Step 2 scoped lists); behaviour is unchanged.
class AdminBookingCountNote extends StatelessWidget {
  const AdminBookingCountNote({
    super.key,
    required this.count,
    required this.total,
    required this.isSearching,
  });

  final int count;
  final int? total;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isSearching) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            count >= 50
                ? l10n.adminAuditFirstMatches(50)
                : l10n.adminAuditMatching(count),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return AdminCountLine(shown: count, total: total);
  }
}
