import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Simplified booking filter bar:
/// 1. Two horizontal origin tabs (Walk-in | Online) with live counts.
/// 2. Compact search field.
/// 3. Minimized status chips (All, Pending, Paid, Active, Completed,
///    plus Cancelled only when present or selected).
class RequestsFilterBar extends StatelessWidget {
  const RequestsFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.filter,
    required this.counts,
    required this.onFilterChanged,
    this.originTab = 'walk_in',
    this.walkInCount = 0,
    this.onlineCount = 0,
    this.onOriginTabChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String filter;
  final Map<String, int> counts;
  final ValueChanged<String> onFilterChanged;
  final String originTab;
  final int walkInCount;
  final int onlineCount;
  final ValueChanged<String>? onOriginTabChanged;

  Widget _chip(
    BuildContext context,
    AppLocalizations l10n,
    String status,
    String label,
  ) {
    final selected = filter == status;
    final count = counts[status] ?? 0;
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(
        l10n.requestsFilterChip(label, count),
        style: const TextStyle(fontSize: 14),
      ),
      selected: selected,
      onSelected: (_) => onFilterChanged(status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cancelledCount = counts['cancelled'] ?? 0;
    final showCancelled = cancelledCount > 0 || filter == 'cancelled';

    return Column(
      children: [
        if (onOriginTabChanged != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    key: const ValueKey('bookings_origin_walk_in'),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    showCheckmark: false,
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        '${l10n.bookingsTabWalkIn} ($walkInCount)',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    selected: originTab == 'walk_in',
                    onSelected: (_) => onOriginTabChanged!('walk_in'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    key: const ValueKey('bookings_origin_online'),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    showCheckmark: false,
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                        '${l10n.bookingsTabOnline} ($onlineCount)',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    selected: originTab == 'online',
                    onSelected: (_) => onOriginTabChanged!('online'),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.bookingSearchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            children: [
              _chip(context, l10n, 'all', l10n.filterAll),
              const SizedBox(width: 8),
              _chip(context, l10n, 'pending', l10n.bookingsFilterPending),
              const SizedBox(width: 8),
              _chip(context, l10n, 'paid', l10n.statusPaid),
              const SizedBox(width: 8),
              _chip(context, l10n, 'active', l10n.active),
              const SizedBox(width: 8),
              _chip(context, l10n, 'completed', l10n.statusCompleted),
              if (showCancelled) ...[
                const SizedBox(width: 8),
                _chip(context, l10n, 'cancelled', l10n.statusCancelled),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
