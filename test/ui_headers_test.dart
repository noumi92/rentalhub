// Phase D (D1) — one header system.
//
// Rulebook §4.3 defines exactly two header heights: hero 230 (screens
// whose hero card overlaps the header) and compact 100 (every
// title-only screen). Call sites pass a `variant:`, never a `height:`.
// The base gradient is #16194F → #242875 (light) / #0B0D26 → #16194F
// (dark), and hero cards overlap the header by -28.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/custom_curved_header.dart';

import 'test_helper.dart';

/// The top-level (depth-1) argument text of the constructor call whose
/// opening paren is at [openParenIndex] in [source]. Nested widget
/// arguments — e.g. `SizedBox(height: ...)` inside titleWidget — sit at
/// depth > 1 and are excluded, so only direct constructor arguments
/// are scanned.
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

/// The header's own CustomPaint — not the debug banner's: the one whose
/// painter is a [CurvedGradientHeaderPainter]. `find.byType(CustomPaint)`
/// also matches the DEBUG banner, so widget lookups must use this.
Finder get _headerPaint => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is CurvedGradientHeaderPainter,
    );

void main() {
  group('D1 — no per-call-site header heights', () {
    test('no CustomCurvedHeader call site passes a height: argument',
        () {
      final violations = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = file.path.replaceAll(r'\', '/');
        // The widget definition itself, not a call site.
        if (path == 'lib/core/widgets/custom_curved_header.dart') continue;
        final source = file.readAsStringSync();
        for (final m
            in RegExp(r'CustomCurvedHeader\s*\(').allMatches(source)) {
          final topLevel = _topLevelArgs(source, m.end - 1);
          if (RegExp(r'(^|[\s,])height\s*:').hasMatch(topLevel)) {
            violations.add('$path: CustomCurvedHeader still passes height:');
          }
        }
      }
      expect(violations, isEmpty,
          reason:
              'Call sites must pass variant:, never height:.\n${violations.join('\n')}');
    });

    test('every CustomCurvedHeader call site passes a variant', () {
      final violations = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = file.path.replaceAll(r'\', '/');
        if (path == 'lib/core/widgets/custom_curved_header.dart') continue;
        final source = file.readAsStringSync();
        for (final m
            in RegExp(r'CustomCurvedHeader\s*\(').allMatches(source)) {
          final topLevel = _topLevelArgs(source, m.end - 1);
          if (!topLevel.contains('variant:')) {
            violations.add('$path: CustomCurvedHeader has no variant:');
          }
        }
      }
      expect(violations, isEmpty,
          reason:
              'Every call site must pass variant: hero or compact.\n${violations.join('\n')}');
    });

    test('header tokens are the rulebook §4.3 values', () {
      expect(AppColors.primaryDark, const Color(0xFF16194F));
      expect(AppColors.headerGradientEnd, const Color(0xFF242875));
      expect(AppColors.primaryDarkOnDark, const Color(0xFF0B0D26));
      expect(AppDimensions.headerHeight, 230.0);
      expect(AppDimensions.headerCompactHeight, 100.0);
      expect(AppDimensions.headerOverlapOffset, -28.0);
    });
  });

  group('D1 — header variants render the rulebook heights', () {
    testWidgets('hero variant is 230 high in both themes', (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await TestHarness.pumpScreenWithOverflowCheck(
          tester: tester,
          screen: const CustomCurvedHeader(
            variant: CustomCurvedHeaderVariant.hero,
            titleWidget: Text('Hero'),
          ),
          theme: theme,
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
      }
    });

    testWidgets('compact variant is 100 high in both themes',
        (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await TestHarness.pumpScreenWithOverflowCheck(
          tester: tester,
          screen: const CustomCurvedHeader(
            variant: CustomCurvedHeaderVariant.compact,
            titleWidget: Text('Compact'),
          ),
          theme: theme,
        );
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byType(ClipRRect),
            matching: find.byType(Container),
          ),
        );
        expect(
          (container.constraints as BoxConstraints).minHeight,
          AppDimensions.headerCompactHeight,
        );
      }
    });

    testWidgets('variant defaults to hero', (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: const CustomCurvedHeader(titleWidget: Text('Default')),
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

    testWidgets('hero header reserves status-bar padding plus 10',
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
              body: CustomCurvedHeader(
                variant: CustomCurvedHeaderVariant.hero,
                titleWidget: Text('Hero'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ClipRRect),
          matching: find.byType(Container),
        ),
      );
      expect(
        (container.constraints as BoxConstraints).minHeight,
        AppDimensions.headerHeight + 24,
      );
      final padding = tester.widget<Padding>(
        find.descendant(
          of: _headerPaint,
          matching: find.byType(Padding),
        ),
      );
      expect(padding.padding.resolve(TextDirection.ltr).top, 24 + 10);
    });

    testWidgets('header paints the light gradient in light mode and '
        'the dark gradient in dark mode', (tester) async {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        await TestHarness.pumpScreenWithOverflowCheck(
          tester: tester,
          screen: const CustomCurvedHeader(
            variant: CustomCurvedHeaderVariant.hero,
            titleWidget: Text('Hero'),
          ),
          theme: theme,
        );
        final paint = tester.widget<CustomPaint>(_headerPaint);
        final painter = paint.painter as CurvedGradientHeaderPainter;
        expect(painter.isDark, theme.brightness == Brightness.dark);
      }
    });
  });

  group('D1 — hero card overlap', () {
    testWidgets('HeaderOverlapContainer translates its child by -28px',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: const HeaderOverlapContainer(
          child: SizedBox(width: 50, height: 50),
        ),
      );
      final transform =
          tester.widget<Transform>(find.byType(Transform));
      final translation = transform.transform.getTranslation();
      expect(translation.x, 0.0);
      expect(translation.y, AppDimensions.headerOverlapOffset);
      expect(translation.y, -28.0);
    });
  });
}
