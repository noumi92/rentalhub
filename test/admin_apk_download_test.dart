import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/data/services/admin_apk_release_service.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_platform_settings_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_apk_download_card.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

const _validVersionJson =
    '{"app":"rentalhub","versionName":"1.0.0","versionCode":1,"build":68,"commit":"70269a5cd9eed554160bdfa366a99d3d8625427c","apk":"app-release.apk","updatedAt":"2026-11-13T17:30:12Z"}';
const _baseUrl = 'https://admin.example.test/panel/';

AdminApkReleaseService _serviceFor(String body, [int status = 200]) {
  return AdminApkReleaseService(
    client: MockClient((_) async => http.Response(body, status)),
    baseUri: Uri.parse(_baseUrl),
  );
}

class _FakeAdminSupportDataSource extends AdminSupportDataSource {
  @override
  Future<PlatformSettings> getPlatformSettings() async =>
      const PlatformSettings();

  @override
  Future<bool> savePlatformSettings(PlatformSettings settings,
          {String? adminRole}) async =>
      true;
}

Future<void> _pumpCard(
  WidgetTester tester, {
  String? adminRole,
  AdminApkReleaseService? service,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AdminApkDownloadCard(
          adminRole: adminRole,
          service: service,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
    SignedInUser.override = const SignedInUserData(
      uid: 'cust-101',
      displayName: 'Ahmed Raza',
      phoneNumber: '03001234567',
    );
  });

  tearDownAll(() {
    SignedInUser.override = null;
  });

  group('AppReleaseInfo.fromJson', () {
    test('a full version.json parses every field', () {
      final info = AppReleaseInfo.fromJson({
        'app': 'rentalhub',
        'versionName': '1.0.0',
        'versionCode': 1,
        'build': 68,
        'commit': '70269a5cd9eed554160bdfa366a99d3d8625427c',
        'apk': 'app-release.apk',
        'updatedAt': '2026-11-13T17:30:12Z',
      });
      expect(info.versionName, '1.0.0');
      expect(info.versionCode, 1);
      expect(info.build, 68);
      expect(info.commit, '70269a5cd9eed554160bdfa366a99d3d8625427c');
      expect(info.apkFileName, 'app-release.apk');
      expect(info.apkFileNameOrDefault, 'app-release.apk');
      expect(info.updatedAt, DateTime.utc(2026, 11, 13, 17, 30, 12));
    });

    test('missing fields stay null; the APK name falls back', () {
      final info = AppReleaseInfo.fromJson({'versionName': '1.0.0'});
      expect(info.versionName, '1.0.0');
      expect(info.versionCode, isNull);
      expect(info.build, isNull);
      expect(info.commit, isNull);
      expect(info.apkFileName, isNull);
      expect(info.updatedAt, isNull);
      expect(info.apkFileNameOrDefault, 'app-release.apk');
    });

    test('string numbers parse; bad values stay null, never invented', () {
      final info = AppReleaseInfo.fromJson({
        'versionCode': '3',
        'build': 'not-a-number',
        'apk': '',
        'updatedAt': 'not-a-date',
      });
      expect(info.versionCode, 3);
      expect(info.build, isNull);
      expect(info.updatedAt, isNull);
      expect(info.apkFileNameOrDefault, 'app-release.apk');
    });
  });

  group('AdminApkReleaseService.fetchLatest', () {
    test('resolves version.json and the download URL off the panel URL',
        () async {
      final service = _serviceFor(_validVersionJson);
      expect(service.versionJsonUri.toString(),
          '${_baseUrl}apk/version.json');
      final info = await service.fetchLatest();
      expect(info, isNotNull);
      expect(info!.versionName, '1.0.0');
      expect(service.downloadUriFor(info).toString(),
          '${_baseUrl}apk/app-release.apk');
    });

    test('a missing file (404) reads as no build, not an error', () async {
      final service = _serviceFor('Not found', 404);
      expect(await service.fetchLatest(), isNull);
    });

    test('a network failure reads as no build, not an error', () async {
      final service = AdminApkReleaseService(
        client: MockClient((_) async => throw http.ClientException('boom')),
        baseUri: Uri.parse(_baseUrl),
      );
      expect(await service.fetchLatest(), isNull);
    });

    test('malformed JSON throws FormatException', () async {
      final service = _serviceFor('{not json');
      await expectLater(service.fetchLatest(), throwsFormatException);
    });

    test('non-object JSON throws FormatException', () async {
      final service = _serviceFor('["a", "b"]');
      await expectLater(service.fetchLatest(), throwsFormatException);
    });
  });

  group('AdminApkDownloadCard — role gating', () {
    testWidgets('hidden for operations', (tester) async {
      await _pumpCard(tester,
          adminRole: 'operations', service: _serviceFor(_validVersionJson));
      expect(find.text('Android app (APK)'), findsNothing);
      expect(find.text('Download APK'), findsNothing);
    });

    testWidgets('hidden for support', (tester) async {
      await _pumpCard(tester,
          adminRole: 'support', service: _serviceFor(_validVersionJson));
      expect(find.text('Android app (APK)'), findsNothing);
      expect(find.text('Download APK'), findsNothing);
    });

    testWidgets('hidden when no role resolves (signed-out / no user)',
        (tester) async {
      await _pumpCard(tester, service: _serviceFor(_validVersionJson));
      expect(find.text('Android app (APK)'), findsNothing);
    });
  });

  group('AdminApkDownloadCard — super admin states', () {
    testWidgets('shows version, build, date, button and URL when loaded',
        (tester) async {
      await _pumpCard(tester,
          adminRole: 'super_admin',
          service: _serviceFor(_validVersionJson));
      expect(find.text('Android app (APK)'), findsOneWidget);
      expect(find.text('1.0.0 (code 1)'), findsOneWidget);
      expect(find.text('68'), findsOneWidget);
      expect(find.text('2026-11-13 17:30 UTC'), findsOneWidget);
      expect(find.text('Download APK'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              (w.data ?? '').contains('apk/app-release.apk'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('honest empty state when no build is published',
        (tester) async {
      await _pumpCard(tester,
          adminRole: 'super_admin', service: _serviceFor('Not found', 404));
      expect(find.text('Android app (APK)'), findsOneWidget);
      expect(find.text('No build published yet'), findsOneWidget);
      expect(find.text('Download APK'), findsNothing);
    });

    testWidgets('error state with retry; retry loads after a bad file',
        (tester) async {
      var calls = 0;
      final flaky = AdminApkReleaseService(
        client: MockClient((_) async {
          calls++;
          if (calls == 1) return http.Response('{not json', 200);
          return http.Response(_validVersionJson, 200);
        }),
        baseUri: Uri.parse(_baseUrl),
      );
      await _pumpCard(tester, adminRole: 'super_admin', service: flaky);
      expect(find.text('Could not load the latest build.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Download APK'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load the latest build.'), findsNothing);
      expect(find.text('1.0.0 (code 1)'), findsOneWidget);
      expect(find.text('Download APK'), findsOneWidget);
    });
  });

  group('AdminPlatformSettingsView — APK card removed (Phase 1, 1.3)', () {
    testWidgets('no role sees the APK card in Settings any more',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminPlatformSettingsView(
            dataSource: _FakeAdminSupportDataSource(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Android app (APK)'), findsNothing);
      expect(find.text('Download APK'), findsNothing);
      expect(find.text('Cities & settings'), findsWidgets);
      expect(find.text('Save settings'), findsOneWidget);
    });

    testWidgets('the card still exists on its own route', (tester) async {
      await _pumpCard(
        tester,
        adminRole: 'super_admin',
        service: _serviceFor(_validVersionJson),
      );
      expect(find.text('Android app (APK)'), findsOneWidget);
      expect(find.text('Download APK'), findsOneWidget);
      expect(find.text('1.0.0 (code 1)'), findsOneWidget);
      expect(find.text('68'), findsOneWidget);
    });
  });
}
