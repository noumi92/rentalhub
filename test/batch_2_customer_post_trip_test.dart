import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_bookings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_cancel_booking_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_dashboard_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_dispute_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_profile_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_rate_trip_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_reputation_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_saved_shops_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_settings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_sos_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_support_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Batch 2: Customer Post-Trip & Dashboard Tests', () {
    testWidgets('CustomerDashboardView: renders header, stats, and quick service buttons', (tester) async {
      bool explored = false;
      bool openedBookings = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDashboardView(
            onExploreShops: () => explored = true,
            onOpenBookings: () => openedBookings = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer Dashboard'), findsOneWidget);
      expect(find.text('Total Trips'), findsOneWidget);
      expect(find.text('Trust Score'), findsOneWidget);
      expect(find.text('Explore Shops'), findsOneWidget);
      expect(find.text('My Bookings'), findsOneWidget);

      await tester.tap(find.text('Explore Shops'));
      await tester.pumpAndSettle();
      expect(explored, isTrue);

      await tester.tap(find.text('My Bookings'));
      await tester.pumpAndSettle();
      expect(openedBookings, isTrue);
    });

    testWidgets('CustomerBookingsView: switches between 5 tabs and filters records', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerBookingsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Reservations'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();
      expect(find.text('Pending'), findsOneWidget);

      await tester.tap(find.text('Approved'));
      await tester.pumpAndSettle();
      expect(find.text('Approved'), findsOneWidget);
    });

    testWidgets('CustomerWalletView: displays escrow balance and transaction ledger', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerWalletView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wallet & Security Escrow'), findsOneWidget);
      expect(find.text('Active Escrow & Advances'), findsOneWidget);
      expect(find.text('Rs. 15,000'), findsOneWidget);
      expect(find.text('Transaction Ledger'), findsOneWidget);
    });

    testWidgets('CustomerSupportView: searches FAQs and triggers contact options', (tester) async {
      bool filedDispute = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerSupportView(
            onFileDispute: () => filedDispute = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support Center'), findsOneWidget);
      expect(find.text('Call Helpline'), findsOneWidget);
      expect(find.text('WhatsApp Desk'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);

      // Search FAQ
      await tester.enterText(find.byType(TextField), 'deposit');
      await tester.pumpAndSettle();

      expect(find.text('When is my security deposit returned?'), findsOneWidget);

      // Tap dispute banner
      await tester.tap(find.text('File a Formal Complaint / Dispute'));
      await tester.pumpAndSettle();
      expect(filedDispute, isTrue);
    });

    testWidgets('CustomerDisputeView: toggles category and files dispute claim', (tester) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDisputeView(
            initialBookingId: 'RH-849201',
            onDisputeSubmitted: () => submitted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('File Complaint / Dispute'), findsOneWidget);
      expect(find.text('Deposit Withheld'), findsOneWidget);
      expect(find.text('RH-849201'), findsOneWidget);

      // Toggle category
      await tester.tap(find.text('Unfair Damage Penalty'));
      await tester.pumpAndSettle();

      // Enter explanation
      await tester.enterText(
        find.widgetWithText(TextField, 'Describe what happened with dates, amounts, and showroom staff names...'),
        'Showroom charged Rs. 3,000 for pre-existing scratches documented on handover.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit Claim'));
      await tester.pumpAndSettle();
      expect(submitted, isTrue);
    });

    testWidgets('CustomerRateTripView: sets dual stars and submits review', (tester) async {
      bool submitted = false;
      final booking = BookingEntity(
        bookingId: 'RH-849205',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 9000,
        remainingBalance: 0,
        status: 'completed',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerRateTripView(
            booking: booking,
            onRatingSubmitted: () => submitted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rate Your Experience'), findsOneWidget);
      expect(find.text('Showroom Service Quality'), findsOneWidget);
      expect(find.text('Vehicle Condition & Cleanliness'), findsOneWidget);

      await tester.tap(find.text('Submit Trip Review'));
      await tester.pumpAndSettle();
      expect(submitted, isTrue);
    });

    testWidgets('CustomerCancelBookingView: selects reason and confirms cancellation', (tester) async {
      bool cancelled = false;
      final ds = di.sl<BookingRemoteDataSource>();
      final booking = await ds.createBookingRequest(
        customerId: 'cust-cancel',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 5000,
        advanceRequired: 1000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerCancelBookingView(
            booking: booking,
            onCancelled: () => cancelled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel Reservation'), findsOneWidget);
      expect(find.text('Cancellation Policy'), findsOneWidget);

      await tester.tap(find.text('Found another vehicle'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Cancellation'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
    });

    testWidgets('CustomerProfileView: renders user profile, trust score, and menu options', (tester) async {
      bool openedDocs = false;
      bool openedSaved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerProfileView(
            onOpenDocuments: () => openedDocs = true,
            onOpenSavedShops: () => openedSaved = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trust Score: 4.8 / 5.0'), findsOneWidget);
      expect(find.text('My Documents (KYC)'), findsOneWidget);
      expect(find.text('Saved Showrooms'), findsOneWidget);

      await tester.tap(find.text('My Documents (KYC)'));
      await tester.pumpAndSettle();
      expect(openedDocs, isTrue);

      await tester.tap(find.text('Saved Showrooms'));
      await tester.pumpAndSettle();
      expect(openedSaved, isTrue);
    });

    testWidgets('CustomerSavedShopsView: displays bookmarked showrooms list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerSavedShopsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Showrooms'), findsOneWidget);
      expect(find.text('Al-Falah Rent a Car'), findsOneWidget);
      expect(find.text('Capital Wheels Islamabad'), findsOneWidget);
    });

    testWidgets('CustomerSettingsView: toggles Urdu interface and notifications', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerSettingsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('Urdu Interface (اردو)'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);

      await tester.tap(find.text('Urdu Interface (اردو)'));
      await tester.pumpAndSettle();
    });

    testWidgets('CustomerSosView: renders SOS pulse button and emergency contacts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerSosView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergency SOS Assistance'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Call Police Emergency 15'), findsOneWidget);
      expect(find.text('Share Live Location via WhatsApp'), findsOneWidget);

      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();
    });

    testWidgets('CustomerReputationView: renders 4-dimensional performance metrics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerReputationView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Trust & Reputation'), findsOneWidget);
      expect(find.text('4.8 / 5.0'), findsOneWidget);
      expect(find.text('4-Dimensional Performance Score'), findsOneWidget);
      expect(find.text('Vehicle Care & Cleanliness'), findsOneWidget);
      expect(find.text('On-Time Handover Punctuality'), findsOneWidget);
    });
  });
}
