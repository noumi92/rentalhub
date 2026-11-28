import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/handover/data/datasources/pdf_contract_generator.dart';
import 'package:rentalhub/features/handover/domain/entities/handover_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_agreement_wizard_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

BookingEntity _testBooking() => BookingEntity(
      bookingId: 'RH-WIZ-1',
      customerId: 'cust-1',
      shopId: 'shop-1',
      vehicleId: 'veh-1',
      vehicleName: 'Toyota Corolla Altis 2022',
      vehiclePlate: 'LEA-22-1234',
      customerName: 'Ahmed Khan',
      customerPhone: '03001234567',
      customerCnic: '35202-1234567-1',
      guarantorName: 'Bilal Ahmed',
      guarantorCnic: '35201-7654321-3',
      guarantorRelation: 'Cousin',
      packageType: '24h',
      pickupTime: DateTime(2026, 10, 26, 17, 0),
      returnTime: DateTime(2026, 10, 28, 17, 0),
      totalAmount: 12000,
      advanceRequired: 5000,
      advancePaid: 5000,
      remainingBalance: 7000,
      status: 'active',
    );

/// A minimal valid 1x1 PNG, used as a stand-in signature image.
Uint8List _tinyPng() => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );

Future<Uint8List> _realPdf() => PdfContractGenerator.generateA4Agreement(
      agreementId: 'RH-WIZ-1',
      shopName: 'Al-Falah Rent a Car',
      customerName: 'Ahmed Khan',
      cnicNumber: '35202-1234567-1',
      customerPhone: '03001234567',
      vehicleDetails: 'Toyota Corolla Altis 2022',
      packageType: '24h',
      isWithDriver: false,
      pickupTime: DateTime(2026, 10, 26, 17, 0),
      returnTime: DateTime(2026, 10, 28, 17, 0),
      totalAmount: 12000,
      advancePaid: 5000,
      securityDeposit: 20000,
      initialOdometer: 48250,
      fuelLevel: '3/4 tank',
      damageNotes: const [],
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

  group('Item 10 — O46 agreement preview', () {
    testWidgets('preview shows guarantor details and the true photo count',
        (tester) async {
      final pdf = await _realPdf();
      await _pump(
        tester,
        OwnerAgreementWizardView(
          booking: _testBooking(),
          pdfBytes: pdf,
          odometer: 48250,
          fuelLevel: '3/4 tank',
          handoverPhotoCount: 3,
        ),
      );
      expect(find.text('Generated'), findsOneWidget);
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text('35201-7654321-3'), findsOneWidget);
      expect(find.text('Cousin'), findsOneWidget);
      expect(find.text('Handover photos'), findsOneWidget);
      expect(find.text('3 photos'), findsOneWidget);
      // The RH-... bookingId stays the agreement number — no AGR
      // counter anywhere on the preview. It appears twice: the app
      // bar subtitle and the paper sheet's agreement-no row.
      expect(find.text('#RH-WIZ-1'), findsNWidgets(2));
      expect(find.textContaining('AGR-'), findsNothing);
      expect(find.text('Terms & signatures'), findsOneWidget);
    });

    testWidgets('preview advances to the terms step', (tester) async {
      final pdf = await _realPdf();
      await _pump(
        tester,
        OwnerAgreementWizardView(
          booking: _testBooking(),
          pdfBytes: pdf,
          odometer: 48250,
          fuelLevel: '3/4 tank',
          handoverPhotoCount: 4,
        ),
      );
      await tester.ensureVisible(find.text('Terms & signatures'));
      await tester.tap(find.text('Terms & signatures'));
      await tester.pumpAndSettle();
      expect(find.text('10 terms · 3 signatures'), findsOneWidget);
      expect(find.text('Signatures'), findsOneWidget);
    });
  });

  group('Item 10 — O47 terms & signatures', () {
    testWidgets('finalize is blocked until all 3 signatures exist',
        (tester) async {
      await _pump(
        tester,
        OwnerAgreementWizardView(
          booking: _testBooking(),
          initialStep: 1,
          pdfBytes: await _realPdf(),
          odometer: 48250,
          fuelLevel: '3/4 tank',
          handoverPhotoCount: 4,
          customerSignaturePng: _tinyPng(),
          ownerSignaturePng: _tinyPng(),
          // No guarantor signature: the third party is missing.
        ),
      );
      expect(find.text('Finalize agreement'), findsOneWidget);
      expect(
          find.text('All 3 signatures are required before finalizing.'),
          findsOneWidget);
      // The 10 terms all render (number chips + stripped text).
      expect(
          find.text('The vehicle shall be used within city limits unless '
              'an out-city rate has been agreed.'),
          findsOneWidget);
      expect(find.textContaining('Traffic challans'), findsOneWidget);
    });

    testWidgets('finalize is allowed once all 3 signatures exist',
        (tester) async {
      await _pump(
        tester,
        OwnerAgreementWizardView(
          booking: _testBooking(),
          initialStep: 1,
          pdfBytes: await _realPdf(),
          odometer: 48250,
          fuelLevel: '3/4 tank',
          handoverPhotoCount: 4,
          customerSignaturePng: _tinyPng(),
          ownerSignaturePng: _tinyPng(),
          guarantorSignaturePng: _tinyPng(),
        ),
      );
      expect(
          find.text('All 3 signatures are required before finalizing.'),
          findsNothing);
      await tester.ensureVisible(find.text('Finalize agreement'));
      await tester.tap(find.text('Finalize agreement'));
      await tester.pumpAndSettle();
      expect(find.text('Agreement ready'), findsOneWidget);
      expect(find.text('Signed by all 3 parties'), findsOneWidget);
    });
  });

  group('Item 10 — O48 download / view agreement', () {
    testWidgets('ready step shows true file metadata and download/view actions only',
        (tester) async {
      final pdf = await _realPdf();
      await _pump(
        tester,
        OwnerAgreementWizardView(
          booking: _testBooking(),
          initialStep: 2,
          pdfBytes: pdf,
          customerSignaturePng: _tinyPng(),
          ownerSignaturePng: _tinyPng(),
          guarantorSignaturePng: _tinyPng(),
        ),
      );
      expect(find.text('Agreement ready'), findsOneWidget);
      expect(find.text('Signed by all 3 parties'), findsOneWidget);
      expect(find.text('agreement-RH-WIZ-1.pdf'), findsOneWidget);
      // True metadata: A4, 1 page, real size — never "2 pages".
      expect(find.textContaining('A4 · 1 page'), findsOneWidget);
      expect(find.textContaining('2 pages'), findsNothing);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('View Agreement'), findsOneWidget);
      expect(find.text('Share on WhatsApp'), findsNothing);
      expect(find.text('Print'), findsNothing);
      expect(find.text('Copy verification link'), findsNothing);
      expect(find.text('Done'), findsOneWidget);
    });
  });

  group('Item 10 — PDF guarantor block + photo count', () {
    test('PDF bytes change with the guarantor block and photo count',
        () async {
      final base = await _realPdf();
      final withGuarantor =
          await PdfContractGenerator.generateA4Agreement(
        agreementId: 'RH-WIZ-1',
        shopName: 'Al-Falah Rent a Car',
        customerName: 'Ahmed Khan',
        cnicNumber: '35202-1234567-1',
        customerPhone: '03001234567',
        vehicleDetails: 'Toyota Corolla Altis 2022',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 17, 0),
        returnTime: DateTime(2026, 10, 28, 17, 0),
        totalAmount: 12000,
        advancePaid: 5000,
        securityDeposit: 20000,
        initialOdometer: 48250,
        fuelLevel: '3/4 tank',
        damageNotes: const [],
        guarantorName: 'Bilal Ahmed',
        guarantorCnic: '35201-7654321-3',
        guarantorRelation: 'Cousin',
        handoverPhotoCount: 4,
      );
      expect(String.fromCharCodes(withGuarantor.take(4)), '%PDF');
      expect(withGuarantor, isNot(base));
      final withPhotosOnly =
          await PdfContractGenerator.generateA4Agreement(
        agreementId: 'RH-WIZ-1',
        shopName: 'Al-Falah Rent a Car',
        customerName: 'Ahmed Khan',
        cnicNumber: '35202-1234567-1',
        customerPhone: '03001234567',
        vehicleDetails: 'Toyota Corolla Altis 2022',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 10, 26, 17, 0),
        returnTime: DateTime(2026, 10, 28, 17, 0),
        totalAmount: 12000,
        advancePaid: 5000,
        securityDeposit: 20000,
        initialOdometer: 48250,
        fuelLevel: '3/4 tank',
        damageNotes: const [],
        handoverPhotoCount: 3,
      );
      expect(withPhotosOnly, isNot(base));
      expect(withPhotosOnly, isNot(withGuarantor));
    });

    test('HandoverEntity.photoCount counts only photos actually taken',
        () {
      final handover = HandoverEntity(
        bookingId: 'RH-WIZ-1',
        initialOdometer: 48250,
        fuelLevel: '3/4 tank',
        customerSignatureSvg: '',
        ownerSignatureSvg: '',
        photoFrontUrl: 'https://example.test/front.jpg',
        photoBackUrl: 'https://example.test/back.jpg',
        photoLeftUrl: null,
        photoRightUrl: '',
      );
      expect(handover.photoCount, 2);
    });
  });
}
