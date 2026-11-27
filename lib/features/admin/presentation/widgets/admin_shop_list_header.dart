import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import 'admin_sort_menu.dart';

/// Phase 3 (3.4) — the shops list header, extracted from
/// [AdminShopsView] so the view stays under the 250-line cap: the
/// server search field (400 ms debounce in the view) and the status
/// filter chips.
class AdminShopListHeader extends StatelessWidget {
  const AdminShopListHeader({
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

  /// Phase 4 (4.3) — the sort control for the list. Name orders
  /// by `shop_name` server-side; status orders by
  /// `verification_status` (suspended first) server-side.
  final String sort;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: l10n.admin2_shopsSearchHint,
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
                'all': l10n.filterAll,
                'approved': l10n.statusApproved,
                'pending': l10n.pending,
                'suspended': l10n.admin2_suspended,
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: filter == entry.key,
                  onSelected: (_) => onFilter(entry.key),
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
                      label: l10n.adminSortNameAsc),
                  AdminSortOption(
                      id: AdminListSort.nameDesc,
                      label: l10n.adminSortNameDesc),
                  AdminSortOption(
                      id: AdminListSort.statusAsc,
                      label: l10n.adminSortStatus),
                ],
                selectedId: sort,
                onSelected: onSort),
          ],
        ),
      ],
    );
  }
}
