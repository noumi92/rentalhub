import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/debounced_button.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// User decision 2026-11-09: button labels use smaller regular text —
// never bold. Primary (elevated/filled) labels are 14sp w400;
// secondary (outlined/text) labels are 12sp w400. The button themes
// own the sizes; hardcoded bold label styles in views were removed
// in the same change, so a plain button label inherits the theme.

TextStyle? _buttonTextStyle(ButtonStyle? style) =>
    style?.textStyle?.resolve(<WidgetState>{});

void main() {
  group('button label theme', () {
    test('primary buttons (elevated/filled) use 14sp regular labels', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        for (final style in [
          theme.elevatedButtonTheme.style,
          theme.filledButtonTheme.style,
        ]) {
          final textStyle = _buttonTextStyle(style);
          expect(textStyle, isNotNull);
          expect(textStyle!.fontSize, 14);
          expect(textStyle.fontWeight, FontWeight.w400);
        }
      }
    });

    test('secondary buttons (outlined/text) use 12sp regular labels', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        for (final style in [
          theme.outlinedButtonTheme.style,
          theme.textButtonTheme.style,
        ]) {
          final textStyle = _buttonTextStyle(style);
          expect(textStyle, isNotNull);
          expect(textStyle!.fontSize, 12);
          expect(textStyle.fontWeight, FontWeight.w400);
        }
      }
    });
  });

  testWidgets('DebouncedButton label is 14sp regular', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DebouncedButton(
            text: 'Save changes',
            onPressed: () {},
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Save changes'));
    expect(label.style, isNotNull);
    expect(label.style!.fontSize, 14);
    expect(label.style!.fontWeight, FontWeight.w400);
  });

  testWidgets('plain ElevatedButton label carries no hardcoded style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ElevatedButton(
            onPressed: () {},
            child: const Text('Go'),
          ),
        ),
      ),
    );

    // No inline style: the 14sp regular theme style applies.
    expect(tester.widget<Text>(find.text('Go')).style, isNull);
  });

  test('no bold weight remains inside a button label in the changed files',
      () {
    // Every file this change touched. The scan finds each
    // ElevatedButton/TextButton/OutlinedButton/FilledButton/
    // DebouncedButton constructor span (balanced parens) and fails if
    // a w700/w800/w900 weight sits inside it. Bold text elsewhere
    // (headings, prices, status labels) is out of scope and untouched.
    const changedFiles = [
      'lib/core/theme/app_theme.dart',
      'lib/core/widgets/app_feedback.dart',
      'lib/core/widgets/debounced_button.dart',
      'lib/features/admin/presentation/views/admin_blacklist_tribunal_view.dart',
      'lib/features/auth/presentation/views/widgets/google_sign_in_button.dart',
      'lib/features/auth/presentation/views/widgets/profile_avatar_picker.dart',
      'lib/features/discovery/presentation/views/shop_detail_view.dart',
      'lib/features/discovery/presentation/views/widgets/location_permission_dialog.dart',
      'lib/features/discovery/presentation/views/widgets/map_shop_preview_card.dart',
      'lib/features/discovery/presentation/views/widgets/shop_list_card.dart',
      'lib/features/discovery/presentation/views/widgets/vehicle_detail_action_bar.dart',
      'lib/features/owner/presentation/views/owner_notifications_view.dart',
      'lib/features/owner/presentation/widgets/dashboard/subscription_tier_card.dart',
      'lib/features/owner/presentation/widgets/onboarding/shop_approval_status_step_widget.dart',
      'lib/features/owner/presentation/widgets/onboarding/shop_details_step_widget.dart',
      'lib/features/owner/presentation/widgets/onboarding/shop_location_step_widget.dart',
      'lib/features/owner/presentation/widgets/operations/request_triage_card.dart',
      'lib/features/bookings/presentation/views/booking_success_view.dart',
      'lib/features/customer/presentation/widgets/booking_ticket_card.dart',
      'lib/features/owner/presentation/views/owner_booking_confirmed_view.dart',
      'lib/features/owner/presentation/widgets/operations/requested_booking_detail.dart',
    ];
    final boldInButton = <String>[];
    for (final path in changedFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path must exist');
      final hits = _boldButtonLabels(file.readAsStringSync());
      boldInButton.addAll(hits.map((line) => '$path:$line'));
    }
    expect(
      boldInButton,
      isEmpty,
      reason: 'Bold button labels remain: ${boldInButton.join(', ')}',
    );
  });
}

final _buttonCtor = RegExp(
  r'\b(?:ElevatedButton|TextButton|OutlinedButton|FilledButton|DebouncedButton)(?:\.icon)?\s*\(',
);
final _boldWeight = RegExp(
  r'fontWeight:\s*FontWeight\.(w700|w800|w900|bold)\b',
);

/// Line numbers of bold weights found inside a button constructor span.
List<int> _boldButtonLabels(String source) {
  final hits = <int>[];
  for (final match in _buttonCtor.allMatches(source)) {
    final open = match.end - 1;
    final close = _matchingParen(source, open);
    final span = source.substring(open, close);
    for (final bold in _boldWeight.allMatches(span)) {
      final offset = open + bold.start;
      hits.add('\n'.allMatches(source.substring(0, offset)).length + 1);
    }
  }
  return hits;
}

/// Index just past the ')' matching the '(' at [open].
/// Strings and line comments are skipped so parens inside them
/// do not count.
int _matchingParen(String source, int open) {
  var depth = 0;
  var i = open;
  while (i < source.length) {
    final ch = source[i];
    if (ch == "'" || ch == '"') {
      final quote = source.startsWith(ch * 3, i) ? ch * 3 : ch;
      i += quote.length;
      while (i < source.length && !source.startsWith(quote, i)) {
        if (source[i] == '\\') i++;
        i++;
      }
      i += quote.length;
      continue;
    }
    if (ch == '/' && i + 1 < source.length && source[i + 1] == '/') {
      final nl = source.indexOf('\n', i);
      i = nl == -1 ? source.length : nl;
      continue;
    }
    if (ch == '(') depth++;
    if (ch == ')') {
      depth--;
      if (depth == 0) return i + 1;
    }
    i++;
  }
  return source.length;
}
