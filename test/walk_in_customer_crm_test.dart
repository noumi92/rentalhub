// Walk-in customer CRM (2026-11-21): detail-screen actions by
// source, Block/Unblock/Archive writes, wizard edit mode (prefill
// + identity preservation) and KYC slot replace. Widget tests only.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_customer_saver.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_media_upload_service.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_slot_replace_service.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_add_customer_wizard.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_kyc_slots.dart';
import 'package:rentalhub/features/trust/data/services/cnic_ocr_service.dart';
import 'package:rentalhub/features/trust/utils/cnic_text_parser.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

import 'test_helper.dart';

const _face = 'https://example.invalid/kyc/face.jpg';
const _fingerL = 'https://example.invalid/kyc/finger-left.jpg';
const _fingerR = 'https://example.invalid/kyc/finger-right.jpg';
const _licFront = 'https://example.invalid/kyc/lic-front.jpg';
const _licBack = 'https://example.invalid/kyc/lic-back.jpg';
const _bill = 'https://example.invalid/kyc/bill.jpg';
const _signature = 'https://example.invalid/kyc/signature.png';

CustomerEntity _fullWalkIn({
  required String id,
  required String shopId,
  String name = 'Ayesha Khan',
  String cnic = '35202-9999999-9',
  String approvalStatus = 'approved',
  DateTime? createdAt,
}) =>
    CustomerEntity(
      customerId: id,
      shopId: shopId,
      name: name,
      phone: '0300-9999999',
      cnic: cnic,
      source: 'walk_in',
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 10)),
      profilePhotoUrl: _face,
      leftFingerprintUrl: _fingerL,
      rightFingerprintUrl: _fingerR,
      licenseNumber: 'LHR-1234567',
      licenseExpiry: '01.01.2030',
      licenseFrontUrl: _licFront,
      licenseBackUrl: _licBack,
      utilityBillUrl: _bill,
      signatureUrl: _signature,
      approvalStatus: approvalStatus,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockImagePickerPlatform mockPicker;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    if (di.sl.isRegistered<KycMediaUploadService>()) {
      di.sl.unregister<KycMediaUploadService>();
    }
    di.sl.registerSingleton<KycMediaUploadService>(_FakeUploader());
  });

  setUp(() {
    mockPicker = MockImagePickerPlatform.setup();
    mockPicker.mockResult = XFile('test/assets/mock_selfie.jpg');
  });

  tearDown(() {
    MockImagePickerPlatform.tearDown();
  });

  Future<CustomerRemoteDataSource> customers() async =>
      di.sl<CustomerRemoteDataSource>();
  Future<BookingRemoteDataSource> bookings() async =>
      di.sl<BookingRemoteDataSource>();

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  Future<void> seedBooking({
    required String customerId,
    required String shopId,
    required DateTime pickup,
  }) async {
    await (await bookings()).createBookingRequest(
      customerId: customerId,
      shopId: shopId,
      vehicleId: 'veh-1',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: pickup,
      returnTime: pickup.add(const Duration(days: 1)),
      totalAmount: 9000,
      advanceRequired: 1000,
      customerName: 'Ayesha Khan',
      customerPhone: '0300-9999999',
      customerCnic: '35202-9999999-9',
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required String customerId,
    required String shopId,
    KycSlotReplaceService? replacer,
  }) async {
    // Distinct key per customer: without it the framework reuses
    // the previous detail view's State (same type, no key) and the
    // new customer shows the old customer's data (_load only runs
    // in initState).
    await tester.pumpWidget(wrap(OwnerCustomerDetailView(
      key: ValueKey(customerId),
      customerId: customerId,
      shopId: shopId,
      replacer: replacer,
    )));
    await tester.pumpAndSettle();
  }

  group('derived statuses', () {
    test('statusForShop defaults to active and reads stored entries', () {
      final e = CustomerEntity(
        customerId: 'c1',
        shopId: 'shop-1',
        name: 'A',
        phone: '0300-1',
        createdAt: _created,
        shopStatuses: {'shop-1': 'blocked', 'shop-2': 'archived'},
      );
      expect(e.statusForShop('shop-9'), 'active');
      expect(e.statusForShop('shop-1'), 'blocked');
      expect(e.statusForShop('shop-2'), 'archived');
      // Bare UID reads the doc-id entry too.
      expect(
        CustomerEntity(
          customerId: 'c2',
          shopId: 'shop-1',
          name: 'A',
          phone: '0300-1',
          createdAt: _created,
          shopStatuses: {'shop_abc': 'blocked'},
        ).statusForShop('abc'),
        'blocked',
      );
    });

    test('isKycCompleteForEntity needs the full slot set', () {
      final full = _fullWalkIn(id: 'c-full', shopId: 'shop-1');
      expect(isKycCompleteForEntity(full), isTrue);
      expect(
        isKycCompleteForEntity(_fullWalkIn(
          id: 'c-nolic',
          shopId: 'shop-1',
        ).copyWith(licenseNumber: '')),
        isFalse,
      );
    });

    test('customerWithSlotUrl replaces one slot and never the CNIC', () {
      final base = _fullWalkIn(id: 'c-slot', shopId: 'shop-1');
      const newFace = 'https://cdn.example/kyc/new-face.jpg';
      final updated = customerWithSlotUrl(base, 'profilePhotoUrl', newFace);
      expect(updated.profilePhotoUrl, newFace);
      expect(updated.cnic, base.cnic);
      expect(updated.customerId, base.customerId);
      expect(updated.licenseFrontUrl, base.licenseFrontUrl);
      final withExtra = customerWithSlotUrl(
          base, 'extraDocumentUrls', 'https://cdn.example/kyc/extra.jpg');
      expect(withExtra.extraDocumentUrls,
          ['https://cdn.example/kyc/extra.jpg']);
    });

    test('KycDraft.fromEntity prefills and counts on-file media', () {
      final entity = _fullWalkIn(id: 'c-draft', shopId: 'shop-1');
      final draft = KycDraft.fromEntity(entity);
      expect(draft.name, 'Ayesha Khan');
      expect(draft.cnic, '35202-9999999-9');
      expect(draft.licenseNumber, 'LHR-1234567');
      expect(draft.phone, '0300-9999999');
      expect(draft.termsAgreed, isTrue);
      expect(draft.hasFacePhoto, isTrue);
      expect(draft.hasLeftFingerprints, isTrue);
      expect(draft.hasRightFingerprints, isTrue);
      expect(draft.hasLicenseFront, isTrue);
      expect(draft.hasLicenseBack, isTrue);
      expect(draft.hasUtilityBill, isTrue);
      expect(draft.hasSignature, isTrue);
      expect(draft.existingUrlFor('profilePhotoUrl'), _face);
      // Removing the on-file photo clears it from the draft.
      draft.clearExisting('profilePhotoUrl');
      expect(draft.hasFacePhoto, isFalse);
    });
  });

  group('detail actions by source', () {
    testWidgets('walk-in shows Block/Edit/Archive, no Approve/Reject',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-crm-w1',
        shopId: 'shop-crm-1',
        name: 'Ayesha Khan',
        phone: '0300-9999999',
        cnic: '35202-9999999-9',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ));
      await pumpDetail(tester,
          customerId: 'cust-crm-w1', shopId: 'shop-crm-1');

      expect(find.text('Block'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Approve profile'), findsNothing);
      expect(find.text('Reject profile'), findsNothing);
      // Derived chips: active + KYC incomplete (no media on file).
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('KYC Incomplete'), findsOneWidget);
    });

    testWidgets('online keeps Approve/Reject + Block, no Edit/Archive',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-crm-o1',
        shopId: 'shop-crm-1',
        name: 'Online Omar',
        phone: '0300-8888888',
        cnic: '35202-8888888-8',
        source: 'online',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ));
      await pumpDetail(tester,
          customerId: 'cust-crm-o1', shopId: 'shop-crm-1');

      expect(find.text('Approve profile'), findsOneWidget);
      expect(find.text('Reject profile'), findsOneWidget);
      expect(find.text('Block'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Archive'), findsNothing);
      // No KYC replace tiles for online records.
      expect(find.byKey(const ValueKey('kyc_replace_profilePhotoUrl')),
          findsNothing);
    });

    testWidgets('frequent badge with 2+ rentals; dormant after 90 days',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(_fullWalkIn(
          id: 'cust-crm-f1', shopId: 'shop-crm-2'));
      await seedBooking(
          customerId: 'cust-crm-f1',
          shopId: 'shop-crm-2',
          pickup: DateTime.now().subtract(const Duration(days: 5)));
      await seedBooking(
          customerId: 'cust-crm-f1',
          shopId: 'shop-crm-2',
          pickup: DateTime.now().subtract(const Duration(days: 3)));
      await pumpDetail(tester,
          customerId: 'cust-crm-f1', shopId: 'shop-crm-2');
      expect(find.text('Frequent'), findsOneWidget);
      expect(find.text('Dormant'), findsNothing);

      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-crm-d1',
        shopId: 'shop-crm-2',
        name: 'Dormant Daniyal',
        phone: '0300-7777777',
        cnic: '35202-7777777-7',
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ));
      await pumpDetail(tester,
          customerId: 'cust-crm-d1', shopId: 'shop-crm-2');
      expect(find.text('Dormant'), findsOneWidget);
    });
  });

  group('block / unblock / archive', () {
    testWidgets('Block writes blocked, shows banner + chip; Unblock restores',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(_fullWalkIn(
          id: 'cust-crm-b1', shopId: 'shop-crm-3'));
      await pumpDetail(tester,
          customerId: 'cust-crm-b1', shopId: 'shop-crm-3');

      await tester.ensureVisible(find.text('Block'));
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(find.text('Blocked'), findsOneWidget);
      expect(
          find.text(
              'This customer is blocked for this shop. They cannot make new bookings.'),
          findsOneWidget);
      expect(find.text('Unblock'), findsOneWidget);
      final stored = await ds.getCustomerById('cust-crm-b1');
      expect(stored?.statusForShop('shop-crm-3'), 'blocked');
      // The other shops' entries (none) are untouched and the
      // record itself was never deleted.
      expect(stored?.name, 'Ayesha Khan');

      await tester.ensureVisible(find.text('Unblock'));
      // The Block success SnackBar sits over the bottom action row
      // until it dismisses; let it clear (and the button debounce
      // expire) before tapping Unblock, or the tap lands on the
      // SnackBar instead. The long pump fires the SnackBar timer;
      // the settle runs the removal frame after it.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Blocked'), findsNothing);
      expect(find.text('Unblock'), findsNothing);
      final restored = await ds.getCustomerById('cust-crm-b1');
      expect(restored?.statusForShop('shop-crm-3'), 'active');
    });

    testWidgets('Archive asks first, then writes archived',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(_fullWalkIn(
          id: 'cust-crm-a1', shopId: 'shop-crm-4'));
      await pumpDetail(tester,
          customerId: 'cust-crm-a1', shopId: 'shop-crm-4');

      await tester.ensureVisible(find.text('Archive'));
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.text('Archive customer?'), findsOneWidget);

      // Cancel keeps the customer active.
      await tester.tap(find.byKey(const ValueKey('customer_archive_cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);

      await tester.ensureVisible(find.text('Archive'));
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('customer_archive_confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Archived'), findsOneWidget);
      expect(
          find.text(
              'This customer is archived. Their record and history are kept.'),
          findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Archive'), findsNothing);
      final stored = await ds.getCustomerById('cust-crm-a1');
      expect(stored?.statusForShop('shop-crm-4'), 'archived');

      // Restore brings the customer back to active.
      await tester.ensureVisible(find.text('Restore'));
      // Same SnackBar-over-action-row wait as the Unblock tap
      // above (the 'Customer archived' SnackBar).
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);
      final restored = await ds.getCustomerById('cust-crm-a1');
      expect(restored?.statusForShop('shop-crm-4'), 'active');
    });
  });

  group('wizard edit mode', () {
    testWidgets('prefills from the entity and save preserves identity',
        (tester) async {
      final ds = await customers();
      final existing = _fullWalkIn(
        id: 'cust-crm-e1',
        shopId: 'shop-crm-5',
        createdAt: DateTime(2026, 1, 15),
      );
      await ds.upsertCustomer(existing);

      final router = GoRouter(
        initialLocation: '/owner/customers/cust-crm-e1/edit',
        routes: [
          GoRoute(
            path: '/owner/customers/:id/edit',
            builder: (context, state) => OwnerAddCustomerWizard(
              editingCustomer: existing,
            ),
          ),
          GoRoute(
            path: '/owner/customers/:id',
            builder: (_, state) => Scaffold(
                body: Text('detail-stub ${state.pathParameters['id']}')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();

      // Edit copy, prefilled identity, read-only CNIC.
      expect(find.text('Edit Customer'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Full name'))
            .controller
            ?.text,
        'Ayesha Khan',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'CNIC Number'))
            .controller
            ?.text,
        '35202-9999999-9',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'CNIC Number'))
            .readOnly,
        isTrue,
      );

      // Change the name only, then walk the steps: every step
      // validates from the on-file media, no re-capture needed.
      await tester.enterText(
          find.widgetWithText(TextField, 'Full name'), 'Ayesha Edited');
      await tester.ensureVisible(find.text('Verify CNIC & Blacklist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify CNIC & Blacklist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Save changes'), findsOneWidget);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('detail-stub cust-crm-e1'), findsOneWidget);
      final saved = await ds.getCustomerById('cust-crm-e1');
      expect(saved?.customerId, 'cust-crm-e1');
      expect(saved?.createdAt, DateTime(2026, 1, 15));
      expect(saved?.shopId, 'shop-crm-5');
      expect(saved?.approvalStatus, 'approved');
      expect(saved?.name, 'Ayesha Edited');
      // Media already on file stayed (no re-capture happened).
      expect(saved?.profilePhotoUrl, _face);
      expect(saved?.leftFingerprintUrl, _fingerL);
      expect(saved?.licenseFrontUrl, _licFront);
      expect(saved?.signatureUrl, _signature);
    });

    test('saver preserves identity + on-file media in edit mode', () async {
      final ds = await customers();
      final existing = _fullWalkIn(
        id: 'cust-crm-e2',
        shopId: 'shop-crm-6',
        createdAt: DateTime(2026, 2, 20),
      );
      await ds.upsertCustomer(existing);
      final draft = KycDraft.fromEntity(existing);
      draft.name = 'Renamed';
      final result = await KycCustomerSaver().save(
        shopId: 'shop-crm-6',
        draft: draft,
        existing: existing,
      );
      expect(result.customer.customerId, 'cust-crm-e2');
      expect(result.customer.createdAt, DateTime(2026, 2, 20));
      expect(result.customer.shopId, 'shop-crm-6');
      expect(result.customer.approvalStatus, 'approved');
      expect(result.customer.name, 'Renamed');
      expect(result.customer.profilePhotoUrl, _face);
      expect(result.customer.signatureUrl, _signature);
      final stored = await ds.getCustomerById('cust-crm-e2');
      expect(stored?.name, 'Renamed');
      expect(stored?.profilePhotoUrl, _face);
    });
  });

  group('KYC replace', () {
    testWidgets('tap a tile replaces that slot URL in place',
        (tester) async {
      final ds = await customers();
      await ds.upsertCustomer(_fullWalkIn(
          id: 'cust-crm-r1', shopId: 'shop-crm-7'));
      final replacer = _FakeReplacer();
      await pumpDetail(tester,
          customerId: 'cust-crm-r1',
          shopId: 'shop-crm-7',
          replacer: replacer);

      await tester.ensureVisible(
          find.byKey(const ValueKey('kyc_replace_profilePhotoUrl')));
      await tester.tap(
          find.byKey(const ValueKey('kyc_replace_profilePhotoUrl')));
      await tester.pumpAndSettle();

      expect(replacer.lastField, 'profilePhotoUrl');
      final stored = await ds.getCustomerById('cust-crm-r1');
      expect(stored?.profilePhotoUrl, 'https://cdn.example/kyc/replaced.jpg');
      // The CNIC number (record key) is untouched by a replace.
      expect(stored?.cnic, '35202-9999999-9');
    });

    test('replace service uses the rear camera for non-CNIC slots', () async {
      final service = KycSlotReplaceService(uploader: _FakeUploader());
      final url = await service.replaceSlot(
        customer: _fullWalkIn(id: 'c-svc', shopId: 'shop-1'),
        field: 'licenseFrontUrl',
        shopId: 'shop-1',
        fromGallery: false,
      );
      expect(url, 'https://cdn.example/kyc/replaced.jpg');
      expect(mockPicker.lastSource, ImageSource.camera);
      expect(mockPicker.lastCameraDevice, CameraDevice.rear);
    });

    test('replace service rejects an unreadable gallery CNIC photo',
        () async {
      final service = KycSlotReplaceService(
        ocrService: _FakeCnicOcrService(),
        uploader: _FakeUploader(),
      );
      expect(
        service.replaceSlot(
          customer: _fullWalkIn(id: 'c-svc2', shopId: 'shop-1'),
          field: 'cnicFrontUrl',
          shopId: 'shop-1',
          fromGallery: true,
        ),
        throwsA(isA<KycSlotReplaceException>().having(
          (e) => e.unreadable,
          'unreadable',
          isTrue,
        )),
      );
    });
  });
}

