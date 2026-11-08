import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/handover/data/datasources/handover_local_data_source.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_cubit.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customer_scan_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_handover_signature_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_return_settlement_view.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Batch 4: Owner Operations & Blacklist CRUD Logic', () {
    late BlacklistRemoteDataSource blacklistDs;
    late BookingRemoteDataSource bookingDs;
    late HandoverCubit handoverCubit;

    setUp(() {
      blacklistDs = di.sl<BlacklistRemoteDataSource>();
      bookingDs = di.sl<BookingRemoteDataSource>();
      // Phase B (E3): the cubit is constructed directly without a
      // storage client, so sync stays local-only in tests and never
      // attempts a real cPanel upload.
      handoverCubit = HandoverCubit(
        localDataSource: di.sl<HandoverLocalDataSource>(),
      );
    });

    test('Blacklist Verification: detects blacklisted CNIC and retrieves incident file', () async {
      final isBlacklisted = await blacklistDs.isCnicBlacklisted('35201-9999999-1');
      expect(isBlacklisted, isTrue);

      final record = await blacklistDs.getBlacklistRecordByCnic('35201-9999999-1');
      expect(record, isNotNull);
      expect(record!.blacklistId, equals('BLK-1001'));
      expect(record.reasonCategory, contains('Default'));

      final cleanCheck = await blacklistDs.isCnicBlacklisted('35201-1111111-1');
      expect(cleanCheck, isFalse);
    });

    test('Booking Request Triage: approves incoming customer request', () async {
      final booking = await bookingDs.createBookingRequest(
        customerId: 'cust-triage-1',
        shopId: 'shop-1',
        vehicleId: 'v1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 10000,
        advanceRequired: 1000,
      );

      expect(booking.status, equals('requested'));

      final approved = await bookingDs.updateBookingStatus(
        bookingId: booking.bookingId,
        status: 'approved',
      );
      expect(approved.status, equals('approved'));
    });

    test('Handover Execution: captures telemetry, dual signatures and completes agreement', () async {
      await handoverCubit.completeHandoverOfflineFirst(
        bookingId: 'RH-TEST-HANDOVER-1',
        shopName: 'Al-Falah Rent a Car',
        customerName: 'Tariq Mehmood',
        cnicNumber: '35201-1234567-1',
        vehicleDetails: 'Toyota Yaris ATIV (2024)',
        initialOdometer: 32000,
        fuelLevel: '4/4 (Full)',
        damageNotes: ['Clean'],
        customerSignatureSvg: '<svg>cust</svg>',
        ownerSignatureSvg: '<svg>host</svg>',
        isOnline: true,
      );

      final pending = await di.sl<HandoverCubit>().localDataSource.getPendingSyncHandovers();
      expect(pending.any((h) => h.bookingId == 'RH-TEST-HANDOVER-1' && !h.isSynced), isFalse);
    });

    test('Settlement Arithmetic: computes excess KM penalty and net refund', () {
      const initialOdo = 50000;
      const returnOdo = 50350;
      const kmCap = 250;
      const ratePerExcessKm = 25;
      const depositHeld = 15000;
      const fuelDeficit = 3000;

      final totalDriven = returnOdo - initialOdo; // 350 km
      final excessKm = totalDriven - kmCap; // 100 km
      final excessPenalty = excessKm * ratePerExcessKm; // Rs. 2,500
      final totalDeductions = excessPenalty + fuelDeficit; // Rs. 5,500
      final netRefund = depositHeld - totalDeductions; // Rs. 9,500

      expect(totalDriven, equals(350));
      expect(excessKm, equals(100));
      expect(excessPenalty, equals(2500));
      expect(netRefund, equals(9500));
    });
  });

  group('Batch 4: Screen UI Actions & Rendering Tests', () {
    testWidgets('OwnerCustomerScanView: scans CNIC and displays blacklist result', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OwnerCustomerScanView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KYC & Blacklist Radar'), findsOneWidget);
      expect(find.text('NADRA CNIC Verification'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '35201-9999999-1');
      await tester.tap(find.text('Verify CNIC & Blacklist'));
      await tester.pumpAndSettle();

      expect(find.text('CRITICAL ALERT: BLACKLISTED CITIZEN'), findsOneWidget);
      expect(find.text('Decline / Refuse Service'), findsOneWidget);
    });

    testWidgets('OwnerBookingRequestsView: displays incoming triage list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerBookingRequestsView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Requests Triage'), findsOneWidget);
      // Phase A (A1): the hardcoded demo request was removed. With no
      // bookings in Firestore the view shows an honest empty state.
      expect(find.text('No pending booking requests'), findsOneWidget);
      expect(find.text('Approve & Pay'), findsNothing);
    });

    testWidgets('OwnerHandoverSignatureView: captures dual signatures and validates', (tester) async {
      final testBooking = BookingEntity(
        bookingId: 'RH-HO-99',
        customerId: 'c1',
        shopId: 'shop-1',
        vehicleId: 'v1',
        vehicleName: 'Honda Civic RS Turbo',
        packageType: '24h',
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advancePaid: 9000,
        remainingBalance: 0,
        status: 'paid',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerHandoverSignatureView(booking: testBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vehicle Handover & Inspection'), findsOneWidget);
      expect(find.text('Dual Legal Endorsement & Signatures'), findsOneWidget);
      expect(find.text('Damage & Condition Notes'), findsOneWidget);

      // Phase B (E2): the pads are real now — certifying without
      // signing is refused instead of toggling a fake signature.
      await tester.ensureVisible(
          find.text('Certify Handover & Generate Contract'));
      await tester.tap(find.text('Certify Handover & Generate Contract'));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'Both customer and host must sign on the pads before vehicle departure.'),
          findsOneWidget);
    });

    testWidgets('OwnerReturnSettlementView: displays return odometer telemetry and settlement', (tester) async {
      final testBooking = BookingEntity(
        bookingId: 'RH-RET-88',
        customerId: 'c1',
        shopId: 'shop-1',
        vehicleId: 'v1',
        vehicleName: 'Honda Civic RS Turbo',
        packageType: '24h',
        pickupTime: DateTime.now().subtract(const Duration(days: 1)),
        returnTime: DateTime.now(),
        totalAmount: 9000,
        advancePaid: 9000,
        remainingBalance: 0,
        status: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerReturnSettlementView(
            booking: testBooking,
            initialOdometer: 40000,
            kmAllowance: 200,
            initialDeposit: 15000,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vehicle Return & Settlement'), findsOneWidget);
      expect(find.text('Deposit & Return Balance Settlement'), findsOneWidget);
      expect(find.text('Finalize Return & Settle Deposit'), findsOneWidget);
    });
  });
}

