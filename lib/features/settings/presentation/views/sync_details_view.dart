import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/sync_engine.dart';
import '../../../../core/data/sync_queue_entry.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../widgets/sync_entry_card.dart';

/// Phone-test #4: the screen the failed-sync banner opens (and the
/// Settings entry point). The queue lives in SharedPreferences key
/// `offline_sync_queue_v2`, so until now there was no way to see
/// which entry was stuck, retry it, or discard it — the banner just
/// said "1 change pending sync" forever.
///
/// Lists every queued entry with its kind, entity, attempts and last
/// error. Retry now resets attempts/backoff and drains; Discard
/// removes the entry. Both are the only ways a parked (exhausted)
/// entry leaves the queue.
class SyncDetailsView extends StatefulWidget {
  const SyncDetailsView({super.key});

  @override
  State<SyncDetailsView> createState() => _SyncDetailsViewState();
}

class _SyncDetailsViewState extends State<SyncDetailsView> {
  OfflineSyncQueue? _queue;
  SyncEngine? _engine;
  List<SyncQueueEntry> _entries = [];
  bool _loading = true;
  String? _retryingId;
  StreamSubscription<void>? _queueSub;

  @override
  void initState() {
    super.initState();
    // The view degrades to the empty state when the queue is not
    // registered (e.g. a standalone pump) instead of throwing.
    try {
      _queue = sl<OfflineSyncQueue>();
    } catch (_) {
      _queue = null;
    }
    try {
      _engine = sl<SyncEngine>();
    } catch (_) {
      _engine = null;
    }
    _queueSub = _queue?.changes.listen((_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    unawaited(_queueSub?.cancel());
    super.dispose();
  }

  Future<void> _refresh() async {
    final entries = await _queue?.pendingEntries() ?? <SyncQueueEntry>[];
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _retry(SyncQueueEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final engine = _engine;
    if (engine == null) {
      // Audit §31: retry used to silently no-op when the engine
      // wasn't registered.
      if (mounted) {
        AppFeedback.showError(
            context, l10n?.syncFailed(1) ?? 'Sync failed — will retry');
      }
      return;
    }
    setState(() => _retryingId = entry.id);
    try {
      await engine.retryEntry(entry);
      await _refresh();
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
            context, l10n?.syncFailed(1) ?? 'Sync failed — will retry');
      }
    } finally {
      if (mounted) setState(() => _retryingId = null);
    }
  }

  Future<void> _discard(SyncQueueEntry entry) async {
    final l10n = AppLocalizations.of(context);
    // Audit §31/C10: Discard deletes a queued offline change with
    // no confirmation and no undo — confirm first, showing the
    // entry kind.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.syncDiscardTitle ?? 'Discard this change?'),
        content: Text(l10n?.syncDiscardBody(
                syncKindLabel(l10n, entry.kind), entry.entityId) ??
            '${syncKindLabel(l10n, entry.kind)} • ${entry.entityId}\nIt will not sync.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.commonGoBack ?? 'Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.commonConfirm ?? 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _queue?.remove(entry.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n?.syncDetailsTitle ?? 'Sync details',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _loading
                  ? const AppLoadingState()
                  : _entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_done_outlined, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                l10n?.syncNoPending ?? 'Nothing pending',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return SyncEntryCard(
                              entry: entry,
                              kindLabel: syncKindLabel(l10n, entry.kind),
                              failedLabel:
                                  l10n?.syncDetailsFailed ?? 'Failed',
                              attemptsLabel: l10n?.syncDetailsAttempts(
                                      entry.attempts) ??
                                  'Attempts: ${entry.attempts}',
                              retryLabel:
                                  l10n?.syncRetryNow ?? 'Retry now',
                              discardLabel:
                                  l10n?.syncDiscard ?? 'Discard',
                              isRetrying: _retryingId == entry.id,
                              onRetry: () => _retry(entry),
                              onDiscard: () => _discard(entry),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
