import 'package:flutter/material.dart';

import '../../data/datasources/admin_platform_data_source.dart';

/// One review moderation card (extracted from [AdminReviewsView] to
/// keep the view under the 250-line cap). Shows the review, its
/// signals and its moderation state, plus the Keep / Hide /
/// Ask-to-edit / Warn actions.
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
    final r = review;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r.customerName ?? r.customerId} • ${r.vehicleName ?? r.bookingId}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Shop ${r.shopRating ?? '—'}/5 • Car ${r.vehicleRating ?? '—'}/5 • Owner: punctuality ${r.ownerPunctuality ?? '—'}, care ${r.ownerCare ?? '—'}, behaviour ${r.ownerBehavior ?? '—'}',
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
              'Moderation: ${r.moderationStatus}${r.moderationReason.isNotEmpty ? ' — ${r.moderationReason}' : ''}',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => onModerate(r, 'visible'),
                  child: const Text('Keep'),
                ),
                OutlinedButton(
                  onPressed: () => onModerate(r, 'hidden'),
                  child: const Text('Hide'),
                ),
                OutlinedButton(
                  onPressed: () => onModerate(r, 'edit_requested'),
                  child: const Text('Ask to edit'),
                ),
                OutlinedButton(
                  onPressed: () => onModerate(r, 'warned'),
                  child: const Text('Warn'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
