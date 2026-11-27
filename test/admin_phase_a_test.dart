import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/admin_guard.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/data/services/admin_session.dart';
import 'package:rentalhub/features/admin/domain/admin_permissions.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_activity_log_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_coming_soon_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_login_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_team_view.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // The invite tile formats expiry dates with DateFormat, which
    // needs locale data initialized in the test environment.
    await initializeDateFormatting('en');
    await di.initDependencies();
  });

  group('Phase A (A2) — permission matrix', () {
    test('super admin can do everything, support only triage', () {
      for (final permission in AdminPermission.values) {
        expect(AdminPermissions.can('super_admin', permission), isTrue,
            reason: '$permission');
      }
      expect(
          AdminPermissions.can('support', AdminPermission.decideVendor),
          isFalse);
      expect(
          AdminPermissions.can('support', AdminPermission.manageTeam),
          isFalse);
      expect(
          AdminPermissions.can('support', AdminPermission.decideDispute),
          isFalse);
      expect(
          AdminPermissions.can('support', AdminPermission.triageTicket),
          isTrue);
      expect(
          AdminPermissions.can('support', AdminPermission.viewActivityLog),
          isTrue);
      expect(
          AdminPermissions.can('operations', AdminPermission.manageTeam),
          isFalse);
      expect(
          AdminPermissions.can('operations', AdminPermission.decideVendor),
          isTrue);
      expect(AdminPermissions.can(null, AdminPermission.manageTeam),
          isFalse);
      expect(AdminPermissions.label('super_admin'), 'Super Admin');
      expect(AdminPermissions.label('operations'), 'Operations');
      expect(AdminPermissions.label('support'), 'Support');
      expect(AdminGuard.isAdminRole('owner'), isFalse);
      expect(AdminGuard.isSuperAdmin('super_admin'), isTrue);
    });
  });

  group('Phase A (A1/A5) — data layer (in-memory / offline)', () {
    test('invites round-trip with a 48 h expiry', () async {
      final ds = AdminRemoteDataSource();
      final invite = await ds.createInvite(
        email: 'ops-test@rentalhub.pk',
        adminRole: 'operations',
        callerRole: 'super_admin',
      );
      expect(invite.email, 'ops-test@rentalhub.pk');
      expect(invite.adminRole, 'operations');
      expect(invite.accepted, isFalse);
      expect(invite.isExpired, isFalse);
      expect(
        invite.expiresAt!.difference(DateTime.now()).inHours,
        greaterThanOrEqualTo(47),
      );
      final list = await ds.getInvites();
      expect(list.any((i) => i.id == invite.id), isTrue);
      await ds.revokeInvite(invite.id, callerRole: 'super_admin');
      final after = await ds.getInvites();
      expect(after.any((i) => i.id == invite.id), isFalse);
    });

    test('platform stats are zeros when Firestore is unreachable', () async {
      final ds = AdminRemoteDataSource();
      final stats = await ds.getPlatformStats();
      expect(stats.shopCount, 0);
      expect(stats.activeBookingCount, 0);
      expect(stats.openDisputeCount, 0);
      expect(stats.openTicketCount, 0);
    });

    test('audit log CSV has the right header and rows', () {
      final csv = AdminRemoteDataSource.auditLogsCsv([
        AuditLogEntry.fromMap('log-1', {
          'type': 'admin_action',
          'action': 'blacklist_reversed',
          'actor_email': 'admin@rentalhub.pk',
          'target_type': 'blacklist',
          'target_id': 'BLK-1',
          'detail': 'CNIC removed.',
          'decision': 'Court clearance.',
          'created_at': '2026-11-06T10:00:00.000Z',
        }),
      ]);
      final lines = csv.split('\n');
      expect(lines.first,
          'Date,Action,Actor,Target type,Target,Detail,Decision');
      expect(lines[1], contains('blacklist_reversed'));
      expect(lines[1], contains('admin@rentalhub.pk'));
      expect(lines[1], contains('Court clearance.'));
    });

    test('TOTP session starts unverified and clears cleanly', () {
      AdminSession.clear();
      expect(AdminSession.isTotpVerifiedForCurrentUser, isFalse);
      AdminSession.markTotpVerified('uid-1');
      // No Firebase user in tests, so the flag cannot match anyone.
      expect(AdminSession.isTotpVerifiedForCurrentUser, isFalse);
      AdminSession.clear();
    });
  });

  group('Phase A — admin views render', () {
    testWidgets('login view shows the credentials form', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminLoginView()));
      await tester.pumpAndSettle();
      expect(find.text('RentalHub Admin'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('team view shows members, invites and the invite form',
        (tester) async {
      final ds = sl<AdminRemoteDataSource>();
      await ds.createInvite(
        email: 'team-view-test@rentalhub.pk',
        adminRole: 'support',
        callerRole: 'super_admin',
      );
      await tester.pumpWidget(const MaterialApp(
          home: AdminTeamView(adminRole: 'super_admin')));
      await tester.pumpAndSettle();
      expect(find.text('Team members'), findsOneWidget);
      // Phase 2 (2.5): invites and the invite form live on the
      // Invites tab now.
      await tester.tap(find.text('Invites'));
      await tester.pumpAndSettle();
      expect(find.text('Pending invites'), findsOneWidget);
      expect(find.text('Invite an admin'), findsOneWidget);
      expect(find.text('team-view-test@rentalhub.pk'), findsOneWidget);
      expect(find.text('Save invite'), findsOneWidget);
    });

    testWidgets('team view hides management for non-super admins',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: AdminTeamView(adminRole: 'support')));
      await tester.pumpAndSettle();
      expect(find.text('Invite an admin'), findsNothing);
      expect(find.textContaining('Only a super admin'), findsOneWidget);
    });

    testWidgets('activity log shows its honest empty state',
        (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminActivityLogView()));
      await tester.pumpAndSettle();
      // Twice: the header title and the narrow nav strip's chip.
      expect(find.text('Activity Log'), findsWidgets);
      expect(find.textContaining('No audit entries yet'), findsOneWidget);
    });

    testWidgets('dashboard shows live-count KPI cards', (tester) async {
      await tester.pumpWidget(
          const MaterialApp(home: AdminDashboardView()));
      await tester.pumpAndSettle();
      expect(find.text('Registered shops'), findsOneWidget);
      expect(find.text('Active bookings'), findsOneWidget);
      expect(find.text('Open disputes'), findsOneWidget);
      expect(find.text('Open support tickets'), findsOneWidget);
    });

    testWidgets('coming-soon view states the phase honestly',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: AdminComingSoonView(
            activeRoute: '/admin/shops',
            title: 'Shops',
            subtitle: 'Shop approvals and the shops list',
            body: 'Shop approvals and the shops list arrive in Phase B.',
          )));
      await tester.pumpAndSettle();
      expect(find.text('Shop approvals and the shops list arrive in Phase B.'),
          findsOneWidget);
    });
  });
}
