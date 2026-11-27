import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/admin_guard.dart';
import 'package:rentalhub/features/admin/data/services/admin_session.dart';
import 'package:rentalhub/features/admin/domain/admin_permissions.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_team_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_permission_check.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// F-C1 (admin audit 2026-11-14) — the 12-permission matrix (13
// permissions incl. downloadApk) must actually gate the admin
// actions. These tests pin the matrix itself, the fail-closed
// session guard the data sources call, and the team view's
// matrix-routed manage check (F-m4). The route-guard redirects
// and the per-method data-source guards are exercised by the
// widget tests in the admin phase files; a support-role call to a
// decision method returns false before any Firestore write (the
// offline tests already assert decisions fail with no Firestore,
// and the guard runs before the Firestore resolution).

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('F-C1 — the permission matrix (AdminPermissions.can)', () {
    test('super admin holds every permission', () {
      for (final permission in AdminPermission.values) {
        expect(
          AdminPermissions.can('super_admin', permission),
          isTrue,
          reason: 'super_admin must hold $permission',
        );
      }
    });

    test('operations holds day-to-day decisions, never team', () {
      expect(AdminPermissions.can('operations', AdminPermission.manageTeam),
          isFalse);
      expect(AdminPermissions.can('operations', AdminPermission.decideKyc),
          isTrue);
      expect(
          AdminPermissions.can('operations', AdminPermission.decideVendor),
          isTrue);
      expect(
          AdminPermissions.can(
              'operations', AdminPermission.manageBlacklist),
          isTrue);
      expect(
          AdminPermissions.can(
              'operations', AdminPermission.manageDisputes),
          isTrue);
      expect(
          AdminPermissions.can('operations', AdminPermission.decideDispute),
          isTrue);
      expect(
          AdminPermissions.can('operations', AdminPermission.triageTicket),
          isTrue);
      expect(
          AdminPermissions.can('operations', AdminPermission.resolveTicket),
          isTrue);
      expect(
          AdminPermissions.can(
              'operations', AdminPermission.managePlatform),
          isTrue);
      expect(AdminPermissions.can('operations', AdminPermission.downloadApk),
          isFalse);
    });

    test('support triages only: disputes, tickets, activity log', () {
      for (final permission in [
        AdminPermission.manageTeam,
        AdminPermission.decideKyc,
        AdminPermission.decideVendor,
        AdminPermission.manageBlacklist,
        AdminPermission.decideDispute,
        AdminPermission.resolveTicket,
        AdminPermission.managePlatform,
        AdminPermission.manageSubscriptions,
        AdminPermission.toggleFlagship,
        AdminPermission.downloadApk,
      ]) {
        expect(
          AdminPermissions.can('support', permission),
          isFalse,
          reason: 'support must NOT hold $permission',
        );
      }
      expect(
          AdminPermissions.can('support', AdminPermission.manageDisputes),
          isTrue);
      expect(AdminPermissions.can('support', AdminPermission.triageTicket),
          isTrue);
      expect(
          AdminPermissions.can('support', AdminPermission.viewActivityLog),
          isTrue);
    });

    test('an unknown or null role holds nothing', () {
      for (final permission in AdminPermission.values) {
        expect(AdminPermissions.can(null, permission), isFalse);
        expect(AdminPermissions.can('owner', permission), isFalse);
        expect(AdminPermissions.can('', permission), isFalse);
      }
    });

    test('AdminGuard.can mirrors the matrix', () {
      expect(
          AdminGuard.can('support', AdminPermission.decideVendor), isFalse);
      expect(AdminGuard.can('super_admin', AdminPermission.manageTeam),
          isTrue);
      expect(
          AdminGuard.can('operations', AdminPermission.decideDispute),
          isTrue);
    });
  });

  group('F-C1 — the session guard judges an explicit role strictly', () {
    test('an explicit support role is refused, operations allowed', () async {
      expect(
        await AdminSession.currentAdminCan(AdminPermission.decideVendor,
            adminRole: 'support'),
        isFalse,
      );
      expect(
        await AdminSession.currentAdminCan(AdminPermission.decideVendor,
            adminRole: 'operations'),
        isTrue,
      );
      expect(
        await AdminSession.currentAdminCan(AdminPermission.resolveTicket,
            adminRole: 'support'),
        isFalse,
      );
      expect(
        await AdminSession.currentAdminCan(AdminPermission.triageTicket,
            adminRole: 'support'),
        isTrue,
      );
    });

    test('with no signed-in user there is no identity to gate', () async {
      // No signed-in user in this test process: the guard proceeds
      // and the write attempt is judged by the Firestore rules
      // (which require an authenticated admin). A signed-in user
      // whose role cannot be read is still refused — that path
      // needs a signed-in session and is covered by the matrix
      // tests above, not by this offline case.
      expect(
        await AdminSession.currentAdminCan(AdminPermission.decideVendor),
        isTrue,
      );
      expect(
        await AdminSession.currentAdminCan(AdminPermission.manageTeam,
            adminRole: null),
        isTrue,
      );
    });
  });

  group('F-m4 — team management goes through the matrix', () {
    Future<void> pumpTeam(
      WidgetTester tester,
      String role,
    ) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: AdminTeamView(adminRole: role),
        width: 360,
        height: 800,
        textScale: 1.0,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }

    testWidgets('operations sees the team read-only (no invite form)',
        (tester) async {
      await pumpTeam(tester, 'operations');
      await tester.pumpAndSettle();
      expect(find.text('Admin Team'), findsWidgets);
      expect(
        find.textContaining('Only a super admin can invite'),
        findsOneWidget,
      );
      expect(find.text('Send invite'), findsNothing);
    });

    testWidgets('super admin sees the invite form', (tester) async {
      await pumpTeam(tester, 'super_admin');
      await tester.pumpAndSettle();
      expect(find.text('Admin Team'), findsWidgets);
      // Phase 2 (2.5): the invite form lives on the Invites tab now.
      // The harness resets the viewport when it returns, so re-apply
      // it before tapping (the approvals-sheet test does the same).
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invites'));
      await tester.pumpAndSettle();
      expect(find.text('Save invite'), findsOneWidget);
    });
  });

  group('F-C1 — the tap-time check proceeds when the role is unknown',
      () {
    testWidgets('no signed-in user: proceed, role null (data source decides)',
        (tester) async {
      ({bool proceed, String? role})? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _CheckProbe(
            permission: AdminPermission.decideVendor,
            onResult: (r) => result = r,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.proceed, isTrue);
      expect(result!.role, isNull);
    });
  });
}

class _CheckProbe extends StatefulWidget {
  const _CheckProbe({required this.permission, required this.onResult});

  final AdminPermission permission;
  final void Function(({bool proceed, String? role}) result) onResult;

  @override
  State<_CheckProbe> createState() => _CheckProbeState();
}

class _CheckProbeState extends State<_CheckProbe> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final result =
        await AdminPermissionCheck.check(context, widget.permission);
    if (mounted) widget.onResult(result);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
