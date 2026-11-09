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
      label: Text(l10n.requestsFilterChip(label, count)),
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
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).dividerColor)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _chip(context, l10n, 'requested', l10n.requestsFilterNew),
              const SizedBox(width: 8),
              _chip(context, l10n, 'payment_submitted',
                  l10n.requestsFilterProof),
              const SizedBox(width: 8),
              _chip(context, l10n, 'approved', l10n.statusApproved),
              const SizedBox(width: 8),
              _chip(context, l10n, 'rejected', l10n.statusRejected),
            ],
          ),
        ),
      ],
    );
  }
}
