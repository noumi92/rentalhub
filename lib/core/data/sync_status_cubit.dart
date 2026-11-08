import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/offline_sync_queue.dart';
import '../network/connectivity_service.dart';

/// The sync state of one entity (a booking, a vehicle, a handover)
/// as shown in the UI.
enum SyncEntryStatus { synced, pending, failed }

class SyncStatusState extends Equatable {
  final bool isOnline;
  final int pendingCount;
  final int failedCount;

  /// Worst status per entity id (failed beats pending).
  final Map<String, SyncEntryStatus> byEntity;

  const SyncStatusState({
    required this.isOnline,
    required this.pendingCount,
    required this.failedCount,
    required this.byEntity,
  });

  @override
  List<Object?> get props => [isOnline, pendingCount, failedCount, byEntity];
}

/// Phase B (B5): the visible half of offline sync — one cubit that
/// turns the connectivity stream + the queue into UI state.
///
/// * `isOnline` — the connectivity state (offline banner).
/// * `pendingCount` — queued entries (Settings row, banner).
/// * `statusFor(entityId)` — per-item state for booking / handover
///   rows ("Synced" / "Pending sync" / "Sync failed — will retry").
///
/// The cubit refreshes on every queue change and every
/// connectivity transition; it never blocks a flow (D9).
class SyncStatusCubit extends Cubit<SyncStatusState> {
  final ConnectivityService connectivity;
  final OfflineSyncQueue queue;

  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<void>? _queueSub;

  SyncStatusCubit({required this.connectivity, required this.queue})
      : super(const SyncStatusState(
          isOnline: true,
          pendingCount: 0,
          failedCount: 0,
          byEntity: {},
        ));

  Future<void> start() async {
    await refresh();
    _connectivitySub ??= connectivity.onlineStream.listen((_) async {
      await refresh();
    });
    _queueSub ??= queue.changes.listen((_) async {
      await refresh();
    });
  }

  Future<void> refresh() async {
    final entries = await queue.pendingEntries();
    final byEntity = <String, SyncEntryStatus>{};
    var failed = 0;
    for (final entry in entries) {
      final status = entry.isExhausted
          ? SyncEntryStatus.failed
          : SyncEntryStatus.pending;
      if (status == SyncEntryStatus.failed) failed++;
      final existing = byEntity[entry.entityId];
      if (existing == null ||
          (existing == SyncEntryStatus.pending &&
              status == SyncEntryStatus.failed)) {
        byEntity[entry.entityId] = status;
      }
    }
    if (isClosed) return;
    emit(SyncStatusState(
      isOnline: connectivity.isOnline,
      // Phone-test #4: only genuinely pending entries count as
      // pending — exhausted entries are failed, not pending, or the
      // banner would say "1 change pending sync" forever.
      pendingCount: entries.length - failed,
      failedCount: failed,
      byEntity: byEntity,
    ));
  }

  SyncEntryStatus statusFor(String entityId) =>
      state.byEntity[entityId] ?? SyncEntryStatus.synced;

  @override
  Future<void> close() async {
    await _connectivitySub?.cancel();
    await _queueSub?.cancel();
    return super.close();
  }
}
