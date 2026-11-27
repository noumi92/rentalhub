import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'admin_sort_menu.dart';
import 'admin_status_chip.dart';

/// Phase 3 (3.4) — the bookings list header, extracted from
/// [AdminBookingsView] so the view stays under the 250-line cap:
/// the server search field (400 ms debounce in the view) and the
/// horizontally scrolling lifecycle-status chips.
class AdminBookingListHeader extends StatelessWidget {
  const AdminBookingListHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.statuses,
    required this.filter,
    required this.onFilter,
    required this.sort,
    required this.onSort,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<String> statuses;
  final String filter;
  final ValueChanged<String> onFilter;

  /// Phase 4 (4.3) — the sort control for the list. Date orders
  /// by `pickupTime`, amount by `totalAmount`, status by `status`
  /// — all server-side.
  final String sort;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: l10n.admin2_bookingsSearchHint,
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
          alignment: AlignmentDirectional.centerStart,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < statuses.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(humanizeStatus(statuses[i], l10n)),
                    selected: filter == statuses[i],
                    onSelected: (_) => onFilter(statuses[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AdminSortMenu(
                options: [
                  AdminSortOption(
                      id: AdminListSort.dateNewest,
                      label: l10n.adminSortDateNewest),
                  AdminSortOption(
                      id: AdminListSort.dateOldest,
                      label: l10n.adminSortDateOldest),
                  AdminSortOption(
                      id: AdminListSort.amountHigh,
                      label: l10n.adminSortAmountHigh),
                  AdminSortOption(
                      id: AdminListSort.amountLow,
                      label: l10n.adminSortAmountLow),
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
