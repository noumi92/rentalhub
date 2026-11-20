import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/approved_accounts_body.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/shop_payment_account.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/approve_booking_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// O18 — Approve & Assign Account: the owner picks the payment
// account at approval time, the booking stores it plus a 30-minute
// (display-only) payment deadline, and the customer then sees only
// the assigned account.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BookingModel modelFor(String id) {
    return BookingModel(
      bookingId: id,
      customerId: 'cust-$id',
      shopId: 'shop-1',
      vehicleId: 'veh-1',
      packageType: '24h',
      pickupTime: DateTime(2026, 11, 20, 9),
      returnTime: DateTime(2026, 11, 21, 9),
      totalAmount: 9000,
      advanceRequired: 3000,
      remainingBalance: 6000,
      customerName: 'Ayesha Khan',
      customerPhone: '0300-1111111',
      vehicleName: 'Honda Civic Oriel',
    );
  }

  group('O18 — write path', () {
    test('updateBookingStatus stores the account + deadline', () async {
      final ds = BookingRemoteDataSource();
      final created = await ds.createBookingRequest(
        customerId: 'cust-o18a',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 20, 9),
        returnTime: DateTime(2026, 11, 21, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Ayesha Khan',
      );
      final deadline = DateTime(2026, 11, 20, 10, 30);
      final updated = await ds.updateBookingStatus(
        bookingId: created.bookingId,
        status: 'approved',
        selectedPaymentAccount: '0300-1111111',
        paymentDeadline: deadline,
      );
      expect(updated.status, 'approved');
      expect(updated.selectedPaymentAccount, '0300-1111111');
      expect(updated.paymentDeadline, deadline);
      final stored = await ds.getBookingById(created.bookingId);
      expect(stored?.selectedPaymentAccount, '0300-1111111');
      expect(stored?.paymentDeadline, deadline);
      // The model round-trips both fields (the offline queue
      // replays them from the same map).
      final restored = BookingModel.fromMap(
          BookingModel.fromEntity(updated).toMap(), updated.bookingId);
      expect(restored.selectedPaymentAccount, '0300-1111111');
      expect(restored.paymentDeadline, deadline);
    });

    test('a later status-only update keeps the assigned account', () async {
      final ds = BookingRemoteDataSource();
      final created = await ds.createBookingRequest(
        customerId: 'cust-o18b',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 20, 9),
        returnTime: DateTime(2026, 11, 21, 9),
        totalAmount: 9000,
        advanceRequired: 3000,
        customerName: 'Bilal Ahmed',
      );
      await ds.updateBookingStatus(
        bookingId: created.bookingId,
        status: 'approved',
        selectedPaymentAccount: 'PK00MEZN0000000000000001',
        paymentDeadline: DateTime(2026, 11, 20, 10, 30),
      );
      final proofed = await ds.updatePaymentProof(
        bookingId: created.bookingId,
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-1',
      );
      expect(proofed.status, 'payment_submitted');
      expect(proofed.selectedPaymentAccount, 'PK00MEZN0000000000000001');
    });
  });

  group('O18 — account visibility', () {
    final accounts = ShopPaymentAccount.fromShopData({
      'bank_accounts': [
        {
          'type': 'jazzcash',
          'account': '0300-1111111',
          'title': 'Shop JazzCash',
        },
        {
          'type': 'easypaisa',
          'account': '0300-2222222',
          'title': 'Shop EasyPaisa',
        },
        {
          'type': 'bank',
          'bank_name': 'Meezan Bank',
          'iban': 'PK00MEZN0000000000000001',
          'title': 'Shop Current',
        },
      ],
    });
    test('parses wallets and banks from the shop doc shape', () {
      expect(accounts.length, 3);
      expect(accounts[0].number, '0300-1111111');
      expect(accounts[2].number, 'PK00MEZN0000000000000001');
      expect(accounts[2].isWallet, isFalse);
    });

    test('no assignment shows every account', () {
      expect(ShopPaymentAccount.visible(accounts, null).length, 3);
    });

    test('an assignment shows only the chosen account', () {
      final shown = ShopPaymentAccount.visible(accounts, '0300-2222222');
      expect(shown.length, 1);
      expect(shown.single.number, '0300-2222222');
    });

    test('a removed assigned account falls back to all accounts', () {
      expect(
          ShopPaymentAccount.visible(accounts, '0300-9999999').length, 3);
    });
  });

  group('O18 — approve sheet', () {
    testWidgets('selecting an account + confirming writes it + deadline',
        (tester) async {
      final fake = _FakeBookingDataSource(modelFor('RH-o18'));
      final accounts = ShopPaymentAccount.fromShopData({
        'bank_accounts': [
          {
            'type': 'jazzcash',
            'account': '0300-1111111',
            'title': 'Shop JazzCash',
          },
          {
            'type': 'bank',
            'bank_name': 'Meezan Bank',
            'iban': 'PK00MEZN0000000000000001',
            'title': 'Shop Current',
          },
        ],
      });
      BookingEntity? approved;
      final before = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showApproveBookingSheet(
                  context,
                  booking: modelFor('RH-o18'),
                  accounts: accounts,
                  securityDepositPkr: 25000,
                  dataSource: fake,
                  onApproved: (updated) => approved = updated,
                ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Approve & assign payment account'), findsOneWidget);
      expect(find.textContaining('0300-1111111'), findsOneWidget);
      expect(find.textContaining('PK00MEZN0000000000000001'), findsOneWidget);
      // Terms: advance now, remaining at pickup, vehicle deposit.
      expect(find.textContaining('3,000'), findsWidgets);
      expect(find.textContaining('6,000'), findsWidgets);
      expect(find.textContaining('25,000'), findsOneWidget);
      // Confirm is disabled until an account is picked.
      final confirm = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Approve & assign account'));
      expect(confirm.onPressed, isNull);

      await tester.tap(find.text('JazzCash'));
      await tester.pump();
      await tester.tap(find.text('Approve & assign account'));
      await tester.pumpAndSettle();

      expect(fake.calls, 1);
      expect(fake.lastStatus, 'approved');
      expect(fake.lastAccount, '0300-1111111');
      expect(fake.lastDeadline, isNotNull);
      expect(
        fake.lastDeadline!.difference(before),
        greaterThanOrEqualTo(const Duration(minutes: 29)),
      );
      expect(
        fake.lastDeadline!.difference(before),
        lessThanOrEqualTo(const Duration(minutes: 31)),
      );
      expect(approved?.status, 'approved');
      expect(approved?.selectedPaymentAccount, '0300-1111111');
      expect(find.text('Approve & assign payment account'), findsNothing);
    });

    testWidgets('no configured accounts leaves confirm disabled',
        (tester) async {
      final fake = _FakeBookingDataSource(modelFor('RH-o18b'));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showApproveBookingSheet(
                  context,
                  booking: modelFor('RH-o18b'),
                  accounts: const [],
                  dataSource: fake,
                  onApproved: (_) {},
                ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'No payment accounts configured for this shop yet. Add one in shop settings before approving.'),
          findsOneWidget);
      final confirm = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Approve & assign account'));
      expect(confirm.onPressed, isNull);
      expect(fake.calls, 0);
    });
  });

  group('O18 — customer payment view', () {
    Future<FakeFirebaseFirestore> seededShop() async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('shops').doc('shop-1').set({
        'bank_accounts': [
          {
            'type': 'jazzcash',
            'account': '0300-1111111',
            'title': 'Shop JazzCash',
          },
          {
            'type': 'easypaisa',
            'account': '0300-2222222',
            'title': 'Shop EasyPaisa',
          },
        ],
      });
      return fake;
    }

    Future<void> pumpBody(
      WidgetTester tester,
      FakeFirebaseFirestore fake,
      BookingEntity booking,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ApprovedAccountsBody(
              booking: booking,
              firestore: fake,
              onProceedToUploadProof: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('no assignment shows every account', (tester) async {
      final fake = await seededShop();
      await pumpBody(tester, fake, modelFor('RH-o18c').copyWith(status: 'approved'));
      expect(find.text('0300-1111111'), findsOneWidget);
      expect(find.text('0300-2222222'), findsOneWidget);
      expect(
          find.text(
              'Pay to the verified showroom accounts below and capture a screenshot of your transfer.'),
          findsOneWidget);
    });

    testWidgets('an assignment shows only the chosen account + deadline',
        (tester) async {
      final fake = await seededShop();
      final booking = modelFor('RH-o18d').copyWith(
        status: 'approved',
        selectedPaymentAccount: '0300-2222222',
        paymentDeadline: DateTime(2026, 11, 20, 10, 30),
      );
      await pumpBody(tester, fake, booking);
      expect(find.text('0300-2222222'), findsOneWidget);
      expect(find.text('0300-1111111'), findsNothing);
      expect(find.text('Pay only into the assigned account below.'),
          findsOneWidget);
      expect(find.textContaining('Pay within 30 minutes'), findsOneWidget);
    });
  });
}

/// Records updateBookingStatus calls instead of touching Firestore.
class _FakeBookingDataSource extends BookingRemoteDataSource {
  final BookingEntity booking;
  int calls = 0;
  String? lastStatus;
  String? lastAccount;
  DateTime? lastDeadline;

  _FakeBookingDataSource(this.booking);

  @override
  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
    String? rejectionReason,
    String? selectedPaymentAccount,
    DateTime? paymentDeadline,
  }) async {
    calls++;
    lastStatus = status;
    lastAccount = selectedPaymentAccount;
    lastDeadline = paymentDeadline;
    return booking.copyWith(
      status: status,
      selectedPaymentAccount: selectedPaymentAccount,
      paymentDeadline: paymentDeadline,
    );
  }
}
