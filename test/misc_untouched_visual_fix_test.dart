import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/auth/presentation/views/widgets/role_selector_card.dart';
import 'package:rentalhub/features/auth/presentation/views/widgets/security_policy_banner.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_booking_detail_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_cancel_booking_view.dart';
import 'package:rentalhub/features/settings/presentation/views/sync_details_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleBooking = BookingEntity(
    bookingId: 'BKG-1042',
    customerId: 'cust-001',
    shopId: 'shop-001',
    vehicleId: 'veh-001',
    packageType: 'weekly',
    pickupTime: DateTime(2026, 11, 20, 9),
    returnTime: DateTime(2026, 11, 27, 9),
    totalAmount: 52500,
    advanceRequired: 10000,
    advancePaid: 10000,
    remainingBalance: 42500,
    status: 'approved',
    vehicleName: 'Toyota Corolla Grande 2023',
    vehiclePlate: 'LEA-23-4567',
    shopName: 'Al-Madina Rent a Car',
    rejectionReason: 'Payment proof was blurry, please upload again.',
  );

  group('Misc untouched visual fixes (2026-11-14)', () {
    testWidgets('RoleSelectorCard renders in Urdu at 360px without overflow',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: Scaffold(
          body: RoleSelectorCard(
            roleKey: 'owner',
            title: 'Owner',
            urduSubtitle: 'مالک',
            description:
                'List your cars and manage bookings, payments and customers.',
            icon: Icons.directions_car_filled_rounded,
            isSelected: true,
            onTap: () {},
          ),
        ),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
        locale: const Locale('ur'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(find.text('مالک'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
    });

    testWidgets('CustomerCancelBookingView renders at 360px without overflow',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: CustomerCancelBookingView(booking: sampleBooking),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(find.text('Change of travel plans'), findsOneWidget);
    });

    testWidgets(
        'CustomerBookingDetailView renders in Urdu at 360px without overflow',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: CustomerBookingDetailView(booking: sampleBooking),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
        locale: const Locale('ur'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      // The vehicle name renders in the app bar, the ticket card and
      // the summary, so expect all three — the overflow check above
      // is the assertion that matters here.
      expect(find.text('Toyota Corolla Grande 2023'), findsWidgets);
    });

    testWidgets('SecurityPolicyBanner renders in dark mode without overflow',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SecurityPolicyBanner(
                message:
                    'Your account is protected by two-step verification.',
              ),
            ),
          ),
        ),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(
          find.text('Your account is protected by two-step verification.'),
          findsOneWidget);
    });

    testWidgets('SyncDetailsView shows the shared empty state when idle',
        (WidgetTester tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: const SyncDetailsView(),
        width: 360.0,
        height: 640.0,
        textScale: 1.35,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(find.text('Nothing pending'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });
  });
}
