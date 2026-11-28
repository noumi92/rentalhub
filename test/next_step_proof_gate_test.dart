import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helper.dart';
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/domain/repositories/booking_repository.dart';
import 'package:rentalhub/features/bookings/presentation/services/payment_proof_upload_service.dart';
import 'package:rentalhub/features/bookings/presentation/views/owner_payment_accounts_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/payment_proof_upload_view.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/approved_accounts_body.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_summary_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_payment_verification_view.dart';
import 'package:rentalhub/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

/// Next-step batch (2026-11-21), Worker A: the proof prompt is gated
/// on `approved` and a (re-)submitted proof can never downgrade a
/// booking that is already past payment. The guards live at four
/// layers — data source (hard reject), upload service, cubit and the
/// upload view (submit-time) — and the owner detail route / accounts
/// view branch on status instead of sending everything past
/// `payment_submitted` to the accounts screen.

BookingEntity _booking({
  String status = 'approved',
  int advancePaid = 0,
  String shopId = 'shop-1',
  String customerName = 'Ayesha Khan',
}) =>
    BookingEntity(
      bookingId: 'RH-nextstep-1',
      customerId: 'cust-1',
      shopId: shopId,
      vehicleId: 'veh-1',
      vehicleName: 'Honda Civic Oriel',
      vehiclePlate: 'LEA-23-4567',
      packageType: '24h',
      pickupTime: DateTime(2026, 11, 22, 9),
      returnTime: DateTime(2026, 11, 23, 9),
      totalAmount: 9000,
      advanceRequired: 3000,
      advancePaid: advancePaid,
      remainingBalance: 9000 - advancePaid,
      status: status,
      customerName: customerName,
      customerPhone: '0300-1111111',
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

// ------------------------------------------------------------------
// 1. Data source: updatePaymentProof hard-rejects past-payment.
// ------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('updatePaymentProof downgrade guard (data source)', () {
    Future<BookingEntity> bookingInState(
        BookingRemoteDataSource ds, String status) async {
      final created = await ds.createBookingRequest(
        customerId: 'cust-guard',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 22, 9),
        returnTime: DateTime(2026, 11, 23, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Guard Case',
      );
      if (status == 'paid') {
        await ds.updateBookingStatus(
            bookingId: created.bookingId, status: 'approved');
        await ds.updatePaymentProof(
          bookingId: created.bookingId,
          paymentProofUrl: 'https://example.com/proof.jpg',
          transactionId: 'TID-1',
        );
        return ds.verifyPayment(
            bookingId: created.bookingId, advanceAmount: 3000);
      }
      if (status == 'requested') return created;
      return ds.updateBookingStatus(
          bookingId: created.bookingId, status: status);
    }

    for (final status in ['paid', 'active', 'completed', 'cancelled']) {
      test('refuses a proof for a $status booking and leaves it $status',
          () async {
        final ds = BookingRemoteDataSource();
        final booking = await bookingInState(ds, status);
        expect(booking.status, status);

        await expectLater(
          ds.updatePaymentProof(
            bookingId: booking.bookingId,
            paymentProofUrl: 'https://example.com/proof-late.jpg',
            transactionId: 'TID-LATE',
          ),
          throwsStateError,
        );
        final after = await ds.getBookingById(booking.bookingId);
        expect(after?.status, status);
      });
    }

    test('approved still accepts a proof', () async {
      final ds = BookingRemoteDataSource();
      final booking = await bookingInState(ds, 'approved');
      final proofed = await ds.updatePaymentProof(
        bookingId: booking.bookingId,
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-2',
      );
      expect(proofed.status, 'payment_submitted');
    });

    test('requested is NOT in the guard list (open user question)',
        () async {
      final ds = BookingRemoteDataSource();
      final booking = await bookingInState(ds, 'requested');
      final proofed = await ds.updatePaymentProof(
        bookingId: booking.bookingId,
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-3',
      );
      expect(proofed.status, 'payment_submitted');
    });

    test('a proof can still be re-filed while awaiting verification',
        () async {
      final ds = BookingRemoteDataSource();
      final booking = await bookingInState(ds, 'approved');
      final first = await ds.updatePaymentProof(
        bookingId: booking.bookingId,
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-4',
      );
      expect(first.status, 'payment_submitted');
      final second = await ds.updatePaymentProof(
        bookingId: booking.bookingId,
        paymentProofUrl: 'https://example.com/proof2.jpg',
        transactionId: 'TID-5',
      );
      expect(second.status, 'payment_submitted');
      expect(second.paymentProofUrl, 'https://example.com/proof2.jpg');
    });
  });

  // ----------------------------------------------------------------
  // 2. Upload service: refuses past-payment before any upload/queue.
  // ----------------------------------------------------------------

  group('PaymentProofUploadService guard', () {
    late Directory tempDir;
    late File receiptFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nextstep-service');
      receiptFile = File('${tempDir.path}/receipt.png')
        ..writeAsBytesSync(_pngBytes);
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('paid booking: no upload attempt, no queue entry', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final queue = OfflineSyncQueue(prefs: prefs);
      final httpClient = _FakeHttpClient();
      final client = CPanelStorageClient(
          apiSecretKey: 'test-secret', httpClient: httpClient);

      final result = await PaymentProofUploadService.uploadProof(
        client: client,
        file: receiptFile,
        customerId: 'cust-1',
        bookingId: 'RH-nextstep-1',
        transactionId: 'TID-9',
        queue: queue,
        bookingStatus: 'paid',
      );

      expect(result.status, PaymentProofUploadStatus.failed);
      expect(result.proofUrl, isNull);
      expect(httpClient.requests, 0);
      expect(await queue.pendingCount, 0);
    });

    test('approved booking: uploads normally', () async {
      final httpClient = _FakeHttpClient();
      final client = CPanelStorageClient(
          apiSecretKey: 'test-secret', httpClient: httpClient);

      final result = await PaymentProofUploadService.uploadProof(
        client: client,
        file: receiptFile,
        customerId: 'cust-1',
        bookingId: 'RH-nextstep-1',
        transactionId: 'TID-9',
        bookingStatus: 'approved',
      );

      expect(result.status, PaymentProofUploadStatus.uploaded);
      expect(result.proofUrl, contains('media.php?key='));
      expect(httpClient.requests, greaterThan(0));
    });
  });

  // ----------------------------------------------------------------
  // 3. Cubit: refuses past-payment before any receipt upload.
  // ----------------------------------------------------------------

  group('PaymentCubit guard', () {
    late Directory tempDir;
    late File receiptFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nextstep-cubit');
      receiptFile = File('${tempDir.path}/receipt.png')
        ..writeAsBytesSync(_pngBytes);
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    PaymentCubit cubitWith(_GuardRepo repo) => PaymentCubit(
          storageClient: CPanelStorageClient(
              apiSecretKey: 'test-secret', httpClient: _FakeHttpClient()),
          bookingRepository: repo,
        );

    for (final status in ['paid', 'active', 'completed', 'cancelled']) {
      test('submitPaymentProof with currentStatus $status errors '
          'without touching the repository', () async {
        final repo = _GuardRepo(_booking(status: status));
        final cubit = cubitWith(repo);

        await cubit.submitPaymentProof(
          bookingId: 'RH-nextstep-1',
          customerUid: 'cust-1',
          receiptScreenshot: receiptFile,
          transactionId: 'TID-9',
          currentStatus: status,
        );

        expect(cubit.state, isA<PaymentError>());
        expect(repo.updatePaymentProofCalls, 0);
      });
    }

    test('approved with a receipt files the signed URL', () async {
      final repo = _GuardRepo(_booking());
      final cubit = cubitWith(repo);

      await cubit.submitPaymentProof(
        bookingId: 'RH-nextstep-1',
        customerUid: 'cust-1',
        receiptScreenshot: receiptFile,
        transactionId: 'TID-9',
        currentStatus: 'approved',
      );

      expect(cubit.state, isA<PaymentSubmittedSuccess>());
      expect(repo.updatePaymentProofCalls, 1);
      expect(repo.lastProofUrl, contains('media.php?key='));
    });
  });

  // ----------------------------------------------------------------
  // 4. OwnerPaymentAccountsView gating (defence in depth).
  // ----------------------------------------------------------------

  group('OwnerPaymentAccountsView status gating', () {
    testWidgets('approved with a partial advance still shows the '
        'Upload Proof CTA', (tester) async {
      await tester.pumpWidget(_wrap(OwnerPaymentAccountsView(
        booking: _booking(advancePaid: 1000),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Upload Payment Proof & Receipt'), findsOneWidget);
    });

    testWidgets('paid booking (no signed-in owner) shows the read-only '
        'summary, never the CTA', (tester) async {
      await tester.pumpWidget(_wrap(OwnerPaymentAccountsView(
        booking: _booking(status: 'paid', advancePaid: 3000),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.text('Upload Payment Proof & Receipt'), findsNothing);
      expect(find.text('Start Handover'), findsNothing);
    });

    testWidgets('active booking shows the read-only summary, never the '
        'CTA', (tester) async {
      await tester.pumpWidget(_wrap(OwnerPaymentAccountsView(
        booking: _booking(status: 'active', advancePaid: 3000),
      )));
      await tester.pumpAndSettle();
      expect(find.text('On trip'), findsOneWidget);
      expect(find.text('Upload Payment Proof & Receipt'), findsNothing);
    });

    testWidgets('disputed booking shows the summary with the '
        'View / Resolve Dispute step', (tester) async {
      await tester.pumpWidget(_wrap(OwnerPaymentAccountsView(
        booking: _booking(status: 'disputed', advancePaid: 3000),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Disputed'), findsOneWidget);
      expect(find.text('View / Resolve Dispute'), findsOneWidget);
      expect(find.text('Upload Payment Proof & Receipt'), findsNothing);
    });

    testWidgets('completed booking shows the summary with the '
        'Rate customer step', (tester) async {
      await tester.pumpWidget(_wrap(OwnerPaymentAccountsView(
        booking: _booking(status: 'completed', advancePaid: 3000),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Rate customer'), findsOneWidget);
      expect(find.text('View / Resolve Dispute'), findsNothing);
      expect(find.text('Upload Payment Proof & Receipt'), findsNothing);
    });

    testWidgets('requested booking without a signed-in owner shows '
        'the summary without Approve/Reject (default deny)', (tester) async {
      await tester.pumpWidget(_wrap(OwnerPaymentAccountsView(
        booking: _booking(status: 'requested'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Upload Payment Proof & Receipt'), findsNothing);
    });

    testWidgets('paid booking for the rightful owner opens the '
        'Confirmed view', (tester) async {
      await sl.reset();
      SharedPreferences.setMockInitialValues(
          {'rentalhub_locked_role': 'owner'});
      final prefs = await SharedPreferences.getInstance();
      sl.registerSingleton<AuthRemoteDataSource>(
          AuthRemoteDataSource(prefs: prefs));
      final fake = FakeFirebaseFirestore();
      await fake.collection('shops').doc('shop_shop-1').set({
        'owner_id': 'shop-1',
        'shop_id': 'shop_shop-1',
        'shop_name': 'Al-Falah Rent a Car',
      });
      addTearDown(() async => sl.reset());

      await tester.pumpWidget(_wrap(OwnerPaymentAccountsView(
        booking: _booking(
            status: 'paid', advancePaid: 3000, shopId: 'shop_shop-1'),
        firestore: fake,
      )));
      await tester.pumpAndSettle();
      expect(find.text('Start Handover'), findsOneWidget);
      expect(find.text('Upload Payment Proof & Receipt'), findsNothing);
    });

    testWidgets('ApprovedAccountsBody on its own hides the CTA for a '
        'paid booking', (tester) async {
      await tester.pumpWidget(_wrap(ApprovedAccountsBody(
        booking: _booking(status: 'paid', advancePaid: 3000),
        onProceedToUploadProof: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Upload Payment Proof & Receipt'), findsNothing);
    });

    testWidgets('the summary view never renders a handover button, '
        'even for a paid booking', (tester) async {
      await tester.pumpWidget(_wrap(OwnerBookingSummaryView(
        booking: _booking(status: 'paid', advancePaid: 3000),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Start Handover'), findsNothing);
      expect(find.text('View / Resolve Dispute'), findsNothing);
    });
  });

  // ----------------------------------------------------------------
  // 5. Router: ownerRequestsDetail branches on status (source check,
  //    same pattern as owner_phase_d_bookings_test.dart).
  // ----------------------------------------------------------------

  group('ownerRequestsDetail routing', () {
    test('payment_submitted -> verification, all other statuses -> unified detail',
        () async {
      final router =
          await File('lib/core/routing/app_router.dart').readAsString();
      final start = router.indexOf('ownerRequestsDetail');
      final end = router.indexOf('ownerPaymentProof', start);
      final branch = router.substring(start, end);
      expect(branch, contains('OwnerPaymentVerificationView'));
      expect(branch, contains("'payment_submitted'"));
      expect(branch, contains('OwnerBookingDetailView'));
      expect(branch, isNot(contains('booking-confirmed')));
    });
  });

  // ----------------------------------------------------------------
  // 6. Verify Confirm / Reject land on All Bookings.
  // ----------------------------------------------------------------

  group('OwnerPaymentVerificationView save navigation', () {
    late _FakeVerifyDataSource fakeDs;
    late GoRouter router;

    setUp(() async {
      await sl.reset();
      fakeDs = _FakeVerifyDataSource();
      sl.registerSingleton<BookingRemoteDataSource>(fakeDs);
      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                OwnerPaymentVerificationView(booking: _submittedBooking()),
          ),
          GoRoute(
            path: '/owner/requests',
            builder: (context, state) => Scaffold(
              body: Text(
                  'ALL filter=${state.uri.queryParameters['filter']}'),
            ),
          ),
        ],
      );
    });

    tearDown(() async => sl.reset());

    Future<void> pumpVerification(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('Confirm goes to All Bookings (?filter=all)',
        (tester) async {
      await pumpVerification(tester);
      // The Confirm button sits below the fold in the 800x600
      // test viewport — scroll it into view before tapping.
      await tester.ensureVisible(find.byType(DebouncedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DebouncedButton));
      await tester.pumpAndSettle();

      expect(fakeDs.verifyCalls, 1);
      expect(find.text('ALL filter=all'), findsOneWidget);
    });

    testWidgets('Reject goes to All Bookings (?filter=all)',
        (tester) async {
      await pumpVerification(tester);
      final rejectButton =
          find.widgetWithText(OutlinedButton, 'Payment Not Received');
      await tester.ensureVisible(rejectButton);
      await tester.pumpAndSettle();
      await tester.tap(rejectButton);
      await tester.pumpAndSettle();
      // The rejection dialog: enter a reason, confirm.
      await tester.enterText(find.byType(TextField).last, 'Unreadable');
      await tester.tap(
          find.widgetWithText(FilledButton, 'Payment Not Received'));
      await tester.pumpAndSettle();

      expect(fakeDs.rejectCalls, 1);
      expect(find.text('ALL filter=all'), findsOneWidget);
    });
  });

  // ----------------------------------------------------------------
  // 7. PaymentProofUploadView: submit-time guard + owner landing.
  // ----------------------------------------------------------------

  group('PaymentProofUploadView submit-time guard and owner landing',
      () {
    late Directory tempDir;
    late File receiptFile;
    late _FakeProofDataSource fakeDataSource;
    late MockImagePickerPlatform mockPicker;

    const pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');

    setUp(() async {
      await sl.reset();
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('nextstep-upload');
      receiptFile = File('${tempDir.path}/receipt.png')
        ..writeAsBytesSync(_pngBytes);
      mockPicker = MockImagePickerPlatform.setup();
      mockPicker.mockResult = XFile(receiptFile.path);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel,
              (MethodCall call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      });
      fakeDataSource = _FakeProofDataSource(_booking());
      sl.registerSingleton<BookingRemoteDataSource>(fakeDataSource);
    });

    tearDown(() async {
      MockImagePickerPlatform.tearDown();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
      await sl.reset();
      try {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    void registerClient(_FakeHttpClient httpClient) {
      sl.registerSingleton<CPanelStorageClient>(
        CPanelStorageClient(
            apiSecretKey: 'test-secret', httpClient: httpClient),
      );
    }

    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.tap(find.text('From Gallery'));
      await tester.pumpAndSettle();
      expect(find.text('Screenshot Ready'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'JAZZ-902189');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DebouncedButton));
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump(const Duration(milliseconds: 100));
        final done = fakeDataSource.updatePaymentProofCalls > 0 ||
            find
                .text('Proof submitted! Waiting for showroom confirmation.')
                .evaluate()
                .isNotEmpty ||
            find
                .text(
                    'Could not submit your payment proof. Please try again.')
                .evaluate()
                .isNotEmpty ||
            find.textContaining('ALL filter=').evaluate().isNotEmpty;
        if (done) break;
      }
    }

    testWidgets('a paid booking is refused at submit time: no '
        'updatePaymentProof call, no upload', (tester) async {
      final queue = OfflineSyncQueue(
          prefs: await SharedPreferences.getInstance());
      sl.registerSingleton<OfflineSyncQueue>(queue);
      registerClient(_FakeHttpClient());

      await tester.pumpWidget(_wrap(PaymentProofUploadView(
        booking: _booking(status: 'paid', advancePaid: 3000),
      )));
      await tester.pumpAndSettle();
      await fillAndSubmit(tester);

      expect(fakeDataSource.updatePaymentProofCalls, 0);
      expect(
          find.text('Could not submit your payment proof. Please try again.'),
          findsOneWidget);
      expect(await queue.pendingCount, 0);
    });

    testWidgets('owner submit with no callback lands on All Bookings',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {'rentalhub_locked_role': 'owner'});
      final prefs = await SharedPreferences.getInstance();
      sl.registerSingleton<AuthRemoteDataSource>(
          AuthRemoteDataSource(prefs: prefs));
      final queue = OfflineSyncQueue(prefs: prefs);
      sl.registerSingleton<OfflineSyncQueue>(queue);
      registerClient(_FakeHttpClient());

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                PaymentProofUploadView(booking: _booking()),
          ),
          GoRoute(
            path: '/owner/requests',
            builder: (context, state) => Scaffold(
              body: Text(
                  'ALL filter=${state.uri.queryParameters['filter']}'),
            ),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      await fillAndSubmit(tester);

      expect(fakeDataSource.updatePaymentProofCalls, 1);
      expect(find.text('ALL filter=all'), findsOneWidget);
    });
  });
}

/// A valid 1x1 transparent PNG, so the picked-file preview decodes.
const _pngBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

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

/// Records `updatePaymentProof` calls instead of touching Firestore.
class _FakeProofDataSource extends BookingRemoteDataSource {
  final BookingEntity booking;
  int updatePaymentProofCalls = 0;

  _FakeProofDataSource(this.booking);

  @override
  Future<BookingEntity> updatePaymentProof({
    required String bookingId,
    required String paymentProofUrl,
    required String transactionId,
  }) async {
    updatePaymentProofCalls++;
    return booking.copyWith(
      status: 'payment_submitted',
      paymentProofUrl: paymentProofUrl,
      transactionId: transactionId,
    );
  }
}

/// Records verify / reject calls for the verification-view tests.
class _FakeVerifyDataSource extends BookingRemoteDataSource {
  int verifyCalls = 0;
  int rejectCalls = 0;

  @override
  Future<BookingEntity> verifyPayment({
    required String bookingId,
    required int advanceAmount,
  }) async {
    verifyCalls++;
    return _submittedBooking()
        .copyWith(status: 'paid', advancePaid: advanceAmount);
  }

  @override
  Future<BookingEntity> rejectPaymentProof({
    required String bookingId,
    required String reason,
  }) async {
    rejectCalls++;
    return _submittedBooking()
        .copyWith(status: 'approved', rejectionReason: reason);
  }
}

BookingEntity _submittedBooking() => _booking(
      status: 'payment_submitted',
      advancePaid: 0,
    );

/// A [BookingRepository] that records `updatePaymentProof` calls and
/// refuses everything else — the cubit guard test fails loudly if
/// the repository is reached at all for a past-payment booking.
class _GuardRepo implements BookingRepository {
  final BookingEntity booking;
  int updatePaymentProofCalls = 0;
  String? lastProofUrl;

  _GuardRepo(this.booking);

  @override
  Future<BookingEntity> updatePaymentProof({
    required String bookingId,
    required String paymentProofUrl,
    required String transactionId,
  }) async {
    updatePaymentProofCalls++;
    lastProofUrl = paymentProofUrl;
    return booking.copyWith(
      status: 'payment_submitted',
      paymentProofUrl: paymentProofUrl,
      transactionId: transactionId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
