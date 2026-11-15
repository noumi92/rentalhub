import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/network/firestore_service.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/bookings/presentation/views/owner_payment_accounts_view.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/finance/data/datasources/cash_closing_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_account_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_category_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_settings_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/finance_transfer_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/partner_share_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/shop_reset_data_source.dart';
import 'package:rentalhub/features/finance/data/datasources/staff_data_source.dart';
import 'package:rentalhub/features/finance/domain/entities/finance_settings_entity.dart';
import 'package:rentalhub/features/fleet/data/datasources/fixed_route_remote_data_source.dart';
import 'package:rentalhub/features/fleet/domain/entities/fixed_route_entity.dart';
import 'package:rentalhub/features/notifications/data/datasources/notification_data_source.dart';
import 'package:rentalhub/features/owner/presentation/services/subscription_data_source.dart';
import 'package:rentalhub/features/owner/presentation/services/kyc_media_upload_service.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step2_photo.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step3_docs.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step4_guarantor.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_add_customer_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_add_customer_wizard.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_added_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_shop_settings_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

import 'test_helper.dart';

// Shop-id linking (2026-11-15): shop documents are
// `shops/shop_<uid>` (field `owner_id` = the bare UID) while
// [currentShopId] returns the bare UID. In tests nobody is signed
// in, so the bare UID is the 'shop-1' fallback and the canonical
// shop doc is `shop_shop-1` with `owner_id` 'shop-1'.
//
// (b) wizard / add-customer saves carry the canonical shop doc id.
// (c) shop settings reads AND writes the real shop doc.
// (d) the payment-accounts identity check passes for the rightful
// owner on a customer booking (prefixed shopId) and still rejects
// a different shop's owner.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockImagePickerPlatform mockPicker;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'rentalhub_locked_role': 'owner'});
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

  /// A fake Firestore with the one real shop doc: `shop_shop-1`,
  /// owned by the bare UID 'shop-1'.
  FakeFirebaseFirestore shopFirestore() {
    final fake = FakeFirebaseFirestore();
    return fake;
  }

  Future<void> seedShop(FakeFirebaseFirestore fake) async {
    await fake.collection('shops').doc('shop_shop-1').set({
      'owner_id': 'shop-1',
      'shop_id': 'shop_shop-1',
      'name': 'Al-Falah Rent a Car',
      'ownerName': 'Nouman Karim',
      'phoneNumber': '0300-1111111',
      'address': 'Main Boulevard',
      'city': 'Lahore',
      'openingHours': '9:00 AM - 9:00 PM',
    });
  }

  Widget wrap(Widget home) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  group('customer query reads both id forms', () {
    test('getShopCustomers finds canonically-written customers by bare UID',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      final ds = CustomerRemoteDataSource(firestore: fake);
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-shopid-1',
        shopId: 'shop_shop-1',
        name: 'Canonical Customer',
        phone: '0300-1111111',
        cnic: '35201-1111111-1',
        source: 'walk_in',
        createdAt: DateTime(2026, 11, 15),
      ));
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-shopid-2',
        shopId: 'shop-1',
        name: 'Legacy Customer',
        phone: '0300-2222222',
        cnic: '35201-2222222-2',
        source: 'walk_in',
        createdAt: DateTime(2026, 11, 15),
      ));

      // Queried by the bare UID, the owner sees both the canonical
      // and the legacy record.
      final byBare = await ds.getShopCustomers('shop-1');
      expect(byBare.map((c) => c.customerId),
          containsAll(['cust-shopid-1', 'cust-shopid-2']));
      // Queried by the doc id, same result.
      final byDoc = await ds.getShopCustomers('shop_shop-1');
      expect(byDoc.map((c) => c.customerId),
          containsAll(['cust-shopid-1', 'cust-shopid-2']));
      // getCustomerByCnic delegates here, so it is covered too.
      final byCnic = await ds.getCustomerByCnic('shop-1', '35201-1111111-1');
      expect(byCnic?.customerId, 'cust-shopid-1');
      // A different shop sees neither.
      final other = await ds.getShopCustomers('shop_other');
      expect(other, isEmpty);
    });
  });

  group('wizard save carries the canonical shop doc id (b)', () {
    testWidgets('full wizard flow saves with shopId shop_shop-1',
        (tester) async {
      const cnic = '35201-9999999-9';
      final fake = shopFirestore();
      await seedShop(fake);
      final router = GoRouter(
        initialLocation: '/owner/customers/add?cnic=$cnic',
        routes: [
          GoRoute(
            path: '/owner/customers/add',
            builder: (context, state) => OwnerAddCustomerWizard(
              prefilledCnic: state.uri.queryParameters['cnic'],
              firestore: fake,
            ),
          ),
          GoRoute(
            path: '/owner/customers/added/:id',
            builder: (context, state) => OwnerCustomerAddedView(
              customerId: state.pathParameters['id']!,
              customer: state.extra as CustomerEntity?,
            ),
          ),
          GoRoute(
            path: '/owner/customers',
            builder: (context, state) =>
                const OwnerCustomersListView(shopId: 'shop-1'),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: CNIC prefilled; fill name + phone, verify, Next.
      await tester.enterText(
          find.widgetWithText(TextField, 'Full name'), 'Ayesha Khan');
      await tester.enterText(find.widgetWithText(TextField, 'WhatsApp number'),
          '0300-4444444');
      await tester.ensureVisible(find.text('Verify CNIC & Blacklist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify CNIC & Blacklist'));
      await tester.pumpAndSettle();
      expect(find.text('No blacklist record found'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: face + left/right finger photos.
      expect(find.byType(Step2Photo), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('step2_face_take')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step2_face_take')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
          find.byKey(const ValueKey('step2_finger_left_scan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step2_finger_left_scan')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
          find.byKey(const ValueKey('step2_finger_right_scan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step2_finger_right_scan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: license front/back + bill, number + expiry,
      // signature, terms.
      expect(find.byType(Step3Docs), findsOneWidget);
      await tapLicenseCamera(tester, const ValueKey('step3_license_front'));
      await tapLicenseCamera(tester, const ValueKey('step3_license_back'));
      await tapSheetCamera(tester, const ValueKey('step3_bill'));
      final licenseFields = find.byType(TextFormField);
      await tester.enterText(licenseFields.at(0), 'LHR-1234567');
      await tester.enterText(licenseFields.at(1), '01.01.2030');
      await tester.pump();
      await tester.ensureVisible(find.byType(Signature));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.drag(find.byType(Signature), const Offset(100, 5));
      await tester.pump();
      await tester.ensureVisible(
          find.byKey(const ValueKey('step3_signature_confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('step3_signature_confirm')));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.ensureVisible(
          find.byKey(const ValueKey('step3_terms_checkbox')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('step3_terms_checkbox')));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 4: no guarantor (optional) — Save.
      expect(find.byType(Step4Guarantor), findsOneWidget);
      await tester.tap(find.text('Save customer'));
      await tester.pumpAndSettle();

      expect(find.text('Customer added'), findsOneWidget);
      final saved = await di.sl<CustomerRemoteDataSource>()
          .getCustomerByCnic('shop_shop-1', cnic);
      expect(saved, isNotNull);
      expect(saved!.name, 'Ayesha Khan');
      // The record carries the shop DOCUMENT id, not the bare UID.
      expect(saved.shopId, 'shop_shop-1');
    });

    testWidgets('simple add-customer form saves with the canonical shop id',
        (tester) async {
      const cnic = '35201-8888888-8';
      final fake = shopFirestore();
      await seedShop(fake);
      final router = GoRouter(
        initialLocation: '/owner/customers/add',
        routes: [
          GoRoute(
            path: '/owner/customers/add',
            builder: (context, state) =>
                OwnerAddCustomerView(firestore: fake),
          ),
          GoRoute(
            path: '/owner/customers',
            builder: (context, state) =>
                const OwnerCustomersListView(shopId: 'shop-1'),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'CNIC Number'), cnic);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full name'), 'Bilal Ahmed');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Phone number'), '0300-2222222');
      await tester.tap(find.text('Save customer'));
      await tester.pumpAndSettle();

      final saved = await di.sl<CustomerRemoteDataSource>()
          .getCustomerByCnic('shop_shop-1', cnic);
      expect(saved, isNotNull);
      expect(saved!.name, 'Bilal Ahmed');
      expect(saved.shopId, 'shop_shop-1');
    });
  });

  group('shop settings resolves the real shop doc (c)', () {
    testWidgets('loads the shop name from the canonical doc',
        (tester) async {
      final fake = shopFirestore();
      await seedShop(fake);
      await tester.pumpWidget(
          wrap(OwnerShopSettingsView(firestore: fake)));
      await tester.pumpAndSettle();

      expect(find.text('Al-Falah Rent a Car'), findsOneWidget);
      expect(find.text('Lahore'), findsOneWidget);
      // No duplicate doc was created under the bare UID.
      expect(
          (await fake.collection('shops').doc('shop-1').get()).exists,
          isFalse);
    });

    testWidgets('save writes back to the canonical doc, not a bare-UID doc',
        (tester) async {
      final fake = shopFirestore();
      await seedShop(fake);
      await tester.pumpWidget(
          wrap(OwnerShopSettingsView(firestore: fake)));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Al-Falah Rent a Car'),
          'Al-Falah Motors');
      await tester.tap(find.text('Save shop settings'));
      await tester.pumpAndSettle();

      final doc =
          await fake.collection('shops').doc('shop_shop-1').get();
      expect(doc.data()?['name'], 'Al-Falah Motors');
      expect(
          (await fake.collection('shops').doc('shop-1').get()).exists,
          isFalse);
    });
  });

  group('payment-accounts identity check (d)', () {
    BookingModel modelFor(String shopId) => BookingModel(
          bookingId: 'RH-shopid',
          customerId: 'cust-shopid',
          shopId: shopId,
          vehicleId: 'veh-1',
          packageType: '24h',
          pickupTime: DateTime(2026, 11, 15, 9),
          returnTime: DateTime(2026, 11, 16, 9),
          totalAmount: 9000,
          remainingBalance: 9000,
          customerName: 'Ayesha Khan',
          customerPhone: '0300-1111111',
          vehicleName: 'Honda Civic Oriel',
        );

    testWidgets('rightful owner sees Approve on a prefixed-shopId booking',
        (tester) async {
      final fake = shopFirestore();
      await seedShop(fake);
      await tester.pumpWidget(wrap(OwnerPaymentAccountsView(
        booking: modelFor('shop_shop-1'),
        firestore: fake,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Approve'), findsWidgets);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('a different shop owner sees the summary without actions',
        (tester) async {
      final fake = shopFirestore();
      await seedShop(fake);
      await tester.pumpWidget(wrap(OwnerPaymentAccountsView(
        booking: modelFor('shop_other-shop'),
        firestore: fake,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Approve'), findsNothing);
      expect(find.text('Decline'), findsNothing);
      // The summary itself still renders.
      expect(find.text('Ayesha Khan'), findsOneWidget);
    });
  });

  // (e) Sweep (2026-11-15): every remaining shop-id caller resolves
  // through the shared helper — reads match both id forms, writes
  // carry the canonical shop doc id. Each data source is seeded with
  // the real shop doc `shop_shop-1` (owner_id 'shop-1'); the owner
  // always queries by the bare UID 'shop-1'.
  group('sweep: remaining data sources resolve both id forms (e)', () {
    test('fixed routes: save canonicalizes, read finds both forms',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('fixed_routes').doc('route-legacy').set({
        'routeId': 'route-legacy',
        'shopId': 'shop-1',
        'originCity': 'Lahore',
        'destinationCity': 'Faisalabad',
        'distanceKm': 180,
        'fixedPricePkr': 12000,
      });
      final ds = FixedRouteRemoteDataSource(firestore: fake);
      await ds.saveFixedRoute(const FixedRouteEntity(
        routeId: 'route-new',
        shopId: 'shop-1',
        originCity: 'Lahore',
        destinationCity: 'Islamabad',
        distanceKm: 300,
        fixedPricePkr: 18000,
      ));
      final stored = await fake
          .collection('fixed_routes')
          .doc('route-new')
          .get();
      expect(stored.data()?['shopId'], 'shop_shop-1');
      final routes = await ds.getShopFixedRoutes('shop-1');
      expect(routes.map((r) => r.routeId),
          containsAll(['route-new', 'route-legacy']));
    });

    test('blacklist: report canonicalizes, inbox finds both forms',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      final ds = BlacklistRemoteDataSource(firestore: fake);
      await fake.collection('blacklist').doc('BLK-legacy').set({
        'blacklistId': 'BLK-legacy',
        'reportedByShopId': 'shop-1',
        'cnicNumber': '35201-1111111-1',
        'phoneNumber': '0300-1111111',
        'reasonCategory': 'damage',
        'description': 'legacy',
        'isActive': true,
      });
      final reported = await ds.reportCustomerToBlacklist(
        reportedByShopId: 'shop-1',
        cnicNumber: '35201-2222222-2',
        phoneNumber: '0300-2222222',
        reasonCategory: 'damage',
        description: 'new',
      );
      expect(reported.reportedByShopId, 'shop_shop-1');
      final mine = await ds.getShopReports('shop-1');
      expect(mine.map((r) => r.blacklistId),
          containsAll([reported.blacklistId, 'BLK-legacy']));
    });

    test('customer upsert canonicalizes the CNIC-review bare write',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      final ds = CustomerRemoteDataSource(firestore: fake);
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-sweep-1',
        shopId: 'shop-1',
        name: 'Sweep Customer',
        phone: '0300-3333333',
        cnic: '35201-3333333-3',
        source: 'ocr',
        createdAt: DateTime(2026, 11, 15),
      ));
      final stored =
          await fake.collection('customers').doc('cust-sweep-1').get();
      expect(stored.data()?['shopId'], 'shop_shop-1');
      final found = await ds.getShopCustomers('shop-1');
      expect(found.map((c) => c.customerId), contains('cust-sweep-1'));
    });

    test('subscription reads the canonical shops doc, not free',
        () async {
      final fake = shopFirestore();
      await fake.collection('shops').doc('shop_shop-1').set({
        'owner_id': 'shop-1',
        'shop_id': 'shop_shop-1',
        'subscriptionTier': 'business',
        'subscriptionStatus': 'active',
      });
      final ds = SubscriptionDataSource(firestore: fake);
      final state = await ds.getShopSubscription('shop-1');
      expect(state.tier, 'business');
      expect(state.status, 'active');
    });

    test('subscription requests: submit canonicalizes, history finds both',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('subscription_requests').doc('req-legacy').set({
        'shopId': 'shop-1',
        'tier': 'basic',
        'billingPeriod': 'monthly',
        'price': 4999,
        'transactionId': 'legacy-trx',
        'status': 'approved',
      });
      final ds = SubscriptionDataSource(firestore: fake);
      await ds.submitSubscriptionRequest(
        shopId: 'shop-1',
        tier: 'business',
        billingPeriod: 'monthly',
        price: 12999,
        transactionId: 'new-trx',
        isTrial: false,
      );
      final history = await ds.getSubscriptionHistory('shop-1');
      expect(history.map((r) => r.transactionId),
          containsAll(['new-trx', 'legacy-trx']));
      final snap = await fake
          .collection('subscription_requests')
          .where('shopId', isEqualTo: 'shop_shop-1')
          .get();
      expect(snap.docs.map((d) => d.data()['transactionId']),
          contains('new-trx'));
    });

    test('subscription staff count matches canonical staff rows',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('staff').doc('STF-1').set({
        'staffId': 'STF-1',
        'shopId': 'shop_shop-1',
        'name': 'Ali',
        'role': 'manager',
      });
      final ds = SubscriptionDataSource(firestore: fake);
      expect(await ds.getStaffCount('shop-1'), 1);
    });

    test('finance accounts: save canonicalizes, read finds both forms',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('finance_accounts').doc('ACC-legacy').set({
        'accountId': 'ACC-legacy',
        'shopId': 'shop-1',
        'name': 'Legacy Bank',
        'type': 'bank',
        'openingBalancePkr': 0,
        'isDefault': false,
      });
      final ds = FinanceAccountDataSource(firestore: fake);
      final saved = await ds.saveAccount(
          shopId: 'shop-1', name: 'New Cash', type: 'cash');
      expect(saved.shopId, 'shop_shop-1');
      final accounts = await ds.getShopAccounts('shop-1');
      expect(accounts.map((a) => a.accountId),
          containsAll([saved.accountId, 'ACC-legacy']));
    });

    test('finance transfers: add canonicalizes, read finds both forms',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('finance_transfers').doc('TRF-legacy').set({
        'transferId': 'TRF-legacy',
        'shopId': 'shop-1',
        'accountId': 'ACC-legacy',
        'kind': 'income',
        'category': 'rent',
        'amountPkr': 5000,
      });
      final ds = FinanceTransferDataSource(firestore: fake);
      final saved = await ds.addTransfer(
        shopId: 'shop-1',
        accountId: 'ACC-1',
        kind: 'income',
        category: 'rent',
        amountPkr: 7000,
      );
      expect(saved.shopId, 'shop_shop-1');
      final list = await ds.getShopTransfers('shop-1');
      expect(list.map((t) => t.transferId),
          containsAll([saved.transferId, 'TRF-legacy']));
    });

    test('partner shares: save canonicalizes, read finds both forms',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('partner_shares').doc('SHR-legacy').set({
        'shareId': 'SHR-legacy',
        'shopId': 'shop-1',
        'partnerName': 'Legacy Partner',
        'sharePercent': 20,
      });
      final ds = PartnerShareDataSource(firestore: fake);
      final saved = await ds.savePartner(
          shopId: 'shop-1', partnerName: 'New Partner', sharePercent: 30);
      expect(saved.shopId, 'shop_shop-1');
      final list = await ds.getShopPartners('shop-1');
      expect(list.map((p) => p.shareId),
          containsAll([saved.shareId, 'SHR-legacy']));
    });

    test('cash closing: id embeds the canonical id, read finds both',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      final day = DateTime(2026, 11, 15);
      await fake.collection('cash_closings').doc('CLS-legacy').set({
        'closingId': 'CLS-legacy',
        'shopId': 'shop-1',
        'date': day.toIso8601String(),
        'openingCash': 0,
        'expectedCash': 0,
        'countedCash': 0,
        'difference': 0,
      });
      final ds = CashClosingDataSource(firestore: fake);
      final saved = await ds.saveClosing(
        shopId: 'shop-1',
        date: day,
        openingCash: 1000,
        expectedCash: 5000,
        countedCash: 5000,
      );
      expect(saved.shopId, 'shop_shop-1');
      expect(saved.closingId, startsWith('CLS-shop_shop-1-'));
      final list = await ds.getShopClosings('shop-1');
      expect(list.map((c) => c.closingId),
          containsAll([saved.closingId, 'CLS-legacy']));
    });

    test('deposits: canonical booking deposit is visible to the owner',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      final ds = SecurityDepositDataSource(firestore: fake);
      await ds.collect(
        bookingId: 'RH-dep-1',
        customerId: 'cust-1',
        shopId: 'shop_shop-1',
        amount: 10000,
      );
      await ds.collect(
        bookingId: 'RH-dep-2',
        customerId: 'cust-1',
        shopId: 'shop-1',
        amount: 5000,
      );
      final stored =
          await fake.collection('security_deposits').doc('RH-dep-2').get();
      expect(stored.data()?['shopId'], 'shop_shop-1');
      final list = await ds.getShopDeposits('shop-1');
      expect(list.map((d) => d.bookingId),
          containsAll(['RH-dep-1', 'RH-dep-2']));
    });

    test('finance categories: add canonicalizes, read finds both forms',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('finance_categories').doc('CAT-legacy').set({
        'categoryId': 'CAT-legacy',
        'shopId': 'shop-1',
        'kind': 'income',
        'code': 'legacy_rent',
        'name': 'Legacy Rent',
      });
      final ds = FinanceCategoryDataSource(firestore: fake);
      final saved = await ds.addCategory(
          shopId: 'shop-1', kind: 'income', name: 'New Rent');
      expect(saved.shopId, 'shop_shop-1');
      final list = await ds.getShopCategories('shop-1', kind: 'income');
      expect(list.map((c) => c.categoryId),
          containsAll([saved.categoryId, 'CAT-legacy']));
    });

    test('staff: add canonicalizes, read finds both forms', () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('staff').doc('STF-legacy').set({
        'staffId': 'STF-legacy',
        'shopId': 'shop-1',
        'name': 'Legacy Staff',
        'role': 'driver',
      });
      final ds = StaffDataSource(firestore: fake);
      final saved = await ds.addStaff(
          shopId: 'shop-1', name: 'New Staff', role: 'manager');
      expect(saved.shopId, 'shop_shop-1');
      final list = await ds.getShopStaff('shop-1');
      expect(list.map((s) => s.staffId),
          containsAll([saved.staffId, 'STF-legacy']));
    });

    test('notifications: canonical booking notice is visible to owner',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      final ds = NotificationDataSource(firestore: fake);
      final created = await ds.createNotification(
        shopId: 'shop-1',
        title: 'New booking',
        body: 'A customer requested a car.',
        type: 'booking_requested',
        bookingId: 'RH-notif-1',
      );
      expect(created.shopId, 'shop_shop-1');
      await fake.collection('notifications').doc('NTF-legacy').set({
        'notificationId': 'NTF-legacy',
        'shopId': 'shop-1',
        'title': 'Legacy',
        'body': 'legacy',
        'type': 'info',
        'createdAt': DateTime(2026, 11, 14).toIso8601String(),
        'read': false,
      });
      final list = await ds.getShopNotifications('shop-1');
      expect(list.map((n) => n.notificationId),
          containsAll([created.notificationId, 'NTF-legacy']));
      await ds.markAllRead('shop-1');
      final after = await ds.getShopNotifications('shop-1');
      expect(after.where((n) => !n.read), isEmpty);
    });

    test('finance settings: save canonicalizes, legacy doc still read',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      final ds = FinanceSettingsDataSource(firestore: fake);
      await ds.saveSettings(
          const FinanceSettingsEntity(shopId: 'shop-1', currency: 'PKR'));
      final stored = await fake
          .collection('finance_settings')
          .doc('shop_shop-1')
          .get();
      expect(stored.exists, isTrue);
      final readBack = await ds.getSettings('shop-1');
      expect(readBack.shopId, 'shop_shop-1');
      // Legacy bare-UID document is honoured when no canonical one
      // exists.
      final legacyFake = shopFirestore();
      await seedShop(legacyFake);
      await legacyFake
          .collection('finance_settings')
          .doc('shop-1')
          .set({'shopId': 'shop-1', 'currency': 'PKR', 'taxPercent': 5});
      final legacyDs = FinanceSettingsDataSource(firestore: legacyFake);
      expect((await legacyDs.getSettings('shop-1')).taxPercent, 5);
    });

    test('shop reset deletes both id forms', () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('bookings').doc('RH-reset-1').set({
        'bookingId': 'RH-reset-1',
        'shopId': 'shop_shop-1',
        'customerId': 'cust-1',
      });
      await fake.collection('bookings').doc('RH-reset-2').set({
        'bookingId': 'RH-reset-2',
        'shopId': 'shop-1',
        'customerId': 'cust-1',
      });
      final ds = ShopResetDataSource(firestore: fake);
      expect(await ds.resetBookings('shop-1'), 2);
      expect((await fake.collection('bookings').get()).docs, isEmpty);
    });

    test('admin counts match both id forms; credits read canonical doc',
        () async {
      final fake = shopFirestore();
      await seedShop(fake);
      await fake.collection('vehicles').doc('veh-1').set({
        'vehicleId': 'veh-1',
        'shopId': 'shop_shop-1',
      });
      await fake.collection('vehicles').doc('veh-2').set({
        'vehicleId': 'veh-2',
        'shopId': 'shop-1',
      });
      await fake.collection('bookings').doc('RH-adm-1').set({
        'bookingId': 'RH-adm-1',
        'shopId': 'shop_shop-1',
      });
      await fake
          .collection('whatsapp_credits')
          .doc('shop_shop-1')
          .set({'balance': 42});
      final ds = AdminShopsDataSource(firestore: fake);
      expect(await ds.getShopVehicleCount('shop-1'), 2);
      expect(await ds.getShopBookingCount('shop-1'), 1);
      expect(await ds.getShopCreditsBalance('shop-1'), 42);
    });

    test('legacy FirestoreService vehicle read finds both forms',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('vehicles').doc('veh-1').set({
        'vehicle_id': 'veh-1',
        'shop_id': 'shop_shop-1',
        'make': 'Toyota',
        'model': 'Corolla',
        'year': 2022,
        'plate_number': 'LEA-24-1001',
        'category': 'Sedan',
        'transmission': 'Automatic',
        'fuel_type': 'Petrol',
        'seats': 5,
        'status': 'Available',
      });
      await fake.collection('vehicles').doc('veh-2').set({
        'vehicle_id': 'veh-2',
        'shop_id': 'shop-1',
        'make': 'Honda',
        'model': 'Civic',
        'year': 2023,
        'plate_number': 'LEA-24-1002',
        'category': 'Sedan',
        'transmission': 'Automatic',
        'fuel_type': 'Petrol',
        'seats': 5,
        'status': 'Available',
      });
      // The resolution needs the shop doc for the bare UID.
      await fake.collection('shops').doc('shop_shop-1').set({
        'owner_id': 'shop-1',
        'shop_id': 'shop_shop-1',
      });
      final service = FirestoreService(firestore: fake);
      final vehicles = await service.getShopVehicles('shop-1');
      expect(vehicles.map((v) => v.vehicleId),
          containsAll(['veh-1', 'veh-2']));
    });
  });
}

