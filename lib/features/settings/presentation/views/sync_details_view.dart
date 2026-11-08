import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/sync_engine.dart';
import '../../../../core/data/sync_queue_entry.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/minimal_app_bar.dart';

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
    final engine = _engine;
    if (engine == null) return;
    await engine.retryEntry(entry);
    await _refresh();
  }

  Future<void> _discard(SyncQueueEntry entry) async {
    await _queue?.remove(entry.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n?.syncDetailsTitle ?? 'Sync details',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
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
                            return _SyncEntryCard(
                              entry: entry,
                              retryLabel:
                                  l10n?.syncRetryNow ?? 'Retry now',
                              discardLabel:
                                  l10n?.syncDiscard ?? 'Discard',
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

/// One queued entry: kind, entity id, attempts and last error, with
/// Retry now + Discard. The error text is a raw diagnostic string
/// (English, from the handler), so it is shown as stored.
class _SyncEntryCard extends StatelessWidget {
  final SyncQueueEntry entry;
  final String retryLabel;
  final String discardLabel;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  const _SyncEntryCard({
    required this.entry,
    required this.retryLabel,
    required this.discardLabel,
    required this.onRetry,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    entry.kind,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (entry.isExhausted)
                  Chip(
                    label: Text(
                      'Failed',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.entityId, style: theme.textTheme.bodyMedium),
            Text(
              'Attempts: ${entry.attempts}',
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
                  onPressed: onDiscard,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text(discardLabel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
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
