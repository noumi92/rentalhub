import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/models/customer_model.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/customer/utils/customer_grouping.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_blacklist_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_cnic_review_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/guarantor_picker.dart';
import 'package:rentalhub/features/trust/utils/cnic_text_parser.dart';

// Owner Module Plan — Phase C: customers list, CNIC OCR with review,
// guarantor picker, and the blacklist made real (Firestore).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  const frontText = '''
PAKISTAN
National Identity Card
Name
Muhammad Ahmed
Father Name
Muhammad Ali
Identity Number
35201-1234567-1
Date of Birth
15.03.1990
Date of Issue
01.01.2020
Date of Expiry
01.01.2030
''';

  const backText = '''
Permanent Address
House 12, Street 4, Gulberg III, Lahore
Current Address
House 12, Street 4, Gulberg III, Lahore
''';

  group('Phase C (C2) — CNIC text parsing', () {
    test('front of the card reads name, father, CNIC and dates', () {
      final r = CnicTextParser.parseFront(frontText);
      expect(r.name, 'Muhammad Ahmed');
      expect(r.fatherName, 'Muhammad Ali');
      expect(r.cnicNumber, '35201-1234567-1');
      expect(r.dateOfBirth, '15.03.1990');
      expect(r.dateOfIssue, '01.01.2020');
      expect(r.dateOfExpiry, '01.01.2030');
      expect(r.hasAnything, isTrue);
    });

    test('back of the card reads the address', () {
      final r = CnicTextParser.parseBack(backText);
      expect(r.address, 'House 12, Street 4, Gulberg III, Lahore');
      expect(r.hasAnything, isTrue);
    });

    test('OCR digit confusion (O for 0) is corrected in the CNIC', () {
      final r = CnicTextParser.parseFront(
          'Identity Number\n352O1-1234567-1\nDate of Birth\n15.O3.199O');
      expect(r.cnicNumber, '35201-1234567-1');
      expect(r.dateOfBirth, '15.03.1990');
    });

    test('garbage text parses to nothing', () {
      final r = CnicTextParser.parseFront('hello world\nno card here');
      expect(r.hasAnything, isFalse);
      expect(CnicTextParser.parseBack('hello').hasAnything, isFalse);
    });
  });

  group('Phase C (C1) — customer records and grouping', () {
    test('customer model round-trips with OCR fields', () {
      final model = CustomerModel(
        customerId: 'cust-3520112345671',
        shopId: 'shop-1',
        name: 'Muhammad Ahmed',
        phone: '0300-1234567',
        cnic: '35201-1234567-1',
        source: 'ocr',
        createdAt: DateTime(2026, 11, 6),
        dateOfBirth: '15.03.1990',
        cnicExpiry: '01.01.2030',
      );
      final restored =
          CustomerModel.fromMap(model.toMap(), 'cust-3520112345671');
      expect(restored.toMap(), model.toMap());
      expect(restored.dateOfBirth, '15.03.1990');
    });

    test('datasource upserts and finds by CNIC', () async {
      final ds = CustomerRemoteDataSource();
      final customer = CustomerEntity(
        customerId: 'cust-3520112345671',
        shopId: 'shop-c1',
        name: 'Muhammad Ahmed',
        phone: '0300-1234567',
        cnic: '35201-1234567-1',
        source: 'ocr',
        createdAt: DateTime(2026, 11, 6),
      );
      await ds.upsertCustomer(customer);
      final found = await ds.getCustomerByCnic('shop-c1', '3520112345671');
      expect(found?.name, 'Muhammad Ahmed');
      expect(await ds.getCustomerByCnic('shop-c1', '35201-9999999-9'),
          isNull);
      final all = await ds.getShopCustomers('shop-c1');
      expect(all.length, 1);
    });

    test('bookings group by CNIC with totals and last booking', () {
      BookingModel booking(String id, String cnic, int total, int day) {
        return BookingModel(
          bookingId: id,
          customerId: 'cust-$id',
          shopId: 'shop-1',
          vehicleId: 'veh-1',
          packageType: '24h',
          pickupTime: DateTime(2026, 11, day, 9),
          returnTime: DateTime(2026, 11, day + 1, 9),
          totalAmount: total,
          remainingBalance: total,
          customerName: 'Muhammad Ahmed',
          customerPhone: '0300-1234567',
          customerCnic: cnic,
        );
      }

      final summaries = groupCustomerSummaries(
        bookings: [
          booking('b1', '35201-1234567-1', 9000, 3),
          booking('b2', '3520112345671', 11500, 5),
          booking('b3', '', 6000, 2),
        ],
        savedCustomers: [
          CustomerEntity(
            customerId: 'cust-3520112345671',
            shopId: 'shop-1',
            name: 'Muhammad Ahmed',
            phone: '0300-1234567',
            cnic: '35201-1234567-1',
            source: 'ocr',
            createdAt: DateTime(2026, 11, 6),
          ),
        ],
      );
      expect(summaries.length, 2);
      final ahmed = summaries.firstWhere((s) => s.name == 'Muhammad Ahmed');
      expect(ahmed.bookingCount, 2);
      expect(ahmed.totalSpent, 20500);
      expect(ahmed.lastBookingAt?.day, 5);
      expect(ahmed.savedRecord, isNotNull);
    });

    test('booking carries CNIC and guarantor fields', () {
      final model = BookingModel(
        bookingId: 'RH-c1',
        customerId: 'walkin-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 9000,
        remainingBalance: 9000,
        customerName: 'Walk-in Customer',
        customerPhone: '0300-1122334',
        customerCnic: '35201-1234567-1',
        guarantorName: 'Muhammad Ali',
        guarantorCnic: '35201-7654321-2',
        guarantorPhone: '0300-7654321',
      );
      final restored = BookingModel.fromMap(model.toMap(), 'RH-c1');
      expect(restored.customerCnic, '35201-1234567-1');
      expect(restored.guarantorName, 'Muhammad Ali');
      expect(restored.guarantorCnic, '35201-7654321-2');
      expect(restored.toMap(), model.toMap());
    });

    testWidgets('customers list rolls bookings up per customer',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      await ds.createBookingRequest(
        customerId: 'cust-ahmed',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 3, 9),
        returnTime: DateTime(2026, 11, 4, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Muhammad Ahmed',
        customerPhone: '0300-1234567',
        customerCnic: '35201-1234567-1',
      );
      await ds.createBookingRequest(
        customerId: 'cust-ahmed-2',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 5, 9),
        returnTime: DateTime(2026, 11, 6, 9),
        totalAmount: 11500,
        advanceRequired: 3000,
        customerName: 'Muhammad Ahmed',
        customerPhone: '0300-1234567',
        customerCnic: '3520112345671',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: OwnerCustomersListView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Muhammad Ahmed'), findsOneWidget);
      expect(find.textContaining('2 bookings • Rs. 20500'), findsOneWidget);

      await tester.tap(find.text('Muhammad Ahmed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Rs. 9000'), findsWidgets);
    });
  });

  group('Phase C (C3) — guarantor picker', () {
    testWidgets('picking a saved customer selects them as guarantor',
        (tester) async {
      final ds = di.sl<CustomerRemoteDataSource>();
      await ds.upsertCustomer(CustomerEntity(
        customerId: 'cust-g1',
        shopId: 'shop-1',
        name: 'Muhammad Ali',
        phone: '0300-7654321',
        cnic: '35201-7654321-2',
        source: 'walk_in',
        createdAt: DateTime(2026, 11, 6),
      ));
      GuarantorSelection? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuarantorPicker(
              shopId: 'shop-1',
              onChanged: (g) => picked = g,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Muhammad Ali'), findsOneWidget);

      await tester.tap(find.text('Muhammad Ali'));
      await tester.pumpAndSettle();
      expect(picked?.name, 'Muhammad Ali');
      expect(picked?.cnic, '35201-7654321-2');
      expect(find.textContaining('35201-7654321-2 • 0300-7654321'),
          findsOneWidget);
    });

    testWidgets('a blacklisted CNIC cannot be added as guarantor',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuarantorPicker(
              shopId: 'shop-1',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add new guarantor'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Guarantor full name'),
          'Bad Actor');
      await tester.enterText(
          find.widgetWithText(TextField, 'Phone number'), '0300-0000000');
      await tester.enterText(
          find.widgetWithText(TextField, 'CNIC number'), '35201-9999999-1');
      await tester.tap(find.text('Save & Select Guarantor'));
      await tester.pumpAndSettle();
      expect(find.textContaining('blacklisted'), findsOneWidget);
    });
  });

  group('Phase C (C4) — blacklist made real', () {
    test('report, lookup, my-reports and revert', () async {
      final ds = BlacklistRemoteDataSource();
      // The offline sample is still there.
      expect(await ds.isCnicBlacklisted('35201-9999999-1'), isTrue);
      final record = await ds.getBlacklistRecordByCnic('35201-9999999-1');
      expect(record?.blacklistId, 'BLK-1001');

      final reported = await ds.reportCustomerToBlacklist(
        reportedByShopId: 'shop-c4',
        cnicNumber: '35201-1111111-1',
        phoneNumber: '0300-1111111',
        reasonCategory: 'Non-payment',
        description: 'Did not pay Rs. 9000 for a 1-day rental.',
      );
      expect(await ds.isCnicBlacklisted('3520111111111'), isTrue);
      final mine = await ds.getShopReports('shop-c4');
      expect(mine.length, 1);
      expect(mine.first.blacklistId, reported.blacklistId);

      final reverted = await ds.revertBlacklistRecord(
        blacklistId: reported.blacklistId,
        adminUid: 'admin-1',
        justification: 'Paid in full after tribunal review.',
      );
      expect(reverted.isActive, isFalse);
      expect(await ds.isCnicBlacklisted('35201-1111111-1'), isFalse);
    });

    testWidgets('blacklist view files a report and lists it',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OwnerBlacklistView(shopId: 'shop-c4-view'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Blacklist Reports'), findsOneWidget);
      expect(find.text('My reports (0)'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Customer CNIC'),
          '35201-2222222-2');
      await tester.enterText(
          find.widgetWithText(TextField, 'Customer phone'), '0300-2222222');
      await tester.enterText(
          find.widgetWithText(
              TextField, 'What happened? (dates, car, amount)'),
          'Returned the car 3 days late with damage.');
      await tester.tap(find.text('Report to Blacklist'));
      await tester.pumpAndSettle();
      expect(find.text('My reports (1)'), findsOneWidget);
      expect(find.text('35201-2222222-2'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });
  });

  group('Phase C (C2) — CNIC review view', () {
    testWidgets('review saves the scanned customer', (tester) async {
      String? savedCnic;
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerCnicReviewView(
            initial: CnicTextParser.parseFront(frontText),
            shopId: 'shop-1',
            onSaved: (cnic) => savedCnic = cnic,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Review Scanned CNIC'), findsOneWidget);
      final nameField =
          tester.widget<TextField>(find.widgetWithText(TextField, 'Full Name'));
      expect(nameField.controller?.text, 'Muhammad Ahmed');

      await tester.enterText(
          find.widgetWithText(TextField, 'Phone Number'), '0300-1234567');
      await tester.ensureVisible(
          find.text('Save Customer & Check Blacklist'));
      await tester.tap(find.text('Save Customer & Check Blacklist'));
      await tester.pumpAndSettle();
      expect(savedCnic, '35201-1234567-1');

      final saved = await di.sl<CustomerRemoteDataSource>()
          .getCustomerByCnic('shop-1', '35201-1234567-1');
      expect(saved?.name, 'Muhammad Ahmed');
      expect(saved?.source, 'ocr');
    });
  });

  group('Phase C — routing', () {
    test('customers and blacklist routes exist', () async {
      final names = await File('lib/core/routing/route_names.dart')
          .readAsString();
      final router =
          await File('lib/core/routing/app_router.dart').readAsString();
      expect(names, contains("ownerCustomers = '/owner/customers'"));
      expect(router, contains('OwnerCustomersListView'));
      expect(router, contains('OwnerBlacklistView'));
    });
  });
}
