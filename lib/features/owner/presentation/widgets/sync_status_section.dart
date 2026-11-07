import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/data/sync_status_cubit.dart';
import '../../../../core/widgets/offline_banner.dart';

/// Phase B (B5): the owner settings "Sync" card — one live row
/// showing offline / pending / failed / all-synced. Extracted from
/// [OwnerSettingsView] so that view stays under the rulebook's
/// 250-line cap.
class SyncStatusSection extends StatelessWidget {
  const SyncStatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sync',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.primary)),
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
                  final text = !sync.isOnline
                      ? (sync.pendingCount > 0
                          ? "You're offline — ${sync.pendingCount} change${sync.pendingCount == 1 ? '' : 's'} will sync when you're back online"
                          : "You're offline — changes will sync when you're back online")
                      : sync.failedCount > 0
                          ? '${sync.failedCount} change${sync.failedCount == 1 ? '' : 's'} failed to sync — will retry'
                          : sync.pendingCount > 0
                              ? '${sync.pendingCount} change${sync.pendingCount == 1 ? '' : 's'} pending sync'
                              : 'All changes synced';
                  return Row(
                    children: [
                      Icon(
                        sync.isOnline && sync.pendingCount == 0
                            ? Icons.check_circle_outline_rounded
                            : Icons.sync_outlined,
                        color: AppColors.primary,
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
