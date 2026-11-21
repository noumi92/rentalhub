import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_payment_verification_view.dart';
import 'package:rentalhub/features/payments/presentation/cubit/payment_cubit.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

/// Item 8: fresh payment proofs did not display to the owner.
/// The live server probe (2026-11-21) showed the upload itself
/// works — POST /storage/upload.php returns 200 with
/// `payments/<32-hex>.png` — but EVERY media.php request answers
/// LiteSpeed 403 "Access to this resource on the server is denied!"
/// before PHP runs, so every signed proof URL is unviewable until
/// media.php is unblocked on cPanel. These tests pin the APP side
/// of the chain end to end (fake upload → stored key → signed URL
/// → owner viewer resolves it) and the two app-side breaks found
/// while tracing it:
/// 1. `uploadFile` returned '' on a 200 with no filename/URL, and
///    callers wrapped '' into a signed URL (`?key=&auth=…`) and
///    reported success — a `payment_submitted` with no viewable proof.
/// 2. the owner view passed the stored value raw to Image.network,
///    so a bare key (`payments/<file>`, filed by PaymentCubit) could
///    never display — a bare key is not a URL.

const _pngBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

/// Every network image in these tests answers with the 1px test PNG
/// (same pattern as audit_impl_finish_onboarding_fleet_test.dart).
class _PngHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _PngHttpClient();
}

class _PngHttpClient extends Fake implements HttpClient {
  // NetworkImage builds its client as `HttpClient()..autoUncompress
  // = false` — a Fake without this setter throws on the assignment
  // and every image load fails.
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _PngHttpRequest();
  @override
  void close({bool force = false}) {}
}

class _PngHttpRequest extends Fake implements HttpClientRequest {
  final HttpHeaders _headers = _PngHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  // NetworkImage may set these on the request; a Fake without them
  // throws and the image fails to load.
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;

  @override
  Future<HttpClientResponse> close() async => _PngHttpResponse();
}

