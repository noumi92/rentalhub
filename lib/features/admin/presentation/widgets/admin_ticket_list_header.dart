import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'admin_sort_menu.dart';

/// Phase 4 (4.3) — the tickets inbox header, extracted from
/// [AdminTicketsView] so the view stays under the 250-line cap
/// with its sort control: the server search field (400 ms debounce
/// in the view), the status chips, and the sort menu.
class AdminTicketListHeader extends StatelessWidget {
  const AdminTicketListHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.filter,
    required this.onFilter,
    required this.sort,
    required this.onSort,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String filter;
  final ValueChanged<String> onFilter;

  /// Phase 4 (4.3) — the sort control for the list. Date orders
  /// by `createdAt`, status by `status` — both server-side.
  final String sort;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: l10n?.adminAuditSearchTicketsHint ??
                'Search by message or customer ID…',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            children: [
              for (final entry in {
                'all': l10n?.filterAll ?? 'All',
                'open': l10n?.admin2_open ?? 'Open',
                'in_progress': l10n?.admin2_inProgress ?? 'In progress',
                'escalated': l10n?.admin2_escalated ?? 'Escalated',
                'closed': l10n?.admin2_closed ?? 'Closed',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: filter == entry.key,
                  onSelected: (_) {
                    onFilter(entry.key);
                  },
                ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AdminSortMenu(
                options: [
                  AdminSortOption(
                      id: AdminListSort.dateNewest,
                      label: l10n?.adminSortDateNewest ?? 'Newest first'),
                  AdminSortOption(
                      id: AdminListSort.dateOldest,
                      label: l10n?.adminSortDateOldest ?? 'Oldest first'),
                  AdminSortOption(
                      id: AdminListSort.statusAsc,
                      label: l10n?.adminSortStatus ?? 'Status'),
                ],
                selectedId: sort,
                onSelected: onSort),
          ],
        ),
      ],
    );
  }
}
