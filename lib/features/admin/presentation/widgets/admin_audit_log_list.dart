import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import 'admin_load_more_button.dart';

/// The activity log's list: loading / error / empty states, the
/// count line, the entries, and the "Load more" footer. Extracted
/// from the view so the view stays under the 250-line cap.
class AdminAuditLogList extends StatelessWidget {
  const AdminAuditLogList({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.entries,
    required this.countLabel,
    required this.compact,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;
  final List<AuditLogEntry> entries;
  final String? countLabel;
  final bool compact;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  // Locale-aware: the old hand-rolled English month list ignored
  // the admin's locale (Urdu users saw English month names).
  static String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('d MMM yyyy HH:mm', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Tests pump without localization delegates — fall back to
    // English instead of crashing on a null check.
    final l10n = AppLocalizations.of(context);
    if (isLoading) return const AppLoadingState();
    if (hasError) {
      return AppErrorState(
        message: l10n?.admin2_activityLoadFailed ??
            'Could not load the activity log.',
        onRetry: onRetry,
      );
    }
    if (entries.isEmpty) {
      return AppEmptyState(
        title: l10n?.admin2_activityEmptyTitle ?? 'No audit entries yet',
        message: l10n?.admin2_activityEmptyHint ??
            'Admin actions will appear here as they happen.',
      );
    }
    final countLabel = this.countLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (countLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              countLabel,
              style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i >= entries.length) {
                return AdminLoadMoreButton(
                  isLoadingMore: isLoadingMore,
                  onPressed: onLoadMore,
                );
              }
              final e = entries[i];
              final subtitle =
                  '${e.actorEmail} • ${e.targetType} ${e.targetId}'
                  '${e.detail.isEmpty ? '' : '\n${e.detail}'}'
                  '${e.decision == null ? '' : '\n${l10n?.admin2_activityDecision(e.decision!) ?? 'Decision: ${e.decision}'}'}';
              return Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: Theme.of(context).dividerColor),
                ),
                // Compact: the trailing date squeezes the entry
                // text at 360px (worse at 2.0x scale), so the date
                // joins the subtitle.
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                    child:
                        const Icon(Icons.history_rounded, size: 20),
                  ),
                  title: Text(
                    e.action,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    compact
                        ? '$subtitle\n${_formatDate(context, e.createdAt)}'
                        : subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                  isThreeLine: true,
                  trailing: compact
                      ? null
                      : Text(
                          _formatDate(context, e.createdAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
