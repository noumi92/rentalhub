// Audit 2026-11-13, SH-C1 (Critical) — the demo-identity auth fallback.
//
// `AuthRemoteDataSource` used to sign any credentials in as a hardcoded
// demo identity when FirebaseAuth was unavailable. The fallback defaults
// are deleted and both sign-in methods fail closed; this scan makes
// sure the demo identity can never come back into lib/ — the same
// pattern as the `password123` scan in test/ui_dark_mode_test.dart
// (which scans lib/ only, so this file's own literals do not trip it).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  group('SH-C1 — no demo identity in lib/', () {
    test('no hardcoded demo uid or demo email anywhere in lib/', () {
      final offenders = <String>[];
      for (final file in _dartFiles('lib')) {
        final content = file.readAsStringSync();
        final hits = <String>[];
        if (content.contains('usr_pk_001')) hits.add('usr_pk_001');
        if (content.contains('ahmed.raza@rentalhub.pk')) {
          hits.add('ahmed.raza@rentalhub.pk');
        }
        if (hits.isNotEmpty) offenders.add('${file.path}: ${hits.join(', ')}');
      }
      expect(offenders, isEmpty,
          reason:
              'Demo-identity fallback (SH-C1) is back in lib/ — sign-in must fail closed when FirebaseAuth is unavailable:\n${offenders.join('\n')}');
    });

    test('both sign-in methods fail closed when FirebaseAuth is null', () {
      final source = File(
        'lib/features/auth/data/datasources/auth_remote_data_source.dart',
      ).readAsStringSync();
      expect(source, contains("throw const ServerException(message: 'Authentication unavailable')"));
      // No sign-in path may start from a demo default.
      expect(source, isNot(contains("?? 'usr_pk_001'")));
      expect(source, isNot(contains("= 'usr_pk_001'")));
      expect(source, isNot(contains('ahmed.raza@rentalhub.pk')));
    });

    test('LoginView treats an unregistered data source as an error, never success', () {
      final login = File('lib/features/auth/presentation/views/login_view.dart')
          .readAsStringSync();
      expect(login, contains('!sl.isRegistered<AuthRemoteDataSource>()'));
      // The old shape — call-if-registered, then show success anyway —
      // must not come back.
      expect(login, isNot(contains('if (sl.isRegistered<AuthRemoteDataSource>()) {')));
    });

    test('main.dart fails visibly when Firebase init fails', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('_FirebaseInitFailedApp'));
      expect(main, isNot(contains("debugPrint('Firebase initialization notice: \$e')")));
    });
  });
}
