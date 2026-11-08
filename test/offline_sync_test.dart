import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/core/data/sync_engine.dart';
import 'package:rentalhub/core/data/sync_status_cubit.dart';
import 'package:rentalhub/core/data/upload_sync_handler.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/network/connectivity_service.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/widgets/offline_banner.dart';
import 'package:rentalhub/features/settings/presentation/views/sync_details_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake HTTP client for the cPanel storage client: counts requests
/// and answers with a canned status/body.
class FakeHttpClient extends http.BaseClient {
  int requests = 0;
  final int statusCode;
  final String body;

  FakeHttpClient({
    this.statusCode = 200,
    this.body = '{"url": "payments/receipt-1.jpg"}',
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests++;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
    );
  }
}

Future<SharedPreferences> freshPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

ConnectivityService fakeConnectivity(
  StreamController<List<ConnectivityResult>> controller, {
  List<ConnectivityResult> initial = const [ConnectivityResult.none],
}) {
  return ConnectivityService(
    checkConnectivity: () async => initial,
    connectivityChanges: controller.stream,
    debounce: Duration.zero,
  );
}

void main() {
  group('ConnectivityService (B2)', () {
    test('offline → online emits exactly [false, true]', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final service = fakeConnectivity(controller);
      final seen = <bool>[];
      service.onlineStream.listen(seen.add);
      await service.start();
      await Future.delayed(const Duration(milliseconds: 20));
      controller.add([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(seen, [false, true]);
      expect(service.isOnline, isTrue);
      await service.dispose();
      await controller.close();
    });

    test('rapid flapping coalesces to the final state', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final service = fakeConnectivity(controller);
      final seen = <bool>[];
      service.onlineStream.listen(seen.add);
      await service.start();
      await Future.delayed(const Duration(milliseconds: 20));
      controller.add([ConnectivityResult.wifi]);
      controller.add([ConnectivityResult.none]);
      controller.add([ConnectivityResult.wifi]);
      controller.add([ConnectivityResult.none]);
      await Future.delayed(const Duration(milliseconds: 20));
      // One real transition (online → offline), not four.
      expect(seen, [false]);
      expect(service.isOnline, isFalse);
      await service.dispose();
      await controller.close();
    });

    test('plugin failure does not crash and assumes online', () async {
      final service = ConnectivityService(
        checkConnectivity: () async {
          throw Exception('no plugin');
        },
        connectivityChanges: const Stream.empty(),
        debounce: Duration.zero,
      );
      await service.start();
      expect(service.isOnline, isTrue);
      await service.dispose();
    });
  });

  group('OfflineSyncQueue (B3)', () {
    test('entries survive a simulated restart', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      await queue.enqueue(
        kind: 'booking_create',
        entityId: 'RH-1',
        payload: {'bookingId': 'RH-1', 'status': 'requested'},
      );
      // The entry lives in the prefs store, not in the queue object:
      // prove it by reading the raw stored JSON, then re-creating
      // the store from it (a restart) and reading through a new
      // queue instance.
      final stored = prefs.getString(OfflineSyncQueue.queueKey);
      expect(stored, isNotNull);
      SharedPreferences.setMockInitialValues(
          {OfflineSyncQueue.queueKey: stored!});
      final prefs2 = await SharedPreferences.getInstance();
      final queue2 = OfflineSyncQueue(prefs: prefs2);
      final entries = await queue2.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.entityId, 'RH-1');
    });

    test('the same work twice enqueues once (idempotency)', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      const payload = {'bookingId': 'RH-2', 'status': 'requested'};
      final first = await queue.enqueue(
          kind: 'booking_create', entityId: 'RH-2', payload: payload);
      final second = await queue.enqueue(
          kind: 'booking_create', entityId: 'RH-2', payload: payload);
      expect(first.id, second.id);
      expect(await queue.pendingCount, 1);
    });

    test('FIFO order is preserved', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      for (final id in ['e1', 'e2', 'e3']) {
        await queue.enqueue(
            kind: 'firestore_set', entityId: id, payload: {'docId': id});
      }
      final entries = await queue.pendingEntries();
      expect(entries.map((e) => e.entityId).toList(), ['e1', 'e2', 'e3']);
    });

    test('dedupeKey replace: a re-submitted file supersedes', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      await queue.enqueue(
        kind: 'upload',
        entityId: 'b1',
        payload: {'filePath': '/tmp/old.jpg'},
        dedupeKey: 'upload:b1:paymentProofUrl',
      );
      await queue.enqueue(
        kind: 'upload',
        entityId: 'b1',
        payload: {'filePath': '/tmp/new.jpg'},
        dedupeKey: 'upload:b1:paymentProofUrl',
        replaceExisting: true,
      );
      final entries = await queue.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.payload['filePath'], '/tmp/new.jpg');
    });
  });

  group('SyncEngine (B3)', () {
    test('drain syncs entries and removes them', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => true);
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await queue.enqueue(
          kind: 'test', entityId: 'b', payload: {'x': 2});
      expect(await engine.drain(), 2);
      expect(await queue.pendingCount, 0);
    });

    test('handler failure keeps the entry queued with backoff', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => false);
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      expect(await engine.drain(), 0);
      final entries = await queue.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.attempts, 1);
      expect(entries.first.nextRetryAt, isNotNull);
      expect(entries.first.nextRetryAt!.isAfter(DateTime.now()), isTrue);
    });

    test('five failures leave the entry queued and exhausted', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => false);
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      for (var i = 0; i < 5; i++) {
        await engine.drain();
        // Make the entry due again (backoff would otherwise skip it).
        final entry = (await queue.pendingEntries()).first;
        await queue.updateEntry(entry.copyWith(
          nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
        ));
      }
      final entries = await queue.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.attempts, 5);
      expect(entries.first.isExhausted, isTrue);
    });

    test('concurrent drains never overlap', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      final gate = Completer<void>();
      var calls = 0;
      engine.registerHandler('test', (_, __) async {
        calls++;
        await gate.future;
        return true;
      });
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      final first = engine.drain();
      final second = await engine.drain();
      expect(second, 0);
      gate.complete();
      expect(await first, 1);
      expect(calls, 1);
    });

    test('offline → online triggers exactly one drain', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      var calls = 0;
      engine.registerHandler('test', (_, __) async {
        calls++;
        return true;
      });
      final controller = StreamController<List<ConnectivityResult>>();
      final service = fakeConnectivity(controller);
      engine.startAutoSync(service);
      await service.start();
      await Future.delayed(const Duration(milliseconds: 20));
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      controller.add([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(calls, 1);
      expect(await queue.pendingCount, 0);
      await service.dispose();
      await controller.close();
    });

    test('entries with no handler are skipped, never removed', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      await queue.enqueue(
          kind: 'unknown-kind', entityId: 'a', payload: {'x': 1});
      expect(await engine.drain(), 0);
      expect(await queue.pendingCount, 1);
    });
  });

  group('UploadSyncHandler (B3)', () {
    test('upload-only entry syncs and is removed', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      final httpClient = FakeHttpClient();
      final handler = UploadSyncHandler(
        storageClient: CPanelStorageClient(
          apiSecretKey: 'test-secret',
          httpClient: httpClient,
        ),
      );
      engine.registerHandler('upload', handler.call);
      await queue.enqueue(
        kind: 'upload',
        entityId: 'b1',
        payload: {
          'fileB64': base64Encode(utf8.encode('receipt-bytes')),
          'fileName': 'receipt.jpg',
          'folder': 'payments',
          'userUid': 'u1',
        },
      );
      expect(await engine.drain(), 1);
      expect(httpClient.requests, 1);
      expect(await queue.pendingCount, 0);
    });

    test('retry after a partial success does not re-upload', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      final httpClient = FakeHttpClient();
      final handler = UploadSyncHandler(
        storageClient: CPanelStorageClient(
          apiSecretKey: 'test-secret',
          httpClient: httpClient,
        ),
      );
      engine.registerHandler('upload', handler.call);
      await queue.enqueue(
        kind: 'upload',
        entityId: 'b1',
        payload: {
          'fileB64': base64Encode(utf8.encode('receipt-bytes')),
          'fileName': 'receipt.jpg',
          'folder': 'payments',
          'userUid': 'u1',
          'targetCollection': 'bookings',
          'targetDocId': 'b1',
          'targetField': 'paymentProofUrl',
        },
      );
      // First drain: the upload succeeds (1 request) but there is no
      // Firestore in tests, so the doc write cannot confirm.
      expect(await engine.drain(), 0);
      expect(httpClient.requests, 1);
      var entries = await queue.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.result['remoteUrl'], isNotNull);
      // Second drain: the handler must resume from the stored URL,
      // not upload the file a second time.
      entries = await queue.pendingEntries();
      await queue.updateEntry(entries.first.copyWith(
        nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
      ));
      expect(await engine.drain(), 0);
      expect(httpClient.requests, 1);
    });

    test('upload failure keeps the entry queued', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      final httpClient = FakeHttpClient(statusCode: 500, body: 'error');
      final handler = UploadSyncHandler(
        storageClient: CPanelStorageClient(
          apiSecretKey: 'test-secret',
          httpClient: httpClient,
        ),
      );
      engine.registerHandler('upload', handler.call);
      await queue.enqueue(
        kind: 'upload',
        entityId: 'b1',
        payload: {
          'fileB64': base64Encode(utf8.encode('receipt-bytes')),
          'fileName': 'receipt.jpg',
          'folder': 'payments',
          'userUid': 'u1',
        },
      );
      expect(await engine.drain(), 0);
      final entries = await queue.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.attempts, 1);
    });
  });

  group('Phone-test #4 — exhausted entries are parked, not pending', () {
    Future<void> exhaust(
      SyncEngine engine,
      OfflineSyncQueue queue,
    ) async {
      for (var i = 0; i < 5; i++) {
        await engine.drain();
        final entry = (await queue.pendingEntries()).first;
        await queue.updateEntry(entry.copyWith(
          nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
        ));
      }
    }

    test('exhausted entries count as failed, not pending', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => false);
      final controller = StreamController<List<ConnectivityResult>>();
      final service = fakeConnectivity(controller,
          initial: const [ConnectivityResult.wifi]);
      final cubit = SyncStatusCubit(connectivity: service, queue: queue);
      await service.start();
      await cubit.start();
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await exhaust(engine, queue);
      await cubit.refresh();
      expect(cubit.state.pendingCount, 0);
      expect(cubit.state.failedCount, 1);
      expect(cubit.statusFor('a'), SyncEntryStatus.failed);
      await cubit.close();
      await service.dispose();
      await controller.close();
    });

    test('an exhausted entry is never retried again', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      var calls = 0;
      engine.registerHandler('test', (_, __) async {
        calls++;
        return false;
      });
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await exhaust(engine, queue);
      expect(calls, 5);
      // Three more drains (entry due again): the handler must not run.
      for (var i = 0; i < 3; i++) {
        final entry = (await queue.pendingEntries()).first;
        await queue.updateEntry(entry.copyWith(
          nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
        ));
        await engine.drain();
      }
      expect(calls, 5);
      expect(await queue.pendingCount, 1);
    });

    test('an entry with no handler is parked as failed, not skipped',
        () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      await queue.enqueue(
          kind: 'unknown-kind', entityId: 'a', payload: {'x': 1});
      expect(await engine.drain(), 0);
      var entries = await queue.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.attempts, 1);
      expect(entries.first.lastError, contains('No sync handler'));
      // Five drains park it as exhausted — still queued, still
      // visible, never silently dropped.
      for (var i = 0; i < 4; i++) {
        final entry = (await queue.pendingEntries()).first;
        await queue.updateEntry(entry.copyWith(
          nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
        ));
        await engine.drain();
      }
      entries = await queue.pendingEntries();
      expect(entries.length, 1);
      expect(entries.first.isExhausted, isTrue);
    });

    test('retry resets an exhausted entry and drains it', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => false);
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await exhaust(engine, queue);
      expect((await queue.pendingEntries()).first.isExhausted, isTrue);
      engine.registerHandler('test', (_, __) async => true);
      final entry = (await queue.pendingEntries()).first;
      await engine.retryEntry(entry);
      expect(await queue.pendingCount, 0);
    });

    test('an upload whose local file is gone is discarded, not retried',
        () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      final handler = UploadSyncHandler(
        storageClient: CPanelStorageClient(
          apiSecretKey: 'test-secret',
          httpClient: FakeHttpClient(),
        ),
      );
      engine.registerHandler('upload', handler.call);
      await queue.enqueue(
        kind: 'upload',
        entityId: 'b1',
        payload: {
          'filePath': '/definitely/not/here/receipt.jpg',
          'folder': 'payments',
          'userUid': 'u1',
        },
      );
      expect(await engine.drain(), 1);
      expect(await queue.pendingCount, 0);
    });

    testWidgets('banner shows the failed state for exhausted entries',
        (tester) async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => false);
      final controller = StreamController<List<ConnectivityResult>>();
      final service = fakeConnectivity(controller,
          initial: const [ConnectivityResult.wifi]);
      final cubit = SyncStatusCubit(connectivity: service, queue: queue);
      await service.start();
      await cubit.start();
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await exhaust(engine, queue);
      await cubit.refresh();

      await tester.pumpWidget(
        BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: const MaterialApp(
            home: Scaffold(body: OfflineBanner()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Sync failed — tap to review'), findsOneWidget);
      expect(find.textContaining('pending sync'), findsNothing);

      await tester.runAsync(() async {
        await cubit.close();
        await service.dispose();
        await controller.close();
      });
    });

    testWidgets('sync details lists entries with Retry now and Discard',
        (tester) async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => false);
      await sl.reset();
      sl.registerSingleton<OfflineSyncQueue>(queue);
      sl.registerSingleton<SyncEngine>(engine);
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await exhaust(engine, queue);
      // A succeeding handler, so Retry now actually clears the entry.
      engine.registerHandler('test', (_, __) async => true);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SyncDetailsView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sync details'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.textContaining('handler reported failure'),
          findsOneWidget);
      expect(find.text('Retry now'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      await tester.tap(find.text('Retry now'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing pending'), findsOneWidget);
      expect(await queue.pendingCount, 0);

      await tester.runAsync(() async {
        await sl.reset();
      });
    });

    testWidgets('sync details Discard removes the entry', (tester) async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      await sl.reset();
      sl.registerSingleton<OfflineSyncQueue>(queue);
      sl.registerSingleton<SyncEngine>(engine);
      await queue.enqueue(
          kind: 'test', entityId: 'b', payload: {'x': 1});

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SyncDetailsView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('b'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      // Audit §31: Discard now asks for confirmation first.
      expect(find.text('Discard this change?'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing pending'), findsOneWidget);
      expect(await queue.pendingCount, 0);

      await tester.runAsync(() async {
        await sl.reset();
      });
    });
  });

  group('SyncStatusCubit + OfflineBanner (B5)', () {
    test('pending count matches the queue length', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final controller = StreamController<List<ConnectivityResult>>();
      final service = fakeConnectivity(controller,
          initial: const [ConnectivityResult.wifi]);
      final cubit = SyncStatusCubit(connectivity: service, queue: queue);
      await service.start();
      await cubit.start();
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await queue.enqueue(
          kind: 'test', entityId: 'b', payload: {'x': 2});
      await cubit.refresh();
      expect(cubit.state.pendingCount, 2);
      expect(cubit.statusFor('a'), SyncEntryStatus.pending);
      expect(cubit.statusFor('missing'), SyncEntryStatus.synced);
      await cubit.close();
      await service.dispose();
      await controller.close();
    });

    test('an item flips Pending → Synced after a drain', () async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final engine = SyncEngine(queue: queue);
      engine.registerHandler('test', (_, __) async => true);
      final controller = StreamController<List<ConnectivityResult>>();
      final service = fakeConnectivity(controller,
          initial: const [ConnectivityResult.wifi]);
      final cubit = SyncStatusCubit(connectivity: service, queue: queue);
      await service.start();
      await cubit.start();
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await cubit.refresh();
      expect(cubit.statusFor('a'), SyncEntryStatus.pending);
      await engine.drain();
      await cubit.refresh();
      expect(cubit.statusFor('a'), SyncEntryStatus.synced);
      expect(cubit.state.pendingCount, 0);
      await cubit.close();
      await service.dispose();
      await controller.close();
    });

    testWidgets('banner appears offline and hides on reconnect',
        (tester) async {
      final prefs = await freshPrefs();
      final queue = OfflineSyncQueue(prefs: prefs);
      final controller = StreamController<List<ConnectivityResult>>();
      final service = fakeConnectivity(controller,
          initial: const [ConnectivityResult.wifi]);
      final cubit = SyncStatusCubit(connectivity: service, queue: queue);
      await service.start();
      await cubit.start();

      await tester.pumpWidget(
        BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: const MaterialApp(
            home: Scaffold(body: OfflineBanner()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining("You're offline"), findsNothing);

      controller.add([ConnectivityResult.none]);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining("You're offline"), findsOneWidget);

      controller.add([ConnectivityResult.wifi]);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining("You're offline"), findsNothing);

      // A queued entry while online shows the pending count.
      await queue.enqueue(
          kind: 'test', entityId: 'a', payload: {'x': 1});
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('1 change pending sync'), findsOneWidget);

      // Teardown under FakeAsync: stream cancel/close futures only
      // complete in the real async zone — awaiting them directly
      // hangs forever (and so does the fake-clock test timeout).
      // runAsync is the documented escape hatch for exactly this.
      await tester.runAsync(() async {
        await cubit.close();
        await service.dispose();
        await controller.close();
      });
    });
  });
}
