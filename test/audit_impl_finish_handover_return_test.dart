import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/handover/data/datasources/pdf_contract_generator.dart';
import 'package:rentalhub/features/owner/presentation/services/return_settlement_service.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_contract_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_return_landing_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_return_settlement_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/contract_paper_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

BookingEntity _testBooking() => BookingEntity(
      bookingId: 'RH-FIN-1',
      customerId: 'cust-1',
      shopId: 'shop-1',
      vehicleId: 'veh-1',
      vehicleName: 'Toyota Corolla GLi 2022',
      vehiclePlate: 'LEA-22-4567',
      customerName: 'Ali Raza',
      customerPhone: '03001112233',
      customerCnic: '35202-1234567-1',
      guarantorName: 'Ahmed Khan',
      packageType: '24h',
      pickupTime: DateTime.now().subtract(const Duration(days: 1)),
      returnTime: DateTime.now().add(const Duration(days: 2)),
      totalAmount: 21000,
      advanceRequired: 5000,
      advancePaid: 5000,
      remainingBalance: 16000,
      status: 'active',
    );

/// A minimal valid 1x1 PNG, used as a stand-in signature image.
Uint8List _tinyPng() => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );

Future<void> _pump(WidgetTester tester, Widget view) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: view,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Finish build — O25 return landing screen', () {
    testWidgets('landing renders summary, due date and start entry',
        (tester) async {
      await _pump(tester, OwnerReturnLandingView(booking: _testBooking()));
      expect(find.text('Return & Settlement'), findsOneWidget);
      expect(
          find.text(
              'Booking #RH-FIN-1 • Ali Raza — Toyota Corolla GLi 2022'),
          findsOneWidget);
      expect(find.text('Return due'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Rs. 21,000'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Rs. 16,000'), findsOneWidget);
      expect(find.text('Start Return Inspection'), findsOneWidget);
    });
  });

  group('Finish build — O26 return payment steps', () {
    testWidgets(
        'return view starts at the inspection with refund then close steps',
        (tester) async {
      await _pump(tester, OwnerReturnSettlementView(booking: _testBooking()));
      // The landing moved to its own route: no landing content here.
      expect(find.text('Start Return Inspection'), findsNothing);
      // The single Finalize button is gone, replaced by the two steps.
      expect(find.text('Finalize Return & Settle Security'), findsNothing);
      // The inspection itself is the first thing on the screen.
      expect(find.text('Vehicle Return & Settlement'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Minor damage'), findsOneWidget);
      // Step 1: Refund Security (row label + button).
      expect(find.text('Refund Security'), findsNWidgets(2));
      // Step 2: Complete & Close Booking, disabled until the refund
      // step is recorded.
      expect(find.text('Complete & Close Booking'), findsOneWidget);
    });

    test('refund state read resolves to not-recorded without Firestore',
        () async {
      final state =
          await ReturnSettlementService.loadRefundState('RH-FIN-NONE');
      expect(state.recorded, isFalse);
      expect(state.amount, 0);
    });

    test(
        'refund write round-trips through the in-memory fallback (no live Firestore in tests)',
        () async {
      await ReturnSettlementService.recordRefund(
          bookingId: 'RH-FIN-NONE', amount: 100);
      final state =
          await ReturnSettlementService.loadRefundState('RH-FIN-NONE');
      expect(state.recorded, isTrue);
      expect(state.amount, 100);
    });
  });

  group('Finish build — O20 contract fare table and signing', () {
    testWidgets('fare table derives daily rate and days from the booking',
        (tester) async {
      await _pump(
        tester,
        OwnerContractView(
          booking: _testBooking(),
          pdfBytes: Uint8List.fromList(const [37, 80, 68, 70]),
        ),
      );
      expect(find.text('Fare Breakdown'), findsOneWidget);
      expect(find.text('Daily Rate'), findsOneWidget);
      // 3 days (pickup −1d → return +2d), Rs. 21,000 / 3 = Rs. 7,000.
      expect(find.text('Rs. 7,000'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);
      expect(find.text('Total Rent'), findsOneWidget);
      // Total / Advance / Remaining render twice: once on the paper
      // sheet, once in the fare table.
      expect(find.text('Rs. 21,000'), findsNWidgets(2));
      expect(find.text('Advance:'), findsNWidgets(2));
      expect(find.text('Remaining:'), findsNWidgets(2));
    });

    testWidgets('agree checkbox, guarantor pad and sign button render',
        (tester) async {
      await _pump(
        tester,
        OwnerContractView(
          booking: _testBooking(),
          pdfBytes: Uint8List.fromList(const [37, 80, 68, 70]),
        ),
      );
      expect(find.text('I agree to the terms above'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Guarantor / Witness Signature'), findsOneWidget);
      expect(find.text('Sign Agreement'), findsOneWidget);
      // Toggling the checkbox persists (or fails honestly) without
      // crashing the view when there is no Firestore.
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });

    testWidgets('paper sheet renders a captured guarantor PNG',
        (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ContractPaperSheet(
              booking: _testBooking(),
              odometer: 45200,
              fuelLevel: '4/4 (Full)',
              securityDeposit: 20000,
              guarantorSignaturePng: _tinyPng(),
              guarantorName: 'Ahmed Khan',
            ),
          ),
        ),
      );
      expect(find.text('Guarantor Signature'), findsOneWidget);
      expect(find.text('Ahmed Khan'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
            (w) => w is Image && w.image is MemoryImage),
        findsOneWidget,
      );
    });

    test('PDF generator renders the guarantor as a third signature block',
        () async {
      final withoutGuarantor =
          await PdfContractGenerator.generateA4Agreement(
        agreementId: 'RH-FIN-PDF',
        shopName: 'Test Showroom',
        customerName: 'Ali Raza',
        cnicNumber: '35202-1234567-1',
        customerPhone: '03001112233',
        vehicleDetails: 'Toyota Corolla GLi 2022',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 3)),
        totalAmount: 21000,
        advancePaid: 5000,
        securityDeposit: 20000,
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        damageNotes: const [],
      );
      final withGuarantor =
          await PdfContractGenerator.generateA4Agreement(
        agreementId: 'RH-FIN-PDF',
        shopName: 'Test Showroom',
        customerName: 'Ali Raza',
        cnicNumber: '35202-1234567-1',
        customerPhone: '03001112233',
        vehicleDetails: 'Toyota Corolla GLi 2022',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 3)),
        totalAmount: 21000,
        advancePaid: 5000,
        securityDeposit: 20000,
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        damageNotes: const [],
        guarantorSignaturePng: _tinyPng(),
        guarantorName: 'Ahmed Khan',
      );
      expect(String.fromCharCodes(withGuarantor.take(4)), '%PDF');
      expect(withGuarantor, isNotEmpty);
      expect(withGuarantor, isNot(withoutGuarantor));
    });
  });

  group('Finish build — O24 share options', () {
    testWidgets('share sheet lists WhatsApp, Email and Print',
        (tester) async {
      await _pump(
        tester,
        OwnerContractView(
          booking: _testBooking(),
          pdfBytes: Uint8List.fromList(const [37, 80, 68, 70]),
        ),
      );
      await tester.tap(find.byTooltip('Share PDF'));
      await tester.pumpAndSettle();
      expect(find.text('Share Agreement'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);
      expect(
        find.text(
            'The agreement file is shared to the app you choose. Nothing is sent automatically.'),
        findsOneWidget,
      );
    });
  });
}
