// Rulebook architecture tests — DOC-12 (`.ai/doc12_comprehensive_rulebook.md`).
//
// These are static tests: they read the repo (like `file_line_count_test.dart`)
// and enforce the architecture rules in rulebook §1–§2.
//
// Known debt is registered in the `kDebt*` maps below, mirroring rulebook §13.
// A test FAILS if a violation appears that is not registered, or if a
// registered violation gets worse (more files, more lines, more importers).
// Removing a debt entry from both here and rulebook §13 is how an item is
// finished — never by weakening a test.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Rulebook §2.2 / R1: views must be <= 250 lines.
// Files over the cap today (rulebook D19) with their line counts at
// `master` `af8c73c`. A file may shrink; it must never grow past its
// registered count, and no new file may exceed 250.
// Phase B (B2) removed `owner_rate_matrix_view.dart` (261 -> 229).
// Phase C (C3) deleted the orphaned `customer_dashboard_view.dart`
// (295) outright — its route was unreferenced, a duplicate of Home.
// Phase C/D shrank the other two D19 files to the cap or below:
// `owner_onboarding_view.dart` is now 250 and
// `customer_dispute_view.dart` is now 192, so they leave this map.
// Only `owner_add_vehicle_view.dart` (259) is still over the cap.
const Map<String, int> kOverLimitViews = {
  'lib/features/owner/presentation/views/owner_add_vehicle_view.dart': 259,
};

// Rulebook §2.2 / D1–D3: the mock flow views, with line counts at
// `af8c73c`. They must be replaced and deleted, one item at a time.
// They must never grow, and no new file directly under `presentation/`
// may exceed 250 lines.
// The owner flow view was deleted in Phase A (A2) — its routes now point
// at the real owner views. Do not re-add it.
// The customer flow view was deleted in the customer module build
// (Phase A, A1) — its routes now point at the real customer views.
// Do not re-add it.
// The admin flow view was deleted in the admin panel build (Phase A,
// A6) — its routes now point at the real admin views. Do not re-add it.
const Map<String, int> kFlowViews = {};

// Rulebook §2.3 / D4: files in `lib/` that import `mock_data.dart` today.
// No new importer may appear; removing one is progress.
// Phase B (B1) removed the three owner importers: `owner_add_vehicle_view`,
// `owner_fleet_view`, `fleet_vehicle_card`.
// Phase G (G1) verified ZERO importers remain: the five discovery
// importers (`shop_cars_view`, `shop_detail_view`, `vehicle_detail_view`,
// `customer_vehicle_card`, `vehicle_hero_card`) no longer reference
// `mock_data.dart` — the set is empty, matching rulebook §13 D4.
// `mock_data.dart` itself still exists (see the test below); deleting
// the file is the remaining D4 step.
const Set<String> kMockDataImporters = <String>{};

int _lineCount(File file) => file.readAsLinesSync().length;

List<File> _dartFiles(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) return <File>[];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

