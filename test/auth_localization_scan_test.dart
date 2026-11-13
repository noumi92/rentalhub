// Audit 2026-11-13, SH-M4 — `AppLocalizations.of(context)!` force-unwrap.
//
// The force-unwrap is the exact pattern behind the CI #47 LoginView
// crash (null-check when delegates are missing). The safe pattern is
// `AppLocalizations.of(context)?.x ?? '<fallback>'`, which the shared
// widgets already use. The cap is 0 in lib/core/ + lib/features/auth/
// — the login and shared-widget scope of this fix. (The 300-file
// repo-wide count is out of scope for this item.)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  test('no AppLocalizations.of(context)! in lib/core/ or lib/features/auth/ (SH-M4)', () {
    const scopes = ['lib/core', 'lib/features/auth'];
    final offenders = <String>[];
    for (final dir in scopes) {
      for (final file in _dartFiles(dir)) {
        final matches = RegExp(r'AppLocalizations\.of\(context\)!')
            .allMatches(file.readAsStringSync())
            .length;
        if (matches > 0) offenders.add('${file.path} ($matches)');
      }
    }
    expect(offenders, isEmpty,
        reason:
            'Force-unwrapped localizations survive (SH-M4) — use AppLocalizations.of(context)?.x ?? \'<fallback>\':\n${offenders.join('\n')}');
  });
}
