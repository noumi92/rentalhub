import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../data/sync_status_cubit.dart';
import '../di/injection_container.dart';
import '../routing/route_names.dart';

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
/// * Online with nothing pending but failed entries → "Sync failed —
///   tap to review" (error colours, tappable → sync details).
///   Phone-test #4: exhausted entries used to count as pending, so
///   the banner said "1 change pending sync" forever.
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
        // Phone-test #4: failed entries no longer count as pending,
        // so the banner hides only when nothing is pending AND
        // nothing has failed.
        if (state.isOnline &&
            state.pendingCount == 0 &&
            state.failedCount == 0) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final isOffline = !state.isOnline;
        // Phone-test #4: online with no pending work but failed
        // entries is a distinct state — tappable, opens sync details.
        final isFailed =
            state.isOnline && state.pendingCount == 0 && state.failedCount > 0;
        // Phase F: the banner copy is localized; the plural keys carry
        // the 1-vs-many form, so no English singular/plural ternary
        // lives in the widget. The English fallback covers pumps
        // without localization delegates (unit tests); the app always
        // provides delegates, so users see the localized copy.
        final l10n = AppLocalizations.of(context);
        final background = isOffline
            ? theme.colorScheme.errorContainer
            : isFailed
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.surfaceContainerHighest;
        final foreground = isOffline
            ? theme.colorScheme.onErrorContainer
            : isFailed
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onSurface;
        final text = isOffline
            ? (state.pendingCount > 0
                ? l10n?.syncOfflineWithPending(state.pendingCount) ??
                    "You're offline — ${state.pendingCount} change${state.pendingCount == 1 ? '' : 's'} will sync when you're back online"
                : l10n?.syncOffline ??
                    "You're offline — changes will sync when you're back online")
            : isFailed
                ? l10n?.syncFailedBanner ?? 'Sync failed — tap to review'
                : l10n?.syncPending(state.pendingCount) ??
                    '${state.pendingCount} change${state.pendingCount == 1 ? '' : 's'} pending sync';
        // Audit fix (C1 / dead band): the banner no longer wraps
        // itself in a SafeArea — the shell (AppShell) owns the top
        // inset exactly once, so no ~status-bar-height empty strip
        // appears between the banner and the header. Standalone
        // pumps (tests) render it flush at the top, as before.
        // Audit fix (§4.6): 15 px vertical padding puts the tappable
        // failed banner at the 48 dp minimum tap height (15 + ~18 px
        // text line + 15); the offline/pending states get the same
        // height so the banner never jumps when its state changes.
        final banner = Container(
          width: double.infinity,
          color: background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                isOffline
                    ? Icons.wifi_off_outlined
                    : isFailed
                        ? Icons.error_outline_rounded
                        : Icons.sync_outlined,
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
              if (isFailed)
                Icon(Icons.chevron_right_rounded, size: 18, color: foreground),
            ],
          ),
        );
        // The failed banner is tappable (opens sync details); the
        // offline/pending states stay plain. maybeOf keeps pumps
        // without a GoRouter from throwing on tap. The Semantics
        // label is the a11y name for the tap target (E3 scan).
        return isFailed
            ? Semantics(
                button: true,
                label: text,
                child: GestureDetector(
                  onTap: () => GoRouter.maybeOf(context)
                      ?.push(RouteNames.syncDetails),
                  child: banner,
                ),
              )
            : banner;
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
    // Phase F: the chip copy is localized (short forms — the chip
    // carries no count, unlike the banner). English fallback for
    // delegate-less pumps, as above.
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isFailed
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isFailed
            ? l10n?.syncFailedShort ?? 'Sync failed — will retry'
            : l10n?.syncPendingShort ?? 'Pending sync',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isFailed
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
