import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';

/// Phase 3 (3.6b) — what the blacklist-report dialog returns: the
/// reason *category* (one of [BlacklistReasonCategory]) and the
/// free-text *description*. The two used to be the same string —
/// the category is now a real enum value and the description is
/// the admin's own words.
class BlacklistReportReason {
  const BlacklistReportReason({
    required this.category,
    required this.description,
  });

  final BlacklistReasonCategory category;
  final String description;
}

String _categoryLabel(BlacklistReasonCategory c, AppLocalizations? l10n) {
  return switch (c) {
    BlacklistReasonCategory.fraud =>
      l10n?.admin2_blacklistCatFraud ?? 'Fraud',
    BlacklistReasonCategory.lateReturn =>
      l10n?.admin2_blacklistCatLateReturn ?? 'Late return',
    BlacklistReasonCategory.damage =>
      l10n?.admin2_blacklistCatDamage ?? 'Damage',
    BlacklistReasonCategory.nonPayment =>
      l10n?.admin2_blacklistCatNonPayment ?? 'Non-payment',
    BlacklistReasonCategory.abusiveBehaviour =>
      l10n?.admin2_blacklistCatAbusive ?? 'Abusive behaviour',
    BlacklistReasonCategory.other =>
      l10n?.admin2_blacklistCatOther ?? 'Other',
  };
}

/// AD-M6: the confirmation dialog for "Report to blacklist". The
/// report is the most consequential action on the customer screen, so
/// it asks for a mandatory reason (suspend-dialog pattern) and
/// returns it — or null when the admin cancels. The reason is what
/// the tribunal judges the case on.
Future<BlacklistReportReason?> showBlacklistReportDialog(
    BuildContext context) async {
  final reasonController = TextEditingController();
  final l10n = AppLocalizations.of(context);
  String? error;
  var category = BlacklistReasonCategory.fraud;
  final confirmedReason = await showDialog<BlacklistReportReason>(
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
              DropdownButtonFormField<BlacklistReasonCategory>(
                initialValue: category,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n?.admin2_blacklistCategoryLabel ??
                      'Reason category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: BlacklistReasonCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_categoryLabel(c, l10n)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => category = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n?.admin2_blacklistDescriptionLabel ??
                      l10n?.admin2_blacklistReasonLabel ??
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
              // Phase 1 (1.1): 48dp minimum touch targets
              // (rulebook §4.6) — neither dialog button had one.
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size(0, 48)),
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  error = l10n?.admin2_blacklistReasonRequired ??
                      'A reason is required to report a customer.';
                  setDialogState(() {});
                  return;
                }
                Navigator.of(ctx).pop(BlacklistReportReason(
                  category: category,
                  description: reason,
                ));
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

/// The admin-note composer on the customer detail screen,
/// extracted from AdminCustomerDetailView so the view stays under
/// the 250-line cap.
///
/// Phase 4 (4.4a): the Watchlist / Report-to-blacklist actions
/// used to live here too, but they moved to the sticky action bar
/// ([CustomerDetailStickyActions]) so they are reachable from every
/// tab — keeping them here as well would put two identical buttons
/// on the screen on the Notes tab.
class CustomerDetailActions extends StatelessWidget {
  const CustomerDetailActions({
    super.key,
    required this.noteController,
    required this.isWorking,
    required this.onAddNote,
  });

  final TextEditingController noteController;
  final bool isWorking;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isWorking ? null : onAddNote,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(l10n?.admin2_custActionAddNote ?? 'Add note'),
        ),
      ],
    );
  }
}
