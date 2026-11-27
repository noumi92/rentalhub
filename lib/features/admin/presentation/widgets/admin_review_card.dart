import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import 'admin_list_card.dart';
import 'admin_status_chip.dart';

/// One review moderation card (extracted from [AdminReviewsView] to
/// keep the view under the 250-line cap). Shows the review, its
/// signals and its moderation state, plus the Keep / Hide /
/// Ask-to-edit / Warn actions.

/// The label for a moderation action code ('visible' / 'hidden' /
/// 'edit_requested' / 'warned'), localised when [l10n] is given.
String reviewActionLabel(String status, [AppLocalizations? l10n]) {
  if (l10n != null) {
    final localized = switch (status) {
      'visible' => l10n.admin2_reviewKeep,
      'hidden' => l10n.admin2_reviewHide,
      'edit_requested' => l10n.admin2_reviewAskToEdit,
      'warned' => l10n.admin2_reviewWarn,
      _ => null,
    };
    if (localized != null) return localized;
  }
  return humanizeStatus(status, l10n);
}
class AdminReviewCard extends StatelessWidget {
  final AdminReview review;
  final Future<void> Function(AdminReview review, String status) onModerate;

  const AdminReviewCard({
    super.key,
    required this.review,
    required this.onModerate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = review;
    // Phase 4 (4.1) — the card shell is the shared shape; the
    // body stays custom (ratings/signals/actions are not a
    // ListTile row).
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: adminCardShape(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r.customerName ?? r.customerId} • ${r.vehicleName ?? r.bookingId}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.admin2_reviewCardRatings(r.shopRating?.toString() ?? '—', r.vehicleRating?.toString() ?? '—', r.ownerPunctuality?.toString() ?? '—', r.ownerCare?.toString() ?? '—', r.ownerBehavior?.toString() ?? '—'),
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (r.customerComment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('"${r.customerComment}"',
                  style: const TextStyle(
                      fontSize: 13, fontStyle: FontStyle.italic)),
            ],
            if (r.signals.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: r.signals
                    .map((s) => Chip(
                          label: Text(s,
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${l10n.admin2_reviewModeration(reviewActionLabel(r.moderationStatus, l10n))}${r.moderationReason.isNotEmpty ? ' — ${r.moderationReason}' : ''}',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  // AD-M8: 48dp minimum touch target, and the button
                  // matching the current moderation state is disabled.
                  onPressed: r.moderationStatus == 'visible'
                      ? null
                      : () => onModerate(r, 'visible'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.admin2_reviewKeep),
                ),
                OutlinedButton(
                  onPressed: r.moderationStatus == 'hidden'
                      ? null
                      : () => onModerate(r, 'hidden'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.admin2_reviewHide),
                ),
                OutlinedButton(
                  onPressed: r.moderationStatus == 'edit_requested'
                      ? null
                      : () => onModerate(r, 'edit_requested'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.admin2_reviewAskToEdit),
                ),
                OutlinedButton(
                  onPressed: r.moderationStatus == 'warned'
                      ? null
                      : () => onModerate(r, 'warned'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.admin2_reviewWarn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
