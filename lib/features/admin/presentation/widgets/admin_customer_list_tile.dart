import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import 'admin_list_card.dart';
import 'admin_status_chip.dart';

/// One customer row in the admin list: name, phone, CNIC state,
/// source, and the blacklist / watchlist flags. Extracted from the
/// view so the view stays under the 250-line cap.
///
/// Phase 4 (4.1) — the row is the shared [AdminListCard] shell.
/// Phase 4 (4.4b) — live-score-only trust display: the stored
/// `trust_score` used to show here as a "hint" and disagreed with
/// the live score on the detail screen (live 3.5 vs stored 5.0).
/// The stored value is no longer shown anywhere in the UI; the
/// live score with its breakdown lives on the customer detail
/// screen. The row still carries `storedTrustScore` in the data
/// layer (other callers construct it) but this tile ignores it.
class AdminCustomerListTile extends StatelessWidget {
  const AdminCustomerListTile({super.key, required this.row});

  final AdminCustomerRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = row.customer;
    final flags = [
      if (row.isBlacklisted)
        l10n?.adminAuditBlacklisted ?? 'Blacklisted',
      if (row.watchlisted)
        l10n?.adminAuditWatchlisted ?? 'Watchlisted',
    ];
    return AdminListCard(
      icon: Icons.person_rounded,
      title: c.name,
      subtitle:
          '${c.phone} • CNIC ${c.cnic ?? l10n?.admin2_notOnFile ?? 'not on file'} • ${humanizeStatus(c.source, l10n)}'
          '${flags.isEmpty ? '' : ' • ${flags.join(' • ')}'}',
      trailing: adminListChevron,
      onTap: () => context.go(
        RouteNames.adminCustomerDetail
            .replaceFirst(':customerId', c.customerId),
      ),
    );
  }
}
