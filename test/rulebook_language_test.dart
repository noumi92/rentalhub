// Rulebook language tests — DOC-12 (`.ai/doc12_comprehensive_rulebook.md`), §5.
//
// English (LTR) + Urdu (RTL), dynamic switching, persisted choice.
// Target-state tests for infrastructure that does not exist yet are
// `skip:`ped with their debt ID (rulebook §7.7).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('Rulebook §5.2 — localization infrastructure', () {
    test('flutter_localizations and intl are dependencies', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_localizations'));
      expect(pubspec, contains('intl:'));
    });

    test('English and Urdu .arb files exist and share the same keys', () {
      fail('not implemented yet');
    },
        skip:
            'D6: no .arb files, no l10n.yaml, no AppLocalizations yet — see rulebook §13. Un-skip when §5.2 lands.');

    test('switching locale changes the displayed strings', () {
      fail('not implemented yet');
    },
        skip:
            'D5/D6: no locale wiring in main.dart yet — see rulebook §13. Un-skip when the language toggle drives the app locale.');

    test('the language choice persists across restart', () {
      fail('not implemented yet');
    },
        skip:
            'D5: the Urdu toggle is local setState only, nothing is persisted — see rulebook §13. Un-skip when the choice is saved in SharedPreferences.');
  });

  group('Rulebook §5.3 — no new hardcoded Urdu strings', () {
    test('hardcoded Urdu text appears only in the registered files', () {
      final offenders = <String>{};
      final libDir = Directory('lib');
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
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
