import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/admin_guard.dart';
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_logs_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shop_accreditation_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_blacklist_tribunal_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_subscriptions_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_settings_view.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Batch 5: Super Admin Security & Tribunal Reversal Logic', () {
    test(
        'AdminGuard: verifies only superadmin@rentalhub.pk with super_admin role',
        () {
      expect(
        AdminGuard.verifySuperAdmin(
            email: 'superadmin@rentalhub.pk', role: 'super_admin'),
        isTrue,
      );
      expect(
        AdminGuard.verifySuperAdmin(email: 'owner@rentalhub.pk', role: 'owner'),
        isFalse,
      );
      expect(
        AdminGuard.verifySuperAdmin(
            email: 'hacker@test.com', role: 'super_admin'),
        isFalse,
      );
      expect(
        AdminGuard.verifySuperAdmin(email: null, role: null),
        isFalse,
      );
    });

    test(
        'Blacklist Tribunal Reversal: requires non-empty justification and clears CNIC from active list',
        () async {
      final ds = di.sl<BlacklistRemoteDataSource>();
      final item = await ds.reportCustomerToBlacklist(
        reportedByShopId: 'shop-test',
        cnicNumber: '35201-7777777-1',
        phoneNumber: '0300-7777777',
        reasonCategory: 'Court Order Cleared',
        description: 'Under review',
      );

      expect(await ds.isCnicBlacklisted('35201-7777777-1'), isTrue);

      // Empty justification must throw ArgumentError
      expect(
        () => ds.revertBlacklistRecord(
          blacklistId: item.blacklistId,
          adminUid: 'super_admin_master',
          justification: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Valid justification reverses the record
      final reverted = await ds.revertBlacklistRecord(
        blacklistId: item.blacklistId,
        adminUid: 'super_admin_master',
        justification:
            'Court acquitted hirer with formal police clearance cert #9921',
      );

      expect(reverted.isActive, isFalse);
      expect(reverted.revertedReason, contains('Court acquitted'));
      expect(await ds.isCnicBlacklisted('35201-7777777-1'), isFalse);
    });
  });

  group('Batch 5: Owner Executive Views UI Tests', () {
    testWidgets('OwnerDashboardView: renders revenue telemetry and trip ledger',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OwnerDashboardView(shopId: 'shop-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Showroom Revenue & Operations'), findsOneWidget);
      expect(find.text('Gross Revenue (This Month)'), findsOneWidget);
      expect(find.text('Completed Trip Ledger & Settlements'), findsOneWidget);
    });

    testWidgets('OwnerSubscriptionView: renders tiers and opens upgrade dialog',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OwnerSubscriptionView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Showroom Membership Plans'), findsOneWidget);
      expect(find.text('Starter Freemium'), findsOneWidget);
      expect(find.text('Pro Showroom'), findsOneWidget);

      await tester.ensureVisible(find.text('Upgrade to Pro Showroom'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upgrade to Pro Showroom'));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(find.text('Submit Upgrade Verification'), findsOneWidget);
    });

    testWidgets('OwnerWhatsAppLogsView: renders log tiles and filters',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OwnerWhatsAppLogsView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('WhatsApp Alert Dispatches'), findsOneWidget);
      expect(find.text('Muhammad Hamza'), findsOneWidget);
      expect(find.text('Delivered'), findsWidgets);
    });
  });

  group('Batch 5: Super Admin 1440px Web Panel UI Tests', () {
    testWidgets('AdminDashboardView: renders 1440px layout, sidebar and KPIs',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdminDashboardView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('RENTALHUB'), findsOneWidget);
      expect(find.text('SUPER ADMIN 1440'), findsOneWidget);
      expect(find.text('Active Rentals On Road'), findsOneWidget);
      expect(find.text('Accredited Showrooms'), findsOneWidget);
      expect(find.text('National Blacklist Flags'), findsOneWidget);
    });

    testWidgets(
        'AdminShopAccreditationView: displays queue and accredits showroom',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdminShopAccreditationView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Showroom Accreditation Queue'), findsOneWidget);
      expect(find.text('Khyber Car Rentals'), findsOneWidget);
      expect(find.text('Accredit'), findsWidgets);

      await tester.ensureVisible(find.text('Accredit').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accredit').first);
      await tester.pumpAndSettle();

      expect(find.text('VERIFIED'), findsWidgets);
    });

    testWidgets('AdminBlacklistTribunalView: displays cases and tribunal desk',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdminBlacklistTribunalView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('National Rental Fraud & Blacklist Tribunal'),
          findsOneWidget);
      expect(find.textContaining('BLK-'), findsWidgets);
    });

    testWidgets(
        'AdminSubscriptionsView: displays tier distribution and gateway credit top-up',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdminSubscriptionsView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscriptions & Messaging Gateway Credit'),
          findsOneWidget);
      expect(find.text('Basic Freemium'), findsOneWidget);
      expect(find.text('WhatsApp Meta Cloud API'), findsOneWidget);

      await tester.tap(find.text('Top Up').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('19200'), findsOneWidget);
    });

    testWidgets(
        'AdminSettingsView: composes system broadcast and exports ledger',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdminSettingsView()),
      );
      await tester.pumpAndSettle();

      expect(
          find.text('System Broadcasts & Financial Exports'), findsOneWidget);
      expect(find.text('Compose Platform Push Broadcast'), findsOneWidget);
      expect(find.text('Export Ledger (CSV)'), findsOneWidget);
      expect(find.text('Export Tribunal Dossier (PDF)'), findsOneWidget);

      await tester.tap(find.text('Export Ledger (CSV)'));
      await tester.pumpAndSettle();
    });
  });
}
