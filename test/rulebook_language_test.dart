// Rulebook language tests — DOC-12 (`.ai/doc12_comprehensive_rulebook.md`), §5.
//
// English (LTR) + Urdu (RTL), dynamic switching, persisted choice.
// Target-state tests for infrastructure that does not exist yet are
// `skip:`ped with their debt ID (rulebook §7.7).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/settings/app_settings_cubit.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_settings_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Rulebook §5.3 / D20: files that contain hardcoded Urdu text today.
// Verified by scanning lib/ at `master` `af8c73c`: a greeting default in
// both header widgets, Urdu subtitles/labels in login, role selection,
// settings, vehicle detail, and documents views. No new file may gain
// hardcoded Urdu strings — new strings go through AppLocalizations (§5.2).
const Set<String> kHardcodedUrduFiles = {
  'lib/core/widgets/custom_curved_header.dart',
  'lib/core/widgets/curved_header.dart',
  'lib/features/auth/presentation/views/login_view.dart',
  'lib/features/auth/presentation/views/onboarding_role_view.dart',
  'lib/features/customer/presentation/views/customer_settings_view.dart',
  'lib/features/discovery/presentation/views/vehicle_detail_view.dart',
  'lib/features/trust/presentation/views/customer_documents_view.dart',
};

bool _containsUrdu(String content) =>
    RegExp(r'[\u0600-\u06FF]').hasMatch(content);

String _posix(String path) => path.replaceAll(r'\', '/');

void main() {
  // Phase B (G3): the locale-switch test pumps the settings view,
  // which reads AppSettingsCubit from DI.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Rulebook §5.2 — localization infrastructure', () {
    test('flutter_localizations and intl are dependencies', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_localizations'));
      expect(pubspec, contains('intl:'));
    });

    test('English and Urdu .arb files exist and share the same keys', () {
      // Phase B (G3): the .arb infrastructure landed — un-skipped
      // with a real check instead of the placeholder.
      final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
      final ur = jsonDecode(File('lib/l10n/app_ur.arb').readAsStringSync())
          as Map<String, dynamic>;
      final enKeys =
          en.keys.where((k) => !k.startsWith('@')).toSet();
      final urKeys =
          ur.keys.where((k) => !k.startsWith('@')).toSet();
      expect(enKeys, isNotEmpty);
      expect(urKeys, equals(enKeys),
          reason: 'Every English key needs an Urdu translation.');
      expect(File('l10n.yaml').existsSync(), isTrue);
    });

    testWidgets('switching locale changes the displayed strings',
        (tester) async {
      // Phase B (G3): the owner settings screen is the first fully
      // translated screen — it renders in Urdu under the ur locale.
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ur'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: OwnerSettingsView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('دکان کی ترتیبات'), findsOneWidget);
      expect(find.text('Shop Settings'), findsNothing);
    });

    test('the language choice persists across restart', () async {
      // Phase B (G3): AppSettingsCubit persists `app_locale` in
      // SharedPreferences and reloads it on construction.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = AppSettingsCubit(prefs: prefs);
      await cubit.setLocale('ur');
      final reloaded = AppSettingsCubit(prefs: prefs);
      expect(reloaded.state.localeCode, 'ur');
      await cubit.setLocale('en');
    });
  });

  group('Rulebook §5.3 — no new hardcoded Urdu strings', () {
    test('hardcoded Urdu text appears only in the registered files', () {
      final offenders = <String>{};
      final libDir = Directory('lib');
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // The generated localizations under lib/l10n/ are derived
        // from the .arb files — they are the sanctioned source, not
        // hardcoded strings in code (Phase B, G3).
        if (_posix(entity.path).startsWith('lib/l10n/')) continue;
        if (_containsUrdu(entity.readAsStringSync())) {
          offenders.add(_posix(entity.path));
        }
      }
      final unregistered = offenders.difference(kHardcodedUrduFiles);
      expect(unregistered, isEmpty,
          reason:
              'Rulebook §5.2: user-facing strings must go through AppLocalizations. '
              'New hardcoded Urdu found in:\n${unregistered.join('\n')}');
    });
  });

  group('Rulebook §5.3 — RTL mechanism', () {
    testWidgets('an RTL Directionality mirrors layout', (tester) async {
      late TextDirection seen;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) {
                seen = Directionality.of(context);
                return const Text('اردو');
              },
            ),
          ),
        ),
      );
      expect(seen, TextDirection.rtl);
      expect(find.text('اردو'), findsOneWidget);
    });

    testWidgets('an LTR Directionality is the English default',
        (tester) async {
      late TextDirection seen;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                seen = Directionality.of(context);
                return const Text('English');
              },
            ),
          ),
        ),
      );
      expect(seen, TextDirection.ltr);
    });

    test('Noto Nastaliq Urdu font is bundled for Urdu text', () {
      fail('not implemented yet');
    },
        skip:
            'D7/D20: no font files in assets/, no fonts: block in pubspec.yaml — see rulebook §13. Un-skip when Noto Nastaliq Urdu (and Inter) are bundled.');
  });
}
