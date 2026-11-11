// Rulebook testing tests — DOC-12 (`.ai/doc12_comprehensive_rulebook.md`), §7.
//
// These tests check that the test suite itself follows the rulebook:
// overflow coverage, CI gates, and the testing infrastructure DOC-2 §10
// requires. Target-state tests are `skip:`ped with their debt ID (§7.7).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Rulebook §7.2 / D11: views covered by the overflow test today.
// Coverage may only grow — a view must never drop out of this list.
const Set<String> kOverflowCoveredViews = {
  'CustomerHomeView',
  'VehicleDetailView',
  'ShopDetailView',
  'OwnerFleetView',
  'CustomerDocumentsView',
  'OnboardingProfileView',
  'OnboardingRoleView',
  'OwnerOnboardingView',
  'OwnerAddVehicleView',
  // Phase G (G1): the booking-flow screen migrated in Phases E/F.
  'OwnerPaymentAccountsView',
};

void main() {
  group('Rulebook §7.2 — overflow coverage', () {
    test('overflow test covers at least the 9 registered views', () {
      final content =
          File('test/multi_screen_overflow_test.dart').readAsStringSync();
      final missing = <String>[];
      for (final view in kOverflowCoveredViews) {
        if (!content.contains(view)) missing.add(view);
      }
      expect(missing, isEmpty,
          reason:
              'Rulebook §7.2 (D11): views dropped out of overflow coverage:\n${missing.join('\n')}');
      final cases =
          RegExp(r'testWidgets\(').allMatches(content).length;
      expect(cases, greaterThanOrEqualTo(10),
          reason: 'expected at least 10 overflow cases, found $cases');
    });

    test('the multi-viewport harness is actually used', () {
      fail('not implemented yet');
    },
        skip:
            'D11: pumpScreenMultiViewport is defined in test_helper.dart but never called; only the single 360px check runs — see rulebook §13. Un-skip when overflow tests run all three viewports (360x640, 393x852, 412x915).');

    test('form screens have a keyboard-overlay overflow test', () {
      fail('not implemented yet');
    },
        skip:
            'D11: no bottomInset/viewInsets keyboard test exists — see rulebook §13. Un-skip when a 350px keyboard overlay test lands.');
  });

  group('Rulebook §7.4 — data integration tests', () {
    test('repository tests use fake_cloud_firestore', () {
      // D12 RESOLVED 2026-11-11: fake_cloud_firestore is a dev
      // dependency and test/shop_id_resolution_test.dart runs
      // FleetRemoteDataSource tests against FakeFirebaseFirestore
      // (shop-id resolution: doc-id + UID reads, canonical writes).
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('fake_cloud_firestore'));
      final testFile = File('test/shop_id_resolution_test.dart');
      expect(testFile.existsSync(), isTrue);
      expect(testFile.readAsStringSync(), contains('FakeFirebaseFirestore'));
    });

    test('cPanel upload errors (401/413/500) and retry backoff are tested',
        () {
      fail('not implemented yet');
    },
        skip:
            'D12: no mock cPanel HTTP test exists — see rulebook §13. Un-skip when the mocked upload-error tests land.');
  });

  group('Rulebook §7.1 — CI gate', () {
    test('CI runs flutter analyze and flutter test as the gate', () {
      final ci =
          File('.github/workflows/ci.yml').readAsStringSync();
      expect(ci, contains('flutter analyze'));
      expect(ci, contains('flutter test'));
      expect(ci, contains('lint_and_test'));
    });

    test('the line-count test enforces the 250-line rule', () {
      // D14 RESOLVED 2026-11-08, Phase G (G1): file_line_count_test.dart
      // now enforces 250 lines (rulebook §2.2 / R1). The single view
      // still over the cap (`owner_add_vehicle_view.dart`, 259) is a
      // registered D19 exception inside that file — the cap itself is
      // 250, so this test pins the cap rather than the exception.
      final content =
          File('test/file_line_count_test.dart').readAsStringSync();
      expect(content, contains('exceeds 250 lines of code'));
      expect(content, isNot(contains('exceeds 300 lines of code')));
      expect(content, contains('kOverLimitViews'));
    });
  });
}
