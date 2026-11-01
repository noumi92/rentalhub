import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestHarness {
  /// Pumps a widget inside an overflow guard that checks small viewports
  /// (e.g. 360x640) and scaled text factors (e.g. 1.35x) to catch RenderFlex overflows.
  static Future<void> pumpScreenWithOverflowCheck({
    required WidgetTester tester,
    required Widget screen,
    double width = 360.0,
    double height = 640.0,
    double textScale = 1.35,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ThemeData.light(useMaterial3: true),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify zero overflow exceptions were thrown during layout
    expect(tester.takeException(), isNull);
  }
}

