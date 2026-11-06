import 'dart:convert';
import 'dart:io';
// (typed_data comes in via flutter_test)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/presentation/widgets/booking_ticket_card.dart';
import 'package:rentalhub/features/handover/data/datasources/handover_local_data_source.dart';
import 'package:rentalhub/features/handover/data/datasources/pdf_contract_generator.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_cubit.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_booking_requests_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_contract_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_handover_signature_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_qr_scan_view.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  // A valid 1x1 transparent PNG, used as a stand-in signature.
  final tinyPng = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

  group('Phase E (E3) — real A4 agreement PDF', () {
    test('generates a real PDF with a %PDF header and a verify URL',
        () async {
      final bytes = await PdfContractGenerator.generateA4Agreement(
        agreementId: 'RH-E3-1',
        shopName: 'Test Showroom',
        customerName: 'Ayesha Khan',
        cnicNumber: '35202-1234567-1',
        customerPhone: '03001234567',
        vehicleDetails: 'Honda Civic Oriel 2021',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 9000,
        advancePaid: 3000,
        securityDeposit: 20000,
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        damageNotes: const ['Scratch on right door'],
      );
      // A real PDF starts with %PDF; the old generator only wrote
      // that header followed by comments.
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });

    test('verification URL points at the cPanel verify page', () {
      expect(
        PdfContractGenerator.verificationUrlFor('RH-E3-1'),
        'https://rentalhub.62onlinestore.com/api/verify_agreement.php?id=RH-E3-1',
      );
    });
  });

  group('Phase E (E2/E3) — handover saves the real PDF offline', () {
    test('offline handover stores PDF + signatures, syncs locally',
        () async {
      final cubit = HandoverCubit(
        localDataSource: di.sl<HandoverLocalDataSource>(),
      );
      final entity = await cubit.completeHandoverOfflineFirst(
        bookingId: 'RH-E3-2',
        shopName: 'Test Showroom',
        customerName: 'Ayesha Khan',
        cnicNumber: '35202-1234567-1',
        vehicleDetails: 'Honda Civic Oriel 2021',
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        damageNotes: const ['Scratch on right door'],
        // A real 1x1 PNG — the PDF generator embeds the signature
        // bytes as images and rejects anything that is not one.
        customerSignaturePng: tinyPng,
        ownerSignaturePng: tinyPng,
        isOnline: false,
      );
      expect(entity.isSynced, isFalse);
      expect(entity.agreementPdfB64, isNotNull);
      expect(entity.customerSignatureB64, isNotNull);
      expect(cubit.state, isA<HandoverSavedOffline>());

      final stored = await di
          .sl<HandoverLocalDataSource>()
          .getHandover('RH-E3-2');
      expect(stored, isNotNull);
      expect(stored!.agreementPdfB64, isNotNull);
      expect(stored.damageNotes, ['Scratch on right door']);

      final synced = await cubit.syncPendingHandovers();
      expect(synced, 1);
      expect(cubit.state, isA<HandoverSynced>());
    });
  });

  group('Phase E (E2) — handover view', () {
    testWidgets('shows real pads and damage editor, refuses unsigned',
        (tester) async {
      final booking = BookingEntity(
        bookingId: 'RH-E3-3',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic Oriel 2021',
        packageType: '24h',
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
        remainingBalance: 6000,
      );
      await tester.pumpWidget(
        MaterialApp(home: OwnerHandoverSignatureView(booking: booking)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dual Legal Endorsement & Signatures'),
          findsOneWidget);
      expect(find.text('Damage & Condition Notes'), findsOneWidget);
      // No hardcoded damage notes from the old flow.
      expect(find.text('Minor right door scratch noted'), findsNothing);

      await tester.ensureVisible(
          find.text('Certify Handover & Generate Contract'));
      await tester.tap(find.text('Certify Handover & Generate Contract'));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'Both customer and host must sign on the pads before vehicle departure.'),
          findsOneWidget);
    });
  });

  group('Phase E (E3) — contract view', () {
    testWidgets('shows the real PDF QR and honest customer data',
        (tester) async {
      final pdf = await PdfContractGenerator.generateA4Agreement(
        agreementId: 'RH-E3-4',
        shopName: 'Test Showroom',
        customerName: 'Ayesha Khan',
        cnicNumber: '35202-1234567-1',
        customerPhone: '03001234567',
        vehicleDetails: 'Honda Civic Oriel 2021',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advancePaid: 3000,
        securityDeposit: 20000,
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        damageNotes: const [],
      );
      final booking = BookingEntity(
        bookingId: 'RH-E3-4',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic Oriel 2021',
        customerName: 'Ayesha Khan',
        customerPhone: '03001234567',
        customerCnic: '35202-1234567-1',
        packageType: '24h',
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
        remainingBalance: 6000,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: OwnerContractView(
            booking: booking,
            pdfBytes: pdf,
            securityDeposit: 20000,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('35202-1234567-1'), findsOneWidget);
      expect(find.text('Rs. 20000 (refundable)'), findsOneWidget);
      // The old fake claims are gone.
      expect(find.text('AL-FALAH RENT A CAR LAHORE'), findsNothing);
      expect(find.text('Verified Clean (NADRA / Tribunal)'), findsNothing);
      expect(find.text('0300-1122334'), findsNothing);
    });
  });

  group('Phase E (E1) — booking QR', () {
    testWidgets('paid booking shows a QR, requested booking does not',
        (tester) async {
      BookingEntity booking(String id, String status) => BookingEntity(
            bookingId: id,
            customerId: 'cust-1',
            shopId: 'shop-1',
            vehicleId: 'veh-1',
            vehicleName: 'Honda Civic Oriel 2021',
            packageType: '24h',
            isWithDriver: false,
            pickupTime: DateTime.now(),
            returnTime: DateTime.now().add(const Duration(days: 1)),
            totalAmount: 9000,
            advanceRequired: 3000,
            remainingBalance: 6000,
            status: status,
          );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingTicketCard(
              booking: booking('RH-E3-5', 'paid'),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingTicketCard(
              booking: booking('RH-E3-6', 'requested'),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
    });
  });

  group('Phase E (D1 follow-up) — approve keeps the booking visible',
      () {
    testWidgets('an approved request moves to the Approved filter',
        (tester) async {
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-e1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic Oriel 2021',
        customerName: 'Approve Me',
        customerPhone: '03001234567',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 3000,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: OwnerBookingRequestsView(shopId: 'shop-1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Approve Me'), findsOneWidget);

      await tester.tap(find.text('Approve & Pay'));
      await tester.pumpAndSettle();
      expect(find.text('Approve Me'), findsNothing);

      await tester.tap(find.textContaining('Approved ('));
      await tester.pumpAndSettle();
      expect(find.text('Approve Me'), findsOneWidget);
      expect(find.text('Approve & Pay'), findsNothing);
      expect(
          (await ds.getBookingById(booking.bookingId))?.status, 'approved');
    });
  });

  group('Phase E — routing', () {
    test('owner scan route and view are wired', () {
      final router = File('lib/core/routing/app_router.dart')
          .readAsStringSync();
      expect(router, contains('OwnerQrScanView'));
      expect(router, contains("RouteNames.ownerQrScan"));
      final names = File('lib/core/routing/route_names.dart')
          .readAsStringSync();
      expect(names, contains("ownerQrScan = '/owner/scan'"));
      expect(const OwnerQrScanView(), isA<OwnerQrScanView>());
    });
  });
}