class _PngHttpResponse extends Fake implements HttpClientResponse {
  static final List<int> _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _png.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _PngHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(_png).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

class _PngHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  ContentType? get contentType => ContentType('image', 'png');

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name] = <String>[value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    (_values[name] ??= <String>[]).add(value.toString());
  }

  @override
  List<String>? operator [](String name) => _values[name];

  @override
  String? value(String name) =>
      _values[name] == null || _values[name]!.isEmpty
          ? null
          : _values[name]!.first;

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {
    _values.remove(name);
  }

  @override
  void clear() {
    _values.clear();
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  void noFolding(String name) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('uploadFile empty-key hole', () {
    Future<File> tempPng() async {
      final file = File(
        '${Directory.systemTemp.path}/item8-test-${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(_pngBytes);
      return file;
    }

    test('a 200 with no filename or URL throws instead of returning empty',
        () async {
      final client = CPanelStorageClient(
        apiSecretKey: 'test-secret',
        httpClient: MockClient(
          (_) async => http.Response('{"success": true}', 200),
        ),
      );
      final file = await tempPng();
      await expectLater(
        client.uploadFile(file: file, userUid: 'u', folder: 'payments'),
        throwsA(isA<ServerException>()),
      );
      await file.delete();
    });

    test('a 200 with an empty filename throws', () async {
      final client = CPanelStorageClient(
        apiSecretKey: 'test-secret',
        httpClient: MockClient(
          (_) async => http.Response(
              jsonEncode({'success': true, 'filename': '', 'url': ''}), 200),
        ),
      );
      final file = await tempPng();
      await expectLater(
        client.uploadFile(file: file, userUid: 'u', folder: 'payments'),
        throwsA(isA<ServerException>()),
      );
      await file.delete();
    });
  });

  group('resolveStoredMediaUrl (owner display resolution)', () {
    CPanelStorageClient testClient() =>
        CPanelStorageClient(apiSecretKey: 'test-secret');

    test('a bare key becomes a signed media.php URL', () {
      final url = testClient().resolveStoredMediaUrl('payments/abc123.jpg');
      expect(url, startsWith(
          'https://rentalhub.62onlinestore.com/storage/media.php?key='));
      expect(Uri.parse(url).queryParameters['key'], 'payments/abc123.jpg');
      expect(Uri.parse(url).queryParameters.containsKey('auth'), isTrue);
    });

    test('a legacy public URL is left alone (it loads directly today)',
        () {
      const stored =
          'https://rentalhub.62onlinestore.com/storage/payments/abc123.jpg';
      expect(testClient().resolveStoredMediaUrl(stored), stored);
    });

    test('a stored signed URL is left alone (media.php has no expiry)',
        () {
      const stored =
          'https://rentalhub.62onlinestore.com/storage/media.php?key=payments%2Fabc123.jpg&auth=oldtoken';
      expect(testClient().resolveStoredMediaUrl(stored), stored);
    });

    test('a non-cPanel http URL passes through unchanged', () {
      const stored = 'https://example.com/proof.jpg';
      expect(testClient().resolveStoredMediaUrl(stored), stored);
    });

    test('blank resolves to empty (no-screenshot state, not a broken image)',
        () {
      expect(testClient().resolveStoredMediaUrl(''), '');
      expect(testClient().resolveStoredMediaUrl('   '), '');
    });
  });

  group('PaymentCubit stores a viewable URL, not the bare key', () {
    test('submitPaymentProof files the signed URL', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('item8-cubit-test');
      final receipt = File('${tempDir.path}/receipt.png')
        ..writeAsBytesSync(_pngBytes);
      final storage = CPanelStorageClient(
        apiSecretKey: 'test-secret',
        httpClient: MockClient(
          (_) async => http.Response(
              jsonEncode({
                'success': true,
                'url':
                    'https://rentalhub.62onlinestore.com/storage/payments/receipt-9f3.jpg',
                'filename': 'receipt-9f3.jpg',
                'category': 'payments',
              }),
              200),
        ),
      );
      final dataSource = BookingRemoteDataSource();
      final created = await dataSource.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        totalAmount: 5500,
        advanceRequired: 1500,
      );
      final cubit = PaymentCubit(
        storageClient: storage,
        bookingRepository: BookingRepositoryImpl(remoteDataSource: dataSource),
      );
      await cubit.submitPaymentProof(
        bookingId: created.bookingId,
        customerUid: 'cust-1',
        receiptScreenshot: receipt,
        transactionId: 'JAZZ-902189',
      );
      expect(cubit.state, isA<PaymentSubmittedSuccess>());
      final submitted =
          (cubit.state as PaymentSubmittedSuccess).booking;
      expect(submitted.status, 'payment_submitted');
      // The old code stored the bare key 'payments/receipt-9f3.jpg',
      // which Image.network cannot load. The stored value must be
      // the signed media.php URL.
      expect(submitted.paymentProofUrl, isNot('payments/receipt-9f3.jpg'));
      expect(submitted.paymentProofUrl, contains('media.php?key='));
      expect(submitted.paymentProofUrl, contains('payments'));
      await cubit.close();
      await tempDir.delete(recursive: true);
    });
  });

  group('owner view resolves a stored bare key end to end', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await di.initDependencies();
    });

    tearDownAll(() async {
      await di.sl.reset();
    });

    testWidgets('a bare-key proof renders as a signed media.php image',
        (tester) async {
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = _PngHttpOverrides();
      addTearDown(() => HttpOverrides.global = previousOverrides);

      // The booking as Firestore holds it when the proof was filed
      // as a bare key: no URL, just `payments/<file>`.
      final booking = BookingEntity(
        bookingId: 'RH-849204',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic Oriel',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        totalAmount: 5500,
        advanceRequired: 1500,
        remainingBalance: 5500,
        status: 'payment_submitted',
        paymentProofUrl: 'payments/abc123.jpg',
        transactionId: 'JAZZ-902189',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerPaymentVerificationView(booking: booking),
        ),
      );
      await tester.pump();
      // The proof image loads over real dart:io async work, which
      // does not resolve under the fake clock — runAsync is the
      // documented escape hatch (see payment_proof_upload_view_test).
      // pumpAndSettle would spin forever on the loading spinner
      // while the load is still in flight, so poll with bounded
      // pumps instead.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump(const Duration(milliseconds: 100));
        if (find
            .text('Proof image unavailable — ask the customer to resend it.')
            .evaluate()
            .isEmpty) {
          break;
        }
      }

      // Before the fix the viewer received the bare key verbatim —
      // Image.network cannot load 'payments/abc123.jpg', so the
      // owner saw "Proof unavailable". Now the rendered image must
      // be the signed media.php URL for that key.
      final imageUrls = tester
          .widgetList<Image>(find.byType(Image))
          .map((w) => w.image)
          .whereType<NetworkImage>()
          .map((n) => n.url)
          .toList();
      expect(
        imageUrls.any((u) =>
            u.contains('media.php?key=payments%2Fabc123.jpg') &&
            u.contains('auth=')),
        isTrue,
        reason: 'viewer image URLs were: $imageUrls',
      );
      expect(
          find.text('Proof image unavailable — ask the customer to resend it.'),
          findsNothing);
    });
  });
}
