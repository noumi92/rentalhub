import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_package_catalog_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_packages_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_packages_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_package_catalog_panel.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  group('AdminPackageCatalogDataSource CRUD', () {
    late FakeFirebaseFirestore firestore;
    late AdminPackageCatalogDataSource ds;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      ds = AdminPackageCatalogDataSource(firestore: firestore);
    });

    test('returns default shop and WhatsApp packages when Firestore is empty',
        () async {
      final shops = await ds.getShopPackages();
      final wa = await ds.getWhatsappPackages();
      expect(shops, isNotEmpty);
      expect(wa, isNotEmpty);
    });

    test('creates, updates, and deletes a shop subscription package', () async {
      const created = AdminShopPackage(
        id: 'enterprise',
        name: 'Enterprise',
        monthlyPrice: 12000,
        yearlyPrice: 120000,
        carLimit: null,
        staffLimit: 25,
        freeMonthlyCredits: 500,
      );
      final saved =
          await ds.saveShopPackage(created, adminRole: 'super_admin');
      expect(saved, isTrue);

      final afterCreate = await ds.getShopPackages();
      expect(afterCreate.any((p) => p.id == 'enterprise'), isTrue);

      const updated = AdminShopPackage(
        id: 'enterprise',
        name: 'Enterprise Plus',
        monthlyPrice: 15000,
        yearlyPrice: 150000,
        carLimit: 100,
        staffLimit: 30,
        freeMonthlyCredits: 1000,
        isActive: false,
      );
      expect(
        await ds.saveShopPackage(updated, adminRole: 'super_admin'),
        isTrue,
      );
      final afterUpdate = await ds.getShopPackages();
      final found = afterUpdate.firstWhere((p) => p.id == 'enterprise');
      expect(found.name, 'Enterprise Plus');
      expect(found.monthlyPrice, 15000);
      expect(found.isActive, isFalse);

      expect(
        await ds.deleteShopPackage('enterprise', adminRole: 'super_admin'),
        isTrue,
      );
      final afterDelete = await ds.getShopPackages();
      expect(afterDelete.any((p) => p.id == 'enterprise'), isFalse);
    });

    test('creates, updates, and deletes a WhatsApp credit package', () async {
      const created = AdminWhatsappPackage(
        id: 'mega_2000',
        name: 'Mega 2000',
        credits: 2000,
        price: 1500,
        bestValue: true,
      );
      expect(
        await ds.saveWhatsappPackage(created, adminRole: 'super_admin'),
        isTrue,
      );
      final afterCreate = await ds.getWhatsappPackages();
      final found = afterCreate.firstWhere((p) => p.id == 'mega_2000');
      expect(found.credits, 2000);
      expect(found.bestValue, isTrue);
      expect(found.perMessage, '0.75');

      expect(
        await ds.deleteWhatsappPackage('mega_2000', adminRole: 'super_admin'),
        isTrue,
      );
      final afterDelete = await ds.getWhatsappPackages();
      expect(afterDelete.any((p) => p.id == 'mega_2000'), isFalse);
    });

    test('denies package mutations for read-only support role', () async {
      const pkg = AdminShopPackage(
        id: 'blocked',
        name: 'Blocked',
        monthlyPrice: 1000,
        yearlyPrice: 10000,
        staffLimit: 2,
      );
      expect(await ds.saveShopPackage(pkg, adminRole: 'support'), isFalse);
      expect(
        await ds.deleteShopPackage('free', adminRole: 'support'),
        isFalse,
      );
    });
  });

  group('AdminPackageCatalogPanel widget', () {
    testWidgets('renders shop & WhatsApp packages and creates a new shop pack',
        (tester) async {
      final firestore = FakeFirebaseFirestore();
      final catalogDs = AdminPackageCatalogDataSource(firestore: firestore);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AdminPackageCatalogPanel(
              canManage: true,
              adminRole: 'super_admin',
              dataSource: catalogDs,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shop Subscription Packages'), findsOneWidget);
      expect(find.text('WhatsApp Credit Packages'), findsOneWidget);
      expect(find.byKey(const ValueKey('admin_create_shop_package_btn')),
          findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('admin_create_shop_package_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Create Shop Package'), findsWidgets);
      await tester.enterText(
          find.byKey(const ValueKey('shop_pkg_name')), 'Platinum');
      await tester.enterText(
          find.byKey(const ValueKey('shop_pkg_monthly')), '9000');
      await tester.enterText(
          find.byKey(const ValueKey('shop_pkg_yearly')), '90000');
      await tester.tap(find.byKey(const ValueKey('shop_pkg_save')));
      await tester.pumpAndSettle();

      expect(find.text('Platinum'), findsOneWidget);
    });

    testWidgets('AdminPackagesView renders catalog tab', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final packagesDs = AdminPackagesDataSource(firestore: firestore);
      final catalogDs = AdminPackageCatalogDataSource(firestore: firestore);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminPackagesView(
            initialTab: 'catalog',
            dataSource: packagesDs,
            catalogDataSource: catalogDs,
            adminRole: 'super_admin',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Packages'), findsOneWidget);
      expect(find.text('Shop Subscription Packages'), findsOneWidget);
    });
  });
}
