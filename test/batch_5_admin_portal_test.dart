import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/admin_guard.dart';
import 'package:rentalhub/features/admin/domain/admin_permissions.dart';
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_dashboard_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_logs_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shop_approvals_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_blacklist_tribunal_view.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_coming_soon_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_platform_settings_view.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Batch 5: Super Admin Security & Tribunal Reversal Logic', () {
    test(
        'AdminGuard (Phase A): the role decides, not a hardcoded email',
        () {
      // No email is special any more — the users doc admin_role is
      // the gate, and any super_admin passes regardless of address.
      expect(AdminGuard.isAdminRole('super_admin'), isTrue);
      expect(AdminGuard.isAdminRole('operations'), isTrue);
      expect(AdminGuard.isAdminRole('support'), isTrue);
      expect(AdminGuard.isAdminRole('owner'), isFalse);
      expect(AdminGuard.isAdminRole(null), isFalse);
      expect(AdminGuard.isSuperAdmin('super_admin'), isTrue);
      expect(AdminGuard.isSuperAdmin('operations'), isFalse);
      expect(
        AdminGuard.can('support', AdminPermission.decideVendor),
        isFalse,
      );
      expect(
        AdminGuard.can('super_admin', AdminPermission.manageTeam),
        isTrue,
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
      expect(find.text('ADMIN PANEL'), findsOneWidget);
      expect(find.text('Registered shops'), findsOneWidget);
      expect(find.text('Active bookings'), findsOneWidget);
      expect(find.text('Open disputes'), findsOneWidget);
      expect(find.text('Open support tickets'), findsOneWidget);
    });

    testWidgets(
        'Phase B (B1): approvals queue shows its honest empty state',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdminShopApprovalsView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shop Approvals'), findsOneWidget);
      expect(find.textContaining('No pending applications'),
          findsOneWidget);
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
        'Phase F (gated): subscriptions route shows the honest placeholder',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminComingSoonView(
            activeRoute: RouteNames.adminSubscriptions,
            title: 'Subscriptions',
            subtitle: 'Plans and WhatsApp credits',
            body: 'Subscriptions arrive in Phase F, gated on the Play Console setup (plan D1).',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscriptions'), findsWidgets);
      expect(find.textContaining('Phase F'), findsOneWidget);
    });

    testWidgets(
        'Phase E (E2): platform settings view shows the defaults',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AdminPlatformSettingsView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cities & settings'), findsOneWidget);
      expect(find.text('Save settings'), findsOneWidget);
      expect(find.text('Maintenance mode'), findsOneWidget);
    });
  });
}
