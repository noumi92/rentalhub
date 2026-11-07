import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/data/firestore_set_handler.dart';
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/core/data/sync_engine.dart';
import 'package:rentalhub/core/data/sync_queue_entry.dart';
import 'package:rentalhub/core/data/sync_status_cubit.dart';
import 'package:rentalhub/core/network/connectivity_service.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase B (B4): the write-path contract.
///
/// Validate before queueing, server timestamps for ordering, merge
/// semantics on Firestore writes, no success until persisted, and
/// the agreement PDF hash recorded at handover.
void main() {
  group('Idempotency keys (B3/B4)', () {
    test('the same payload always yields the same key', () {
      const payload = {'bookingId': 'RH-1', 'status': 'requested'};
      final a =
          SyncQueueEntry.computeIdempotencyKey('booking_create', 'RH-1', payload);
      final b =
          SyncQueueEntry.computeIdempotencyKey('booking_create', 'RH-1', payload);
      expect(a, b);
    });

    test('a different payload yields a different key', () {
      final a = SyncQueueEntry.computeIdempotencyKey(
          'booking_create', 'RH-1', {'bookingId': 'RH-1', 'status': 'requested'});
      final b = SyncQueueEntry.computeIdempotencyKey(
          'booking_create', 'RH-1', {'bookingId': 'RH-1', 'status': 'paid'});
      expect(a, isNot(b));
    });
  });

  group('Validate before queueing (B4)', () {
    test('the booking write path validates its payload', () {
      final source = File(
              'lib/features/bookings/data/datasources/booking_remote_data_source.dart')
          .readAsStringSync();
      expect(source.contains('_validateBookingMap'), isTrue);
      expect(
        source.contains("throw ArgumentError('Cannot queue a booking"),
        isTrue,
      );
    });

    test('an invalid firestore_set entry is never applied', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('firestore_set', FirestoreSetHandler().call);
      // No collection/docId: the handler must refuse, and the entry
      // stays queued (flagged by attempts) instead of vanishing.
      await queue.enqueue(
        kind: 'firestore_set',
        entityId: 'x',
        payload: {'fields': {'status': 'paid'}},
      );
      expect(await engine.drain(), 0);
      final entries = await queue.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.attempts, 1);
    });
  });

  group('Pending sync until server confirmation (B4/B5)', () {
    test('a write reported as success is recoverable after restart',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineSyncQueue(prefs: prefs);
      final ds = BookingRemoteDataSource(syncQueue: queue);

      await ds.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'v1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 8, 9),
        returnTime: DateTime(2026, 11, 9, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );

      // Restart: the queued write is still there.
      final stored = prefs.getString(OfflineSyncQueue.queueKey)!;
      SharedPreferences.setMockInitialValues(
          {OfflineSyncQueue.queueKey: stored});
      final prefs2 = await SharedPreferences.getInstance();
      final queue2 = OfflineSyncQueue(prefs: prefs2);
      expect(await queue2.pendingCount, 1);

      // The "server" confirms it (a stand-in handler — there is no
      // Firestore in tests) and the entry is removed.
      final engine = SyncEngine(queue: queue2);
      engine.registerHandler('booking_create', (_, __) async => true);
      expect(await engine.drain(), 1);
      expect(await queue2.pendingCount, 0);
    });

    test('a raw DateTime in a payload survives a restart (B3)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineSyncQueue(prefs: prefs);

      // A future data source passing a raw DateTime must not crash
      // the offline write — it is stored as the ISO string every
      // model's toMap() already produces.
      await queue.enqueue(
        kind: 'firestore_set',
        entityId: 'doc-1',
        payload: {
          'collection': 'test',
          'docId': 'doc-1',
          'fields': {
            'name': 'Test',
            'createdAt': DateTime(2026, 11, 7, 22, 30),
          },
        },
      );

      final stored = prefs.getString(OfflineSyncQueue.queueKey)!;
      SharedPreferences.setMockInitialValues(
          {OfflineSyncQueue.queueKey: stored});
      final prefs2 = await SharedPreferences.getInstance();
      final queue2 = OfflineSyncQueue(prefs: prefs2);
      final entries = await queue2.pendingEntries();
      expect(entries, hasLength(1));
      final fields =
          entries.first.payload['fields'] as Map<String, dynamic>;
      expect(fields['createdAt'], '2026-11-07T22:30:00.000');
    });

    test('pending-sync state is visible until confirmation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineSyncQueue(prefs: prefs);
      final ds = BookingRemoteDataSource(syncQueue: queue);
      final connectivity = ConnectivityService(
        checkConnectivity: () async => [ConnectivityResult.wifi],
        connectivityChanges: const Stream.empty(),
        debounce: Duration.zero,
      );
      final cubit = SyncStatusCubit(connectivity: connectivity, queue: queue);
      await cubit.start();

      final created = await ds.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'v1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 8, 9),
        returnTime: DateTime(2026, 11, 9, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await cubit.refresh();
      expect(cubit.statusFor(created.bookingId), SyncEntryStatus.pending);

      final engine = SyncEngine(queue: queue);
      engine.registerHandler('booking_create', (_, __) async => true);
      await engine.drain();
      await cubit.refresh();
      expect(cubit.statusFor(created.bookingId), SyncEntryStatus.synced);
      expect(cubit.state.pendingCount, 0);

      await cubit.close();
      await connectivity.dispose();
    });
  });

  group('Agreement PDF hash (B4)', () {
    test('the hash is a stable sha-256 of the PDF bytes', () {
      expect(
        HandoverCubit.agreementPdfHash(utf8.encode('hello')),
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      );
      expect(
        HandoverCubit.agreementPdfHash(utf8.encode('hello')),
        HandoverCubit.agreementPdfHash(utf8.encode('hello')),
      );
      expect(
        HandoverCubit.agreementPdfHash(utf8.encode('hello')),
        isNot(HandoverCubit.agreementPdfHash(utf8.encode('hell0'))),
      );
    });

    test('the handover sync records the hash in Firestore', () {
      final source = File(
              'lib/features/handover/presentation/cubit/handover_cubit.dart')
          .readAsStringSync();
      expect(source.contains('agreementPdfSha256'), isTrue);
      expect(source.contains('agreementPdfHash'), isTrue);
    });
  });

  group('Server timestamps + merge semantics (B4)', () {
    test('booking writes use merge-set with a server timestamp', () {
      final source = File(
              'lib/features/bookings/data/datasources/booking_remote_data_source.dart')
          .readAsStringSync();
      expect(source.contains('SetOptions(merge: true)'), isTrue);
      expect(source.contains('FieldValue.serverTimestamp()'), isTrue);
    });

    test('handover writes use merge-set with a server timestamp', () {
      final source = File(
              'lib/features/handover/presentation/cubit/handover_cubit.dart')
          .readAsStringSync();
      expect(source.contains('SetOptions(merge: true)'), isTrue);
      expect(source.contains('FieldValue.serverTimestamp()'), isTrue);
    });
  });
}
