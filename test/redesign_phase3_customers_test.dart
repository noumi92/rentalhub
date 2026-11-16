// Showroom redesign Phase 3 (Customers): the active-rental banner
// selection, the KYC uploaded-count logic, and the rebuilt
// list-row / detail widgets. Widget tests only — no DI/Firestore:
// the list view itself loads through data sources, so its row is
// covered here through CustomerListCardHeader directly.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/customer/utils/customer_grouping.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_active_rental_banner.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_detail_header.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_detail_kyc_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_kyc_slots.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_list_card_header.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_row_book_action.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  CustomerEntity customer({
    String? profilePhotoUrl,
    String? thumbprintUrl,
    String? leftFingerprintUrl,
    String? rightFingerprintUrl,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? licenseFrontUrl,
    String? licenseBackUrl,
    String? utilityBillUrl,
    List<String> extraDocumentUrls = const [],
    String? signatureUrl,
    String approvalStatus = 'pending',
    String? rejectionReason,
  }) =>
      CustomerEntity(
        customerId: 'cust-1',
        shopId: 'shop-1',
        name: 'Ahmed Khan',
        phone: '0300-1234567',
        cnic: '35202-1234567-1',
        createdAt: DateTime.utc(2026, 11, 1),
        profilePhotoUrl: profilePhotoUrl,
        thumbprintUrl: thumbprintUrl,
        leftFingerprintUrl: leftFingerprintUrl,
        rightFingerprintUrl: rightFingerprintUrl,
        cnicFrontUrl: cnicFrontUrl,
        cnicBackUrl: cnicBackUrl,
        licenseFrontUrl: licenseFrontUrl,
        licenseBackUrl: licenseBackUrl,
        utilityBillUrl: utilityBillUrl,
        extraDocumentUrls: extraDocumentUrls,
        signatureUrl: signatureUrl,
        approvalStatus: approvalStatus,
        rejectionReason: rejectionReason,
      );

  BookingEntity booking({
    String id = 'b-1',
    String status = 'requested',
    String? vehicleName,
    int totalAmount = 5000,
  }) =>
      BookingEntity(
        bookingId: id,
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 10, 9),
        returnTime: DateTime(2026, 11, 11, 9),
        totalAmount: totalAmount,
        remainingBalance: 0,
        status: status,
        vehicleName: vehicleName,
      );

  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: child),
      );

  group('Phase 3 — KYC slots (11 tracked)', () {
    test('the slot list has exactly 11 entries with distinct labels', () {
      expect(kycTotalSlots, 11);
      final slots = kycDocSlots(l10n, customer());
      expect(slots, hasLength(11));
      expect(slots.map((s) => s.label).toSet(), hasLength(11));
      for (final slot in slots) {
        expect(slot.label, isNotEmpty);
      }
      // The new finger labels come from the Phase 0 keys.
      expect(slots[2].label, l10n.kycLeftFourFingers);
      expect(slots[3].label, l10n.kycRightFourFingers);
    });

    test('empty record counts 0/11', () {
      expect(kycUploadedCount(customer()), 0);
    });

    test('full record counts 11/11', () {
      const url = 'https://example.invalid/kyc/file.jpg';
      final full = customer(
        profilePhotoUrl: url,
        thumbprintUrl: url,
        leftFingerprintUrl: url,
        rightFingerprintUrl: url,
        cnicFrontUrl: url,
        cnicBackUrl: url,
        licenseFrontUrl: url,
        licenseBackUrl: url,
        utilityBillUrl: url,
        extraDocumentUrls: const [url],
        signatureUrl: url,
      );
      expect(kycUploadedCount(full), 11);
    });

    test('partial record counts only uploaded slots; empty strings do not count', () {
      final partial = customer(
        profilePhotoUrl: 'https://example.invalid/kyc/face.jpg',
        cnicFrontUrl: '',
        licenseFrontUrl: 'https://example.invalid/kyc/lic.jpg',
        extraDocumentUrls: const ['https://example.invalid/kyc/extra.jpg'],
      );
      // Face + license front + extra documents (one slot) = 3.
      expect(kycUploadedCount(partial), 3);
      // Extra documents is a single slot however many files it holds.
      final manyExtras = customer(
        extraDocumentUrls: const [
          'https://example.invalid/kyc/e1.jpg',
          'https://example.invalid/kyc/e2.jpg',
        ],
      );
      expect(kycUploadedCount(manyExtras), 1);
    });
  });

  group('Phase 3 — active-rental banner selection', () {
    test('selects only active bookings from the already-loaded list', () {
      final bookings = [
        booking(id: 'b-1', status: 'completed'),
        booking(id: 'b-2', status: 'active', vehicleName: 'Corolla'),
        booking(id: 'b-3', status: 'approved'),
        booking(id: 'b-4', status: 'active', vehicleName: 'Civic'),
      ];
      final active = selectActiveBookings(bookings);
      expect(active.map((b) => b.bookingId), ['b-2', 'b-4']);
    });

    test('no active booking selects nothing', () {
      expect(
          selectActiveBookings(
              [booking(status: 'completed'), booking(status: 'paid')]),
          isEmpty);
    });

    testWidgets('banner appears iff an active booking exists, with vehicle and amount',
        (tester) async {
      await tester.pumpWidget(wrap(CustomerActiveRentalBanner(
          bookings: [booking(status: 'active', vehicleName: 'Corolla')])));
      await tester.pump();
      expect(find.text(l10n.activeRentals), findsOneWidget);
      expect(find.textContaining('Corolla'), findsOneWidget);
      expect(find.textContaining('Rs. 5,000'), findsOneWidget);
    });

    testWidgets('banner renders nothing without an active booking',
        (tester) async {
      await tester.pumpWidget(wrap(CustomerActiveRentalBanner(
          bookings: [booking(status: 'completed')])));
      await tester.pump();
      expect(find.text(l10n.activeRentals), findsNothing);
    });
  });

  group('Phase 3 — KYC section', () {
    testWidgets('header shows the real uploaded count out of 11',
        (tester) async {
      const url = 'https://example.invalid/kyc/file.jpg';
      final three = customer(
        profilePhotoUrl: url,
        cnicFrontUrl: url,
        signatureUrl: url,
      );
      await tester.pumpWidget(wrap(SizedBox(
          width: 360,
          child: SingleChildScrollView(
              child: CustomerDetailKycSection(customer: three)))));
      // Network thumbnails fail in tests (HttpClient returns 400)
      // and fall back via errorBuilder, so every tile shows
      // "Not provided" here — the uploaded/missing distinction is
      // proven by the kycUploadedCount unit tests above.
      await tester.pumpAndSettle();
      expect(find.text(l10n.customerDetailKycDocumentsCount(3, 11)),
          findsOneWidget);
      expect(find.text(l10n.customerDetailNoDocument), findsWidgets);
      // All 11 slot labels render in the grid.
      for (final slot in kycDocSlots(l10n, three)) {
        expect(find.text(slot.label), findsOneWidget);
      }
    });
  });

  group('Phase 3 — list card header', () {
    testWidgets('phone + CNIC share one line; pill shows total and count',
        (tester) async {
      var tapped = false;
      final summary = CustomerSummary(
        key: 'cnic:3520212345671',
        name: 'Ahmed Khan',
        phone: '0300-1234567',
        cnic: '35202-1234567-1',
        bookingCount: 2,
        totalSpent: 5000,
        bookings: const [],
      );
      await tester.pumpWidget(wrap(CustomerListCardHeader(
        customer: summary,
        blacklisted: false,
        expanded: false,
        onTap: () => tapped = true,
      )));
      await tester.pump();
      expect(find.text('0300-1234567 • 35202-1234567-1'), findsOneWidget);
      expect(
          find.text(l10n.customersBookingTotal('Rs. 5,000', 2)),
          findsOneWidget);
      expect(find.text(l10n.customersBadgeRegular), findsOneWidget);
      await tester.tap(find.byType(CustomerListCardHeader));
      expect(tapped, isTrue);
    });
  });

  group('Phase 3 — expanded row actions', () {
    testWidgets('Call + View Profile + solid Book a Car in a 48px row',
        (tester) async {
      final summary = CustomerSummary(
        key: 'cnic:3520212345671',
        name: 'Ahmed Khan',
        phone: '0300-1234567',
        cnic: '35202-1234567-1',
        bookingCount: 1,
        totalSpent: 5000,
        bookings: const [],
      );
      await tester.pumpWidget(
          wrap(CustomerRowBookAction(customer: summary)));
      await tester.pump();
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
      expect(find.byTooltip(l10n.call), findsOneWidget);
      expect(find.text(l10n.customersViewProfile), findsOneWidget);
      expect(find.text(l10n.quickBookCar), findsOneWidget);
      // The row itself is 48 px high (rulebook §4.6 minimum touch
      // target); the widget adds 12 px bottom padding around it.
      final rowBox = tester.getSize(find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 48 && w.width == null));
      expect(rowBox.height, 48);
      // Call is enabled when a phone number exists.
      final callButton = tester.widget<OutlinedButton>(find.ancestor(
          of: find.byIcon(Icons.call_rounded),
          matching: find.byType(OutlinedButton)));
      expect(callButton.onPressed, isNotNull);
    });

    testWidgets('Call is disabled with no phone number', (tester) async {
      const summary = CustomerSummary(
        key: 'id:cust-1',
        name: 'Ahmed Khan',
        phone: '',
        bookingCount: 0,
        totalSpent: 0,
        bookings: [],
      );
      await tester.pumpWidget(
          wrap(const CustomerRowBookAction(customer: summary)));
      await tester.pump();
      final callButton = tester.widget<OutlinedButton>(find.ancestor(
          of: find.byIcon(Icons.call_rounded),
          matching: find.byType(OutlinedButton)));
      expect(callButton.onPressed, isNull);
    });
  });

  group('Phase 3 — detail header', () {
    testWidgets('rejected profile merges reason + KYC status in one alert',
        (tester) async {
      final rejected = customer(
        approvalStatus: 'rejected',
        rejectionReason: 'CNIC photo unreadable',
      );
      await tester.pumpWidget(wrap(
          CustomerDetailHeader(customer: rejected, blacklisted: false)));
      await tester.pump();
      // Slim identity: phone + CNIC on one line.
      expect(find.text('0300-1234567 • 35202-1234567-1'), findsOneWidget);
      expect(find.text(l10n.statusRejected), findsOneWidget);
      expect(find.text(l10n.customerDetailNotBlacklisted), findsOneWidget);
      expect(find.text('CNIC photo unreadable'), findsOneWidget);
      expect(find.text(l10n.customerDetailKycNotOnFile), findsOneWidget);
    });

    testWidgets('approved profile with KYC on file shows no alert banner',
        (tester) async {
      final ok = customer(
        approvalStatus: 'approved',
        profilePhotoUrl: 'https://example.invalid/kyc/face.jpg',
      );
      await tester.pumpWidget(
          wrap(CustomerDetailHeader(customer: ok, blacklisted: false)));
      await tester.pump();
      expect(find.text(l10n.statusApproved), findsOneWidget);
      expect(find.text(l10n.customerDetailKycNotOnFile), findsNothing);
      expect(find.text(l10n.customerDetailKycOnFile), findsNothing);
    });
  });
}
