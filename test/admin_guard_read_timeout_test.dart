import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/admin/data/services/admin_session.dart';

/// Covers the splash-hang fix (2026-11-10): a Firestore read for the
/// router guard must never hang the route. After a tab is backgrounded
/// the connection can go stale and a server read may never answer, so
/// the guard's reads are bounded — a read that never answers resolves
/// to null within the timeout instead of holding the splash screen
/// forever.
void main() {
  group('AdminSession.guardRead', () {
    test('a read that never answers resolves to null within the timeout',
        () async {
      final stopwatch = Stopwatch()..start();
      final result = await AdminSession.guardRead<String>(
        () => Completer<String>().future,
      );
      stopwatch.stop();
      expect(result, isNull);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
    });

    test('a throwing read resolves to null', () async {
      final result = await AdminSession.guardRead<String>(
        () => Future<String>.error(Exception('boom')),
      );
      expect(result, isNull);
    });

    test('a healthy read passes its value through', () async {
      final result = await AdminSession.guardRead<String>(
        () => Future.value('super_admin'),
      );
      expect(result, 'super_admin');
    });
  });
}
