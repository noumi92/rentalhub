// F-M13: the maintenance notice extracted from SplashView so the
// view stays under the 250-line cap — the notice itself must keep
// rendering the title, body and retry action, and the retry must
// stay disabled while a re-check is in flight.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentalhub/features/auth/presentation/widgets/maintenance_notice.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  testWidgets('maintenance notice shows title, body and retry',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MaintenanceNotice(onRetry: () => retried = true),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Under maintenance'), findsOneWidget);
    expect(find.textContaining('under maintenance right now'),
        findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('retry is disabled while checking', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MaintenanceNotice(onRetry: () {}, isChecking: true),
    ));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
