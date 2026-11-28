import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_platform_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_bookings_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_cars_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shop_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_scoped_list_banner.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sort_menu.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

VehicleEntity _car(String id, String shopId) => VehicleEntity(
      vehicleId: id,
      shopId: shopId,
      make: shopId == 'shop-1' ? 'Honda' : 'Toyota',
      model: shopId == 'shop-1' ? 'Civic' : 'Corolla',
      year: 2022,
      plateNumber: 'LEA-22-$id',
      rates: const VehicleRatesEntity(daily24: 5000),
    );

BookingModel _booking(
  String id,
  String shopId, {
  String status = 'paid',
  DateTime? pickup,
  String? vehicleName,
}) =>
    BookingModel(
      bookingId: id,
      customerId: 'cust-1',
      shopId: shopId,
      vehicleId: 'veh-1',
      packageType: 'daily',
      pickupTime: pickup ?? DateTime(2026, 11, 20),
      returnTime: (pickup ?? DateTime(2026, 11, 20))
          .add(const Duration(days: 1)),
      totalAmount: 5000,
      remainingBalance: 0,
      status: status,
      customerName: 'Ahmed Raza',
      vehicleName: vehicleName ??
          (shopId == 'shop-1' ? 'Civic One' : 'City Two'),
      shopName: shopId == 'shop-1' ? 'Metro Car Rentals' : 'Other Shop',
    );

ShopModel _shop() => ShopModel(
      shopId: 'shop-1',
      ownerId: 'owner-1',
      shopName: 'Metro Car Rentals',
      phoneNumber: '03001234567',
      address: 'Main Boulevard',
      city: 'Lahore',
      geoLocation: const GeoPointEntity(31.5204, 74.3587),
      bankAccounts: const [],
      kycDocuments: const {},
      fleetPhotos: const [],
      ownerName: 'Ahmed Raza',
      cnicNumber: '35202-1234567-1',
    );

class _FakeShopsDataSource extends AdminShopsDataSource {
  @override
  Future<ShopModel?> getShop(String shopId) async =>
      shopId == 'shop-1' ? _shop() : null;

  @override
  Future<int> getShopVehicleCount(String shopId) async => 1;

  @override
  Future<int> getShopBookingCount(String shopId) async => 1;

  @override
  Future<int?> getShopCreditsBalance(String shopId) async => 10;

  @override
  Future<List<VehicleEntity>> getCars() async =>
      [_car('v-1', 'shop-1'), _car('v-2', 'shop-2')];

  @override
  Future<Map<String, CarReview>> getCarReviews() async => {};
}

class _FakePlatformDataSource extends AdminPlatformDataSource {
  @override
  Future<List<BookingModel>> getBookings({String status = 'all'}) async => [
        _booking('b-1', 'shop-1'),
        _booking('b-2', 'shop-2'),
      ];
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    sl.unregister<AdminShopsDataSource>();
    sl.registerSingleton<AdminShopsDataSource>(_FakeShopsDataSource());
    sl.unregister<AdminPlatformDataSource>();
    sl.registerSingleton<AdminPlatformDataSource>(_FakePlatformDataSource());
  });

  group('Step 2 — scoped-list helpers', () {
    test('scopedCars keeps only the shop cars, null keeps all', () {
      final cars = [_car('v-1', 'shop-1'), _car('v-2', 'shop-2')];
      expect(
          scopedCars(cars, 'shop-1').map((v) => v.vehicleId), ['v-1']);
      expect(scopedCars(cars, null).length, 2);
    });

    test('loadShopBookings cuts to one shop', () async {
      final shop1 = await loadShopBookings(_FakePlatformDataSource(), 'shop-1');
      expect(shop1.map((b) => b.bookingId), ['b-1']);
    });

    test('scopedBookings filters by status and search, then sorts', () {
      final bookings = [
        _booking('b-1', 'shop-1',
            status: 'paid', pickup: DateTime(2026, 11, 20)),
        _booking('b-2', 'shop-1',
            status: 'requested',
            pickup: DateTime(2026, 11, 21),
            vehicleName: 'City Two'),
        _booking('b-3', 'shop-2',
            status: 'paid', pickup: DateTime(2026, 11, 22)),
      ];
      // scopedBookings takes the already shop-cut list (what
      // loadShopBookings returns) and applies status/search/sort.
      final base = bookings.where((b) => b.shopId == 'shop-1').toList();
      final scoped =
          scopedBookings(base, 'all', '', AdminListSort.dateNewest);
      expect(scoped.map((b) => b.bookingId), ['b-2', 'b-1']);
      final paid =
          scopedBookings(base, 'paid', '', AdminListSort.dateNewest);
      expect(paid.map((b) => b.bookingId), ['b-1']);
      final found = scopedBookings(
          base, 'all', 'civic', AdminListSort.dateNewest);
      expect(found.map((b) => b.bookingId), ['b-1']);
    });
  });

  group('Step 2 — shop detail entry points', () {
    testWidgets('detail shows cars entry button and hides booking details link',
        (tester) async {
      await _pump(tester, const AdminShopDetailView(shopId: 'shop-1'));
      expect(find.text('Metro Car Rentals'), findsOneWidget);
      expect(find.byKey(const Key('admin2_shopDetailViewCars')),
          findsOneWidget);
      expect(find.text("View this shop's cars"), findsOneWidget);
      expect(find.byKey(const Key('admin2_shopDetailViewBookings')),
          findsNothing);
    });
  });

  group('Step 2 — scoped Cars list', () {
    testWidgets('scoped list shows only the shop cars plus the note',
        (tester) async {
      await _pump(tester, const AdminCarsView(shopId: 'shop-1'));
      expect(find.text('Showing only this shop'), findsOneWidget);
      expect(find.text('Honda Civic (2022)'), findsOneWidget);
      expect(find.text('Toyota Corolla (2022)'), findsNothing);
    });

    testWidgets('global list shows all cars and no note', (tester) async {
      await _pump(tester, const AdminCarsView());
      expect(find.text('Showing only this shop'), findsNothing);
      expect(find.text('Honda Civic (2022)'), findsOneWidget);
      expect(find.text('Toyota Corolla (2022)'), findsOneWidget);
    });
  });

  group('Step 2 — scoped Bookings list', () {
    testWidgets('scoped list shows only the shop bookings plus the note',
        (tester) async {
      await _pump(tester, const AdminBookingsView(shopId: 'shop-1'));
      expect(find.text('Showing only this shop'), findsOneWidget);
      expect(find.textContaining('b-1'), findsOneWidget);
      expect(find.textContaining('b-2'), findsNothing);
    });

    testWidgets('global list shows all bookings and no note',
        (tester) async {
      await _pump(tester, const AdminBookingsView());
      expect(find.text('Showing only this shop'), findsNothing);
      expect(find.textContaining('b-1'), findsOneWidget);
      expect(find.textContaining('b-2'), findsOneWidget);
    });
  });
}
