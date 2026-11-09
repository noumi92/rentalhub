import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_customer_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_customers_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_blacklist_tribunal_view.dart';
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Phase C (C3) — the trust-score formula', () {
    test('a verified new customer scores 3.5', () {
      final score = TrustScoreCalculator.calculate(
        kycStatus: 'verified',
        completedTrips: 0,
        meanOwnerRating: null,
        onTimeReturns: 0,
        lateReturns: 0,
        adverseEvents: 0,
      );
      expect(score.total, 3.5);
      expect(score.kyc, 1.0);
      expect(score.trips, 0.0);
    });

    test('a perfect record scores 5.0', () {
      final score = TrustScoreCalculator.calculate(
        kycStatus: 'verified',
        completedTrips: 12,
        meanOwnerRating: 5.0,
        onTimeReturns: 12,
        lateReturns: 0,
        adverseEvents: 0,
      );
      expect(score.total, 5.0);
    });

    test('a bad record is pulled down and clamped', () {
      final score = TrustScoreCalculator.calculate(
        kycStatus: 'missing',
        completedTrips: 1,
        meanOwnerRating: 1.0,
        onTimeReturns: 0,
        lateReturns: 1,
        adverseEvents: 3,
      );
      expect(score.total, closeTo(2.5 + 0.1 - 0.6 - 0.1 - 1.0, 0.001));
      expect(score.conduct, -1.0);
    });

    test('submitted KYC is worth half of verified', () {
      final score = TrustScoreCalculator.calculate(
        kycStatus: 'submitted',
        completedTrips: 0,
        meanOwnerRating: null,
        onTimeReturns: 0,
        lateReturns: 0,
        adverseEvents: 0,
      );
      expect(score.total, 3.0);
    });
  });

  group('Phase C (C2) — the booking-time blacklist check', () {
    test('a blacklisted CNIC cannot book online', () async {
      final ds = BookingRemoteDataSource(
        blacklist: BlacklistRemoteDataSource(),
      );
      expect(
        () => ds.createBookingRequest(
          customerId: 'customer-1',
          shopId: 'shop-1',
          vehicleId: 'car-1',
          packageType: '24h',
          isWithDriver: false,
          pickupTime: DateTime(2026, 11, 8),
          returnTime: DateTime(2026, 11, 9),
          totalAmount: 5000,
          advanceRequired: 1000,
          customerCnic: '35201-9999999-1',
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('a clean CNIC books normally', () async {
      final ds = BookingRemoteDataSource(
        blacklist: BlacklistRemoteDataSource(),
      );
      final booking = await ds.createBookingRequest(
        customerId: 'customer-1',
        shopId: 'shop-1',
        vehicleId: 'car-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 8),
        returnTime: DateTime(2026, 11, 9),
        totalAmount: 5000,
        advanceRequired: 1000,
        customerCnic: '35202-1111111-1',
      );
      expect(booking.status, 'requested');
    });

    test('a blacklisted guarantor CNIC cannot book either', () async {
      final ds = BookingRemoteDataSource(
        blacklist: BlacklistRemoteDataSource(),
      );
      expect(
        () => ds.createBookingRequest(
          customerId: 'customer-1',
          shopId: 'shop-1',
          vehicleId: 'car-1',
          packageType: '24h',
          isWithDriver: false,
          pickupTime: DateTime(2026, 11, 8),
          returnTime: DateTime(2026, 11, 9),
          totalAmount: 5000,
          advanceRequired: 1000,
          customerCnic: '35202-1111111-1',
          guarantorCnic: '35201-9999999-1',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('Phase C — people data layer (offline)', () {
    test('reads are empty and writes fail honestly offline', () async {
      final ds = AdminPeopleDataSource();
      expect(await ds.getCustomers(), isEmpty);
      expect(await ds.getCustomerDetail('customer-1'), isNull);
      // The blacklist list reads the shared data source's in-memory
      // fallback offline, so the seeded sample record is visible.
      final records = await ds.getBlacklistRecords();
      expect(records.length, 1);
      expect(records.first.entity.blacklistId, 'BLK-1001');
      expect(
        await ds.setCustomerWatchlisted(
            customerId: 'customer-1', watchlisted: true),
        isFalse,
      );
      expect(
        await ds.addCustomerNote(customerId: 'customer-1', text: 'note'),
        isFalse,
      );
      expect(
        await ds.reportCustomerToBlacklist(
          customerId: 'customer-1',
          cnic: '35202-1111111-1',
          phone: '03001234567',
          reasonCategory: 'test',
          description: 'test',
          reportedByShopId: 'shop-1',
        ),
        isFalse,
      );
      expect(
        await ds.decideAppeal(
          blacklistId: 'BLK-1001',
          decision: 'keep',
          reason: 'test',
          adminUid: 'admin-1',
        ),
        isFalse,
      );
    });
  });

  group('Phase C — views render', () {
    testWidgets('customers list shows search and its empty state',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminCustomersView()));
      await tester.pumpAndSettle();
      // Twice: the header title and the narrow nav strip's chip.
      expect(find.text('Customers'), findsWidgets);
      expect(find.textContaining('No customers match'), findsOneWidget);
    });

    testWidgets('customer detail says not found for an unknown customer',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminCustomerDetailView(customerId: 'no-such-customer')));
      await tester.pumpAndSettle();
      expect(find.text('Customer not found.'), findsOneWidget);
    });

    testWidgets('tribunal lists the blacklist cases', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminBlacklistTribunalView()));
      await tester.pumpAndSettle();
      expect(find.text('National Rental Fraud & Blacklist Tribunal'),
          findsOneWidget);
      expect(find.textContaining('BLK-1001'), findsOneWidget);
    });
  });
}
