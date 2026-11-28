import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/views/payment_proof_upload_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/review_booking_request_view.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/advance_deposit_notice_card.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/booking_summary_card.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/trip_type_section.dart';
import 'package:rentalhub/features/customer/presentation/widgets/my_disputes_list.dart';
import 'package:rentalhub/features/finance/utils/settlement_calculator.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_handover_signature_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_return_settlement_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/contract_signing_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_vehicle_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/handover_balance_section.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/return_payment_steps.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void _noop() {}

BookingEntity _testBooking() => BookingEntity(
      bookingId: 'RH-TEAMC-1',
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
      pickupTime: DateTime(2026, 11, 20, 10),
      returnTime: DateTime(2026, 11, 23, 10),
      totalAmount: 21000,
      advanceRequired: 5000,
      advancePaid: 5000,
      remainingBalance: 16000,
      status: 'active',
    );

Future<void> _pump(WidgetTester tester, Widget child,
    {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
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

  group('Team C — PW-21 settlement arithmetic', () {
    test('amountOwed is the excess over the deposit; netRefund clamps at 0',
        () {
      final over = SettlementCalculator.calculate(
        totalKmDriven: 300,
        kmAllowance: 250,
        extraKmPkr: 100,
        fuelLevel: '4/4 (Full)',
        damageCharge: 1000,
        overtimeHours: 0,
        extraHourPkr: 0,
        securityDeposit: 20000,
        extraCharges: 20000,
      );
      expect(over.totalDeductions, 26000);
      expect(over.netRefund, 0);
      expect(over.amountOwed, 6000);
    });

    test('amountOwed is 0 when the deposit covers the deductions', () {
      final under = SettlementCalculator.calculate(
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
      expect(under.totalDeductions, 8000);
      expect(under.netRefund, 12000);
      expect(under.amountOwed, 0);
    });
  });

  group('Team C — PW-13 trip estimate', () {
    testWidgets('per-km estimate renders live at 360px once dates are picked',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(
        tester,
        TripTypeSection(
          isOutOfCity: true,
          onChanged: (_) {},
          fixedRoutes: const [],
          selectedRoute: null,
          onRouteSelected: (_) {},
          outCityMode: 'perKm',
          outCityPerKmPkr: 30,
          pickup: DateTime(2026, 11, 20, 10),
          returnTime: DateTime(2026, 11, 23, 10),
          kmPerDay: 250,
        ),
      );
      expect(
          find.text('≈ Rs. 22,500 for 3 days × 250 km/day'), findsOneWidget);
      expect(find.textContaining('If clearance is refused, the shop contacts you before pickup'),
          findsOneWidget);
    });

    testWidgets('no estimate without dates', (tester) async {
      await _pump(
        tester,
        TripTypeSection(
          isOutOfCity: true,
          onChanged: (_) {},
          fixedRoutes: const [],
          selectedRoute: null,
          onRouteSelected: (_) {},
          outCityMode: 'perKm',
          outCityPerKmPkr: 30,
        ),
      );
      expect(find.textContaining('for 3 days'), findsNothing);
      expect(find.text('Out-of-city: Rs. 30 / km'), findsOneWidget);
    });
  });

  group('Team C — PW-2 deposit refund terms', () {
    Widget card() => BookingSummaryCard(
          carName: 'Toyota Corolla GLi 2022',
          plateNumber: 'LEA-22-4567',
          shopName: 'Test Showroom',
          isWithDriver: false,
          packageType: '24h',
          pickupTime: DateTime(2026, 11, 20, 10),
          returnTime: DateTime(2026, 11, 23, 10),
          totalAmount: 21000,
          advanceRequired: 5000,
          securityDepositPkr: 15000,
        );

    testWidgets('review card shows the refund terms, no time window',
        (tester) async {
      await _pump(tester, card());
      expect(
          find.text(
              'Security refunded after return inspection, minus damage and excess-km charges.'),
          findsOneWidget);
    });

    testWidgets('review card shows the refund terms in Urdu',
        (tester) async {
      await _pump(tester, card(), locale: const Locale('ur'));
      expect(
          find.text(
              'واپسی کے معائنے کے بعد سیکیورٹی واپس کی جائے گی، نقصان اور اضافی کلومیٹر کے چارجز منہا کر کے۔'),
          findsOneWidget);
    });
  });

  group('Team C — PW-11 driver night stay', () {
    testWidgets('with-driver notice uses the verified Rs. 2,000 default',
        (tester) async {
      await _pump(
          tester, const AdvanceDepositNoticeCard(isWithDriver: true));
      expect(find.textContaining('2,000/night'), findsOneWidget);
      expect(find.textContaining('1,500/night'), findsNothing);
    });

    testWidgets('with-driver notice uses the vehicle rate when set',
        (tester) async {
      await _pump(
          tester,
          const AdvanceDepositNoticeCard(
              isWithDriver: true, driverNightStayPkr: 1500));
      expect(find.textContaining('1,500/night'), findsOneWidget);
    });
  });

  group('Team C — PW-21 / AC-11 return payment steps', () {
    testWidgets('owed row, collection step and close hint render',
        (tester) async {
      await _pump(
        tester,
        const ReturnPaymentSteps(
          bookingId: 'RH-TEAMC-1',
          netRefund: 0,
          amountOwed: 5000,
          isFinalizing: false,
          onCompleteClose: _noop,
        ),
      );
      expect(find.text('Amount owed by customer: Rs. 5,000'),
          findsOneWidget);
      expect(find.text('Complete & Close Booking'), findsOneWidget);
      await tester.tap(find.text('Mark Payment Received'));
      await tester.pump();
      expect(find.text('Owed amount collected: Rs. 5,000 via Cash'),
          findsOneWidget);
    });

    testWidgets('no owed step when nothing is owed', (tester) async {
      await _pump(
        tester,
        const ReturnPaymentSteps(
          bookingId: 'RH-TEAMC-1',
          netRefund: 12000,
          amountOwed: 0,
          isFinalizing: false,
          onCompleteClose: _noop,
        ),
      );
      expect(find.textContaining('Amount owed by customer'), findsNothing);
    });
  });

  group('Team C — PW-16 handover balance section', () {
    testWidgets('balance, method chips and deposit render at large text',
        (tester) async {
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: HandoverBalanceSection(
                  balanceDue: 16000,
                  securityDeposit: 15000,
                  selectedMethod: null,
                  onMethodChanged: (m) => picked = m,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Balance due at handover'), findsOneWidget);
      expect(find.text('Rs. 16,000'), findsOneWidget);
      expect(find.text('Rs. 15,000'), findsOneWidget);
      await tester
          .tap(find.byKey(const ValueKey('handover_balance_method_dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('Not yet'), findsWidgets);
      await tester.tap(find.text('JazzCash').last);
      await tester.pumpAndSettle();
      expect(picked, 'jazzcash');
    });

    testWidgets('handover view starts with no fuel picked and shows the balance',
        (tester) async {
      // Full-screen view: pumped as the home, not inside the
      // helper's scroll view (unbounded height breaks its Expanded).
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerHandoverSignatureView(booking: _testBooking()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Balance due at handover'), findsOneWidget);
      expect(find.text('Rs. 16,000'), findsOneWidget);
      // PW-17: no fuel chip (and no method chip) is preselected.
      expect(
          find.byWidgetPredicate(
              (w) => w is ChoiceChip && w.selected),
          findsNothing);
    });
  });

  group('Team C — AC-11 contract signing', () {
    testWidgets('disabled Sign Agreement shows the reason', (tester) async {
      await _pump(
        tester,
        ContractSigningSection(
          booking: _testBooking(),
          onGuarantorSigned: (_) {},
          onPdfRegenerated: (_) {},
        ),
      );
      expect(find.text('Sign Agreement'), findsOneWidget);
      expect(find.text('Add the guarantor signature to sign.'),
          findsOneWidget);
    });
  });

  group('Team C — DS-11 / AC-13 disputes list', () {
    testWidgets('empty list uses the shared empty state', (tester) async {
      await _pump(tester, const MyDisputesList());
      expect(find.text('My Disputes'), findsOneWidget);
      expect(find.text('No disputes filed yet.'), findsOneWidget);
    });
  });

  group('Team C — DS-11 manual booking vehicles', () {
    testWidgets('vehicle loading shows a labelled spinner', (tester) async {
      final depositController = TextEditingController();
      addTearDown(depositController.dispose);
      // pump() only — pumpAndSettle never settles while a spinner
      // animates.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ManualBookingVehicleSection(
                isLoadingVehicles: true,
                vehicles: const [],
                selectedVehicle: null,
                onVehicleChanged: (_) {},
                selectedPackage: null,
                onPackageChanged: (_) {},
                isWithDriver: false,
                onDriverModeChanged: (_) {},
                depositController: depositController,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Loading vehicles…'), findsOneWidget);
    });
  });

  group('Team C — PW-21 return view', () {
    testWidgets('damage above the deposit surfaces the owed row',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerReturnSettlementView(booking: _testBooking()),
        ),
      );
      await tester.pumpAndSettle();
      // Target the damage-charge field by its label (the view also
      // has odometer, damage-notes and fare-amount fields).
      final damageField = find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.labelText == 'Damage charge (Rs.)');
      expect(damageField, findsOneWidget);
      await tester.enterText(damageField, '20000');
      await tester.pump();
      expect(find.text('Amount owed by customer: Rs. 5,000'),
          findsOneWidget);
    });
  });

  group('Team C — BP-2 / BP-4 trailing spacers', () {
    Future<double> gapBelow(WidgetTester tester, Finder lastContent) async {
      final scroll = find.byType(SingleChildScrollView).first;
      await tester.drag(scroll, const Offset(0, -5000));
      await tester.pumpAndSettle();
      return tester.getBottomRight(scroll).dy -
          tester.getBottomRight(lastContent).dy;
    }

    Future<void> pump360(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('BP-2 proof upload: last content 12 dp above the footer',
        (tester) async {
      await pump360(
          tester, PaymentProofUploadView(booking: _testBooking()));
      // Last scroll child is the private-note container (no shop
      // phone on this booking, so no WhatsApp button follows it).
      final note = find.byWidgetPredicate(
          (w) => w is Container && w.child is Row);
      expect(note, findsOneWidget);
      expect(await gapBelow(tester, note), closeTo(12, 1));
    });

    testWidgets('BP-4 review: last content 12 dp above the footer',
        (tester) async {
      await pump360(
        tester,
        ReviewBookingRequestView(
          bookingDraft: {
            'carId': 'veh-1',
            'carName': 'Toyota Corolla GLi 2022',
            'plateNumber': 'LEA-22-4567',
            'shopName': 'Test Showroom',
            'shopId': 'shop-1',
            'shopIsVerified': true,
            'isWithDriver': false,
            'packageType': '24h',
            'pickupTime': DateTime(2026, 11, 20, 10),
            'returnTime': DateTime(2026, 11, 23, 10),
            'totalAmount': 21000,
            'advanceRequired': 5000,
            'tripType': 'in_city',
            'securityDepositPkr': 15000,
          },
        ),
      );
      // Last scroll child is the special-instructions container.
      final notes = find.byWidgetPredicate(
          (w) => w is Container && w.child is Column);
      expect(
          await gapBelow(tester, notes.last), closeTo(12, 1));
    });
  });
}
