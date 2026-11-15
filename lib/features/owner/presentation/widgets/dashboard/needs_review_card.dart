import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Team B (UI/UX audit 2026-11-15, FG-1): the "Needs review"
/// decision card — the first read on the owner dashboard. It shows
/// the waiting count split into new requests vs proofs awaiting
/// verification, the oldest wait, and taps through to the Requests
/// tab (which now defaults to the proof bucket). Rendered only when
/// there is something waiting; a zero queue shows nothing.
class NeedsReviewCard extends StatelessWidget {
  const NeedsReviewCard({
    super.key,
    required this.waitingCount,
    required this.newCount,
    required this.proofCount,
    required this.oldestWaitLabel,
    required this.onTap,
  });

  final int waitingCount;
  final int newCount;
  final int proofCount;

  /// Localised "Oldest wait: 6h" line, or null when no request time
  /// is known yet — the card never invents a wait.
  final String? oldestWaitLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    return Material(
      color: AppColors.warningContainerFor(brightness),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    AppColors.warningTextFor(brightness).withValues(alpha: 0.15),
                child: Icon(
                  Icons.inbox_rounded,
                  color: AppColors.warningTextFor(brightness),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardNeedsReviewTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$waitingCount · ${l10n.dashboardNeedsReviewSplit(newCount, proofCount)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (oldestWaitLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.dashboardOldestWait(oldestWaitLabel!),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.warningTextFor(brightness),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
