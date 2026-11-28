import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_packages_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_packages_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_section_tabs.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sub_tab_bar.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  group('Online vs. Walk-in Customer Separation', () {
    test('isWalkInCustomerDoc accurately distinguishes walk-in vs online docs', () {
      expect(
        AdminPeopleDataSource.isWalkInCustomerDoc('walkin-123', {'name': 'Ali'}),
        isTrue,
      );
      expect(
        AdminPeopleDataSource.isWalkInCustomerDoc('c-1', {'shopId': 'shop-9'}),
        isTrue,
      );
      expect(
        AdminPeopleDataSource.isWalkInCustomerDoc('c-2', {'shop_id': 'shop-9'}),
        isTrue,
      );
      expect(
        AdminPeopleDataSource.isWalkInCustomerDoc('c-3', {'origin': 'walk_in'}),
        isTrue,
      );
      expect(
        AdminPeopleDataSource.isWalkInCustomerDoc('uid-online-1', {
          'name': 'Bilal Ahmed',
          'phone': '03001234567',
        }),
        isFalse,
      );
    });

    test('getCustomersPage excludes walk-in customers while KPI counters separate both', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('customers').doc('online-1').set({
        'name': 'Ayesha Khan',
        'phone': '03001111111',
        'cnic': '35202-1111111-1',
        'createdAt': '2026-11-01T10:00:00Z',
      });
      await fs.collection('customers').doc('walkin-1').set({
        'name': 'Walkin Counter',
        'phone': '03002222222',
        'shopId': 'shop-1',
        'origin': 'walk_in',
        'createdAt': '2026-11-02T10:00:00Z',
      });

      final ds = AdminPeopleDataSource(firestore: fs);
      final page = await ds.getCustomersPage(onlineOnly: true);
      expect(page.items.length, 1);
      expect(page.items.first.customer.customerId, 'online-1');
      expect(await ds.countOnlineCustomers(), 1);
      expect(await ds.countWalkInCustomers(), 1);
    });
  });

  group('Expanded PlatformStats KPIs', () {
    test('counts shops, vehicles, online/walk-in customers, bookings, and packages', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('shops').doc('s-1').set({
        'shop_name': 'Al-Falah Motors',
        'verification_status': 'verified',
        'subscription_tier': 'pro',
      });
      await fs.collection('shops').doc('s-2').set({
        'shop_name': 'City Drive',
        'verification_status': 'pending',
        'subscription_tier': 'free',
      });
      await fs.collection('vehicles').doc('v-1').set({'shop_id': 's-1'});
      await fs.collection('customers').doc('u-1').set({'name': 'Online User'});
      await fs.collection('customers').doc('walkin-1').set({
        'name': 'Counter Guest',
        'shopId': 's-1',
      });
      await fs.collection('bookings').doc('b-1').set({
        'status': 'active',
        'is_walk_in': false,
      });
      await fs.collection('bookings').doc('b-2').set({
        'status': 'completed',
        'is_walk_in': true,
      });
      await fs.collection('subscription_requests').doc('sr-1').set({
        'status': 'pending',
      });
      await fs.collection('credit_purchase_requests').doc('cr-1').set({
        'status': 'pending',
      });

      final stats = await AdminRemoteDataSource(firestore: fs).getPlatformStats();
      expect(stats.shopCount, 2);
      expect(stats.verifiedShopCount, 1);
      expect(stats.pendingShopCount, 1);
      expect(stats.paidShopCount, 1);
      expect(stats.totalVehicleCount, 1);
      expect(stats.onlineCustomerCount, 1);
      expect(stats.walkInCustomerCount, 1);
      expect(stats.onlineBookingCount, 1);
      expect(stats.walkInBookingCount, 1);
      expect(stats.pendingSubscriptionCount, 1);
      expect(stats.pendingCreditRequestCount, 1);
    });
  });

  group('AdminPackagesDataSource & AdminPackagesView', () {
    test('approving subscription request updates shop tier; credit request increments balance', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('shops').doc('s-1').set({
        'shop_name': 'Al-Falah Motors',
        'city': 'Lahore',
        'verification_status': 'verified',
        'subscription_tier': 'free',
      });
      await fs.collection('subscription_requests').doc('req-1').set({
        'shop_id': 's-1',
        'shop_name': 'Al-Falah Motors',
        'tier': 'pro',
        'amount': 4500,
        'trx_id': 'TRX-123',
        'status': 'pending',
      });
      await fs.collection('credit_purchase_requests').doc('cr-1').set({
        'shop_id': 's-1',
        'shop_name': 'Al-Falah Motors',
        'pack_name': 'Starter 250',
        'credits': 250,
        'amount': 1500,
        'trx_id': 'TRX-456',
        'status': 'pending',
      });

      final ds = AdminPackagesDataSource(firestore: fs);
      final subOk = await ds.decideSubscriptionRequest(
        requestId: 'req-1',
        shopId: 's-1',
        tier: 'pro',
        approve: true,
        adminRole: 'super_admin',
      );
      expect(subOk, isTrue);
      final shopDoc = await fs.collection('shops').doc('s-1').get();
      expect(shopDoc.data()?['subscription_tier'], 'pro');

      final crOk = await ds.decideCreditPurchaseRequest(
        requestId: 'cr-1',
        shopId: 's-1',
        packCredits: 250,
        approve: true,
        adminRole: 'super_admin',
      );
      expect(crOk, isTrue);
      final balDoc = await fs.collection('whatsapp_credits').doc('s-1').get();
      expect(balDoc.data()?['balance'], 250);
    });

    testWidgets('AdminPackagesView renders shop plans and sub-tabs cleanly', (tester) async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('shops').doc('s-1').set({
        'shop_name': 'Al-Falah Motors',
        'city': 'Lahore',
        'verification_status': 'verified',
        'subscription_tier': 'business',
      });
      final ds = AdminPackagesDataSource(firestore: fs);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminPackagesView(
            initialTab: 'plans',
            dataSource: ds,
            adminRole: 'super_admin',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Al-Falah Motors'), findsOneWidget);
      expect(find.text('BUSINESS'), findsOneWidget);
      expect(find.text('Shop Plans'), findsOneWidget);
      expect(find.text('Upgrade Requests'), findsOneWidget);
      expect(find.text('WhatsApp Packages'), findsOneWidget);
    });
  });

  group('AdminSubTabBar LTR & RTL responsiveness', () {
    testWidgets('renders at 360px in English LTR and Urdu RTL without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? tapped;
      for (final locale in const [Locale('en'), Locale('ur')]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => AdminSubTabBar(
                  tabs: AdminSectionTabs.shopsAndFleet(
                    context,
                    activeRoute: RouteNames.adminShops,
                    approvalsBadge: 4,
                    carsBadge: 2,
                  ),
                  onSelect: (r) => tapped = r,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.ensureVisible(find.byIcon(Icons.directions_car_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.directions_car_rounded));
      await tester.pumpAndSettle();
      expect(tapped, RouteNames.adminCars);
    });
  });
}
