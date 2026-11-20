import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helper.dart';
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/views/payment_proof_upload_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

/// Item 8: the proof upload must behave like the vehicle-photo
/// upload — a real URL marks `payment_submitted`, a failed upload
/// never does. The old code called `updatePaymentProof` with an
/// empty URL after a failed upload and showed success anyway.

/// A fake HTTP client for the cPanel storage client: counts requests
/// and answers with a canned status/body (same shape as
/// offline_sync_test.dart).
class _FakeHttpClient extends http.BaseClient {
  int requests = 0;
  final int statusCode;
  final String body;

  _FakeHttpClient({
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

/// Records `updatePaymentProof` calls instead of touching Firestore:
/// the guard under test is whether the view calls it at all, and
/// with what URL.
class _FakeBookingDataSource extends BookingRemoteDataSource {
  final BookingEntity booking;
  int updatePaymentProofCalls = 0;
  String? lastProofUrl;
  String? lastTransactionId;

  _FakeBookingDataSource(this.booking);

  @override
  Future<BookingEntity> updatePaymentProof({
    required String bookingId,
    required String paymentProofUrl,
    required String transactionId,
  }) async {
    updatePaymentProofCalls++;
    lastProofUrl = paymentProofUrl;
    lastTransactionId = transactionId;
    return booking.copyWith(
      status: 'payment_submitted',
      paymentProofUrl: paymentProofUrl,
      transactionId: transactionId,
    );
  }
}

// A valid 1x1 transparent PNG, so the picked-file preview decodes.
const _pngBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

const _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');

BookingEntity _testBooking() => BookingEntity(
      bookingId: 'RH-849204',
      customerId: 'cust-1',
      shopId: 'shop-1',
      vehicleId: 'veh-1',
      vehicleName: 'Changan Alsvin Lumiere',
      packageType: '24h',
      pickupTime: DateTime.now(),
      returnTime: DateTime.now().add(const Duration(days: 1)),
      totalAmount: 5500,
      advanceRequired: 1500,
      remainingBalance: 4000,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File receiptFile;
  late _FakeBookingDataSource fakeDataSource;
  late MockImagePickerPlatform mockPicker;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('proof-upload-test');
    receiptFile = File('${tempDir.path}/receipt.png')
      ..writeAsBytesSync(_pngBytes);
    mockPicker = MockImagePickerPlatform.setup();
    mockPicker.mockResult = XFile(receiptFile.path);
    // QueuedUploads.store copies into the app documents dir; point
    // it at the temp dir in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel,
            (MethodCall call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });
    fakeDataSource = _FakeBookingDataSource(_testBooking());
    sl.registerSingleton<BookingRemoteDataSource>(fakeDataSource);
  });

  tearDown(() async {
    MockImagePickerPlatform.tearDown();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    await sl.reset();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<OfflineSyncQueue> registerQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineSyncQueue(prefs: prefs);
    sl.registerSingleton<OfflineSyncQueue>(queue);
    return queue;
  }

  void registerClient(_FakeHttpClient httpClient) {
    sl.registerSingleton<CPanelStorageClient>(
      CPanelStorageClient(apiSecretKey: 'test-secret', httpClient: httpClient),
    );
  }

  /// Pumps the view, picks the receipt from the gallery, enters the
  /// TID and taps submit. Returns the booking passed to
  /// `onProofSubmitted`, if any.
  Future<BookingEntity?> submitProof(WidgetTester tester) async {
    BookingEntity? submitted;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaymentProofUploadView(
          booking: _testBooking(),
          onProofSubmitted: (b) => submitted = b,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('From Gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Screenshot Ready'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'JAZZ-902189');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DebouncedButton));
    // The submit does real async work (dart:io file read inside
    // MultipartFile.fromPath, plus the queue file copy on the
    // failure path) that does not resolve under the fake clock —
    // runAsync is the documented escape hatch for exactly this
    // (see offline_sync_test.dart). Poll until an end state is
    // visible (success / queued / failure) or the bound is hit;
    // the button shows an indeterminate spinner while
    // _isSubmitting, so pumpAndSettle would spin forever, and the
    // snackbar is still up well inside its 3s duration.
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
          find.textContaining('will retry').evaluate().isNotEmpty ||
          find
              .text('Could not submit your payment proof. Please try again.')
              .evaluate()
              .isNotEmpty;
      if (done) break;
    }
    return submitted;
  }

  testWidgets('successful upload marks payment_submitted with the URL',
      (tester) async {
    final queue = await registerQueue();
    registerClient(_FakeHttpClient());

    final submitted = await submitProof(tester);

    expect(fakeDataSource.updatePaymentProofCalls, 1);
    expect(fakeDataSource.lastProofUrl, isNotNull);
    expect(fakeDataSource.lastProofUrl, isNotEmpty);
    expect(fakeDataSource.lastProofUrl, contains('media.php?key='));
    expect(fakeDataSource.lastProofUrl, contains('payments'));
    expect(fakeDataSource.lastTransactionId, 'JAZZ-902189');
    expect(submitted, isNotNull);
    expect(submitted?.status, 'payment_submitted');
    expect(submitted?.paymentProofUrl, fakeDataSource.lastProofUrl);
    expect(
        find.text('Proof submitted! Waiting for showroom confirmation.'),
        findsOneWidget);
    expect(find.textContaining('will retry'), findsNothing);
    expect(await queue.pendingCount, 0);
  });

  testWidgets(
      'failed upload with a queue does NOT mark payment_submitted and '
      'shows the queued/retry state, not success', (tester) async {
    final queue = await registerQueue();
    registerClient(_FakeHttpClient(statusCode: 500, body: 'error'));

    final submitted = await submitProof(tester);

    expect(fakeDataSource.updatePaymentProofCalls, 0);
    expect(submitted, isNull);
    expect(
        find.text('Proof submitted! Waiting for showroom confirmation.'),
        findsNothing);
    expect(
        find.text(
            'Receipt upload failed — saved on this device and will retry when you are back online. Your payment is not marked as submitted yet.'),
        findsOneWidget);
    // The receipt is queued for the drain: same target the working
    // car-image path uses, plus status + TID so the drain files
    // payment_submitted only once the real URL exists.
    expect(await queue.pendingCount, 1);
    final entry = (await queue.pendingEntries()).single;
    expect(entry.kind, 'upload');
    expect(entry.payload['folder'], 'payments');
    expect(entry.payload['targetCollection'], 'bookings');
    expect(entry.payload['targetDocId'], 'RH-849204');
    expect(entry.payload['targetField'], 'paymentProofUrl');
    expect(entry.payload['extra']['status'], 'payment_submitted');
    expect(entry.payload['extra']['transactionId'], 'JAZZ-902189');
  });

  testWidgets(
      'failed upload with no queue does NOT mark payment_submitted '
      'and shows the failure state', (tester) async {
    registerClient(_FakeHttpClient(statusCode: 500, body: 'error'));

    final submitted = await submitProof(tester);

    expect(fakeDataSource.updatePaymentProofCalls, 0);
    expect(submitted, isNull);
    expect(
        find.text('Proof submitted! Waiting for showroom confirmation.'),
        findsNothing);
    expect(find.textContaining('will retry'), findsNothing);
    expect(
        find.text('Could not submit your payment proof. Please try again.'),
        findsOneWidget);
  });
}
