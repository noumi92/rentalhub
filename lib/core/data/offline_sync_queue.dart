import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sync_queue_entry.dart';

/// Phase B (B3): the shared offline sync queue.
///
/// One queue for every write that must not be lost — handover files,
/// bookings, payment proofs, vehicle photos, KYC docs, finance
/// transfers. It is SharedPreferences-backed, so entries survive a
/// restart (unlike the in-memory fallbacks it replaces), and it is
/// the single place the auto-sync trigger (B2) drains.
///
/// Guarantees:
/// * **No duplicates** — [enqueue] dedupes by idempotency key: the
///   same work twice returns the existing entry.
/// * **FIFO per entity** — [pendingEntries] returns entries in
///   insertion order; the drain keeps that order.
/// * **No silent loss** — entries are removed only when a handler
///   reports success. Failures stay queued with attempts/backoff.
/// * **Serialized writes** — mutations chain through one future so
///   concurrent enqueues cannot lose each other.
class OfflineSyncQueue {
  /// The SharedPreferences key holding the JSON list of entries.
  static const String queueKey = 'offline_sync_queue_v2';

  final SharedPreferences prefs;

  final _changes = StreamController<void>.broadcast();

  /// Mutation lock, implemented as an explicit waiter queue — NOT
  /// a chained Future. A Future completed in one zone (e.g. the
  /// queue built during DI init in setUpAll, or a previous
  /// testWidgets test's zone) does not reliably let a later zone's
  /// microtasks flush, so awaiting a stored future hangs forever
  /// with no error. Here every awaited future is a Completer
  /// created in the waiter's own zone, and the lock itself is plain
  /// synchronous state. Ownership transfers directly to the next
  /// waiter, so there is no race between release and re-acquire.
  /// A failed mutation releases the lock in `finally` — the queue
  /// can never wedge.
  bool _busy = false;
  final _waiters = <Completer<void>>[];

  OfflineSyncQueue({required this.prefs});

  /// Fires on every mutation (enqueue, update, remove).
  Stream<void> get changes => _changes.stream;

  Future<List<SyncQueueEntry>> _readAll() async {
    final raw = prefs.getString(queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SyncQueueEntry.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // A corrupt queue must not brick syncing: start fresh. The
      // entries are lost, but a crash loop is worse — and the queue
      // is only ever written by this class, so corruption means the
      // prefs store itself is damaged.
      return [];
    }
  }

  Future<void> _writeAll(List<SyncQueueEntry> entries) async {
    await prefs.setString(
      queueKey,
      jsonEncode(entries.map((e) => e.toJson()).toList(),
          toEncodable: encodeJsonValue),
    );
  }

  Future<T> _serialize<T>(Future<T> Function() work) async {
    if (_busy) {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
      // Woken as the next holder: _busy is still true, ownership
      // was transferred to us — do not re-check.
    } else {
      _busy = true;
    }
    try {
      return await work();
    } finally {
      if (_waiters.isNotEmpty) {
        // Transfer ownership to the next waiter; _busy stays true.
        _waiters.removeAt(0).complete();
      } else {
        _busy = false;
      }
    }
  }

  /// Enqueues [payload] for [kind]/[entityId], or returns the
  /// existing entry when the same work is already queued.
  /// When [dedupeKey] is given, an entry with the same key is the
  /// same logical work: with [replaceExisting] the older entry is
  /// dropped first (a re-submitted file supersedes the previous
  /// one); without it the existing entry is returned.
  Future<SyncQueueEntry> enqueue({
    required String kind,
    required String entityId,
    required Map<String, dynamic> payload,
    String? dedupeKey,
    bool replaceExisting = false,
  }) {
    return _serialize(() async {
      final entry = SyncQueueEntry.create(
        kind: kind,
        entityId: entityId,
        payload: payload,
        dedupeKey: dedupeKey,
      );
      final entries = await _readAll();
      if (dedupeKey != null) {
        final same = entries.where((e) => e.dedupeKey == dedupeKey);
        if (same.isNotEmpty && !replaceExisting) return same.first;
        entries.removeWhere((e) => e.dedupeKey == dedupeKey);
      }
      final existing = entries.where((e) => e.id == entry.id).toList();
      if (existing.isNotEmpty) return existing.first;
      entries.add(entry);
      await _writeAll(entries);
      _changes.add(null);
      return entry;
    });
  }

  /// All queued entries, insertion order (FIFO).
  Future<List<SyncQueueEntry>> pendingEntries() => _readAll();

  /// The queued entries for one entity (any kind), insertion order.
  Future<List<SyncQueueEntry>> entriesForEntity(String entityId) async {
    final entries = await _readAll();
    return entries.where((e) => e.entityId == entityId).toList();
  }

  /// The queued entry for one kind + entity, if any.
  Future<SyncQueueEntry?> entryFor(String kind, String entityId) async {
    final entries = await _readAll();
    final found =
        entries.where((e) => e.kind == kind && e.entityId == entityId);
    return found.isEmpty ? null : found.first;
  }

  Future<int> get pendingCount async => (await _readAll()).length;

  /// Replaces the stored entry with [updated] (same id).
  Future<void> updateEntry(SyncQueueEntry updated) {
    return _serialize(() async {
      final entries = await _readAll();
      final index = entries.indexWhere((e) => e.id == updated.id);
      if (index == -1) return;
      entries[index] = updated;
      await _writeAll(entries);
      _changes.add(null);
    });
  }

  /// Removes the entry — only called when its work is confirmed.
  Future<void> remove(String id) {
    return _serialize(() async {
      final entries = await _readAll();
      entries.removeWhere((e) => e.id == id);
      await _writeAll(entries);
      _changes.add(null);
    });
  }

  /// Test/support helper: drops every entry.
  Future<void> clear() {
    return _serialize(() async {
      await prefs.remove(queueKey);
      _changes.add(null);
    });
  }
}
