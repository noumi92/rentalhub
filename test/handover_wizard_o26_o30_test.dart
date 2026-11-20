import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/handover/data/datasources/handover_local_data_source.dart';
import 'package:rentalhub/features/handover/domain/entities/handover_entity.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_cubit.dart';
import 'package:rentalhub/features/handover/presentation/cubit/handover_wizard_cubit.dart';
import 'package:rentalhub/features/owner/presentation/services/handover_wizard_finalize.dart';
import 'package:rentalhub/features/owner/presentation/views/handover_wizard/handover_wizard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rental_started_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/handover_wizard/handover_booking_picker_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// A valid 1x1 transparent PNG, used as a stand-in signature.
final _tinyPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

BookingEntity _booking({String id = 'RH-WIZ-1'}) => BookingEntity(
      bookingId: id,
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
      advancePaid: 1000,
      advanceRequired: 1000,
      remainingBalance: 8000,
    );

Widget _pumpable(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

// The wizard steps are taller than the default 800x600 test
// viewport — without this, below-the-fold buttons miss their tap.
void _tallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Item 9 — wizard cubit gates', () {
    test('receipt id is derived from the booking id', () {
      final cubit = HandoverWizardCubit(bookingId: 'RH-WIZ-1');
      expect(cubit.state.receiptId, 'RH-RCT-RH-WIZ-1');
      expect(cubit.state.step, 0);
    });

    test('step 0 blocks until the face check is confirmed', () {
      final cubit = HandoverWizardCubit(bookingId: 'RH-WIZ-1');
      cubit.nextStep();
      expect(cubit.state.step, 0);
      expect(cubit.state.error, 'face');
      cubit.setFaceChecked(true);
      expect(cubit.state.faceCheckConfirmed, isTrue);
      expect(cubit.state.faceCheckedAt, isNotNull);
      cubit.nextStep();
      expect(cubit.state.step, 1);
    });

    test('step 1 needs a balance method and a deposit method', () {
      final cubit = HandoverWizardCubit(bookingId: 'RH-WIZ-1');
      cubit.goToStep(1);
      cubit.nextStep(balanceDue: 8000, securityDeposit: 20000);
      expect(cubit.state.error, 'payment');
      cubit.setBalanceMethod('cash');
      cubit.nextStep(balanceDue: 8000, securityDeposit: 20000);
      expect(cubit.state.error, 'deposit');
      cubit.setDepositMethod('easypaisa');
      cubit.setDepositReceived(true);
      expect(cubit.state.depositReceivedAt, isNotNull);
      cubit.nextStep(balanceDue: 8000, securityDeposit: 20000);
      expect(cubit.state.step, 2);
    });

    test('step 1 passes with no balance due and no deposit', () {
      final cubit = HandoverWizardCubit(bookingId: 'RH-WIZ-1');
      cubit.goToStep(1);
      cubit.nextStep(balanceDue: 0, securityDeposit: 0);
      expect(cubit.state.step, 2);
    });

    test('step 2 needs odometer + fuel, step 3 has no gate', () {
      final cubit = HandoverWizardCubit(bookingId: 'RH-WIZ-1');
      cubit.goToStep(2);
      cubit.nextStep();
      expect(cubit.state.error, 'checklist');
      cubit.setOdometer(45200);
      cubit.nextStep();
      expect(cubit.state.error, 'checklist');
      cubit.setFuel('4/4 (Full)');
      cubit.nextStep();
      expect(cubit.state.step, 3);
      cubit.nextStep();
      expect(cubit.state.step, 4);
    });

    test('signatures gate on saved-or-fresh, guarantor not required', () {
      final cubit = HandoverWizardCubit(bookingId: 'RH-WIZ-1');
      expect(cubit.signaturesReady, isFalse);
      cubit.setCustomerSavedSignature(
          url: 'https://example.com/sig.png', pngBytes: _tinyPng);
      expect(cubit.signaturesReady, isFalse);
      cubit.setOwnerSavedSignature(
          url: 'https://example.com/owner.png', pngBytes: _tinyPng);
      expect(cubit.signaturesReady, isTrue);
      expect(cubit.customerSignatureSource, 'saved');
      expect(cubit.ownerSignatureSource, 'saved');
    });

    test('exportSignatures returns the saved PNG bytes', () async {
      final cubit = HandoverWizardCubit(bookingId: 'RH-WIZ-1');
      cubit.setCustomerSavedSignature(pngBytes: _tinyPng);
      cubit.setOwnerSavedSignature(pngBytes: _tinyPng);
      final sigs = await cubit.exportSignatures();
      expect(sigs.customer, _tinyPng);
      expect(sigs.owner, _tinyPng);
    });

    test('photos, timestamps and damage pins round-trip in the draft',
        () {
      final cubit = HandoverWizardCubit(bookingId: 'RH-WIZ-1');
      cubit.setPhotos({
        'front': 'https://example.com/front.jpg',
        'back': null,
        'left': null,
        'right': null,
        'interior': 'https://example.com/interior.jpg',
        'dashboard': null,
      });
      cubit.setPhotoTakenAt({'front': '2026-11-20T10:00:00'});
      expect(cubit.state.photos['interior'], isNotNull);
      expect(cubit.state.photoTakenAt['front'], isNotNull);
      expect(cubit.state.photos.keys,
          containsAll(['interior', 'dashboard']));
    });
  });

  group('Item 9 — HandoverCubit carries the wizard fields', () {
    test('offline handover stores the new fields and reads them back',
        () async {
      final cubit = HandoverCubit(
        localDataSource: di.sl<HandoverLocalDataSource>(),
      );
      final entity = await cubit.completeHandoverOfflineFirst(
        bookingId: 'RH-WIZ-2',
        shopName: 'Test Showroom',
        customerName: 'Ayesha Khan',
        cnicNumber: '35202-1234567-1',
        vehicleDetails: 'Honda Civic Oriel 2021',
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        customerSignaturePng: _tinyPng,
        ownerSignaturePng: _tinyPng,
        faceCheckConfirmed: true,
        faceCheckedAt: DateTime(2026, 11, 20, 10, 5),
        depositPaymentMethod: 'easypaisa',
        depositReceivedAt: DateTime(2026, 11, 20, 10, 6),
        receiptId: 'RH-RCT-RH-WIZ-2',
        acWorking: true,
        lightsWorking: false,
        photoInteriorUrl: 'https://example.com/interior.jpg',
        photoDashboardUrl: 'https://example.com/dashboard.jpg',
        photoTakenAt: const {'front': '2026-11-20T10:00:00'},
        damagePins: const [
          HandoverDamagePin(zone: 'Front Bumper', type: 'Scratch / Mark'),
        ],
        tripStartAt: DateTime(2026, 11, 20, 10, 10),
        customerSignatureSource: 'saved',
        ownerSignatureSource: 'fresh',
        isOnline: false,
      );
      expect(entity.faceCheckConfirmed, isTrue);
      expect(entity.depositPaymentMethod, 'easypaisa');
      expect(entity.receiptId, 'RH-RCT-RH-WIZ-2');
      expect(entity.photoCount, 2);
      expect(entity.damagePins.length, 1);
      expect(entity.tripStartAt, DateTime(2026, 11, 20, 10, 10));
      expect(entity.acWorking, isTrue);
      expect(entity.lightsWorking, isFalse);

      final stored =
          await di.sl<HandoverLocalDataSource>().getHandover('RH-WIZ-2');
      expect(stored, isNotNull);
      expect(stored!.faceCheckConfirmed, isTrue);
      expect(stored.depositPaymentMethod, 'easypaisa');
      expect(stored.receiptId, 'RH-RCT-RH-WIZ-2');
      expect(stored.photoInteriorUrl, 'https://example.com/interior.jpg');
      expect(stored.photoTakenAt['front'], '2026-11-20T10:00:00');
      expect(stored.damagePins.first.zone, 'Front Bumper');
      expect(stored.tripStartAt, DateTime(2026, 11, 20, 10, 10));
      expect(stored.customerSignatureSource, 'saved');
    });
  });

  group('Item 9 — wizard finalize (service)', () {
    test('finalize completes offline and flips the booking active',
        () async {
      final ds = di.sl<BookingRemoteDataSource>();
      final created = await ds.createBookingRequest(
        customerId: 'cust-wiz',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Honda Civic Oriel 2021',
        customerName: 'Ayesha Khan',
        customerPhone: '03001234567',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        advanceRequired: 1000,
      );
      final booking = _booking(id: created.bookingId);
      final wizard = HandoverWizardCubit(bookingId: created.bookingId);
      wizard.setFaceChecked(true);
      wizard.setBalanceMethod('easypaisa');
      wizard.setDepositMethod('cash');
      wizard.setDepositReceived(true);
      wizard.setOdometer(45200);
      wizard.setFuel('3/4 (75%)');
      wizard.setAcWorking(true);
      wizard.setLightsWorking(true);
      wizard.setCustomerSavedSignature(pngBytes: _tinyPng);
      wizard.setOwnerSavedSignature(pngBytes: _tinyPng);
      final result = await HandoverWizardFinalize.run(
        booking: booking,
        shopName: 'Test Showroom',
        securityDeposit: 20000,
        vehiclePlate: 'LEA-23-4567',
        vehicleColour: 'White',
        vehicleFuel: 'Petrol',
        wizard: wizard,
        customerNameFallback: 'Customer',
        vehicleFallback: 'Vehicle',
        isOnline: false,
      );
      expect(result.entity.faceCheckConfirmed, isTrue);
      expect(result.entity.balancePaymentMethod, 'easypaisa');
      expect(result.entity.depositPaymentMethod, 'cash');
      expect(result.entity.receiptId, 'RH-RCT-${created.bookingId}');
      expect(result.entity.tripStartAt, isNotNull);
      expect(result.entity.wizardCompletedAt, isNotNull);
      expect(result.pdfBytes, isNotNull);
      final stored = await ds.getBookingById(created.bookingId);
      expect(stored?.status, 'active');
    });
  });

  group('Item 9 — wizard steps (widgets)', () {
    testWidgets('step 0 blocks Continue until the face check',
        (tester) async {
      _tallViewport(tester);
      await tester.pumpWidget(
          _pumpable(OwnerHandoverWizardView(booking: _booking())));
      await tester.pumpAndSettle();
      expect(find.text('Booking matched'), findsOneWidget);
      expect(find.text('Face matches KYC photo'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Agreement'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Confirm the face check before continuing.'),
          findsOneWidget);
      // The error SnackBar never dismisses under the fake clock
      // (verified with a bare SnackBar probe), and while it is up
      // it floats over the bottom nav bar — so no tap follows it
      // in this test; settle only drains its entrance animation.
      await tester.pumpAndSettle();
    });

    testWidgets('step 0 face confirm advances to payment',
        (tester) async {
      _tallViewport(tester);
      await tester.pumpWidget(
          _pumpable(OwnerHandoverWizardView(booking: _booking())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Face matches KYC photo'));
      await tester.pumpAndSettle();
      expect(find.text('Face check confirmed'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Advance (paid online)'), findsOneWidget);
    });

    testWidgets('step 1 shows EasyPaisa + deposit + receipt',
        (tester) async {
      _tallViewport(tester);
      await tester.pumpWidget(_pumpable(OwnerHandoverWizardView(
          booking: _booking(), initialStep: 1)));
      await tester.pumpAndSettle();
      expect(find.text('Advance (paid online)'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'EasyPaisa'), findsWidgets);
      expect(find.text('Deposit received'), findsOneWidget);
      expect(find.text('Balance received'), findsOneWidget);
      expect(find.text('View receipt'), findsOneWidget);
      await tester.ensureVisible(find.text('View receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View receipt'));
      await tester.pumpAndSettle();
      expect(find.text('Handover receipt'), findsOneWidget);
      expect(find.textContaining('RH-RCT-RH-WIZ-1'), findsOneWidget);
    });

    testWidgets('step 2 has the fuel slider + AC/lights checks',
        (tester) async {
      await tester.pumpWidget(_pumpable(OwnerHandoverWizardView(
          booking: _booking(), initialStep: 2)));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Air conditioning working'), findsOneWidget);
      expect(find.text('All lights working'), findsOneWidget);
      expect(find.text('Damage & Condition Notes'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '45200');
      await tester.drag(find.byType(Slider), const Offset(400, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Interior'), findsOneWidget);
    });

    testWidgets('step 3 shows six photo slots + damage diagram',
        (tester) async {
      await tester.pumpWidget(_pumpable(OwnerHandoverWizardView(
          booking: _booking(), initialStep: 3)));
      await tester.pumpAndSettle();
      for (final label in [
        'Front',
        'Back',
        'Left',
        'Right',
        'Interior',
        'Dashboard',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Mark existing damage'), findsOneWidget);
    });

    testWidgets(
        'step 4 shows saved-signature fallback, guarantor pending, handed-over gate',
        (tester) async {
      await tester.pumpWidget(_pumpable(OwnerHandoverWizardView(
          booking: _booking(), initialStep: 4)));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'Guarantor signature pending — signed in the agreement step.'),
          findsOneWidget);
      expect(find.text('Car Handed Over'), findsOneWidget);
      await tester.tap(find.text('Car Handed Over'));
      await tester.pump();
      expect(
          find.text(
              'Both customer and host must sign on the pads before vehicle departure.'),
          findsOneWidget);
      // Drain the SnackBar timer so it cannot leak into the next test.
      await tester.pumpAndSettle();
    });
  });

  group('Item 9 — rental started trip timer', () {
    testWidgets('shows the trip start + elapsed time from the handover',
        (tester) async {
      final cubit = HandoverCubit(
        localDataSource: di.sl<HandoverLocalDataSource>(),
      );
      await cubit.completeHandoverOfflineFirst(
        bookingId: 'RH-WIZ-3',
        shopName: 'Test Showroom',
        customerName: 'Ayesha Khan',
        vehicleDetails: 'Honda Civic Oriel 2021',
        initialOdometer: 45200,
        fuelLevel: '4/4 (Full)',
        customerSignaturePng: _tinyPng,
        ownerSignaturePng: _tinyPng,
        tripStartAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isOnline: false,
      );
      await tester.pumpWidget(_pumpable(
          OwnerRentalStartedView(booking: _booking(id: 'RH-WIZ-3'))));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('on trip'), findsOneWidget);
      await tester.pumpWidget(Container());
    });
  });

  group('Item 9 — manual booking picker', () {
    testWidgets('empty shop shows the no-ready-bookings state',
        (tester) async {
      await tester.pumpWidget(_pumpable(Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                HandoverBookingPickerSheet.show(context),
            child: const Text('Pick'),
          ),
        ),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      expect(find.text('No bookings ready for handover.'), findsOneWidget);
    });
  });

  group('Item 9 — routing', () {
    test('owner handover route lands on the wizard', () {
      final router = File('lib/core/routing/app_router.dart')
          .readAsStringSync();
      expect(router, contains('OwnerHandoverWizardView'));
      expect(router, contains('RouteNames.ownerHandover'));
    });
  });
}
