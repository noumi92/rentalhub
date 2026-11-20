import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/data/offline_sync_queue.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/data/repositories/platform_settings_repository.dart';
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/utils/unverified_shop_gate.dart';
import 'package:rentalhub/features/finance/data/services/booking_ledger_service.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/notifications/data/datasources/notification_data_source.dart';
import 'package:rentalhub/features/owner/presentation/services/walk_in_booking_service.dart';
import 'package:rentalhub/features/owner/presentation/widgets/guarantor_picker.dart';

// Step-4 save with Firestore present (the phone configuration).
// Kept in its own file on purpose: mixing FakeFirebaseFirestore
// with the real cloud_firestore plugin in one test process breaks
// FieldValue.serverTimestamp() once the real platform is
// registered by a widget test, so this runs in a separate process.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'rentalhub_locked_role': 'owner'});
    await di.initDependencies();
  });

  const testVehicle = VehicleEntity(
    vehicleId: 'veh-walkin-1',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    plateNumber: 'LEA-1000',
    rates: VehicleRatesEntity(
      hourly1: 1500,
      hourly3: 3500,
      hourly6: 6000,
      daily24: 6000,
      outOfCityDaily: 7500,
    ),
    weeklyRate: 36000,
    securityDepositPkr: 20000,
    advanceRequiredPkr: 3000,
    extraHourPkr: 600,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    packages: [
      VehiclePackageEntity(
          label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
      VehiclePackageEntity(
          label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80),
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 6000, kmIncluded: 250),
    ],
  );

  group('step 4 save with Firestore present (phone configuration)', () {
    test('createWalkInBooking completes and the booking reads back',
        () async {
      final fake = FakeFirebaseFirestore();
      final queue = di.sl<OfflineSyncQueue>();
      final ds = BookingRemoteDataSource(
        firestore: fake,
        notifications: di.sl<NotificationDataSource>(),
        blacklist: BlacklistRemoteDataSource(firestore: fake),
        unverifiedShopGate: UnverifiedShopBookingGate(
            settings: di.sl<PlatformSettingsRepository>()),
        syncQueue: queue,
        ledgerService: di.sl<BookingLedgerService>(),
      );
      if (di.sl.isRegistered<BookingRemoteDataSource>()) {
        di.sl.unregister<BookingRemoteDataSource>();
      }
      di.sl.registerSingleton<BookingRemoteDataSource>(ds);

      final pkg24 =
          testVehicle.packages.firstWhere((p) => p.label == '24h');
      final booking = await WalkInBookingService.createWalkInBooking(
        name: 'Ahmed Khan',
        phone: '03001234567',
        cnic: '35202-1234567-1',
        guarantor: const GuarantorSelection(
            name: 'Bilal Ahmed',
            cnic: '35202-1234567-2',
            phone: '03007654321',
            relationship: 'Brother'),
        vehicle: testVehicle,
        package: pkg24,
        isWithDriver: true,
        rentAmount: 6500,
        advanceRequired: 3000,
        pickupTime: DateTime(2026, 11, 20, 10),
        returnTime: DateTime(2026, 11, 21, 10),
        tripType: 'in_city',
        advanceReceived: 3000,
        customerId: 'cust-reg-1',
        depositAmountPkr: 20000,
        discountAmountPkr: 1000,
        paymentMethod: 'cash',
        depositMethod: 'cash',
      );
      expect(booking.customerId, 'cust-reg-1');
      expect(booking.status, 'paid');

      final reloaded = await ds.getBookingById(booking.bookingId);
      expect(reloaded, isNotNull);
      expect(reloaded!.depositAmountPkr, 20000);
      expect(reloaded.advancePaid, 3000);
      final snap =
          await fake.collection('bookings').doc(booking.bookingId).get();
      expect(snap.exists, isTrue);
    });
  });
}
