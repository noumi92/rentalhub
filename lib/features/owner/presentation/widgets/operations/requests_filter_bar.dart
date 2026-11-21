import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Audit §5 item 2 (O14): the search field and the Rejected tab the
/// requests list was missing. Extracted from [OwnerBookingRequestsView]
/// so the view stays under the 250-line cap.
class RequestsFilterBar extends StatelessWidget {
  const RequestsFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.filter,
    required this.counts,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String filter;
  final Map<String, int> counts;
  final ValueChanged<String> onFilterChanged;

  Widget _chip(BuildContext context, AppLocalizations l10n, String status,
      String label) {
    final selected = filter == status;
    final count = counts[status] ?? 0;
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // Item 4 (fleet-style bar): 14sp label set on the Text itself
      // — the bar scrolls horizontally at full size instead of
      // shrinking labels (same pattern as FleetFilterChips).
      label: Text(l10n.requestsFilterChip(label, count),
          style: const TextStyle(fontSize: 14)),
      selected: selected,
      onSelected: (_) => onFilterChanged(status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.bookingSearchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              // Audit 2026-11-15 DS-12: no explicit border — the theme
              // owns the radius-16 input border. The chips below
              // already inherit the navy selected-chip theme token
              // (DS-1): this bar carries no selectedColor override.
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        // Item 4 (2026-11-21): ONE fleet-style bar covering ALL
        // booking statuses, in pipeline order — All first, then
        // New / Proof / Approved / Paid / Active / Disputed /
        // Completed / Rejected / Cancelled. The bar scrolls
        // horizontally at full size (SingleChildScrollView above),
        // so no label shrinks. Paid / Disputed / Cancelled are
        // the statuses the old bar (and the old list whitelist)
        // dropped, which left those bookings unfilterable — and
        // invisible. Labels reuse the existing status keys, so
        // only `statusDisputed` is a new .arb key.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _chip(context, l10n, 'all', l10n.filterAll),
              const SizedBox(width: 8),
              _chip(context, l10n, 'requested', l10n.requestsFilterNew),
              const SizedBox(width: 8),
              _chip(context, l10n, 'payment_submitted',
                  l10n.requestsFilterProof),
              const SizedBox(width: 8),
              _chip(context, l10n, 'approved', l10n.statusApproved),
              const SizedBox(width: 8),
              _chip(context, l10n, 'paid', l10n.statusPaid),
              const SizedBox(width: 8),
              _chip(context, l10n, 'active', l10n.active),
              const SizedBox(width: 8),
              _chip(context, l10n, 'disputed', l10n.statusDisputed),
              const SizedBox(width: 8),
              _chip(context, l10n, 'completed', l10n.statusCompleted),
              const SizedBox(width: 8),
              _chip(context, l10n, 'rejected', l10n.statusRejected),
              const SizedBox(width: 8),
              _chip(context, l10n, 'cancelled', l10n.statusCancelled),
            ],
          ),
        ),
      ],
    );
  }
}
