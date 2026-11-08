// Phone-test #16 (design direction) — one header system, redesigned.
//
// Rulebook §4.3: every screen except login uses `MinimalAppBar` — a
// flat solid-navy bar, 56 px of content below the status-bar inset,
// bold white title 18 sp / w900, subtitle 12 sp white 70%. No curve,
// no gradient, no overlap, no shadow. `CustomCurvedHeader` survives
// only for the login hero (230 px, curved, gradient, -28 px overlap);
// every other call site is a violation.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/custom_curved_header.dart';
import 'package:rentalhub/core/widgets/minimal_app_bar.dart';

import 'test_helper.dart';

/// The top-level (depth-1) argument text of the constructor call whose
/// opening paren is at [openParenIndex] in [source]. Nested widget
/// arguments sit at depth > 1 and are excluded, so only direct
/// constructor arguments are scanned.
String _topLevelArgs(String source, int openParenIndex) {
  final buf = StringBuffer();
  var depth = 0;
  for (var i = openParenIndex; i < source.length; i++) {
    final c = source[i];
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      depth--;
      if (depth == 0) break;
    } else if (depth == 1) {
      buf.write(c);
    }
  }
  return buf.toString();
}

void main() {
  group('#16 — only login still uses the curved header', () {
    test('no CustomCurvedHeader call site except login (and the definition)',
        () {
      const allowed = {
        'lib/core/widgets/custom_curved_header.dart',
        'lib/features/auth/presentation/views/login_view.dart',
      };
      final violations = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = file.path.replaceAll(r'\', '/');
        if (allowed.contains(path)) continue;
        final source = file.readAsStringSync();
        if (RegExp(r'CustomCurvedHeader\s*\(').hasMatch(source)) {
          violations.add('$path: still uses CustomCurvedHeader');
        }
      }
      expect(violations, isEmpty,
          reason: 'Every screen except login must use MinimalAppBar.\n'
              '${violations.join('\n')}');
    });

    test('no MinimalAppBar call site passes a variant: or height:', () {
      final violations = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = file.path.replaceAll(r'\', '/');
        final source = file.readAsStringSync();
        for (final m in RegExp(r'MinimalAppBar\s*\(').allMatches(source)) {
          final topLevel = _topLevelArgs(source, m.end - 1);
          if (RegExp(r'(^|[\s,])(variant|height)\s*:').hasMatch(topLevel)) {
            violations.add('$path: MinimalAppBar passes variant:/height:');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'MinimalAppBar takes title/subtitle/actions/onBack only.\n'
              '${violations.join('\n')}');
    });

    test('login hero tokens are the rulebook §4.3 values', () {
      expect(AppColors.primaryDark, const Color(0xFF16194F));
      expect(AppColors.headerGradientEnd, const Color(0xFF242875));
      expect(AppColors.primaryDarkOnDark, const Color(0xFF0B0D26));
      expect(AppDimensions.headerHeight, 230.0);
      expect(AppDimensions.headerCompactHeight, 100.0);
      expect(AppDimensions.headerOverlapOffset, -28.0);
    });
  });

  group('#16 — MinimalAppBar renders the rulebook §4.3 bar', () {
    Container barContainer(WidgetTester tester) {
      return tester.widget<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == AppColors.primaryDark,
        ),
      );
    }

    testWidgets('flat primaryDark bar, 56 px content, no back at a root',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: const Scaffold(
          body: MinimalAppBar(title: 'Requests', subtitle: '3 waiting'),
        ),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('3 waiting'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
      final container = barContainer(tester);
      // No curve, gradient, or shadow: a plain colour, nothing else.
      expect(container.decoration, isNull);
      expect(tester.getSize(find.byWidget(container)).height, 56);
      final title = tester.widget<Text>(find.text('Requests'));
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w900);
      expect(title.style?.color, Colors.white);
      final subtitle = tester.widget<Text>(find.text('3 waiting'));
      expect(subtitle.style?.fontSize, 12);
      expect(subtitle.style?.color, Colors.white70);
    });

    testWidgets('no subtitle renders a single-line bar', (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: const Scaffold(
          body: MinimalAppBar(title: 'Wallet'),
        ),
        theme: AppTheme.lightTheme,
      );
      expect(find.text('Wallet'), findsOneWidget);
      expect(tester.getSize(find.byWidget(barContainer(tester))).height, 56);
    });

    testWidgets('status-bar inset adds to the 56 px content height',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(360, 640),
              padding: EdgeInsets.only(top: 24),
            ),
            child: Scaffold(
              body: MinimalAppBar(title: 'Bar'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byWidget(barContainer(tester))).height,
          56 + 24);
    });

    testWidgets('actions render and stay tappable', (tester) async {
      var tapped = false;
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: Scaffold(
          body: MinimalAppBar(
            title: 'Fleet',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => tapped = true,
              ),
            ],
          ),
        ),
        theme: AppTheme.lightTheme,
      );
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      expect(tapped, isTrue);
    });

    testWidgets('login hero still renders the curved header', (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: const CustomCurvedHeader(
          variant: CustomCurvedHeaderVariant.hero,
          titleWidget: Text('RentalHub'),
        ),
        theme: AppTheme.lightTheme,
      );
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ClipRRect),
          matching: find.byType(Container),
        ),
      );
      expect(
        (container.constraints as BoxConstraints).minHeight,
        AppDimensions.headerHeight,
      );
    });
  });
}
