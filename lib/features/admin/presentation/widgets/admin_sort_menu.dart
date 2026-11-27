import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Phase 4 (4.3) — the shared sort control for the admin lists: a
/// sort-icon menu in the list header. Each list passes the options
/// that apply to it (amount, name, status, date — whichever its data
/// source can actually order by); the selected option is shown with
/// a check mark. The option [id] is the sort key the view passes to
/// its data source (server-paginated lists) or applies client-side
/// (client-side lists) — see [AdminListSort] for the shared ids.
class AdminSortOption {
  const AdminSortOption({required this.id, required this.label});

  /// Sort key, e.g. 'dateNewest'. Server-paginated lists pass it
  /// straight to their `get*Page(sort: ...)`; client-side lists
  /// switch on it in the view.
  final String id;
  final String label;
}

/// The shared sort ids. A list offers only the subset its data can
/// order by; the ids below are the whole vocabulary so a sort means
/// the same thing on every list that offers it.
abstract final class AdminListSort {
  static const dateNewest = 'dateNewest';
  static const dateOldest = 'dateOldest';
  static const nameAsc = 'nameAsc';
  static const nameDesc = 'nameDesc';
  static const amountHigh = 'amountHigh';
  static const amountLow = 'amountLow';
  static const statusAsc = 'statusAsc';
  static const statusDesc = 'statusDesc';
  static const priority = 'priority';
  static const ratingHigh = 'ratingHigh';
  static const ratingLow = 'ratingLow';
  static const titleAsc = 'titleAsc';
  static const actionAsc = 'actionAsc';
}

class AdminSortMenu extends StatelessWidget {
  const AdminSortMenu({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<AdminSortOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected =
        options.where((o) => o.id == selectedId).firstOrNull ??
            options.first;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: l10n?.adminSortLabel ?? 'Sort',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<String>(
            value: option.id,
            child: Row(
              children: [
                Expanded(child: Text(option.label)),
                if (option.id == selected.id)
                  const Icon(Icons.check_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
