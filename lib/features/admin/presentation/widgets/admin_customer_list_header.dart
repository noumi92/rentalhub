import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'admin_sort_menu.dart';

/// Phase 4 (4.3) — the customers list header, extracted from
/// [AdminCustomersView] so the view stays under the 250-line cap
/// with its sort control: the server search field (400 ms debounce
/// in the view), the CNIC filter chips, and the sort menu.
class AdminCustomerListHeader extends StatelessWidget {
  const AdminCustomerListHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.cnicFilter,
    required this.onCnicFilter,
    required this.sort,
    required this.onSort,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String cnicFilter;
  final ValueChanged<String> onCnicFilter;

  /// Phase 4 (4.3) — the sort control for the list. Name orders
  /// by `name`, date by `createdAt` — both server-side.
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
            hintText: l10n?.admin2_customersSearchHint ??
                'Search by name, phone, or CNIC…',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
                'all': l10n?.adminAuditCnicAll ?? 'All',
                'onFile': l10n?.adminAuditCnicOnFile ?? 'CNIC on file',
                'missing':
                    l10n?.adminAuditCnicMissing ?? 'CNIC missing',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: cnicFilter == entry.key,
                  onSelected: (_) => onCnicFilter(entry.key),
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
                      id: AdminListSort.nameAsc,
                      label: l10n?.adminSortNameAsc ?? 'Name A–Z'),
                  AdminSortOption(
                      id: AdminListSort.nameDesc,
                      label: l10n?.adminSortNameDesc ?? 'Name Z–A'),
                  AdminSortOption(
                      id: AdminListSort.dateNewest,
                      label: l10n?.adminSortDateNewest ?? 'Newest first'),
                  AdminSortOption(
                      id: AdminListSort.dateOldest,
                      label: l10n?.adminSortDateOldest ?? 'Oldest first'),
                ],
                selectedId: sort,
                onSelected: onSort),
          ],
        ),
      ],
    );
  }
}
