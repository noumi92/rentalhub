import 'dart:async';

import '../network/connectivity_service.dart';
import 'offline_sync_queue.dart';
import 'sync_queue_entry.dart';

/// A sync handler drains one queue entry. Returns true when the
/// entry's work is confirmed on the server (the entry is removed),
/// false when it failed (the entry stays queued with backoff).
/// Handlers may update the entry (via [SyncEngine.updateEntry]) to
/// record completed steps — e.g. an uploaded file's URL — so a retry
/// resumes instead of repeating the step.
typedef SyncHandler = Future<bool> Function(
  SyncQueueEntry entry,
  SyncEngine engine,
);

/// Phase B (B3): the drain engine for [OfflineSyncQueue].
///
/// One drain at a time (the [_draining] guard makes the
/// offline → online trigger idempotent: firing twice syncs nothing
/// the second time), FIFO order, exponential backoff per entry
/// (1s → 5s → 30s → 5 min → 30 min; after the 5th attempt the entry
/// stays queued, flagged exhausted, retrying hourly — never silently
/// dropped).
class SyncEngine {
  final OfflineSyncQueue queue;

  final Map<String, SyncHandler> _handlers = {};
  StreamSubscription<bool>? _connectivitySub;
  bool _draining = false;

  SyncEngine({required this.queue});

  /// Backoff after [attempts] failures (attempts is 1-based here).
  static Duration backoffForAttempt(int attempts) {
    const steps = [
      Duration(seconds: 1),
      Duration(seconds: 5),
      Duration(seconds: 30),
      Duration(minutes: 5),
      Duration(minutes: 30),
    ];
    if (attempts <= 0) return Duration.zero;
    if (attempts > steps.length) return const Duration(hours: 1);
    return steps[attempts - 1];
  }

  void registerHandler(String kind, SyncHandler handler) {
    _handlers[kind] = handler;
  }

  bool get hasHandlerForKind => _handlers.isNotEmpty;

  /// Starts the B2 auto-sync trigger: every offline → online
  /// transition drains the queue. Safe to call twice.
  void startAutoSync(ConnectivityService connectivity) {
    _connectivitySub ??= connectivity.onlineStream.listen((online) {
      if (online) unawaited(drain());
    });
  }

  Future<void> updateEntry(SyncQueueEntry entry) =>
      queue.updateEntry(entry);

  /// Drains every due entry once, FIFO. Returns how many entries
  /// were confirmed synced. Never throws — a handler failure is
  /// recorded on the entry, not raised.
  Future<int> drain() async {
    if (_draining) return 0;
    _draining = true;
    var synced = 0;
    try {
      final now = DateTime.now();
      final entries = await queue.pendingEntries();
      for (final entry in entries) {
        if (entry.nextRetryAt != null && entry.nextRetryAt!.isAfter(now)) {
          continue;
        }
        final handler = _handlers[entry.kind];
        if (handler == null) continue;
        bool ok = false;
        try {
          ok = await handler(entry, this);
        } catch (e) {
          // Re-read the entry: the handler may have recorded
          // completed steps (e.g. an uploaded file's URL) before
          // failing, and that progress must survive the failure.
          final latest = await _freshEntry(entry.id) ?? entry;
          await _recordFailure(latest, e.toString());
          continue;
        }
        if (ok) {
          await queue.remove(entry.id);
          synced++;
        } else {
          final latest = await _freshEntry(entry.id) ?? entry;
          await _recordFailure(latest, 'handler reported failure');
        }
      }
    } finally {
      _draining = false;
    }
    return synced;
  }

  Future<SyncQueueEntry?> _freshEntry(String id) async {
    final entries = await queue.pendingEntries();
    final found = entries.where((e) => e.id == id);
    return found.isEmpty ? null : found.first;
  }

  Future<void> _recordFailure(SyncQueueEntry entry, String error) async {
    final attempts = entry.attempts + 1;
    final nextRetry = DateTime.now().add(backoffForAttempt(attempts));
    await queue.updateEntry(entry.copyWith(
      attempts: attempts,
      nextRetryAt: nextRetry,
      lastError: error,
    ));
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
  }
}
