import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/sync_status_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// Phase B (B5): the owner settings "Sync" card — one live row
/// showing offline / pending / failed / all-synced. Extracted from
/// [OwnerSettingsView] so that view stays under the rulebook's
/// 250-line cap.
class SyncStatusSection extends StatelessWidget {
  const SyncStatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Phase F: the section title and status lines are localized
    // (English fallback for delegate-less pumps).
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n?.syncTitle ?? 'Sync',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              // Prefer a provided cubit, else the DI singleton,
              // else render nothing (never throw for a missing
              // provider).
              final cubit = resolveSyncStatusCubit(context);
              if (cubit == null) return const SizedBox.shrink();
              return BlocBuilder<SyncStatusCubit, SyncStatusState>(
                bloc: cubit,
                builder: (context, sync) {
                  // Phase F: localized status lines (plural keys carry
                  // the 1-vs-many form). English fallback for
                  // delegate-less pumps.
                  final text = !sync.isOnline
                      ? (sync.pendingCount > 0
                          ? l10n?.syncOfflineWithPending(sync.pendingCount) ??
                              "You're offline — ${sync.pendingCount} change${sync.pendingCount == 1 ? '' : 's'} will sync when you're back online"
                          : l10n?.syncOffline ??
                              "You're offline — changes will sync when you're back online")
                      : sync.failedCount > 0
                          ? l10n?.syncFailed(sync.failedCount) ??
                              '${sync.failedCount} change${sync.failedCount == 1 ? '' : 's'} failed to sync — will retry'
                          : sync.pendingCount > 0
                              ? l10n?.syncPending(sync.pendingCount) ??
                                  '${sync.pendingCount} change${sync.pendingCount == 1 ? '' : 's'} pending sync'
                              : l10n?.syncAllSynced ?? 'All changes synced';
                  return Row(
                    children: [
                      Icon(
                        sync.isOnline && sync.pendingCount == 0
                            ? Icons.check_circle_outline_rounded
                            : Icons.sync_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
