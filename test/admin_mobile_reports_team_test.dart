import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/presentation/views/admin_activity_log_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_reports_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_team_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_team_member_tile.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// Mobile-first adaptivity (2026-11-10): reports stack Export CSV
// under the From/To row and use two KPI tiles per row on compact
// widths; the team tile stacks its manage actions under the identity
// row; the activity log stacks search + Export CSV and moves the
// entry date into the subtitle.

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  double width = 360,
  double height = 800,
  double textScale = 1.35,
}) async {
  await TestHarness.pumpScreenWithOverflowCheck(
    tester: tester,
    screen: screen,
    width: width,
    height: height,
    textScale: textScale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('admin_mobile_reports', () {
    testWidgets('reports at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminReportsView());
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Export CSV'), findsOneWidget);
    });

    testWidgets('reports at desktop width', (tester) async {
      await _pump(tester, const AdminReportsView(),
          width: 1280, textScale: 1.0);
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Export CSV'), findsOneWidget);
    });
  });

  group('admin_mobile_team', () {
    testWidgets('team view at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminTeamView(adminRole: 'super_admin'));
      expect(find.text('Admin Team'), findsWidgets);
    });

    testWidgets('team view at 360px, 2.0x text', (tester) async {
      await _pump(tester, const AdminTeamView(adminRole: 'super_admin'),
          textScale: 2.0);
      expect(find.text('Admin Team'), findsWidgets);
      expect(find.text('Send invite'), findsOneWidget);
    });

    testWidgets('team member tile stacks actions at 360px',
        (tester) async {
      const member = AdminTeamMember(
        uid: 'uid-1',
        email: 'operations-manager@rentalhub.pk',
        adminRole: 'operations',
        totpEnabled: false,
      );
      await _pump(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AdminTeamMemberTile(
                member: member,
                canManage: true,
                onResetTotp: () {},
                onRevoke: () {},
              ),
            ),
          ));
      expect(find.text('operations-manager@rentalhub.pk'), findsOneWidget);
      expect(find.text('2FA off'), findsOneWidget);
      expect(find.text('Reset 2FA'), findsOneWidget);
      expect(find.text('Revoke role'), findsOneWidget);
    });

    testWidgets('team member tile at desktop width', (tester) async {
      const member = AdminTeamMember(
        uid: 'uid-1',
        email: 'ops@rentalhub.pk',
        adminRole: 'operations',
        totpEnabled: true,
      );
      await _pump(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AdminTeamMemberTile(
                member: member,
                canManage: true,
                onResetTotp: () {},
                onRevoke: () {},
              ),
            ),
          ),
          width: 1280,
          textScale: 1.0);
      expect(find.text('ops@rentalhub.pk'), findsOneWidget);
      expect(find.text('2FA on'), findsOneWidget);
    });
  });

  group('admin_mobile_activity', () {
    testWidgets('activity log at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminActivityLogView());
      expect(find.text('Activity Log'), findsWidgets);
      expect(find.text('Export CSV'), findsOneWidget);
    });

    testWidgets('activity log at desktop width', (tester) async {
      await _pump(tester, const AdminActivityLogView(),
          width: 1280, textScale: 1.0);
      expect(find.text('Activity Log'), findsWidgets);
    });
  });
}
