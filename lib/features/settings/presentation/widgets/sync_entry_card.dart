import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/data/sync_queue_entry.dart';
import '../../../../l10n/app_localizations.dart';

/// One queued entry: kind, entity id, attempts and last error, with
/// Retry now + Discard. The error text is a raw diagnostic string
/// (English, from the handler), so it is shown as stored.
class SyncEntryCard extends StatelessWidget {
  final SyncQueueEntry entry;
  final String kindLabel;
  final String failedLabel;
  final String attemptsLabel;
  final String retryLabel;
  final String discardLabel;
  final bool isRetrying;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  const SyncEntryCard({
    super.key,
    required this.entry,
    required this.kindLabel,
    required this.failedLabel,
    required this.attemptsLabel,
    required this.retryLabel,
    required this.discardLabel,
    this.isRetrying = false,
    required this.onRetry,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    kindLabel,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (entry.isExhausted)
                  Chip(
                    label: Text(
                      failedLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.errorOnContainerFor(brightness)),
                    ),
                    backgroundColor:
                        AppColors.errorContainerFor(brightness),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.entityId, style: theme.textTheme.bodyMedium),
            Text(
              attemptsLabel,
              style: theme.textTheme.bodySmall,
            ),
            if (entry.lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.lastError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: isRetrying ? null : onDiscard,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(discardLabel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  // Audit §31: disable + spinner while retrying.
                  onPressed: isRetrying ? null : onRetry,
                  icon: isRetrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(retryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Audit §31: raw kind codes ('firestore_set', 'upload',
/// 'handover') mapped to friendly, localised names. Unknown kinds
/// fall back to the raw code (a diagnostic, never user copy).
String syncKindLabel(AppLocalizations? l10n, String kind) {
  switch (kind) {
    case 'firestore_set':
      return l10n?.syncKindSavedChange ?? 'Saved change';
    case 'upload':
      return l10n?.syncKindFileUpload ?? 'File upload';
    case 'handover':
      return l10n?.syncKindHandover ?? 'Handover';
    default:
      return kind;
  }
}
