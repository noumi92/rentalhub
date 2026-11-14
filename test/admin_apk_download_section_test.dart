import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/data/services/admin_apk_release_service.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_apk_download_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sidebar_nav.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

const _validVersionJson =
    '{"app":"rentalhub","versionName":"1.0.0","versionCode":1,"build":70,"commit":"b3d5449ffdea009e55125e7a96f1acf2c11c298f","apk":"app-release.apk","updatedAt":"2026-11-14T03:09:12Z"}';
const _baseUrl = 'https://admin.example.test/panel/';

AdminApkReleaseService _serviceFor(String body, [int status = 200]) {
  return AdminApkReleaseService(
    client: MockClient((_) async => http.Response(body, status)),
    baseUri: Uri.parse(_baseUrl),
  );
}

Future<void> _pumpView(
  WidgetTester tester, {
  String? adminRole,
  AdminApkReleaseService? service,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AdminApkDownloadView(
        adminRole: adminRole,
        service: service,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSidebar(
  WidgetTester tester, {
  required bool showApkDownload,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdminSidebarNav(
          activeRoute: RouteNames.adminDashboard,
          onNavigate: (_) {},
          showApkDownload: showApkDownload,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminApkDownloadView', () {
    testWidgets('super admin sees the APK download card', (tester) async {
      await _pumpView(
        tester,
        adminRole: 'super_admin',
        service: _serviceFor(_validVersionJson),
      );
      expect(find.text('APK Download'), findsOneWidget);
      expect(find.text('Android app (APK)'), findsOneWidget);
      expect(find.text('Download APK'), findsOneWidget);
      expect(find.text('1.0.0 (code 1)'), findsOneWidget);
      expect(find.text('70'), findsOneWidget);
    });

    testWidgets('operations admin sees the super-admin-only state',
        (tester) async {
      await _pumpView(
        tester,
        adminRole: 'operations',
        service: _serviceFor(_validVersionJson),
      );
      expect(find.text('APK Download'), findsOneWidget);
      expect(
        find.text('Only super admins can download the APK'),
        findsOneWidget,
      );
      expect(find.text('Download APK'), findsNothing);
      expect(find.text('Android app (APK)'), findsNothing);
    });

    testWidgets('support admin sees the super-admin-only state',
        (tester) async {
      await _pumpView(tester, adminRole: 'support');
      expect(
        find.text('Only super admins can download the APK'),
        findsOneWidget,
      );
      expect(find.text('Download APK'), findsNothing);
    });
  });

  group('AdminSidebarNav APK Download item', () {
    testWidgets('shows for a super admin', (tester) async {
      await _pumpSidebar(tester, showApkDownload: true);
      expect(find.text('APK Download'), findsOneWidget);
      expect(find.byIcon(Icons.android_rounded), findsOneWidget);
      // The base sections are untouched.
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('hidden for any other role', (tester) async {
      await _pumpSidebar(tester, showApkDownload: false);
      expect(find.text('APK Download'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  group('adminApkDownload route', () {
    testWidgets('the route opens the download section', (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.adminApkDownload,
        routes: [
          GoRoute(
            path: RouteNames.adminApkDownload,
            builder: (context, state) => const AdminApkDownloadView(),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      // No signed-in user in tests, so the section renders its
      // super-admin-only state — proving the route reaches the view.
      expect(find.text('APK Download'), findsOneWidget);
      expect(
        find.text('Only super admins can download the APK'),
        findsOneWidget,
      );
    });
  });
}
