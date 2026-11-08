import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/sync_status_cubit.dart';
import '../di/injection_container.dart';

/// Phase B (B5): resolve the cubit a sync widget should listen to.
/// Prefers a [SyncStatusCubit] provided by an ancestor (tests and
/// the app's `BlocProvider` in main.dart); falls back to the DI
/// singleton for screens pumped standalone; null when neither
/// exists, so the widget can render nothing instead of throwing.
SyncStatusCubit? resolveSyncStatusCubit(BuildContext context) {
  try {
    return context.read<SyncStatusCubit>();
  } catch (_) {
    try {
      return sl<SyncStatusCubit>();
    } catch (_) {
      return null;
    }
  }
}

/// Phase B (B5): the slim offline / pending-sync banner.
///
/// * Offline → "You're offline — changes will sync when you're
///   back online" (warning colours).
/// * Online with queued work → "N change(s) pending sync"
///   (neutral, with a small spinner).
/// * Online and nothing pending → renders nothing.
///
/// Reads [SyncStatusCubit]; place it at the top of a tab screen's
/// body. The full rollout (every tab screen) comes with the Phase C
/// shell, which gives the banner one home; this phase wires the two
/// landing screens (customer Home, owner Dashboard) first.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Phase B (B5): prefer a provided cubit, else the DI singleton,
    // else render nothing (never throw for a missing provider).
    final cubit = resolveSyncStatusCubit(context);
    if (cubit == null) return const SizedBox.shrink();
    return BlocBuilder<SyncStatusCubit, SyncStatusState>(
      bloc: cubit,
      builder: (context, state) {
        if (state.isOnline && state.pendingCount == 0) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final isOffline = !state.isOnline;
        final background = isOffline
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest;
        final foreground = isOffline
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onSurface;
        final text = isOffline
            ? (state.pendingCount > 0
                ? "You're offline — ${state.pendingCount} change${state.pendingCount == 1 ? '' : 's'} will sync when you're back online"
                : "You're offline — changes will sync when you're back online")
            : '${state.pendingCount} change${state.pendingCount == 1 ? '' : 's'} pending sync';
        // Phase D (D2): the banner lives at the very top of the shell
        // body, so with edge-to-edge it would render under the status
        // bar when visible. The SafeArea wraps only the visible
        // banner — the hidden branch above stays a zero-size shrink.
        return SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: Container(
            width: double.infinity,
            color: background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                isOffline ? Icons.wifi_off_outlined : Icons.sync_outlined,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

/// Phase B (B5): the per-item sync chip for booking / handover
/// rows. Returns null when the item is synced (no chip).
class SyncStatusChip extends StatelessWidget {
  final SyncEntryStatus status;

  const SyncStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == SyncEntryStatus.synced) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isFailed = status == SyncEntryStatus.failed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFailed
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isFailed ? 'Sync failed — will retry' : 'Pending sync',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isFailed
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
