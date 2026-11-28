import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_bookings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_cancel_booking_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_dispute_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_profile_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_rate_trip_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_reputation_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_saved_shops_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_settings_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_sos_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_support_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/core/settings/app_settings_cubit.dart';
import 'package:rentalhub/features/finance/data/datasources/security_deposit_data_source.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    // CU-m3: the dispute form refuses to file with nobody signed in.
    // Widget tests cannot sign a Firebase user in, so stand in as
    // 'cust-101' via the SignedInUser test override.
    SignedInUser.override = const SignedInUserData(
      uid: 'cust-101',
      displayName: 'Ahmed Raza',
      phoneNumber: '03001234567',
    );
  });

  tearDownAll(() {
    SignedInUser.override = null;
  });

  group('Batch 2: Customer Post-Trip & Dashboard Tests', () {

    testWidgets('CustomerBookingsView: switches between 6 tabs and filters records', (tester) async {
      // Next-step batch: a Disputed chip joins the five grouped tabs
      // (All, Pending, Approved, Active, Disputed, Done). Disputed
      // is an exact-match group; Done still groups completed +
      // cancelled + rejected.
      final ds = di.sl<BookingRemoteDataSource>();
      Future<void> seed(String name, String status) async {
        final created = await ds.createBookingRequest(
          customerId: 'cust-101',
          shopId: 'shop-1',
          vehicleId: 'veh-tabs-${name.replaceAll(' ', '-')}',
          packageType: '24h',
          isWithDriver: false,
          pickupTime: DateTime.now().add(const Duration(hours: 5)),
          returnTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
          totalAmount: 9000,
          advanceRequired: 2500,
          vehicleName: name,
        );
        if (status != 'requested') {
          await ds.updateBookingStatus(
              bookingId: created.bookingId, status: status);
        }
      }

      await seed('Disputed Datsun', 'disputed');
      await seed('Completed Corolla', 'completed');
      await seed('Cancelled Cultus', 'cancelled');
      await seed('Rejected Ravi', 'rejected');

      await tester.pumpWidget(
        const MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerBookingsView(),
        ),
      );
      await tester.pumpAndSettle();

      // The list lazily builds its cards: a booking below the fold
      // is not in the tree until the list scrolls to it.
      Future<void> expectNameVisible(String name) async {
        await tester.scrollUntilVisible(
          find.text(name),
          300,
          // The first Scrollable is the filter bar's horizontal
          // scroller; the list is the last one.
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(find.text(name), findsOneWidget);
      }

      expect(find.text('My Reservations'), findsOneWidget);
      for (final tab in ['All', 'Pending', 'Approved', 'Active', 'Disputed', 'Done']) {
        expect(find.widgetWithText(ChoiceChip, tab), findsOneWidget);
      }
      // All shows every seeded booking.
      await expectNameVisible('Disputed Datsun');
      await expectNameVisible('Completed Corolla');
      await expectNameVisible('Cancelled Cultus');
      await expectNameVisible('Rejected Ravi');

      // Disputed shows only the disputed booking.
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Disputed'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Disputed'));
      await tester.pumpAndSettle();
      expect(find.text('Disputed Datsun'), findsOneWidget);
      expect(find.text('Completed Corolla'), findsNothing);
      expect(find.text('Cancelled Cultus'), findsNothing);
      expect(find.text('Rejected Ravi'), findsNothing);

      // Done still groups completed + cancelled + rejected.
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Done'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Done'));
      await tester.pumpAndSettle();
      await expectNameVisible('Completed Corolla');
      await expectNameVisible('Cancelled Cultus');
      await expectNameVisible('Rejected Ravi');
      expect(find.text('Disputed Datsun'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Pending'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Approved'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Approved'), findsOneWidget);
    });

    testWidgets('CustomerWalletView: shows real advances and deposits from the booking records', (tester) async {
      // F1: seed a real booking with a verified advance and a collected
      // deposit, then the wallet must show those exact amounts — the
      // old hardcoded Rs. 15,000 / 5,000 / 10,000 is gone.
      final bookingDs = di.sl<BookingRemoteDataSource>();
      final booking = await bookingDs.createBookingRequest(
        customerId: 'cust-101',
        shopId: 'shop-1',
        vehicleId: 'veh-civic',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now().add(const Duration(hours: 5)),
        returnTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
        totalAmount: 9000,
        advanceRequired: 2500,
        vehicleName: 'Honda Civic',
      );
      await bookingDs.verifyPayment(
        bookingId: booking.bookingId,
        advanceAmount: 2500,
      );
      await di.sl<SecurityDepositDataSource>().collect(
            bookingId: booking.bookingId,
            customerId: 'cust-101',
            shopId: 'shop-1',
            amount: 10000,
          );

      await tester.pumpWidget(
        const MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerWalletView(),
        ),
      );
      await tester.pumpAndSettle();

      // Phase E (E1): the balance is masked by default — reveal it
      // via the eye toggle before asserting the seeded amounts.
      // CU-m6: the escrow pills carry no eye of their own any more;
      // the header has ONE visibility toggle. The pill amounts stay
      // masked; the advance/deposit figures below are the ledger
      // rows, which are never masked and carry their debit sign
      // ('- Rs. 2,500', not the plain pill text 'Rs. 2,500').
      await tester.tap(find.byTooltip('Show balance'));
      await tester.pump();

      expect(find.text('Wallet & Security Escrow'), findsOneWidget);
      expect(find.text('Total with shop: advances paid + Security held'), findsOneWidget);
      expect(find.text('Rs. 12,500'), findsOneWidget);
      expect(find.text('- Rs. 2,500'), findsOneWidget);
      expect(find.text('- Rs. 10,000'), findsOneWidget);
      expect(find.text('Transaction Ledger'), findsOneWidget);
      expect(find.textContaining('Advance paid — Honda Civic'), findsOneWidget);
      expect(find.textContaining('Security held — Honda Civic'),
          findsOneWidget);
    });

    testWidgets('CustomerSupportView: searches FAQs and triggers contact options', (tester) async {
      bool filedDispute = false;

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerSupportView(
            onFileDispute: () => filedDispute = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support Center'), findsOneWidget);
      // G1: the contact cards reach the customer's own showroom now —
      // no invented RentalHub helpline number.
      expect(find.text('Call your showroom'), findsOneWidget);
      expect(find.text('WhatsApp your showroom'), findsOneWidget);
      expect(find.text('Message Support'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);

      // Search FAQ — the ticket form adds a second TextField, so the
      // search box is the first one in the tree.
      await tester.enterText(find.byType(TextField).first, 'Security');
      await tester.pumpAndSettle();

      expect(find.text('When is my Security returned?'), findsOneWidget);

      // Tap dispute banner
      await tester.tap(find.text('File a Formal Complaint / Dispute'));
      await tester.pumpAndSettle();
      expect(filedDispute, isTrue);
    });

    testWidgets('CustomerDisputeView: toggles category and files dispute claim', (tester) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerDisputeView(
            initialBookingId: 'RH-849201',
            onDisputeSubmitted: () => submitted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('File Complaint / Dispute'), findsOneWidget);
      expect(find.text('Security Withheld'), findsOneWidget);
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
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
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

      // CU-m12: both ratings start UNSET (0) and an untouched rating
      // blocks submit instead of filing a 5 — tap a star on each bar
      // first (the test is named "sets dual stars" for a reason).
      await tester.tap(find.byTooltip('Rate 5 out of 5').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Rate 5 out of 5').at(1));
      await tester.pumpAndSettle();

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
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerCancelBookingView(
            booking: booking,
            onCancelled: () => cancelled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel Reservation'), findsOneWidget);
      // G5: the invented refund timetable is gone — the screen now
      // says plainly what happens (no advance paid yet on this booking).
      expect(find.text('What happens when you cancel'), findsOneWidget);
      expect(find.textContaining('No advance has been paid yet'),
          findsOneWidget);

      await tester.tap(find.text('Found another vehicle'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm Cancellation'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
      // G5: the reason travels with the cancellation.
      final updated = await ds.getBookingById(booking.bookingId);
      expect(updated?.status, 'cancelled');
      expect(updated?.rejectionReason, 'Found another vehicle');
    });

    testWidgets('CustomerProfileView: renders user profile, trust score, and menu options', (tester) async {
      bool openedDocs = false;
      bool openedSaved = false;

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerProfileView(
            onOpenDocuments: () => openedDocs = true,
            onOpenSavedShops: () => openedSaved = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // H1: no signed-in user in tests, so the profile shows Guest
      // once in the hero header (not duplicated in the identity card)
      // and an unknown trust score — never the old hardcoded 4.8.
      expect(find.text('Guest'), findsOneWidget);
      // Trust score shows in the sticky header chip and the unified
      // trust section card.
      expect(find.text('Trust Score: —'), findsNWidgets(2));
      // Unverified header chip opens Documents & KYC directly.
      expect(find.text('Verify KYC'), findsOneWidget);
      expect(find.text('Saved Showrooms'), findsOneWidget);

      await tester.tap(find.text('Verify KYC'));
      await tester.pumpAndSettle();
      expect(openedDocs, isTrue);

      await tester.ensureVisible(find.text('Saved Showrooms'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved Showrooms'));
      await tester.pumpAndSettle();
      expect(openedSaved, isTrue);
    });

    testWidgets('CustomerSavedShopsView: displays bookmarked showrooms list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerSavedShopsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Showrooms'), findsOneWidget);
      // H5: the hardcoded demo shops are gone — with no signed-in
      // customer the list is honestly empty.
      expect(find.text('No saved showrooms yet.'), findsOneWidget);
      expect(
          find.text('Tap the heart on any showroom to save it here.'),
          findsOneWidget);
    });

    testWidgets('CustomerSettingsView: switches language via AppSettingsCubit and shows notification toggles', (tester) async {
      // H2: language and theme are real AppSettingsCubit toggles now —
      // the old fake setState Urdu switch is gone.
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerSettingsView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('Urdu'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('WhatsApp Notifications'), findsOneWidget);

      await tester.tap(find.text('Urdu'));
      await tester.pumpAndSettle();
      expect(di.sl<AppSettingsCubit>().state.localeCode, 'ur');
    });

    testWidgets('CustomerSosView: renders SOS pulse button and emergency contacts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('CustomerReputationView: shows unknown score with no owner reviews', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerReputationView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Trust & Reputation'), findsOneWidget);
      // H3: the hardcoded 4.8 and the invented score bars are gone.
      expect(find.text('— / 5.0'), findsOneWidget);
      expect(
          find.text(
              'No showroom has rated you yet. Your reputation appears here after your first completed trip.'),
          findsOneWidget);
    });
  });
}

