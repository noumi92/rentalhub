// Team H — audit 2026-11-15 fix batch: DS-1, DS-5, DS-6.
//
// DS-5: raw `${d.day}/${d.month}/${d.year}` dates are ambiguous and
// locale-blind; every UI date now goes through the shared helper in
// `lib/core/utils/date_format.dart` (or an explicit locale-aware
// `DateFormat`). The scan below fails if a raw date comes back.
// DS-6: the 11 owner screens that showed `dashboardLoadError` for
// non-dashboard loads now use a dedicated per-screen key; the raw
// error is only ever `debugPrint`ed, never shown.
// DS-1: the selected-chip fill/label come from `chipTheme` (navy +
// white); the three Team H files carry no per-file override.
//
// The DS-3 ratchet (core+auth `AppLocalizations.of(context)!` = 0)
// already lives in `test/auth_localization_scan_test.dart` (SH-M4);
// the DS-7 scale scan lives in `test/ui_phase_a_typography_test.dart`.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rentalhub/core/utils/date_format.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

String _posix(String path) => path.replaceAll(r'\', '/');

List<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  group('DS-5 — localized dates', () {
    test('no raw d/m/y date interpolation in lib/features/', () {
      final offenders = <String>[];
      for (final file in _dartFiles('lib/features')) {
        final path = _posix(file.path);
        final matches = RegExp(r'\.day\}/\${')
            .allMatches(file.readAsStringSync())
            .length;
        if (matches > 0) offenders.add('$path ($matches)');
      }
      expect(offenders, isEmpty,
          reason:
              'Raw d/m/y dates survive (DS-5) — use formatDate/formatDateTime/formatDayTime from lib/core/utils/date_format.dart:\n${offenders.join('\n')}');
    });

    test('no hardcoded-\'en\' day/time format in lib/ (outside the PDFs)',
        () {
      // The three PDF generators pin DateFormat.yMMMd('en') on purpose
      // (legal documents generated in English, no BuildContext) — that
      // is the unambiguous form, not the hardcoded-'en' UI pattern.
      final offenders = <String>[];
      for (final file in _dartFiles('lib')) {
        final path = _posix(file.path);
        if (path.startsWith('lib/l10n/')) continue;
        if (RegExp(r"DateFormat\('d MMM, h:mm a', 'en'\)")
            .hasMatch(file.readAsStringSync())) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty,
          reason:
              'Hardcoded-\'en\' date format survives (DS-5) — pass the locale explicitly or use the date_format helper:\n${offenders.join('\n')}');
    });

    testWidgets('date helper renders a localized month name, EN + UR, 360px',
        (tester) async {
      await initializeDateFormatting('ur');
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<String> pump(Locale locale) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates:
                AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) {
                final date = DateTime(2026, 11, 5, 14, 30);
                return Column(
                  children: [
                    Text(formatDate(context, date)),
                    Text(formatDateTime(context, date)),
                    Text(formatDayTime(context, date)),
                  ],
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' | ');
      }

      final en = await pump(const Locale('en'));
      expect(en, contains('Nov 5, 2026'),
          reason: 'EN date must carry a month name, not 5/11/2026: $en');
      expect(en, isNot(contains('5/11/2026')));

      final ur = await pump(const Locale('ur'));
      expect(ur, isNot(contains('5/11/2026')),
          reason: 'UR date must never render raw d/m/y: $ur');
      // Non-raw string so the \u escapes resolve to the Arabic block
      // without any Arabic-script literal in this file.
      expect(ur.contains(RegExp('[\u0600-\u06FF]')), isTrue,
          reason: 'UR date must carry a localized (Urdu-script) month '
              'name: $ur');
    });
  });

  group('DS-6 — per-screen load errors', () {
    test('dashboardLoadError is used only by the dashboard', () {
      const allowed = {
        'lib/features/owner/presentation/views/owner_dashboard_view.dart',
      };
      final offenders = <String>[];
      for (final file in _dartFiles('lib')) {
        final path = _posix(file.path);
        if (path.startsWith('lib/l10n/') || allowed.contains(path)) {
          continue;
        }
        if (file.readAsStringSync().contains('dashboardLoadError')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty,
          reason:
              'dashboardLoadError is shown for a non-dashboard load (DS-6):\n${offenders.join('\n')}');
    });

    test('each fixed screen uses its own load-error key', () {
      const expected = {
        'lib/features/owner/presentation/views/owner_finance_view.dart':
            'financeLoadError',
        'lib/features/owner/presentation/views/owner_car_pnl_view.dart':
            'carPnlLoadError',
        'lib/features/owner/presentation/views/owner_cash_closing_view.dart':
            'cashClosingLoadError',
        'lib/features/owner/presentation/views/owner_disputes_view.dart':
            'disputesLoadError',
        'lib/features/owner/presentation/views/owner_customer_statement_view.dart':
            'customerStatementLoadError',
        'lib/features/owner/presentation/views/owner_finance_settings_view.dart':
            'financeSettingsLoadError',
        'lib/features/owner/presentation/views/owner_finance_categories_view.dart':
            'financeCategoriesLoadError',
        'lib/features/owner/presentation/views/owner_staff_roles_view.dart':
            'staffRolesLoadError',
        'lib/features/owner/presentation/views/owner_reports_view.dart':
            'reportsLoadError',
        'lib/features/owner/presentation/views/owner_whatsapp_credits_view.dart':
            'whatsappCreditsLoadError',
        'lib/features/owner/presentation/views/owner_whatsapp_history_view.dart':
            'whatsappHistoryLoadError',
      };
      for (final entry in expected.entries) {
        final content = File(entry.key).readAsStringSync();
        expect(content, contains(entry.value),
            reason: '${entry.key} must use its own ${entry.value} key.');
        expect(content, isNot(contains('dashboardLoadError')),
            reason: '${entry.key} still shows dashboardLoadError.');
      }
    });

    test('no fixed screen logs its load error to the user via e.toString()',
        () {
      // The raw error is debugPrinted for diagnostics only; the UI
      // shows the localized key. (DS-13's owner_return_settlement
      // site is Team I's scope, not checked here.)
      const files = [
        'lib/features/owner/presentation/views/owner_finance_view.dart',
        'lib/features/owner/presentation/views/owner_car_pnl_view.dart',
        'lib/features/owner/presentation/views/owner_cash_closing_view.dart',
        'lib/features/owner/presentation/views/owner_disputes_view.dart',
        'lib/features/owner/presentation/views/owner_customer_statement_view.dart',
        'lib/features/owner/presentation/views/owner_finance_settings_view.dart',
        'lib/features/owner/presentation/views/owner_finance_categories_view.dart',
        'lib/features/owner/presentation/views/owner_staff_roles_view.dart',
        'lib/features/owner/presentation/views/owner_reports_view.dart',
        'lib/features/owner/presentation/views/owner_whatsapp_credits_view.dart',
        'lib/features/owner/presentation/views/owner_whatsapp_history_view.dart',
      ];
      for (final path in files) {
        final content = File(path).readAsStringSync();
        expect(content, contains('debugPrint('),
            reason: '$path must log its load failure for diagnostics.');
        expect(content, isNot(contains('e.toString()')),
            reason: '$path must not interpolate e.toString() into a shown string.');
      }
    });
  });

  group('DS-1 — selected chips inherit the theme (Team H files)', () {
    test('no selectedColor/labelStyle override in the three Team H files',
        () {
      const files = [
        'lib/features/owner/presentation/views/owner_whatsapp_history_view.dart',
        'lib/features/owner/presentation/views/owner_disputes_view.dart',
        'lib/features/owner/presentation/widgets/finance/finance_ledger_section.dart',
      ];
      for (final path in files) {
        final content = File(path).readAsStringSync();
        expect(content, isNot(contains('selectedColor:')),
            reason: '$path must inherit the navy selected fill from chipTheme (DS-1).');
        expect(content, isNot(contains('labelStyle:')),
            reason: '$path must inherit the selected label style from chipTheme (DS-1).');
      }
    });
  });
}