/// License tiles show a spinner while OCR runs; the OCR future
/// never completes under the fake clock (ML Kit channel), so
/// pumpAndSettle would time out on the spinner — pump fixed frames
/// instead. The photo is stored before OCR starts.
Future<void> tapLicenseCamera(WidgetTester tester, Key buttonKey) async {
  await tester.ensureVisible(find.byKey(buttonKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byKey(buttonKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Same fixed-frame pumping for a sheet-based pick made while the
/// license spinners are still animating.
Future<void> tapSheetCamera(WidgetTester tester, Key buttonKey) async {
  await tester.ensureVisible(find.byKey(buttonKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byKey(buttonKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  if (find.text('Take Photo (Back Camera)').evaluate().isNotEmpty) {
    await tester.tap(find.text('Take Photo (Back Camera)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Canned uploads: every file the draft carries gets a fixed URL.
class _FakeUploader extends KycMediaUploadService {
  @override
  Future<KycUploadResult> uploadAll({
    required String shopId,
    required String customerId,
    required KycDraft draft,
  }) async {
    final result = KycUploadResult();
    if (draft.facePhoto != null) {
      result.urls['profilePhotoUrl'] = 'https://cdn.example/kyc/face.jpg';
    }
    if (draft.leftFingersPhoto != null) {
      result.urls['leftFingerprintUrl'] =
          'https://cdn.example/kyc/finger-left.jpg';
    }
    if (draft.rightFingersPhoto != null) {
      result.urls['rightFingerprintUrl'] =
          'https://cdn.example/kyc/finger-right.jpg';
    }
    if (draft.cnicFrontPhoto != null) {
      result.urls['cnicFrontUrl'] = 'https://cdn.example/kyc/cnic-front.jpg';
    }
    if (draft.cnicBackPhoto != null) {
      result.urls['cnicBackUrl'] = 'https://cdn.example/kyc/cnic-back.jpg';
    }
    if (draft.licenseFrontPhoto != null) {
      result.urls['licenseFrontUrl'] =
          'https://cdn.example/kyc/lic-front.jpg';
    }
    if (draft.licenseBackPhoto != null) {
      result.urls['licenseBackUrl'] = 'https://cdn.example/kyc/lic-back.jpg';
    }
    if (draft.utilityBillPhoto != null) {
      result.urls['utilityBillUrl'] = 'https://cdn.example/kyc/bill.jpg';
    }
    if (draft.signaturePng != null && draft.signaturePng!.isNotEmpty) {
      result.urls['signatureUrl'] = 'https://cdn.example/kyc/signature.png';
    }
    return result;
  }
}
