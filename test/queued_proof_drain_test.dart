import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/core/data/sync_engine.dart';
import 'package:rentalhub/core/data/sync_queue_entry.dart';
import 'package:rentalhub/core/data/upload_sync_handler.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fix 2 (2026-11-21, queued-proof drain race): a proof queued
/// while the booking was `approved` must not downgrade it on drain
/// once the booking has moved past payment. The drain used to
/// merge-set the queued `extra` map (`status: payment_submitted`)
/// straight into the booking doc — via the `upload` handler AND
/// via the `booking_update` handler — bypassing the
/// `updatePaymentProof` hard reject entirely. Both handlers now
/// re-check the booking's LIVE status at drain time and drop the
/// stale write when it is no longer awaiting verification.

class _FakeHttpClient extends http.BaseClient {
  int requests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests++;
    return http.StreamedResponse(
      Stream.value(utf8.encode('{"url": "payments/receipt-1.jpg"}')),
      200,
    );
  }
}

/// The queued `upload` entry exactly as
/// [PaymentProofUploadService.uploadProof] enqueues it on a failed
/// cPanel upload: the receipt bytes inline, the booking as target,
/// and `extra` carrying the status flip.
Map<String, dynamic> _proofPayload(String bookingId) => {
      'fileB64': base64Encode(utf8.encode('receipt-bytes')),
      'fileName': 'receipt.jpg',
      'folder': 'payments',
      'userUid': 'cust-1',
      'targetCollection': 'bookings',
      'targetDocId': bookingId,
      'targetField': 'paymentProofUrl',
      'extra': {
        'status': 'payment_submitted',
        'transactionId': 'TID-QUEUED',
        'proofSubmittedAt': DateTime.now().toIso8601String(),
      },
    };

