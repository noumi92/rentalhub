import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/bookings/presentation/views/booking_success_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/owner_payment_accounts_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/payment_proof_upload_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/pickup_countdown_pass_view.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_active_trip_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/rent_package_picker_view.dart';
import 'package:rentalhub/features/bookings/presentation/views/review_booking_request_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/shop_cars_view.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Batch 1: Customer Booking Flow CRUD Operations', () {
    late BookingRemoteDataSource dataSource;

    setUp(() {
      dataSource = BookingRemoteDataSource();
    });

    test('Create Booking Request: writes to store with requested status and calculations', () async {
      final pickup = DateTime.now().add(const Duration(hours: 3));
      final ret = pickup.add(const Duration(days: 2));

      final booking = await dataSource.createBookingRequest(
        customerId: 'cust-101',
        shopId: 'shop-gulberg',
        vehicleId: 'veh-civic-01',
        packageType: '24h',
        isWithDriver: true,
        pickupTime: pickup,
        returnTime: ret,
        totalAmount: 18000,
        advanceRequired: 4500,
        vehicleName: 'Honda Civic RS',
        vehiclePlate: 'LEA-24-900',
        shopName: 'Al-Falah Rent a Car',
      );

      expect(booking.bookingId, startsWith('RH-'));
      expect(booking.status, equals('requested'));
      expect(booking.totalAmount, equals(18000));
      expect(booking.advanceRequired, equals(4500));
      expect(booking.advancePaid, equals(0));
      expect(booking.remainingBalance, equals(18000));
      expect(booking.vehicleName, equals('Honda Civic RS'));
    });

    test('Booking State Transitions: requested -> approved -> payment_submitted -> paid', () async {
      final initial = await dataSource.createBookingRequest(
        customerId: 'cust-102',
        shopId: 'shop-01',
        vehicleId: 'veh-yaris',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 7000,
        advanceRequired: 2000,
      );

      // 1. Owner approves request
      final approved = await dataSource.updateBookingStatus(
        bookingId: initial.bookingId,
        status: 'approved',
      );
      expect(approved.status, equals('approved'));

      // 2. Customer submits payment proof
      final submitted = await dataSource.updatePaymentProof(
        bookingId: initial.bookingId,
        paymentProofUrl: 'https://storage.rentalhub.pk/pay_123.jpg',
        transactionId: 'TID-982173',
      );
      expect(submitted.status, equals('payment_submitted'));
      expect(submitted.transactionId, equals('TID-982173'));

      // 3. Showroom confirms payment
      final paid = await dataSource.verifyPayment(
        bookingId: initial.bookingId,
        advanceAmount: 2000,
      );
      expect(paid.status, equals('paid'));
      expect(paid.advancePaid, equals(2000));
      expect(paid.remainingBalance, equals(5000));

      // 4. Query customer bookings
      final list = await dataSource.getCustomerBookings('cust-102');
      expect(list.length, equals(1));
      expect(list.first.bookingId, equals(initial.bookingId));
    });
  });

  group('Batch 1: Screen UI Actions & Rendering Tests', () {
    testWidgets('RentPackagePickerView: renders duration tiers, toggles driver mode and proceeds', (tester) async {
      Map<String, dynamic>? submittedDraft;

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: RentPackagePickerView(
            carId: 'car-civic',
            carName: 'Honda Civic RS',
            plateNumber: 'LEA-24-900',
            shopId: 'shop-01',
            shopName: 'Al-Falah Rent a Car',
            dailySelfDriveRate: 8000,
            dailyWithDriverRate: 11000,
            hourlyRate: 1200,
            onProceedToReview: (draft) => submittedDraft = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Rental Package'), findsOneWidget);
      expect(find.text('Self Drive'), findsOneWidget);
      expect(find.text('With Chauffeur'), findsOneWidget);
      expect(find.text('Daily 24-Hours'), findsOneWidget);
      expect(find.text('6-Hour Express'), findsOneWidget);

      // Toggle to With Chauffeur
      await tester.tap(find.text('With Chauffeur'));
      await tester.pumpAndSettle();

      // Tap 6-Hour Express
      await tester.tap(find.text('6-Hour Express'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(submittedDraft, isNotNull);
      expect(submittedDraft!['carName'], equals('Honda Civic RS'));
      expect(submittedDraft!['isWithDriver'], isTrue);
      expect(submittedDraft!['packageType'], equals('6h'));
    });

    testWidgets('ReviewBookingRequestView: renders cost breakdown and triggers request creation', (tester) async {
      BookingEntity? createdBooking;

      final draft = {
        'carId': 'car-corolla',
        'carName': 'Toyota Corolla Altis',
        'plateNumber': 'ICT-22-101',
        'shopId': 'shop-islamabad',
        'shopName': 'Capital Wheels',
        'isWithDriver': false,
        'packageType': '24h',
        'pickupTime': DateTime.now().add(const Duration(hours: 4)),
        'returnTime': DateTime.now().add(const Duration(days: 1, hours: 4)),
        'totalAmount': 7500,
        'advanceRequired': 1875,
      };

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: ReviewBookingRequestView(
            bookingDraft: draft,
            onRequestCreated: (b) => createdBooking = b,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Reservation'), findsOneWidget);
      expect(find.text('Toyota Corolla Altis'), findsOneWidget);
      expect(find.text('Rs. 7500'), findsOneWidget);
      expect(find.text('Rs. 1875'), findsOneWidget);

      // Enter special instructions
      await tester.enterText(
        find.byType(TextField),
        'Please arrange airport terminal 1 pickup.',
      );
      await tester.pumpAndSettle();

      // Submit request
      await tester.tap(find.text('Send Request to Owner'));
      await tester.pumpAndSettle();

      expect(createdBooking, isNotNull);
      expect(createdBooking!.status, equals('requested'));
    });

    testWidgets('BookingSuccessView: renders transmission card, reference number and buttons', (tester) async {
      final booking = BookingEntity(
        bookingId: 'RH-849201',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Toyota Yaris ATIV',
        shopName: 'Metro Car Rentals',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 6000,
        advanceRequired: 1500,
        remainingBalance: 4500,
      );

      bool proceededToPayment = false;

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: BookingSuccessView(
            booking: booking,
            onProceedToPayment: () => proceededToPayment = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Sent Successfully!'), findsOneWidget);
      expect(find.text('Reference: RH-849201'), findsOneWidget);
      expect(find.text('Message Showroom on WhatsApp'), findsOneWidget);

      await tester.tap(find.text('View Payment Details / Status'));
      await tester.pumpAndSettle();

      expect(proceededToPayment, isTrue);
    });

    testWidgets('OwnerPaymentAccountsView: renders approved banner and showroom transfer options', (tester) async {
      final booking = BookingEntity(
        bookingId: 'RH-849202',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Kia Sportage AWD',
        packageType: '24h',
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 14000,
        advanceRequired: 3500,
        remainingBalance: 10500,
        // §10: a merely `requested` booking renders the decision
        // detail, not the approved banner — this test pumps an
        // approved booking on purpose.
        status: 'approved',
      );

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerPaymentAccountsView(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reservation Request Approved!'), findsOneWidget);
      expect(find.text('Direct Transfer Channels'), findsOneWidget);
      // Phase B (D1): with no accounts configured for the shop, the
      // view says so instead of showing another shop's accounts.
      expect(
          find.text('No payment accounts configured for this shop yet.'),
          findsOneWidget);
      expect(find.text('JazzCash Mobile Account'), findsNothing);
      expect(find.text('Bank Meezan Islamic'), findsNothing);
    });

    testWidgets('PaymentProofUploadView: renders TID input, deposit notice and submits proof', (tester) async {
      final booking = BookingEntity(
        bookingId: 'RH-849204',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Changan Alsvin Lumiere',
        packageType: '24h',
        pickupTime: DateTime.now(),
        returnTime: DateTime.now().add(const Duration(days: 1)),
        totalAmount: 5500,
        advanceRequired: 1500,
        remainingBalance: 4000,
      );

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: PaymentProofUploadView(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Submit Payment Proof'), findsNWidgets(2));
      expect(find.text('Changan Alsvin Lumiere'), findsOneWidget);
      expect(find.text('Rs. 1,500'), findsOneWidget);
      expect(find.text('Transaction Reference / TID'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'JAZZ-902189');
      await tester.pumpAndSettle();

      expect(find.text('JAZZ-902189'), findsOneWidget);
    });

    testWidgets('PickupCountdownPassView: renders live countdown timer and digital QR pass', (tester) async {
      final booking = BookingEntity(
        bookingId: 'RH-849203',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Hyundai Sonata 2.5',
        vehiclePlate: 'LE-21-999',
        shopName: 'Prime Motors Lahore',
        packageType: '24h',
        pickupTime: DateTime.now().add(const Duration(hours: 5)),
        returnTime: DateTime.now().add(const Duration(days: 2)),
        totalAmount: 24000,
        advanceRequired: 6000,
        remainingBalance: 18000,
        status: 'paid',
      );

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: PickupCountdownPassView(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pickup Countdown Pass'), findsOneWidget);
      expect(find.text('COUNTDOWN TO PICKUP'), findsOneWidget);
      expect(find.text('Hyundai Sonata 2.5'), findsOneWidget);
      expect(find.text('RH-849203'), findsOneWidget);
      expect(find.text('Showroom Handover Point'), findsOneWidget);
    });

    testWidgets('ShopCarsView: filters vehicle fleet by category tabs', (tester) async {
      // B3: real VehicleEntity fleet — two sedans and one SUV.
      const vehicles = [
        VehicleEntity(
          vehicleId: 'veh-civic',
          shopId: 'shop-1',
          make: 'Honda',
          model: 'Civic',
          year: 2021,
          plateNumber: 'LEA-4820',
          category: 'Sedan',
          rates: VehicleRatesEntity(daily24: 9000),
        ),
        VehicleEntity(
          vehicleId: 'veh-corolla',
          shopId: 'shop-1',
          make: 'Toyota',
          model: 'Corolla',
          year: 2022,
          plateNumber: 'LEB-1130',
          category: 'Sedan',
          rates: VehicleRatesEntity(daily24: 8000),
        ),
        VehicleEntity(
          vehicleId: 'veh-sportage',
          shopId: 'shop-1',
          make: 'Kia',
          model: 'Sportage',
          year: 2023,
          plateNumber: 'LEC-7710',
          category: 'SUV',
          rates: VehicleRatesEntity(daily24: 15000),
        ),
      ];
      // Tall surface: the fleet list is a lazy ListView, so all three
      // cards must fit in the viewport to be found.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: ShopCarsView(
            shopId: 'shop-1',
            shopName: 'Lahore Luxury Motors',
            vehicles: vehicles,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Available Fleet'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Sedan'), findsOneWidget);
      expect(find.text('SUV'), findsOneWidget);
      expect(find.textContaining('Civic'), findsOneWidget);
      expect(find.textContaining('Sportage'), findsOneWidget);

      await tester.tap(find.text('Sedan'));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.textContaining('Civic'), findsOneWidget);
      expect(find.textContaining('Corolla'), findsOneWidget);
      expect(find.textContaining('Sportage'), findsNothing);

      await tester.tap(find.text('SUV'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Civic'), findsNothing);
      expect(find.textContaining('Sportage'), findsOneWidget);
    });

    // E3: the dedicated active-trip view shows the live trip from the
    // booking (return countdown for an active trip) and says plainly
    // that the handover record is not there yet.
    testWidgets('CustomerActiveTripView: shows return countdown and handover placeholder', (tester) async {
      final booking = BookingEntity(
        bookingId: 'RH-849204',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Toyota Corolla',
        vehiclePlate: 'LEB-1130',
        shopName: 'Prime Motors Lahore',
        packageType: '24h',
        pickupTime: DateTime.now().subtract(const Duration(hours: 2)),
        returnTime: DateTime.now().add(const Duration(hours: 5)),
        totalAmount: 8000,
        advanceRequired: 2000,
        remainingBalance: 6000,
        status: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerActiveTripView(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Trip'), findsOneWidget);
      expect(find.text('Toyota Corolla'), findsOneWidget);
      expect(find.text('TIME UNTIL RETURN'), findsOneWidget);
      expect(find.textContaining('odometer and fuel level'), findsOneWidget);
    });
  });
}
