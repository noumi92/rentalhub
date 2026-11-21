// Walk-in customer CRM (Worker 3) — per-shop Blocked / Archived
// statuses on the customers list and the booking pick:
// * archived rows are hidden from the list under every filter;
// * Blocked is a filter segment (hides at zero count) and a row badge;
// * Pending Approval matches ONLINE saved records only — a walk-in
//   record sitting at 'pending' never matches;
// * KYC Incomplete / Dormant row badges derive from the loaded record;
// * blocked / archived customers cannot be picked for a new booking.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/customer/utils/customer_grouping.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_list_filter_chips.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_status_helpers.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_customer_step.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  const kycFull = (
    profilePhotoUrl: 'https://example.invalid/kyc/face.jpg',
    leftFingerprintUrl: 'https://example.invalid/kyc/left.jpg',
    rightFingerprintUrl: 'https://example.invalid/kyc/right.jpg',
    licenseFrontUrl: 'https://example.invalid/kyc/lic-front.jpg',
    licenseBackUrl: 'https://example.invalid/kyc/lic-back.jpg',
    licenseNumber: 'LHR-26-123456',
    utilityBillUrl: 'https://example.invalid/kyc/bill.jpg',
    signatureUrl: 'https://example.invalid/kyc/sig.png',
  );

  CustomerEntity saved({
    required String id,
    required String shopId,
    required String name,
    required String cnic,
    String source = 'walk_in',
    Map<String, String>? shopStatuses,
    bool kycComplete = false,
  }) =>
      CustomerEntity(
        customerId: id,
        shopId: shopId,
        name: name,
        phone: '0300-0000000',
        cnic: cnic,
        source: source,
        createdAt: DateTime(2026, 11, 1),
        shopStatuses: shopStatuses,
        profilePhotoUrl: kycComplete ? kycFull.profilePhotoUrl : null,
        leftFingerprintUrl: kycComplete ? kycFull.leftFingerprintUrl : null,
        rightFingerprintUrl:
            kycComplete ? kycFull.rightFingerprintUrl : null,
        licenseFrontUrl: kycComplete ? kycFull.licenseFrontUrl : null,
        licenseBackUrl: kycComplete ? kycFull.licenseBackUrl : null,
        licenseNumber: kycComplete ? kycFull.licenseNumber : null,
        utilityBillUrl: kycComplete ? kycFull.utilityBillUrl : null,
        signatureUrl: kycComplete ? kycFull.signatureUrl : null,
      );

  group('customer_status_helpers — pure derivations', () {
    test('shopStatusFor defaults to active; both id forms match', () {
      const bare = 'w3bare';
      final blocked = saved(
          id: 'c1',
          shopId: bare,
          name: 'B',
          cnic: '35202-0000001-1',
          shopStatuses: {bare: 'blocked'});
      final blockedByDocId = saved(
          id: 'c2',
          shopId: bare,
          name: 'B',
          cnic: '35202-0000002-2',
          shopStatuses: {'shop_$bare': 'blocked'});
      final archived = saved(
          id: 'c3',
          shopId: bare,
          name: 'A',
          cnic: '35202-0000003-3',
          shopStatuses: {bare: 'archived'});
      final plain = saved(
          id: 'c4', shopId: bare, name: 'P', cnic: '35202-0000004-4');
      expect(shopStatusFor(null, bare), CustomerEntity.statusActive);
      expect(shopStatusFor(plain, bare), CustomerEntity.statusActive);
      expect(shopStatusFor(blocked, bare), CustomerEntity.statusBlocked);
      // The map is keyed by the `shop_<uid>` document id while the
      // caller holds the bare UID — the fallback still finds it.
      expect(
          shopStatusFor(blockedByDocId, bare), CustomerEntity.statusBlocked);
      expect(shopStatusFor(archived, bare), CustomerEntity.statusArchived);
      // An already-canonical id reads directly.
      expect(shopStatusFor(blockedByDocId, 'shop_$bare'),
          CustomerEntity.statusBlocked);
    });

    test('isCustomerKycComplete needs every slot', () {
      final full = saved(
          id: 'c1',
          shopId: 's',
          name: 'F',
          cnic: '35202-0000001-1',
          kycComplete: true);
      expect(isCustomerKycComplete(full), isTrue);
    });

    test('isCustomerKycComplete is false when any slot is missing', () {
      CustomerEntity missing({
        String? profilePhotoUrl = 'x',
        String? leftFingerprintUrl = 'x',
        String? rightFingerprintUrl = 'x',
        String? licenseFrontUrl = 'x',
        String? licenseBackUrl = 'x',
        String? licenseNumber = 'LHR-1',
        String? utilityBillUrl = 'x',
        String? signatureUrl = 'x',
      }) =>
          CustomerEntity(
            customerId: 'c1',
            shopId: 's',
            name: 'F',
            phone: '0300-0000000',
            cnic: '35202-0000001-1',
            createdAt: DateTime(2026, 11, 1),
            profilePhotoUrl: profilePhotoUrl,
            leftFingerprintUrl: leftFingerprintUrl,
            rightFingerprintUrl: rightFingerprintUrl,
            licenseFrontUrl: licenseFrontUrl,
            licenseBackUrl: licenseBackUrl,
            licenseNumber: licenseNumber,
            utilityBillUrl: utilityBillUrl,
            signatureUrl: signatureUrl,
          );
      expect(isCustomerKycComplete(missing()), isTrue);
      expect(isCustomerKycComplete(missing(signatureUrl: null)), isFalse);
      expect(isCustomerKycComplete(missing(leftFingerprintUrl: null)),
          isFalse);
      expect(isCustomerKycComplete(missing(rightFingerprintUrl: null)),
          isFalse);
      expect(isCustomerKycComplete(missing(licenseNumber: null)), isFalse);
      expect(isCustomerKycComplete(missing(licenseNumber: '  ')), isFalse);
      expect(isCustomerKycComplete(missing(utilityBillUrl: null)), isFalse);
      expect(isCustomerKycComplete(missing(profilePhotoUrl: null)), isFalse);
      expect(isCustomerKycComplete(missing(licenseFrontUrl: '')), isFalse);
    });

    test('isCustomerDormant is 90 days since the last booking', () {
      final now = DateTime(2026, 11, 20);
      expect(isCustomerDormant(null, now: now), isFalse,
          reason: 'never booked is New, not Dormant');
      expect(isCustomerDormant(now.subtract(const Duration(days: 10)),
          now: now), isFalse);
      expect(isCustomerDormant(now.subtract(const Duration(days: 89)),
          now: now), isFalse);
      expect(isCustomerDormant(now.subtract(const Duration(days: 90)),
          now: now), isTrue);
      expect(isCustomerDormant(now.subtract(const Duration(days: 200)),
          now: now), isTrue);
    });

    test('rowStatusBadges combines the three derivations', () {
      const shopId = 'shop-w3-badges';
      final summary = CustomerSummary(
        key: 'cnic:3520200000011',
        name: 'B',
        phone: '0300-0000000',
        cnic: '35202-0000001-1',
        bookingCount: 1,
        totalSpent: 5000,
        lastBookingAt: DateTime(2026, 6, 1),
        bookings: const [],
        savedRecord: saved(
            id: 'c1',
            shopId: shopId,
            name: 'B',
            cnic: '35202-0000001-1',
            shopStatuses: {shopId: 'blocked'}),
      );
      final badges = rowStatusBadges(summary, shopId,
          now: DateTime(2026, 11, 20));
      expect(badges.blocked, isTrue);
      // No KYC fields on the record.
      expect(badges.kycIncomplete, isTrue);
      // Last booking June — over 90 days before 20 Nov.
      expect(badges.dormant, isTrue);
      // A booking-derived row (no saved record) is never KYC
      // Incomplete — there is no record to judge.
      final bookingOnly = CustomerSummary(
        key: 'cnic:3520200000022',
        name: 'N',
        phone: '0300-0000000',
        cnic: '35202-0000002-2',
        bookingCount: 1,
        totalSpent: 5000,
        lastBookingAt: DateTime(2026, 11, 10),
        bookings: const [],
      );
      final badges2 = rowStatusBadges(bookingOnly, shopId,
          now: DateTime(2026, 11, 20));
      expect(badges2.blocked, isFalse);
      expect(badges2.kycIncomplete, isFalse);
      expect(badges2.dormant, isFalse);
    });
  });

  group('CustomerListFilterChips — Blocked segment', () {
    Widget wrapChips({
      CustomerListFilter selected = CustomerListFilter.all,
      int blocked = 1,
      ValueChanged<CustomerListFilter>? onSelected,
    }) =>
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomerListFilterChips(
              selected: selected,
              allCount: 4,
              regularCount: 1,
              newCount: 3,
              blacklistedCount: 0,
              withDuesCount: 0,
              pendingApprovalCount: 0,
              blockedCount: blocked,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        );

    testWidgets('Blocked segment shows with its count', (tester) async {
      await tester.pumpWidget(wrapChips());
      await tester.pumpAndSettle();
      expect(find.text('Blocked (1)'), findsOneWidget);
    });

    testWidgets('Blocked segment hides at zero count', (tester) async {
      await tester.pumpWidget(wrapChips(blocked: 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Blocked ('), findsNothing);
    });

    testWidgets('a selected zero-count Blocked segment stays visible',
        (tester) async {
      await tester.pumpWidget(wrapChips(
          selected: CustomerListFilter.blocked, blocked: 0));
      await tester.pumpAndSettle();
      expect(find.text('Blocked (0)'), findsOneWidget);
    });

    testWidgets('tapping Blocked reports its filter', (tester) async {
      CustomerListFilter? tapped;
      await tester.pumpWidget(wrapChips(onSelected: (f) => tapped = f));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Blocked (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blocked (1)'));
      expect(tapped, CustomerListFilter.blocked);
    });
  });

  group('OwnerCustomersListView — archived / blocked / pending', () {
    Future<void> seedShop(String shopId) async {
      final bookingDs = di.sl<BookingRemoteDataSource>();
      final customerDs = di.sl<CustomerRemoteDataSource>();
      Future<void> seedBooking({
        required String customerId,
        required String name,
        required String phone,
        required String cnic,
        required DateTime pickup,
      }) async {
        await bookingDs.createBookingRequest(
          customerId: customerId,
          shopId: shopId,
          vehicleId: 'veh-1',
          packageType: '24h',
          isWithDriver: false,
          pickupTime: pickup,
          returnTime: pickup.add(const Duration(days: 1)),
          totalAmount: 9000,
          advanceRequired: 1000,
          customerName: name,
          customerPhone: phone,
          customerCnic: cnic,
        );
      }

      // Regular: 2 recent rentals.
      await seedBooking(customerId: 'cust-w3-reg', name: 'Regular Rana', phone: '0300-5551001', cnic: '35202-5551001-1', pickup: DateTime(2026, 11, 3, 9));
      await seedBooking(customerId: 'cust-w3-reg', name: 'Regular Rana', phone: '0300-5551001', cnic: '35202-5551001-1', pickup: DateTime(2026, 11, 4, 9));
      // Dormant: 1 rental, last booking 1 June — over 90 days ago.
      await seedBooking(customerId: 'cust-w3-dor', name: 'Dormant Daniyal', phone: '0300-5551002', cnic: '35202-5551002-2', pickup: DateTime(2026, 6, 1, 9));
      // Archived: 1 recent rental AND a saved record archived for
      // this shop — hidden even though the booking would list her.
      await seedBooking(customerId: 'cust-w3-arch', name: 'Archived Ayesha', phone: '0300-5551003', cnic: '35202-5551003-3', pickup: DateTime(2026, 11, 5, 9));
      await customerDs.upsertCustomer(saved(
          id: 'cust-w3-arch',
          shopId: shopId,
          name: 'Archived Ayesha',
          cnic: '35202-5551003-3',
          shopStatuses: {shopId: 'archived'}));
      // Blocked: saved record, no bookings yet.
      await customerDs.upsertCustomer(saved(
          id: 'cust-w3-blk',
          shopId: shopId,
          name: 'Blocked Bilal',
          cnic: '35202-5551004-4',
          shopStatuses: {shopId: 'blocked'}));
      // Pending Approval: ONLINE saved record, still pending.
      await customerDs.upsertCustomer(saved(
          id: 'cust-w3-pa',
          shopId: shopId,
          name: 'Pending Paula',
          cnic: '35202-5551005-5',
          source: 'online'));
      // Walk-in pending: saved WALK-IN record, still pending —
      // must never match Pending Approval.
      await customerDs.upsertCustomer(saved(
          id: 'cust-w3-wp',
          shopId: shopId,
          name: 'Walkin Waleed',
          cnic: '35202-5551006-6',
          source: 'walk_in'));
      // KYC-complete: saved record with every slot + 1 booking —
      // no KYC Incomplete badge on this row.
      await seedBooking(customerId: 'cust-w3-kyc', name: 'Kyc Karim', phone: '0300-5551007', cnic: '35202-5551007-7', pickup: DateTime(2026, 11, 6, 9));
      await customerDs.upsertCustomer(saved(
          id: 'cust-w3-kyc',
          shopId: shopId,
          name: 'Kyc Karim',
          cnic: '35202-5551007-7',
          kycComplete: true));
    }

    Future<void> pumpList(WidgetTester tester, String shopId) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerCustomersListView(shopId: shopId),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapChip(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    // NOTE: this test runs FIRST in the group on purpose — the
    // shared in-memory pending queue leaks earlier tests' bookings
    // into every shop (pre-existing, see the filters test), so its
    // absolute 'All (1)' count only holds before any booking is
    // seeded in this file.
    testWidgets('doc-id form of the shop key still hides / blocks',
        (tester) async {
      // The caller holds the bare id 'w3doc'; the stored map is
      // keyed by the `shop_<uid>` document id.
      const shopId = 'w3doc';
      final customerDs = di.sl<CustomerRemoteDataSource>();
      await customerDs.upsertCustomer(saved(
          id: 'cust-w3-doc-arch',
          shopId: shopId,
          name: 'Doc Archived',
          cnic: '35202-5552001-1',
          shopStatuses: {'shop_$shopId': 'archived'}));
      await customerDs.upsertCustomer(saved(
          id: 'cust-w3-doc-blk',
          shopId: shopId,
          name: 'Doc Blocked',
          cnic: '35202-5552002-2',
          shopStatuses: {'shop_$shopId': 'blocked'}));
      await pumpList(tester, shopId);

      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Blocked (1)'), findsOneWidget);
      expect(find.text('Doc Blocked'), findsOneWidget);
      expect(find.text('Doc Archived'), findsNothing);
    });

    testWidgets('archived customer is hidden under every filter',
        (tester) async {
      const shopId = 'shop-w3-list';
      await seedShop(shopId);
      await pumpList(tester, shopId);

      // 7 people seeded, 1 archived → 6 visible everywhere.
      expect(find.text('All (6)'), findsOneWidget);
      expect(find.text('Regular (1)'), findsOneWidget);
      expect(find.text('New (5)'), findsOneWidget);
      expect(find.text('Blocked (1)'), findsOneWidget);
      expect(find.text('Pending review (1)'), findsOneWidget);
      expect(find.text('Archived Ayesha'), findsNothing);

      await tapChip(tester, 'All (6)');
      expect(find.text('Archived Ayesha'), findsNothing);
      await tapChip(tester, 'Regular (1)');
      expect(find.text('Archived Ayesha'), findsNothing);
      await tapChip(tester, 'New (5)');
      expect(find.text('Archived Ayesha'), findsNothing);
      await tapChip(tester, 'Blocked (1)');
      expect(find.text('Archived Ayesha'), findsNothing);
      await tapChip(tester, 'Pending review (1)');
      expect(find.text('Archived Ayesha'), findsNothing);
      // Searching for her name finds nothing either.
      await tapChip(tester, 'All (6)');
      await tester.enterText(find.byType(TextField).first, 'Ayesha');
      await tester.pumpAndSettle();
      expect(find.text('Archived Ayesha'), findsNothing);
    });

    testWidgets('Blocked segment isolates the blocked row, with badge',
        (tester) async {
      const shopId = 'shop-w3-list';
      await seedShop(shopId);
      await pumpList(tester, shopId);

      // The row badge is the bare 'Blocked' text (the chip carries
      // the count, 'Blocked (1)').
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('Blocked Bilal'), findsOneWidget);
      await tapChip(tester, 'Blocked (1)');
      expect(find.text('Blocked Bilal'), findsOneWidget);
      expect(find.text('Regular Rana'), findsNothing);
      expect(find.text('Dormant Daniyal'), findsNothing);
      expect(find.text('Pending Paula'), findsNothing);
      expect(find.text('Walkin Waleed'), findsNothing);
      expect(find.text('Kyc Karim'), findsNothing);
    });

    testWidgets('Pending Approval never matches a walk-in record',
        (tester) async {
      const shopId = 'shop-w3-list';
      await seedShop(shopId);
      await pumpList(tester, shopId);

      await tapChip(tester, 'Pending review (1)');
      expect(find.text('Pending Paula'), findsOneWidget);
      expect(find.text('Walkin Waleed'), findsNothing);
      expect(find.text('Blocked Bilal'), findsNothing);
      expect(find.text('Regular Rana'), findsNothing);
    });

    testWidgets('row badges: KYC Incomplete and Dormant', (tester) async {
      const shopId = 'shop-w3-list';
      await seedShop(shopId);
      await pumpList(tester, shopId);

      // KYC Incomplete: Bilal, Paula and Waleed carry saved records
      // with no KYC fields. Karim's record is complete; the
      // booking-derived rows (Rana, Daniyal) have no record at all.
      expect(find.text('KYC Incomplete'), findsNWidgets(3));
      // Dormant: only Daniyal, whose last booking was 1 June.
      expect(find.text('Dormant'), findsOneWidget);
      expect(find.text('Dormant Daniyal'), findsOneWidget);
    });
  });

  group('ManualBookingCustomerStep — blocked / archived guard', () {
    CustomerEntity stepCustomer({
      required String id,
      required String name,
      required String cnic,
      Map<String, String>? shopStatuses,
    }) =>
        CustomerEntity(
          customerId: id,
          // In tests currentShopId() is 'shop-1' (nobody signed in),
          // so statuses are keyed by that id here.
          shopId: 'shop-1',
          name: name,
          phone: '03001234567',
          cnic: cnic,
          createdAt: DateTime(2026, 11, 1),
          shopStatuses: shopStatuses,
        );

    final good = stepCustomer(
        id: 'cust-w3-good', name: 'Good Ghulam', cnic: '35202-1234567-1');
    final blocked = stepCustomer(
        id: 'cust-w3-blocked',
        name: 'Blocked Bilal',
        cnic: '35202-1234567-2',
        shopStatuses: {'shop-1': 'blocked'});
    final archived = stepCustomer(
        id: 'cust-w3-archived',
        name: 'Archived Ayesha',
        cnic: '35202-1234567-3',
        shopStatuses: {'shop-1': 'archived'});

    Widget appFor(Widget home) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        );

    Future<void> pumpStep(
      WidgetTester tester, {
      CustomerEntity? selected,
      ValueChanged<CustomerEntity>? onSelected,
      String? prefilledCnic,
    }) async {
      await tester.pumpWidget(appFor(Scaffold(
        body: SingleChildScrollView(
            child: ManualBookingCustomerStep(
          selected: selected,
          onSelected: onSelected ?? (_) {},
          onAddNewCustomer: (_) {},
          onGuarantorChanged: (_) {},
          initialCustomers: [good, blocked, archived],
          prefilledCnic: prefilledCnic,
        )),
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('archived customer does not appear in the pick list',
        (tester) async {
      await pumpStep(tester);
      expect(
          find.byKey(
              const ValueKey('manual-booking-customer-cust-w3-good')),
          findsOneWidget);
      expect(
          find.byKey(
              const ValueKey('manual-booking-customer-cust-w3-blocked')),
          findsOneWidget);
      expect(
          find.byKey(
              const ValueKey('manual-booking-customer-cust-w3-archived')),
          findsNothing);
      expect(find.text('Archived Ayesha'), findsNothing);
    });

    testWidgets('blocked customer shows the chip and cannot be selected',
        (tester) async {
      CustomerEntity? selected;
      await pumpStep(tester, onSelected: (c) => selected = c);
      expect(find.text('Blocked — cannot book'), findsOneWidget);
      await tester.tap(find.byKey(
          const ValueKey('manual-booking-customer-cust-w3-blocked')));
      await tester.pump();
      expect(selected, isNull);
      expect(
          find.text(
              'This customer is blocked — walk-in booking refused.'),
          findsOneWidget);
      // A normal customer is still selectable.
      await tester.tap(find.byKey(
          const ValueKey('manual-booking-customer-cust-w3-good')));
      await tester.pumpAndSettle();
      expect(selected?.customerId, 'cust-w3-good');
    });

    testWidgets('blocked customer is never auto-selected by prefill',
        (tester) async {
      CustomerEntity? selected;
      await pumpStep(tester,
          onSelected: (c) => selected = c,
          prefilledCnic: '35202-1234567-2');
      expect(selected, isNull);
    });

    testWidgets('search still hides the archived customer', (tester) async {
      await pumpStep(tester);
      await tester.enterText(
          find.byKey(const Key('manual-booking-customer-search')),
          'Archived');
      await tester.pumpAndSettle();
      expect(find.text('Archived Ayesha'), findsNothing);
      expect(
          find.byKey(
              const ValueKey('manual-booking-customer-cust-w3-good')),
          findsNothing);
    });
  });
}
