import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/data/services/admin_apk_release_service.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_announcements_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_platform_settings_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_reports_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_apk_download_card.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_status_chip.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// Untouched-visual-fix pass (2026-11-14), admin module: the admin
// lists used bare spinners and hand-rolled empty texts, load failures
// spun forever, and status chips used raw palette literals and raw
// `snake_case` enums. These tests pin the fixed states.

class _FakeSettingsSource extends AdminSupportDataSource {
  @override
  Future<PlatformSettings> getPlatformSettings() async =>
      const PlatformSettings();
}

class _ThrowingSettingsSource extends AdminSupportDataSource {
  @override
  Future<PlatformSettings> getPlatformSettings() async =>
      throw Exception('boom');
}


Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  double width = 360,
  double height = 800,
  double textScale = 1.35,
  Locale? locale,
}) async {
  await TestHarness.pumpScreenWithOverflowCheck(
    tester: tester,
    screen: screen,
    width: width,
    height: height,
    textScale: textScale,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('admin_untouched_visual_fix', () {
    testWidgets('settings toggles render in Urdu at 360px without overflow',
        (tester) async {
      // operations role: the APK download card stays hidden, so this
      // pumps only the settings form.
      await _pump(
        tester,
        AdminPlatformSettingsView(
          dataSource: _FakeSettingsSource(),
          adminRole: 'operations',
        ),
        locale: const Locale('ur'),
      );
      expect(find.text('غیر تصدیق شدہ دکانیں دکھائیں'), findsOneWidget);
      expect(find.text('غیر تصدیق شدہ دکانوں سے بکنگ کی اجازت دیں'),
          findsOneWidget);
      // The Save button keeps its 48dp touch target at 1.35x text.
      // The label is localised (admin2_settingsSave) and this test
      // pumps Urdu, so the finder uses the Urdu label.
      final saveSize = tester.getSize(
          find.widgetWithText(FilledButton, 'ترتیبات محفوظ کریں'));
      expect(saveSize.height, greaterThanOrEqualTo(48));
    });

    testWidgets('settings shows an error state when the load fails',
        (tester) async {
      await _pump(
        tester,
        AdminPlatformSettingsView(
          dataSource: _ThrowingSettingsSource(),
          adminRole: 'operations',
        ),
      );
      expect(find.text('Could not load the platform settings.'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('reports renders at 360px, 1.35x text', (tester) async {
      await _pump(tester, const AdminReportsView());
      expect(find.text('Reports'), findsWidgets);
      expect(find.textContaining('No data for this range'), findsOneWidget);
    });

    testWidgets('announcements empty state renders at 360px, 1.35x text',
        (tester) async {
      await _pump(tester, const AdminAnnouncementsView());
      expect(find.text('Announcements'), findsWidgets);
      expect(find.text('No announcements yet'), findsOneWidget);
    });

    test('humanizeStatus turns raw enums into readable labels', () {
      expect(humanizeStatus('payment_submitted'), 'Payment submitted');
      expect(humanizeStatus('in_progress'), 'In progress');
      expect(humanizeStatus('open'), 'Open');
      expect(humanizeStatus(''), '');
    });

    testWidgets('status chip shows the human label at 360px',
        (tester) async {
      await _pump(
        tester,
        const Scaffold(
          body: Center(
            child: AdminStatusChip(
              label: 'Payment submitted',
              tone: AdminStatusTone.info,
            ),
          ),
        ),
      );
      expect(find.text('Payment submitted'), findsOneWidget);
    });

    testWidgets('APK card loading row does not overflow at 360px in Urdu',
        (tester) async {
      // Regression: the loading row rendered its label as a bare Text
      // next to the spinner and overflowed ~318px at 360px/Urdu/1.35x.
      // The label is now wrapped in Expanded. Pumped manually (not
      // via the harness): pumpAndSettle would advance the fake clock
      // past the service's 10s timeout and leave the loading state.
      final pendingResponse = Completer<http.Response>();
      final pending = AdminApkReleaseService(
        client: MockClient((_) => pendingResponse.future),
        baseUri: Uri.parse('https://admin.example.test/panel/'),
      );
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
        originalOnError?.call(details);
      };
      try {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ur'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(1.35),
              ),
              child: Scaffold(
                body: AdminApkDownloadCard(
                  adminRole: 'super_admin',
                  service: pending,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(caughtDetails, isNull);
        // Drain the service's 10s timeout timer so the test ends
        // clean: answer the pending request after asserting.
        pendingResponse.complete(http.Response('not found', 404));
        await tester.pump();
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });
}
