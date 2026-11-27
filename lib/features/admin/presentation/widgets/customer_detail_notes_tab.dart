import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import 'admin_detail_section.dart';
import 'customer_detail_actions.dart';

/// Phase 2 (2.5) — the customer detail's Notes & flags tab: the
/// admin notes and the note composer. The Watchlist / Blacklist
/// actions live in the sticky action bar now (Phase 4 4.4a), so
/// they are reachable from every tab.
class CustomerDetailNotesTab extends StatelessWidget {
  const CustomerDetailNotesTab({
    super.key,
    required this.detail,
    required this.noteController,
    required this.isWorking,
    required this.onAddNote,
    this.padding = const EdgeInsets.all(16),
  });

  final CustomerDetail detail;
  final EdgeInsetsGeometry padding;
  final TextEditingController noteController;
  final bool isWorking;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminDetailSection(
              title: l10n.admin2_customerDetailAdminNotes,
              lines: detail.notes.isEmpty
                  ? [l10n.admin2_customerDetailNoNotes]
                  : detail.notes.map((n) => n.text).toList()),
          // Phase 3 (3.6a): the customer detail links to its
          // tribunal entry (the tribunal links back to the customer
          // record), so a blacklisted customer and their case are
          // one tap apart in both directions.
          if (detail.blacklistRecord != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => context.go(RouteNames.adminBlacklist),
                icon: const Icon(Icons.gavel_rounded, size: 18),
                label: Text(l10n.admin2_customerDetailViewTribunal),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48)),
              ),
            ),
            const SizedBox(height: 12),
          ],
          CustomerDetailActions(
            noteController: noteController,
            isWorking: isWorking,
            onAddNote: onAddNote,
          ),
        ],
      ),
    );
  }
}