/// Fake OCR: the gallery photo yields nothing readable.
class _FakeCnicOcrService extends CnicOcrService {
  @override
  Future<CnicScanResult> scanFront(File image) async =>
      const CnicScanResult();

  @override
  Future<CnicScanResult> scanBack(File image) async =>
      const CnicScanResult();
}

/// Canned single-slot uploads.
class _FakeUploader extends KycMediaUploadService {
  @override
  Future<String?> uploadSingle({
    required String shopId,
    required String customerId,
    required String field,
    required XFile file,
  }) async =>
      'https://cdn.example/kyc/replaced.jpg';

  @override
  Future<KycUploadResult> uploadAll({
    required String shopId,
    required String customerId,
    required KycDraft draft,
  }) async {
    // Edit mode: no fresh captures, so nothing to upload — the
    // saver keeps the on-file URLs from the draft.
    return KycUploadResult();
  }
}

/// Records the replaced field and returns a canned URL.
class _FakeReplacer extends KycSlotReplaceService {
  String? lastField;

  @override
  Future<String?> replaceSlot({
    required CustomerEntity customer,
    required String field,
    required String shopId,
    required bool fromGallery,
  }) async {
    lastField = field;
    return 'https://cdn.example/kyc/replaced.jpg';
  }
}

final _created = DateTime(2026, 1, 1);