String _posix(String path) => path.replaceAll(r'\', '/');

void main() {
  group('Rulebook §1 — Clean Architecture', () {
    test('domain layer has zero Flutter imports', () {
      final domainFiles = _dartFiles('lib')
          .where((f) => _posix(f.path).contains('/domain/'))
          .toList();
      expect(domainFiles, isNotEmpty,
          reason: 'expected domain files under lib/features/*/domain/');
      final offenders = <String>[];
      for (final file in domainFiles) {
        final content = file.readAsStringSync();
        if (content.contains('package:flutter/')) {
          offenders.add(_posix(file.path));
        }
      }
      expect(offenders, isEmpty,
          reason:
              'Rulebook §1.2: domain must be pure Dart. Flutter imports found in:\n${offenders.join('\n')}');
    });

    test('every feature has a presentation layer', () {
      const expectedFeatures = <String>{
        'admin',
        'auth',
        'blacklist',
        'bookings',
        'customer',
        'discovery',
        'fleet',
        'handover',
        'owner',
        'payments',
        'trust',
      };
      final featuresDir = Directory('lib/features');
      final found = featuresDir
          .listSync()
          .whereType<Directory>()
          .map((d) => _posix(d.path).split('/').last)
          .toSet();
      expect(found, containsAll(expectedFeatures));
      for (final feature in expectedFeatures) {
        expect(Directory('lib/features/$feature/presentation').existsSync(),
            isTrue,
            reason:
                'Rulebook §1.1: feature "$feature" must have a presentation/ layer');
      }
    });

    test('DebouncedButton defaults to a 400ms lockout', () {
      final file = File('lib/core/widgets/debounced_button.dart');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('milliseconds: 400'),
          reason:
              'Rulebook §4.4 / §7.3: DebouncedButton must enforce a 400ms lockout');
    });
  });

  group('Rulebook §2.2 — 250-line view cap', () {
    test('view files in presentation/views/ are <= 250 lines (except registered debt)', () {
      final views = _dartFiles('lib').where((f) {
        final p = _posix(f.path);
        return p.contains('/presentation/views/') &&
            !p.contains('/presentation/views/widgets/');
      }).toList();
      expect(views, isNotEmpty);
      final violations = <String>[];
      for (final file in views) {
        final path = _posix(file.path);
        final lines = _lineCount(file);
        if (lines <= 250) continue;
        final registered = kOverLimitViews[path];
        if (registered == null) {
          violations.add('$path: $lines lines (over 250, not in debt register)');
        } else if (lines > registered) {
          violations.add(
              '$path: $lines lines (grew past registered $registered — debt must only shrink)');
        }
      }
      expect(violations, isEmpty,
          reason: 'Rulebook §2.2 (D19):\n${violations.join('\n')}');
    });

    test('flow/container files directly under presentation/ are <= 250 lines (except registered debt)', () {
      final files = _dartFiles('lib').where((f) {
        final p = _posix(f.path);
        final parts = p.split('/');
        // .../presentation/<file>.dart — directly under presentation/
        return parts.length >= 2 &&
            parts[parts.length - 2] == 'presentation' &&
            p.endsWith('.dart');
      }).toList();
      final violations = <String>[];
      for (final file in files) {
        final path = _posix(file.path);
        final lines = _lineCount(file);
        if (lines <= 250) continue;
        final registered = kFlowViews[path];
        if (registered == null) {
          violations.add('$path: $lines lines (over 250, not in debt register)');
        } else if (lines > registered) {
          violations.add(
              '$path: $lines lines (grew past registered $registered — debt must only shrink)');
        }
      }
      expect(violations, isEmpty,
          reason: 'Rulebook §2.2 (D1–D3):\n${violations.join('\n')}');
    });
  });

  group('Rulebook §4.4 — nav shell is the only navigation mechanism', () {
    // Phase C (C1/C2): the two StatefulShellRoute shells (customer +
    // owner, five branches each) own the single floating nav
    // (`AppShellNav`, via `AppShell`). The 10 tab-root screens must
    // never embed a nav widget of their own — a second nav would
    // double the pill and break the shell's branch state.
    const tabScreens = <String>[
      'lib/features/discovery/presentation/views/customer_home_view.dart',
      'lib/features/customer/presentation/views/customer_bookings_view.dart',
      'lib/features/customer/presentation/views/customer_wallet_view.dart',
      'lib/features/customer/presentation/views/customer_support_view.dart',
      'lib/features/customer/presentation/views/customer_profile_view.dart',
      'lib/features/owner/presentation/views/owner_dashboard_view.dart',
      'lib/features/owner/presentation/views/owner_fleet_view.dart',
      'lib/features/owner/presentation/views/owner_booking_requests_view.dart',
      'lib/features/owner/presentation/views/owner_customers_list_view.dart',
      'lib/features/owner/presentation/views/owner_settings_view.dart',
    ];

    test('no tab screen embeds a nav widget directly', () {
      final navPatterns = <RegExp>[
        RegExp(r'bottomNavigationBar\s*:'),
        RegExp(r'\bBottomNavigationBar\s*\('),
        RegExp(r'\bNavigationBar\s*\('),
        RegExp(r'AppShellNav'),
      ];
      final offenders = <String>[];
      for (final path in tabScreens) {
        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: 'tab screen missing from the tree: $path');
        final content = file.readAsStringSync();
        for (final pattern in navPatterns) {
          if (pattern.hasMatch(content)) {
            offenders.add('$path matches $pattern');
          }
        }
      }
      expect(offenders, isEmpty,
          reason:
              'Rulebook §4.4: the nav shell is the only navigation mechanism. '
              'Tab screens must not embed a nav widget:\n${offenders.join('\n')}');
    });

    test('AppShellNav is embedded in exactly one place (AppShell)', () {
      final embedders = <String>{};
      for (final file in _dartFiles('lib')) {
        if (file.readAsStringSync().contains('AppShellNav(')) {
          embedders.add(_posix(file.path));
        }
      }
      expect(
        embedders,
        {'lib/core/widgets/app_shell_nav.dart', 'lib/core/routing/app_shell.dart'},
        reason:
            'Rulebook §4.4: AppShellNav must be constructed only by its own '
            'definition and by AppShell. A new embedder is a second nav.',
      );
      final shell = File('lib/core/routing/app_shell.dart').readAsStringSync();
      expect(shell, contains('bottomNavigationBar'));
    });
  });

  group('Rulebook §2.3 — no mock data in production code', () {
    test('no file in lib/ imports mock_data except registered debt', () {
      final importers = <String>{};
      for (final file in _dartFiles('lib')) {
        if (file.readAsStringSync().contains('mock_data')) {
          importers.add(_posix(file.path));
        }
      }
      final unregistered = importers.difference(kMockDataImporters);
      expect(unregistered, isEmpty,
          reason:
              'Rulebook §2.3: new mock_data importers are banned. Unregistered:\n${unregistered.join('\n')}');
      // If the debt was fully fixed, the register must be cleaned up too:
      // a registered file that no longer imports mock_data is progress —
      // remove it from kMockDataImporters (and rulebook §13 D4) in that item.
    });

    test('mock_data.dart itself is registered debt, not a feature', () {
      expect(File('lib/core/models/mock_data.dart').existsSync(), isTrue,
          reason:
              'Rulebook §13 D4: mock_data.dart still exists as registered debt. '
              'If it was deleted, remove this test’s D4 expectation in the same item.');
    });
  });

  group('Rulebook §2.5 / §8 — no placeholders, no secrets', () {
    test('no TODO or FIXME left in lib/', () {
      final offenders = <String>[];
      for (final file in _dartFiles('lib')) {
        final content = file.readAsStringSync();
        if (content.contains('TODO') || content.contains('FIXME')) {
          offenders.add(_posix(file.path));
        }
      }
      expect(offenders, isEmpty,
          reason:
              'Rulebook §2.5 (DOC-0): no placeholders in shipped code:\n${offenders.join('\n')}');
    });

    test('no secrets in lib/', () {
      final patterns = <RegExp>[
        RegExp(r'xox[baprs]-[A-Za-z0-9-]+'),
        RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
        RegExp(r'sk-[A-Za-z0-9]{20,}'),
        RegExp(r'whatsapp[_-]?token', caseSensitive: false),
      ];
      final offenders = <String>[];
      for (final file in _dartFiles('lib')) {
        final content = file.readAsStringSync();
        for (final pattern in patterns) {
          if (pattern.hasMatch(content)) {
            offenders.add('${_posix(file.path)} matches $pattern');
          }
        }
      }
      expect(offenders, isEmpty,
          reason:
              'Rulebook §1.8 / §8.1: secrets belong in Cloud Functions / Secret Manager only:\n${offenders.join('\n')}');
    });
  });
}
