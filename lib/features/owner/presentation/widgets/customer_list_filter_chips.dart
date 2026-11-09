import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// O11: the customers-list filter chips. Classification (documented
/// here and in [OwnerCustomersListView]): Regular = 2+ rentals,
/// New = 0–1 rentals, Flagged = blacklisted or has dues (a booking in
/// an approved/paid/active/completed status with a remaining balance
/// — the same dues definition as the dues screen).
enum CustomerListFilter { all, regular, isNew, flagged }

class CustomerListFilterChips extends StatelessWidget {
  const CustomerListFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CustomerListFilter selected;
  final ValueChanged<CustomerListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      CustomerListFilter.all: l10n.customersFilterAll,
      CustomerListFilter.regular: l10n.customersFilterRegular,
      CustomerListFilter.isNew: l10n.customersFilterNew,
      CustomerListFilter.flagged: l10n.customersFilterFlagged,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          for (final filter in CustomerListFilter.values) ...[
            ChoiceChip(
              label: Text(labels[filter]!),
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
