import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/admin/data/services/admin_session.dart';

/// Covers the temporary password-only fallback (2026-11-10): while the
/// TOTP Cloud Functions are not deployed, the admin login lets the
/// admin in on password alone instead of stranding them on the TOTP
/// step. Only a missing/unreachable Functions backend qualifies — any
/// other failure must still show its error on the TOTP step.
void main() {
  group('AdminSession.isFunctionsUnavailable', () {
    test('not-found callable means the Functions are not deployed', () {
      expect(
        AdminSession.isFunctionsUnavailable(
          FirebaseException(
            plugin: 'firebase_functions',
            code: 'not-found',
            message: 'NOT_FOUND',
          ),
        ),
        isTrue,
      );
    });

    test('unavailable means the Functions backend is unreachable', () {
      expect(
        AdminSession.isFunctionsUnavailable(
          FirebaseException(
            plugin: 'firebase_functions',
            code: 'unavailable',
            message: 'UNAVAILABLE',
          ),
        ),
        isTrue,
      );
    });

    test('the data source unavailable signal counts too', () {
      expect(
        AdminSession.isFunctionsUnavailable(
          Exception('Admin functions are unavailable right now.')),
        isTrue,
      );
    });

    test('other errors stay on the TOTP step', () {
      expect(
        AdminSession.isFunctionsUnavailable(
          FirebaseException(
            plugin: 'firebase_functions',
            code: 'permission-denied',
            message: 'PERMISSION_DENIED',
          ),
        ),
        isFalse,
      );
      expect(
        AdminSession.isFunctionsUnavailable(Exception('boom')),
        isFalse,
      );
    });
  });
}
