import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  });

  tearDown(() async {
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
      expect(find.text('Find Verified Rental Shops'), findsOneWidget);
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
      expect(find.textContaining('Rs. 9000'), findsWidgets);
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
      expect(find.text('Total Fleet'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_rounded), findsOneWidget);
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

      // Step 2: Location & Map
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Location & Map Pin'), findsOneWidget);
      expect(tester.takeException(), isNull);

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

      // Step 2: Photos & Registration
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Car Photos & Docs'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Step 3: Rates & Deposit Policy
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();
      expect(find.text('Rental Rates & Policy'), findsOneWidget);
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
      expect(find.text('Find Verified Rental Shops'), findsOneWidget);
    });

    testWidgets('OwnerDashboardView renders without overflow at 200% text scale',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OwnerDashboardView(),
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
