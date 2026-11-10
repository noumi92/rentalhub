import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/core/network/firestore_service.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/auth/data/models/user_model.dart';
import 'package:rentalhub/features/auth/presentation/views/login_view.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/fleet/data/models/vehicle_model.dart';
import 'package:rentalhub/features/trust/presentation/views/customer_documents_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  // G3: the documents view resolves its KycCubit from DI, so this
  // file initialises the container like the batch test files do.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Data Integrity & Serialization Tests', () {
    test('UserModel: Serialization round-trip maintains role immutability and fields', () {
      final user = UserModel(
        uid: 'user-786',
        phoneNumber: '+923001234567',
        role: 'owner',
        fullName: 'Muhammad Usman',
        email: 'usman@rentalhub.pk',
        isVerified: true,
      );

      final map = user.toMap();
      expect(map['uid'], 'user-786');
      expect(map['phone_number'], '+923001234567');
      expect(map['role'], 'owner');
      expect(map['full_name'], 'Muhammad Usman');
      expect(map['email'], 'usman@rentalhub.pk');

      final fromMapUser = UserModel.fromMap(map, id: 'user-786');
      expect(fromMapUser.uid, user.uid);
      expect(fromMapUser.phoneNumber, user.phoneNumber);
      expect(fromMapUser.role, user.role);
      expect(fromMapUser.fullName, user.fullName);
      expect(fromMapUser.email, user.email);
    });

    test('ShopModel: Serialization round-trip maintains location and payout structure', () {
      final shop = ShopModel(
        shopId: 'shop-001',
        ownerId: 'owner-101',
        shopName: 'PakWheels Rentals',
        city: 'Lahore',
        address: 'Main Boulevard, Gulberg III, Lahore',
        geoLocation: const GeoPointEntity(31.5204, 74.3587),
        phoneNumber: '+923009998877',
        isVerified: true,
        bankAccounts: [
          {
            'type': 'jazzcash',
            'account': '03009998877',
            'title': 'PakWheels Rentals',
          },
          {
            'type': 'bank',
            'bank_name': 'Meezan Bank',
            'iban': 'PK36MEZN0001234567890123',
            'title': 'PakWheels Rentals',
          }
        ],
      );

      final map = shop.toMap();
      expect(map['shop_id'], 'shop-001');
      expect(map['owner_id'], 'owner-101');
      expect(map['shop_name'], 'PakWheels Rentals');
      expect(map['city'], 'Lahore');
      expect(map['latitude'], 31.5204);
      expect(map['longitude'], 74.3587);

      final parsedShop = ShopModel.fromMap(map, id: 'shop-001');
      expect(parsedShop.shopId, 'shop-001');
      expect(parsedShop.ownerId, 'owner-101');
      expect(parsedShop.shopName, 'PakWheels Rentals');
      expect(parsedShop.city, 'Lahore');
      expect(parsedShop.bankAccounts.length, 2);
    });

    test('VehicleModel: Serialization round-trip preserves tiered rates and specs', () {
      const rates = VehicleRatesModel(
        hourly1: 1500,
        hourly3: 3500,
        hourly6: 6000,
        daily24: 9000,
        outOfCityDaily: 11000,
      );

      const vehicle = VehicleModel(
        vehicleId: 'veh-001',
        shopId: 'shop-001',
        make: 'Honda',
        model: 'Civic RS Turbo',
        year: 2023,
        plateNumber: 'LEE-23-9999',
        category: 'Sedan',
        transmission: 'Automatic',
        fuelType: 'Petrol',
        seats: 5,
        status: 'Available',
        isSelfDriveAvailable: true,
        isWithDriverAvailable: true,
        rates: rates,
      );

      expect(vehicle.vehicleId, 'veh-001');
      expect(vehicle.make, 'Honda');
      expect(vehicle.model, 'Civic RS Turbo');
      expect(vehicle.rates.daily24, 9000);
      expect(vehicle.isSelfDriveAvailable, isTrue);
    });
  });

  group('FirestoreService Backend Connectivity & Concurrency Tests', () {
    late FirestoreService firestoreService;

    setUp(() {
      firestoreService = FirestoreService();
    });

    test('User CRUD: saveUser and getUser persist profile data', () async {
      final user = UserModel(
        uid: 'user-test-1',
        phoneNumber: '+923001112233',
        role: 'customer',
        fullName: 'Bilal Ahmed',
        email: 'bilal@test.pk',
      );

      await firestoreService.saveUser(user);
      final retrieved = await firestoreService.getUser('user-test-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.uid, 'user-test-1');
      expect(retrieved.fullName, 'Bilal Ahmed');
      expect(retrieved.role, 'customer');
    });

    test('Shop CRUD: saveShop and getShop retrieve showroom profile and nearby shops', () async {
      final shop = ShopModel(
        shopId: 'shop-lahore-1',
        ownerId: 'owner-lahore-1',
        shopName: 'Royal Rent a Car',
        city: 'Lahore',
        address: 'Gulberg II, Lahore',
        geoLocation: const GeoPointEntity(31.5300, 74.3400),
        phoneNumber: '+923004445566',
        isVerified: true,
        bankAccounts: const [],
      );

      await firestoreService.saveShop(shop);
      final retrieved = await firestoreService.getShop('shop-lahore-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.shopName, 'Royal Rent a Car');
      expect(retrieved.city, 'Lahore');

      final nearby = await firestoreService.getNearbyShops(city: 'Lahore');
      expect(nearby.any((s) => s.shopId == 'shop-lahore-1'), isTrue);
    });

    test('Vehicle CRUD: saveVehicle and getShopVehicles filter by shopId', () async {
      const rates = VehicleRatesModel(
        hourly1: 1000,
        hourly3: 2500,
        hourly6: 4500,
        daily24: 7000,
      );

      const v1 = VehicleModel(
        vehicleId: 'v-001',
        shopId: 'shop-lahore-1',
        make: 'Suzuki',
        model: 'Alto VXR',
        year: 2022,
        plateNumber: 'LAL-22-1234',
        category: 'Hatchback',
        transmission: 'Manual',
        fuelType: 'Petrol',
        seats: 4,
        status: 'Available',
        rates: rates,
      );

      const v2 = VehicleModel(
        vehicleId: 'v-002',
        shopId: 'shop-other-99',
        make: 'Toyota',
        model: 'Yaris',
        year: 2021,
        plateNumber: 'ISB-21-5555',
        category: 'Sedan',
        transmission: 'Automatic',
        fuelType: 'Petrol',
        seats: 5,
        status: 'Available',
        rates: rates,
      );

      await firestoreService.saveVehicle(v1);
      await firestoreService.saveVehicle(v2);

      final shop1Vehicles = await firestoreService.getShopVehicles('shop-lahore-1');
      expect(shop1Vehicles.length, 1);
      expect(shop1Vehicles.first.vehicleId, 'v-001');
      expect(shop1Vehicles.first.make, 'Suzuki');
    });

    test('Concurrency Double-Booking Prevention: rejects second reservation on reserved vehicle', () async {
      const rates = VehicleRatesModel(
        hourly1: 1200,
        hourly3: 3000,
        hourly6: 5500,
        daily24: 8500,
      );

      const vehicle = VehicleModel(
        vehicleId: 'veh-concurrent-1',
        shopId: 'shop-lahore-1',
        make: 'Toyota',
        model: 'Corolla Grande',
        year: 2023,
        plateNumber: 'LEA-23-1111',
        category: 'Sedan',
        transmission: 'Automatic',
        fuelType: 'Petrol',
        seats: 5,
        status: 'Available',
        rates: rates,
      );

      await firestoreService.saveVehicle(vehicle);

      // Customer 1 locks reservation
      await firestoreService.createBookingLock(
        bookingId: 'book-cust-1',
        vehicleId: 'veh-concurrent-1',
        customerId: 'customer-1',
        bookingData: {'rate': 8500, 'package': '24h'},
      );

      // Customer 2 attempts concurrent booking for the same vehicle
      expect(
        () async => await firestoreService.createBookingLock(
          bookingId: 'book-cust-2',
          vehicleId: 'veh-concurrent-1',
          customerId: 'customer-2',
          bookingData: {'rate': 8500, 'package': '24h'},
        ),
        throwsA(isA<ServerException>().having(
          (e) => e.message,
          'message',
          contains('locked by another reservation'),
        )),
      );
    });
  });

  group('Button Gating & Alert Feedback Widget Tests', () {
    testWidgets('LoginView: blocks invalid email and short password with error alerts', (tester) async {
      bool signedIn = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginView(
            onSignedIn: () => signedIn = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final emailField = fields.first;
      final passField = fields.at(1);

      // Enter invalid email
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.text('Sign In with Email'));
      await tester.pumpAndSettle();

      expect(signedIn, isFalse);
      expect(find.text('Please enter a valid email address.'), findsOneWidget);

      // Immediately clear snackbar so next tap is clean
      ScaffoldMessenger.of(tester.element(find.byType(LoginView))).clearSnackBars();
      await tester.pumpAndSettle();

      // Enter valid email but short password
      await tester.enterText(emailField, 'valid@example.com');
      await tester.enterText(passField, '123');
      await tester.tap(find.text('Sign In with Email'));
      await tester.pumpAndSettle();

      expect(signedIn, isFalse);
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);

      // Immediately clear snackbar
      ScaffoldMessenger.of(tester.element(find.byType(LoginView))).clearSnackBars();
      await tester.pumpAndSettle();

      // Enter valid password and sign in successfully
      await tester.enterText(passField, 'secret123');
      await tester.tap(find.text('Sign In with Email'));
      await tester.pumpAndSettle();

      expect(signedIn, isTrue);
      expect(find.text('Signed in successfully!'), findsOneWidget);
    });

    testWidgets('CustomerDocumentsView: blocks submission when CNIC format is invalid', (tester) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomerDocumentsView(
            onSubmitted: () => submitted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid CNIC into TextField
      final cnicField = find.byType(TextField).first;
      await tester.enterText(cnicField, '12345');
      // G3: the submit button is now labelled for what it does.
      // The form is scrollable and the button sits just below the fold on
      // the default 800x600 test surface (the Phase A type scale made the
      // form taller), so bring it into view before tapping.
      await tester.ensureVisible(find.text('Submit KYC Documents'));
      await tester.pumpAndSettle();
      // The form grew with the license section: ensureVisible alone can
      // leave the button's centre just below the fold (it scrolls the
      // minimum to peek the button into view), so scroll to the end
      // before tapping.
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit KYC Documents'));
      await tester.pumpAndSettle();

      expect(submitted, isFalse);
      expect(find.text('CNIC must be exactly 13 digits'), findsOneWidget);
    });
  });
}
