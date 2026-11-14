import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import 'admin_status_chip.dart';

/// One customer row in the admin list: name, phone, CNIC state,
/// source, the stored trust score (a list hint only — the live
/// score on the detail screen governs), and the blacklist /
/// watchlist flags. Extracted from the view so the view stays
/// under the 250-line cap.
class AdminCustomerListTile extends StatelessWidget {
  const AdminCustomerListTile({super.key, required this.row});

  final AdminCustomerRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = row.customer;
    final trust = row.storedTrustScore;
    final flags = [
      if (row.isBlacklisted)
        l10n?.adminAuditBlacklisted ?? 'Blacklisted',
      if (row.watchlisted)
        l10n?.adminAuditWatchlisted ?? 'Watchlisted',
    ];
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: const Icon(
            Icons.person_rounded,
          ),
        ),
        title: Text(c.name,
            style: const TextStyle(
                fontSize: 14,
                )),
        subtitle: Text(
          '${c.phone} • CNIC ${c.cnic ?? l10n?.admin2_notOnFile ?? 'not on file'} • ${humanizeStatus(c.source, l10n)}'
          '${trust == null ? '' : ' • ${(l10n?.adminAuditTrustStored(trust.toStringAsFixed(1)) ?? 'Stored trust ${trust.toStringAsFixed(1)}')}'}'
          '${flags.isEmpty ? '' : ' • ${flags.join(' • ')}'}',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => context.go(
          RouteNames.adminCustomerDetail
              .replaceFirst(':customerId', c.customerId),
        ),
      ),
    );
  }
}
