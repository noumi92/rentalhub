import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_cars_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shop_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shops_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/shop_application_detail_sheet.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

ShopModel _shop({
  String name = 'Metro Car Rentals',
  String city = 'Lahore',
  String address = 'Main Boulevard',
  String phone = '03001234567',
  String? ownerName = 'Ahmed Raza',
  String? cnic = '35202-1234567-1',
  Map<String, dynamic> kyc = const {},
  List<Map<String, dynamic>> bankAccounts = const [],
  List<String> photos = const [],
}) {
  return ShopModel(
    shopId: 'shop-1',
    ownerId: 'owner-1',
    shopName: name,
    phoneNumber: phone,
    address: address,
    city: city,
    geoLocation: const GeoPointEntity(31.5204, 74.3587),
    bankAccounts: bankAccounts,
    kycDocuments: kyc,
    fleetPhotos: photos,
    ownerName: ownerName,
    cnicNumber: cnic,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Phase B (B1) — approvals checklist', () {
    test('a complete shop scores 6 of 6', () {
      final checklist = ShopApplicationChecklist.fromShop(_shop(
        kyc: {'cnic_front': 'key-1'},
        bankAccounts: [
          {'type': 'jazzcash', 'account': '03001234567'}
        ],
        photos: ['https://example.com/car.jpg'],
      ));
      expect(checklist.doneCount, 6);
      expect(checklist.items.length, 6);
    });

    test('an empty shop scores 0 of 6', () {
      final checklist = ShopApplicationChecklist.fromShop(_shop(
        name: '',
        address: '',
        phone: '',
        ownerName: null,
        cnic: null,
      ));
      expect(checklist.doneCount, 0);
    });
  });

  group('Phase B — shops data layer (offline)', () {
    test('lists are empty and decisions fail honestly offline', () async {
      final ds = AdminShopsDataSource();
      expect(await ds.getPendingShops(), isEmpty);
      expect(await ds.getShops(), isEmpty);
      expect(await ds.getCars(), isEmpty);
      expect(await ds.getShop('shop-1'), isNull);
      expect(
        await ds.decideShopApplication(shopId: 'shop-1', decision: 'approved'),
        isFalse,
      );
      expect(
        await ds.setShopSuspended(
            shopId: 'shop-1', suspended: true, reason: 'test'),
        isFalse,
      );
      expect(
        await ds.setCarReview(
            vehicleId: 'car-1', status: 'approved', reason: ''),
        isFalse,
      );
      expect(await ds.getCarReview('car-1'), isNull);
      expect(await ds.getCarReviews(), isEmpty);
    });

    test('car review parses from a Firestore map', () {
      final review = CarReview.fromMap('car-1', {
        'status': 'hidden',
        'reason': 'Photos do not match the car.',
      });
      expect(review.vehicleId, 'car-1');
      expect(review.status, 'hidden');
      expect(review.reason, 'Photos do not match the car.');
    });
  });

  group('Phase B — views render', () {
    testWidgets('approvals is a filter on the shops list, not a screen',
        (tester) async {
      // Phase 3 (3.1): the Approvals screen is deleted — pending
      // is a filter on the shops list, and the decision lives on
      // the shop detail route.
      await tester.pumpWidget(const MaterialApp(
          home: AdminShopsView(initialFilter: 'pending')));
      await tester.pumpAndSettle();
      expect(find.text('Shop Approvals'), findsNothing);
      expect(find.text('Approvals'), findsNothing);
      expect(find.textContaining('No shops match'), findsOneWidget);
    });

    testWidgets('shops list shows search and status filters',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AdminShopsView()));
      await tester.pumpAndSettle();
      expect(find.text('Shops & Fleet'), findsWidgets);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Suspended'), findsWidgets);
      expect(find.textContaining('No shops match'), findsOneWidget);
    });

    testWidgets('shop detail says not found for an unknown shop',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: AdminShopDetailView(shopId: 'no-such-shop')));
      await tester.pumpAndSettle();
      expect(find.text('Shop not found.'), findsOneWidget);
    });

    testWidgets('cars list shows search and review filters',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminCarsView()));
      await tester.pumpAndSettle();
      // Phase 2 (2.3): at the default 800dp test width the shell is
      // the desktop shell, so 'Cars' is both the sidebar item and the
      // header title.
      expect(find.text('Cars'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.textContaining('No cars match'), findsOneWidget);
    });

    testWidgets('application sheet shows the checklist and decisions',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShopApplicationDetailSheet(
            shop: _shop(),
            onDecided: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Metro Car Rentals'), findsOneWidget);
      expect(find.textContaining('Checklist — 3 of 6 complete'),
          findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Ask for more info'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Call owner'), findsOneWidget);
    });
  });
}
