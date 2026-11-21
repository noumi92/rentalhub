import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/views/owner_payment_accounts_view.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/auth/presentation/views/onboarding_profile_view.dart';
import 'package:rentalhub/features/auth/presentation/views/onboarding_role_view.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/customer_home_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/shop_detail_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/vehicle_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_add_vehicle_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/add_vehicle/add_vehicle_step_content.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_fleet_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_onboarding_view.dart';
import 'package:rentalhub/features/trust/presentation/views/customer_documents_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
    // CU-m3: CustomerDocumentsView shows a signed-out error state
    // with nobody signed in. Widget tests cannot sign a Firebase
    // user in, so stand in as 'cust-101' via the SignedInUser
    // test override — the KYC form then renders for the overflow
    // check.
    SignedInUser.override = const SignedInUserData(
      uid: 'cust-101',
      displayName: 'Ahmed Raza',
      phoneNumber: '03001234567',
    );
  });

  tearDown(() async {
    SignedInUser.override = null;
    await sl.reset();
  });

  const sampleShop = ShopEntity(
    shopId: 'shop_001',
    ownerId: 'owner_001',
    shopName: 'Al-Madina Rent a Car',
    phoneNumber: '+92 300 4129811',
    address: 'Main Boulevard, Gulberg III',
    city: 'Lahore',
    geoLocation: GeoPointEntity(31.5204, 74.3587),
    distanceKm: 0.8,
    rating: 4.9,
    availableCount: 12,
    isVerified: true,
  );

  group('Multi-Screen Viewport Overflow Hardening Tests', () {
    testWidgets('CustomerHomeView renders without overflow on 360px viewport',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerHomeView(),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('VehicleDetailView renders without overflow on 360px viewport and 1.35x font scale',
        (WidgetTester tester) async {
      final sampleVehicle = const VehicleEntity(
        vehicleId: 'v1',
        shopId: 'shop-basic',
        make: 'Honda',
        model: 'Civic Oriel',
        year: 2021,
        plateNumber: 'LEA-4820',
        rates: VehicleRatesEntity(daily24: 9000),
      );
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: VehicleDetailView(
          vehicle: sampleVehicle,
          shopName: 'Al-Falah Rent a Car',
          shopPhone: '+923001234567',
        ),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      expect(find.textContaining(sampleVehicle.model), findsWidgets);
      expect(find.textContaining('Rs. 9,000'), findsWidgets);
    });

    testWidgets('ShopDetailView renders without overflow on 360px viewport and 1.35x font scale',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const ShopDetailView(shop: sampleShop),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Al-Madina Rent a Car'), findsOneWidget);
      expect(find.textContaining('Lahore'), findsWidgets);
    });

    testWidgets('OwnerFleetView renders without overflow on 360px viewport and 1.35x font scale',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerFleetView(),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Fleet Management'), findsOneWidget);
      // Phase 2: the KPI boxes are merged into the segmented bar
      // (All / Ready / On Rent / Maintenance), and "+ Add Vehicle"
      // is the extended floating button. The count depends on the
      // harness's seeded shop, so only the "All" segment is pinned.
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.byTooltip('Add Vehicle'), findsOneWidget);
    });

    testWidgets('CustomerDocumentsView renders without overflow on 360px viewport and 1.35x font scale',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerDocumentsView(),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('NADRA CNIC & Driving License KYC'), findsOneWidget);
      expect(find.text('NADRA CNIC — Front Side'), findsOneWidget);
    });

    testWidgets('OnboardingProfileView renders without overflow on 360px viewport',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OnboardingProfileView(),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Step 1: Your Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
    });

    testWidgets('OnboardingRoleView renders without overflow on 360px viewport',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OnboardingRoleView(),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Step 2: Account Role'), findsOneWidget);
      expect(find.text('Rent a Vehicle (Customer)'), findsOneWidget);
    });

    testWidgets('OwnerOnboardingView: Step 1 through Step 4 render with zero overflow on 360px viewport',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerOnboardingView(),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );

      // Step 1: Shop Profile Info
      expect(find.text('Shop Registration'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Audit §1: step-1 fields start empty (the old prefilled demo
      // data used to satisfy validation); enter valid values first.
      // Labels are sibling Texts, not field decorations, so the
      // fields are found by order: shop name, owner, CNIC, WhatsApp,
      // phone.
      await tester.enterText(
          find.byType(TextField).at(0), 'Al-Falah Rent a Car');
      await tester.enterText(find.byType(TextField).at(3), '03001234567');
      await tester.pumpAndSettle();

      // Step 2: Location & Map
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Location & Map Pin'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Audit §1: the address field also starts empty now.
      await tester.enterText(find.byType(TextField).first,
          'Shop 12, Main Boulevard, DHA Phase 5');
      await tester.pumpAndSettle();

      // Step 3: Payout Accounts
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Payout Accounts'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Enable payout method so validation passes to next step
      final switchFinder = find.byType(Switch);
      if (switchFinder.evaluate().isNotEmpty) {
        await tester.tap(switchFinder.first);
        await tester.pumpAndSettle();
      }

      // Step 4: KYC & Legal Docs
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('KYC & Verification'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OwnerAddVehicleView: Step 1 through Step 3 render with zero overflow on 360px viewport',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerAddVehicleView(),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );

      // Step 1: Specs & Capacity & AC
      expect(find.text('Add Vehicle - Specs'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Audit §5: step 1 now requires a valid plate (it used to ship
      // prefilled with the sample plate LEA-23-4567).
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.enterText(find.byType(TextField).last, 'LEA-23-4567');
      await tester.pumpAndSettle();

      // Step 2: Photos & Registration
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Car Photos & Docs'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Step 3: Rates & Deposit Policy — audit §5 (spec O8) blocks
      // step 2 without a front photo, so step 3 is overflow-checked
      // as a standalone step (no photo can be picked in tests).
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Car Photos & Docs'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The rates step needs a Material ancestor (Checkbox/TextField)
      // — the wizard's Scaffold normally provides it — and the wizard
      // scrolls its step content, so the standalone pump must too or
      // the tall step overflows the 640px viewport vertically.
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: Scaffold(body: SingleChildScrollView(child: AddVehicleRatesStep(
          enable1Hour: true,
          onToggle1Hour: (_) {},
          rate1HourController: TextEditingController(text: '1200'),
          enable3Hours: true,
          onToggle3Hours: (_) {},
          rate3HoursController: TextEditingController(text: '3000'),
          enable6Hours: true,
          onToggle6Hours: (_) {},
          rate6HoursController: TextEditingController(text: '5500'),
          enable24Hours: true,
          onToggle24Hours: (_) {},
          rate24HoursController: TextEditingController(text: '8500'),
          outCityDayRateController: TextEditingController(text: '9500'),
          enableWeekly: true,
          onToggleWeekly: (_) {},
          rateWeeklyController: TextEditingController(text: '52000'),
          enableMonthly: true,
          onToggleMonthly: (_) {},
          rateMonthlyController: TextEditingController(text: '210000'),
          supportSelfDrive: true,
          onToggleSelfDrive: (_) {},
          supportWithDriver: true,
          onToggleWithDriver: (_) {},
          securityDepositController: TextEditingController(text: '25000'),
          advanceDepositController: TextEditingController(text: '2000'),
          extraHourChargeController: TextEditingController(text: '600'),
          fuelPolicy: 'Same to Same',
          onFuelPolicyChanged: (_) {},
        ))),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      // 'Rental Rates & Policy' is the wizard's step-3 title, not a
      // text inside the rates step itself — assert on the step's own
      // heading instead.
      expect(find.text('Duration Packages (Hourly & Daily)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OwnerPaymentAccountsView renders without overflow on 360px viewport and 1.35x font scale',
        (WidgetTester tester) async {
      // Phase E/F (E2): the booking-flow screen migrated to the shared
      // AppLoadingState / AppEmptyState. No shop has accounts in the
      // test env, so the Firestore read falls back to the empty state.
      final sampleBooking = BookingEntity(
        bookingId: 'RH-1762574400123-0042',
        customerId: 'cust-101',
        shopId: 'shop-1',
        vehicleId: 'v-1',
        packageType: '24h',
        pickupTime: DateTime(2026, 11, 8, 10),
        returnTime: DateTime(2026, 11, 9, 10),
        totalAmount: 1250000,
        remainingBalance: 1250000,
        status: 'payment_submitted',
        vehicleName: 'Toyota Corolla Grande 1.8',
        vehiclePlate: 'LEA-21-4820',
        shopName: 'Al-Madina Rent a Car',
        customerName: 'Muhammad Ahmed Khan Butt',
        customerPhone: '0300-1234567',
      );
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: OwnerPaymentAccountsView(booking: sampleBooking),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Showroom Payment Accounts'), findsOneWidget);
    });
  });

  group('Phase E/F migrated screens at 200% text scale', () {
    // Phase E3 did the 200% text-scale overflow pass on all 10 tab
    // screens; these four are the ones Phases E/F touched most
    // (quick-action tiles, masked values, filter chips, shared state
    // views). The pass pins the result so a later widget change
    // cannot silently reintroduce a 200% overflow.
    testWidgets('CustomerHomeView renders without overflow at 200% text scale',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerHomeView(),
        width: 360.0,
        height: 640.0,
        textScale: 2.0,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('OwnerDashboardView renders without overflow at 200% text scale',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerDashboardView(shopId: 'shop-1'),
        width: 360.0,
        height: 640.0,
        textScale: 2.0,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Showroom Revenue & Operations'), findsOneWidget);
    });

    testWidgets('CustomerWalletView renders without overflow at 200% text scale',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const CustomerWalletView(),
        width: 360.0,
        height: 640.0,
        textScale: 2.0,
        theme: AppTheme.lightTheme,
      );
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('OwnerFleetView renders without overflow at 200% text scale',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerFleetView(),
        width: 360.0,
        height: 640.0,
        textScale: 2.0,
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Fleet Management'), findsOneWidget);
    });
  });
}
