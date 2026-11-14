import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// The "Showing N" / "N matching entries" line above a paged admin
/// list, shared by the tickets and customers views.
class AdminListCountLabel extends StatelessWidget {
  const AdminListCountLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// The "Load more" footer shared by the paged admin lists
/// (tickets, customers, activity log): full-width, 48dp, disabled
/// while the next page loads.
class AdminLoadMoreButton extends StatelessWidget {
  const AdminLoadMoreButton({
    super.key,
    required this.isLoadingMore,
    required this.onPressed,
  });

  final bool isLoadingMore;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isLoadingMore ? null : onPressed,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(isLoadingMore
              ? (l10n?.admin2_loading ?? 'Loading…')
              : (l10n?.adminAuditLoadMore ?? 'Load more')),
        ),
      ),
    );
  }
}
