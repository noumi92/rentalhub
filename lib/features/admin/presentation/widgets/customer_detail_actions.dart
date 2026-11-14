import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';

/// AD-M6: the confirmation dialog for "Report to blacklist". The
/// report is the most consequential action on the customer screen, so
/// it asks for a mandatory reason (suspend-dialog pattern) and
/// returns it — or null when the admin cancels. The reason is what
/// the tribunal judges the case on.
Future<String?> showBlacklistReportDialog(BuildContext context) async {
  final reasonController = TextEditingController();
  final l10n = AppLocalizations.of(context);
  String? error;
  final confirmedReason = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          title: Text(l10n?.admin2_blacklistReportTitle ??
              'Report to blacklist?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.admin2_blacklistReportBody ??
                  'This blocks the customer platform-wide. Give the reason — the tribunal judges the case on it.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n?.admin2_blacklistReasonLabel ??
                      'Reason (required)',
                  errorText: error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700),
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  error = l10n?.admin2_blacklistReasonRequired ??
                      'A reason is required to report a customer.';
                  setDialogState(() {});
                  return;
                }
                Navigator.of(ctx).pop(reason);
              },
              child: Text(l10n?.admin2_blacklistReportConfirm ?? 'Report'),
            ),
          ],
        );
      },
    ),
  );
  return confirmedReason;
}

/// The action row on the customer detail screen, extracted from
/// AdminCustomerDetailView so the view stays under the 250-line cap:
/// the admin-note composer and the Watchlist / Report-to-blacklist
/// actions.
///
/// Mobile-first (2026-11-10): on a phone the two actions stack
/// full-width — side by side each is ~150dp and "Report to blacklist"
/// clips at large text scales. All buttons are 48dp tall.
class CustomerDetailActions extends StatelessWidget {
  const CustomerDetailActions({
    super.key,
    required this.noteController,
    required this.isWorking,
    required this.onAddNote,
    required this.onWatchlist,
    required this.onBlacklist,
    this.isWatchlisted = false,
  });

  final TextEditingController noteController;
  final bool isWorking;
  final VoidCallback onAddNote;
  final VoidCallback onWatchlist;
  final VoidCallback onBlacklist;

  /// AD-M6: the watchlist button is a toggle — when the customer is
  /// already watchlisted it offers to remove them.
  final bool isWatchlisted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: l10n?.admin2_custActionAddNoteHint ??
                      'Add an admin note…',
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isWorking ? null : onAddNote,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48)),
              child: Text(l10n?.admin2_custActionAddNote ?? 'Add note'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _watchlistButton(context),
              const SizedBox(height: 12),
              _blacklistButton(context),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _watchlistButton(context)),
              const SizedBox(width: 12),
              Expanded(child: _blacklistButton(context)),
            ],
          ),
      ],
    );
  }

  Widget _watchlistButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      onPressed: isWorking ? null : onWatchlist,
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48)),
      child: Text(isWatchlisted
          ? l10n?.admin2_watchlistRemove ?? 'Remove from watchlist'
          : l10n?.admin2_watchlistAdd ?? 'Add to watchlist'),
    );
  }

  Widget _blacklistButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FilledButton(
      style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          minimumSize: const Size(0, 48)),
      onPressed: isWorking ? null : onBlacklist,
      child: Text(l10n?.admin2_custActionBlacklist ?? 'Report to blacklist'),
    );
  }
}
