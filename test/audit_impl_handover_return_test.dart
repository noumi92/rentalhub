import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/widgets/signature_pad.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/finance/utils/settlement_calculator.dart';
import 'package:rentalhub/features/handover/data/datasources/handover_local_data_source.dart';
import 'package:rentalhub/features/handover/data/datasources/pdf_contract_generator.dart';
import 'package:rentalhub/features/handover/domain/entities/handover_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_agreement_signed_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_handover_signature_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_record_damage_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_record_extra_charges_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rental_started_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_return_settlement_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/contract_paper_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

BookingEntity _testBooking() => BookingEntity(
      bookingId: 'RH-AUDIT-B1',
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

  group('Audit impl B — settlement arithmetic', () {
    test('SettlementCalculator folds recorded extra charges into deductions',
        () {
      final breakdown = SettlementCalculator.calculate(
        totalKmDriven: 300,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '4/4 (Full)',
        damageCharge: 1000,
        overtimeHours: 0,
        extraHourPkr: 0,
        securityDeposit: 20000,
        extraCharges: 2000,
      );
      expect(breakdown.extraCharges, 2000);
      expect(breakdown.totalDeductions, 8000);
      expect(breakdown.netRefund, 12000);
    });
  });

  group('Audit impl B — handover record round-trip', () {
    test('photos, documents, accessories and keys persist', () async {
      final ds = di.sl<HandoverLocalDataSource>();
      const entity = HandoverEntity(
        bookingId: 'RH-AUDIT-B2',
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        customerSignatureSvg: '',
        ownerSignatureSvg: '',
        photoFrontUrl: 'https://example.test/handovers/front.jpg',
        photoBackUrl: 'https://example.test/handovers/back.jpg',
        documentsGiven: ['registration', 'insurance'],
        accessories: ['spare_tyre', 'jack', 'tool_kit'],
        keysHandedOver: true,
      );
      await ds.saveHandoverOffline(entity);
      final stored = await ds.getHandover('RH-AUDIT-B2');
      expect(stored, isNotNull);
      expect(stored!.photoFrontUrl,
          'https://example.test/handovers/front.jpg');
      expect(stored.photoBackUrl, 'https://example.test/handovers/back.jpg');
      expect(stored.documentsGiven, ['registration', 'insurance']);
      expect(stored.accessories, ['spare_tyre', 'jack', 'tool_kit']);
      expect(stored.keysHandedOver, isTrue);
    });

    test('PDF generator renders the agreement bytes', () async {
      final bytes = await PdfContractGenerator.generateA4Agreement(
        agreementId: 'RH-AUDIT-B3',
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
        vehiclePlate: 'LEA-22-4567',
        vehicleColour: 'White',
        vehicleFuel: 'Petrol',
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('Audit impl B — handover view', () {
    testWidgets('renders exterior photos and the handover checklist',
        (tester) async {
      await _pump(tester, OwnerHandoverSignatureView(booking: _testBooking()));
      expect(find.text('Vehicle Handover & Inspection'), findsOneWidget);
      expect(find.text('Exterior Photos'), findsOneWidget);
      expect(find.text('Front'), findsOneWidget);
      expect(find.text('Documents Given'), findsOneWidget);
      expect(find.text('Registration'), findsOneWidget);
      expect(find.text('Insurance'), findsOneWidget);
      expect(find.text('Accessories'), findsOneWidget);
      expect(find.text('Spare Tyre'), findsOneWidget);
      expect(find.text('Keys Handed Over'), findsOneWidget);
      expect(find.text('Certify Handover & Generate Contract'),
          findsOneWidget);
    });
  });

  group('Audit impl B — return view', () {
    testWidgets('renders inspection, condition, fare table and payment steps (landing moved out, no single Finalize)',
        (tester) async {
      await _pump(tester, OwnerReturnSettlementView(booking: _testBooking()));
      expect(find.text('Vehicle Return & Settlement'), findsOneWidget);
      // The landing is its own route now — no landing content here.
      expect(find.text('Start Return Inspection'), findsNothing);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Minor damage'), findsOneWidget);
      expect(find.text('Exterior Photos'), findsOneWidget);
      expect(find.text('Total Due'), findsOneWidget);
      expect(find.text('Payment Received'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('JazzCash'), findsOneWidget);
      // The single Finalize button is gone, replaced by the two steps.
      expect(find.text('Finalize Return & Settle Security'), findsNothing);
      // Step 1: Refund Security (row label + button).
      expect(find.text('Refund Security'), findsNWidgets(2));
      // Step 2: Complete & Close Booking, disabled until the refund
      // step is recorded.
      expect(find.text('Complete & Close Booking'), findsOneWidget);
    });
  });

  group('Audit impl B — record damage / extra charges', () {
    testWidgets('record damage renders schematic, photo and deduct toggle',
        (tester) async {
      await _pump(tester, OwnerRecordDamageView(booking: _testBooking()));
      expect(find.text('Record Damage'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Repair Cost'), findsOneWidget);
      expect(find.text('Deduct from Security'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('record extra charges renders type picker and add',
        (tester) async {
      await _pump(
          tester, OwnerRecordExtraChargesView(booking: _testBooking()));
      expect(find.text('Record Extra Charges'), findsOneWidget);
      expect(find.text('Late Return'), findsOneWidget);
      expect(find.text('Extra KM'), findsOneWidget);
      expect(find.text('Damage'), findsOneWidget);
      expect(find.text('Cleaning'), findsOneWidget);
      expect(find.text('Add Charge'), findsOneWidget);
    });
  });

  group('Audit impl B — rental started / agreement signed', () {
    testWidgets('rental started renders banner and actions', (tester) async {
      await _pump(tester, OwnerRentalStartedView(booking: _testBooking()));
      expect(find.text('Rental Started'), findsOneWidget);
      expect(find.text('View Agreement'), findsOneWidget);
      expect(find.text('Message Customer'), findsOneWidget);
    });

    testWidgets('agreement signed renders banner and download/view actions only',
        (tester) async {
      await _pump(
          tester, OwnerAgreementSignedView(booking: _testBooking()));
      expect(find.text('Agreement Signed Successfully'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('View Agreement'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
      expect(find.text('Send to Customer'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('Audit impl B — contract sheet + signature pad', () {
    testWidgets('paper sheet renders fare rows and guarantor pending',
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
            ),
          ),
        ),
      );
      expect(find.text('Advance:'), findsOneWidget);
      expect(find.text('Remaining:'), findsOneWidget);
      expect(find.text('Plate:'), findsOneWidget);
      expect(find.text('Guarantor Signature'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text && (w.data ?? '').contains('Both parties agree')),
        findsOneWidget,
      );
    });

    testWidgets('signature pad has no Auto Sign button', (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: SignaturePadWidget(
            signerLabel: 'Customer Signature',
            signerName: 'Ali Raza',
          ),
        ),
      );
      expect(find.text('Auto Sign'), findsNothing);
      expect(find.text('Clear'), findsOneWidget);
    });
  });
}