void main() {
  group('UploadSyncHandler: queued payment proof at drain time', () {
    late FakeFirebaseFirestore fake;
    late OfflineSyncQueue queue;
    late SyncEngine engine;
    late _FakeHttpClient httpClient;

    setUp(() async {
      fake = FakeFirebaseFirestore();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      queue = OfflineSyncQueue(prefs: prefs);
      engine = SyncEngine(queue: queue);
      httpClient = _FakeHttpClient();
      engine.registerHandler(
        'upload',
        UploadSyncHandler(
          storageClient: CPanelStorageClient(
            apiSecretKey: 'test-secret',
            httpClient: httpClient,
          ),
          firestore: fake,
        ).call,
      );
    });

    Future<void> seedBooking(
      String bookingId,
      String status, {
      String? paymentProofUrl,
      String? transactionId,
    }) async {
      await fake.collection('bookings').doc(bookingId).set({
        'status': status,
        if (paymentProofUrl != null) 'paymentProofUrl': paymentProofUrl,
        if (transactionId != null) 'transactionId': transactionId,
      });
    }

    Future<Map<String, dynamic>?> doc(String bookingId) async {
      final snap =
          await fake.collection('bookings').doc(bookingId).get();
      return snap.data();
    }

    Future<void> queueProof(String bookingId) async {
      await queue.enqueue(
        kind: 'upload',
        entityId: bookingId,
        payload: _proofPayload(bookingId),
      );
    }

    for (final status in [
      'paid',
      'active',
      'completed',
      'cancelled',
      'disputed',
      'rejected',
    ]) {
      test(
          'queued while approved, now $status: drain drops the write '
          'and the booking stays $status', () async {
        // Queue while approved, then the booking moves on (e.g. the
        // payment is verified through another receipt).
        await seedBooking(
          'b1',
          'approved',
        );
        await queueProof('b1');
        await seedBooking(
          'b1',
          status,
          paymentProofUrl: 'https://example.com/verified-proof.jpg',
          transactionId: 'TID-VERIFIED',
        );

        expect(await engine.drain(), 1);
        expect(await queue.pendingCount, 0);

        final after = await doc('b1');
        expect(after?['status'], status);
        // The whole stale write is dropped — the verified proof
        // URL/TID are NOT overwritten by the queued receipt either.
        expect(after?['paymentProofUrl'],
            'https://example.com/verified-proof.jpg');
        expect(after?['transactionId'], 'TID-VERIFIED');
      });
    }

    test('still approved: drain applies payment_submitted as before',
        () async {
      await seedBooking('b1', 'approved');
      await queueProof('b1');

      expect(await engine.drain(), 1);
      expect(await queue.pendingCount, 0);
      expect(httpClient.requests, 1);

      final after = await doc('b1');
      expect(after?['status'], 'payment_submitted');
      expect(after?['paymentProofUrl'], contains('media.php?key='));
      expect(after?['transactionId'], 'TID-QUEUED');
      expect(after?['proofSubmittedAt'], isNotNull);
    });

    test('already payment_submitted (re-file): drain applies the '
        'new URL and keeps the status', () async {
      await seedBooking(
        'b1',
        'payment_submitted',
        paymentProofUrl: 'https://example.com/proof-old.jpg',
        transactionId: 'TID-OLD',
      );
      await queueProof('b1');

      expect(await engine.drain(), 1);

      final after = await doc('b1');
      expect(after?['status'], 'payment_submitted');
      expect(after?['paymentProofUrl'], contains('media.php?key='));
      expect(after?['transactionId'], 'TID-QUEUED');
    });

    test('booking doc missing: entry stays queued (retry), not '
        'dropped and not applied', () async {
      await queueProof('b1');

      expect(await engine.drain(), 0);
      expect(await queue.pendingCount, 1);

      final after = await doc('b1');
      expect(after, isNull);
    });

    test('a non-proof upload to a paid booking is unaffected: the '
        'URL lands, the status is untouched', () async {
      await seedBooking('b1', 'paid');
      await queue.enqueue(
        kind: 'upload',
        entityId: 'b1',
        payload: {
          'fileB64': base64Encode(utf8.encode('receipt-bytes')),
          'fileName': 'receipt.jpg',
          'folder': 'payments',
          'userUid': 'cust-1',
          'targetCollection': 'bookings',
          'targetDocId': 'b1',
          'targetField': 'paymentProofUrl',
          // No `extra.status` — not a proof submission.
        },
      );

      expect(await engine.drain(), 1);

      final after = await doc('b1');
      expect(after?['status'], 'paid');
      expect(after?['paymentProofUrl'], contains('media.php?key='));
    });
  });

  group('BookingRemoteDataSource.syncQueuedUpdate: queued proof', () {
    late FakeFirebaseFirestore fake;
    late BookingRemoteDataSource ds;
    late SyncEngine engine;

    setUp(() async {
      fake = FakeFirebaseFirestore();
      ds = BookingRemoteDataSource(firestore: fake);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      engine = SyncEngine(queue: OfflineSyncQueue(prefs: prefs));
    });

    SyncQueueEntry proofUpdate(String bookingId) =>
        SyncQueueEntry.create(
          kind: 'booking_update',
          entityId: bookingId,
          payload: {
            'fields': {
              'status': 'payment_submitted',
              'paymentProofUrl':
                  'https://example.com/queued-proof.jpg',
              'transactionId': 'TID-QUEUED',
              'proofSubmittedAt':
                  DateTime.now().toIso8601String(),
            },
          },
        );

    Future<Map<String, dynamic>?> doc(String bookingId) async {
      final snap =
          await fake.collection('bookings').doc(bookingId).get();
      return snap.data();
    }

    test('queued while approved, now paid: drain drops the write '
        'and the booking stays paid', () async {
      await fake.collection('bookings').doc('b1').set({
        'status': 'paid',
        'paymentProofUrl': 'https://example.com/verified-proof.jpg',
        'transactionId': 'TID-VERIFIED',
      });

      expect(await ds.syncQueuedUpdate(proofUpdate('b1'), engine),
          isTrue);

      final after = await doc('b1');
      expect(after?['status'], 'paid');
      expect(after?['paymentProofUrl'],
          'https://example.com/verified-proof.jpg');
      expect(after?['transactionId'], 'TID-VERIFIED');
    });

    for (final status in ['active', 'completed', 'cancelled']) {
      test('queued while approved, now $status: drain drops the '
          'write', () async {
        await fake.collection('bookings').doc('b1').set({
          'status': status,
        });

        expect(await ds.syncQueuedUpdate(proofUpdate('b1'), engine),
            isTrue);
        expect((await doc('b1'))?['status'], status);
        expect((await doc('b1'))?['paymentProofUrl'], isNull);
      });
    }

    test('still approved: drain applies payment_submitted as before',
        () async {
      await fake.collection('bookings').doc('b1').set({
        'status': 'approved',
      });

      expect(await ds.syncQueuedUpdate(proofUpdate('b1'), engine),
          isTrue);

      final after = await doc('b1');
      expect(after?['status'], 'payment_submitted');
      expect(after?['paymentProofUrl'],
          'https://example.com/queued-proof.jpg');
      expect(after?['transactionId'], 'TID-QUEUED');
    });

    test('booking doc missing: returns false so the entry stays '
        'queued', () async {
      expect(await ds.syncQueuedUpdate(proofUpdate('b1'), engine),
          isFalse);
    });

    test('a non-proof queued update is unaffected', () async {
      await fake.collection('bookings').doc('b1').set({
        'status': 'approved',
      });
      final entry = SyncQueueEntry.create(
        kind: 'booking_update',
        entityId: 'b1',
        payload: {
          'fields': {'status': 'cancelled'},
        },
      );

      expect(await ds.syncQueuedUpdate(entry, engine), isTrue);
      expect((await doc('b1'))?['status'], 'cancelled');
    });
  });
}
