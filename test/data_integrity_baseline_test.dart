import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/data/firestore_persistence.dart';
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase B (B1): the persistence baseline.
///
/// The baseline is two things: Firestore is explicitly configured
/// (persistence on, 100 MB cache) before anything touches it, and
/// no write path keeps its offline fallback only in memory — a
/// write made offline must still be there after a restart.
void main() {
  group('Firestore persistence baseline (B1)', () {
    test('main.dart pins the baseline before initDependencies', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main.contains('FirestorePersistence.configure()'), isTrue);
      final configureCall = main.indexOf('FirestorePersistence.configure()');
      final initCall = main.indexOf('await initDependencies()');
      expect(configureCall, greaterThan(-1));
      expect(initCall, greaterThan(-1));
      expect(configureCall, lessThan(initCall));
    });

    test('the baseline is persistence on, 100 MB cache', () {
      final source =
          File('lib/core/data/firestore_persistence.dart').readAsStringSync();
      expect(source.contains('persistenceEnabled: true'), isTrue);
      expect(source.contains('cacheSizeBytes'), isTrue);
      expect(FirestorePersistence.cacheSizeBytes, 100 * 1024 * 1024);
    });

    test('configure() degrades gracefully without Firebase', () {
      // No Firebase app exists in tests: configuring must not throw,
      // it just stays unconfigured (and logs the notice).
      FirestorePersistence.resetForTest();
      expect(() => FirestorePersistence.configure(), returnsNormally);
      expect(FirestorePersistence.isConfigured, isFalse);
      FirestorePersistence.resetForTest();
    });
  });

  group('No memory-only write fallbacks (B1)', () {
    test('booking, fleet and finance writes go through the queue', () {
      for (final path in [
        'lib/features/bookings/data/datasources/booking_remote_data_source.dart',
        'lib/features/fleet/data/datasources/fleet_remote_data_source.dart',
        'lib/features/finance/data/datasources/finance_transfer_data_source.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source.contains('syncQueue'), isTrue, reason: path);
        expect(source.contains('enqueue'), isTrue, reason: path);
      }
    });

    test('an offline booking is persisted, not just remembered',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineSyncQueue(prefs: prefs);
      final ds = BookingRemoteDataSource(syncQueue: queue);

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

      // The write is in the persisted queue, not only in memory.
      expect(await queue.pendingCount, 1);
      final entries = await queue.pendingEntries();
      expect(entries.first.kind, 'booking_create');
      expect(entries.first.entityId, created.bookingId);

      // And it reads back through the data source.
      final readBack = await ds.getBookingById(created.bookingId);
      expect(readBack, isNotNull);
      expect(readBack!.bookingId, created.bookingId);
      expect(readBack.status, 'requested');
    });

    test('an offline booking survives a simulated restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineSyncQueue(prefs: prefs);
      final ds = BookingRemoteDataSource(syncQueue: queue);

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

      // Restart: rebuild the store from the persisted JSON and read
      // through a brand-new data source + queue.
      final stored = prefs.getString(OfflineSyncQueue.queueKey)!;
      SharedPreferences.setMockInitialValues(
          {OfflineSyncQueue.queueKey: stored});
      final prefs2 = await SharedPreferences.getInstance();
      final queue2 = OfflineSyncQueue(prefs: prefs2);
      final ds2 = BookingRemoteDataSource(syncQueue: queue2);

      final readBack = await ds2.getBookingById(created.bookingId);
      expect(readBack, isNotNull);
      expect(readBack!.customerId, 'cust-1');
      expect(readBack.totalAmount, 9000);
    });
  });
}
