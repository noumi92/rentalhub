import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Test harness for Pakistani automotive UI & platform mocking.
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
    Locale? locale,
    List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
    List<Locale>? supportedLocales,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;

    FlutterErrorDetails? caughtDetails;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      caughtDetails = details;
      originalOnError?.call(details);
    };

    try {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          theme: theme ?? ThemeData.light(useMaterial3: true),
          localizationsDelegates: localizationsDelegates,
          supportedLocales:
              supportedLocales ?? const <Locale>[Locale('en')],
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

      final exception = tester.takeException();
      if (exception != null) {
        if (caughtDetails != null) {
          debugPrint('EXACT OVERFLOW CAUSE:\n${caughtDetails!.summary}');
          debugPrint('CONTEXT: ${caughtDetails!.context}');
          for (final line in caughtDetails!.informationCollector?.call() ?? <DiagnosticsNode>[]) {
            debugPrint('INFO: $line');
          }
        } else {
          debugPrint('DETAILED FLUTTER ERROR:\n$exception');
        }
      }
      expect(exception, isNull);
    } finally {
      FlutterError.onError = originalOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }

  /// Evaluates screen against multiple Pakistani mobile viewports and font scales:
  /// - 320 x 568 (compact entry device) at 1.25x scale
  /// - 360 x 640 (standard Pakistani Android) at 1.35x scale
  /// - 412 x 915 (large modern screen) at 1.5x scale
  static Future<void> pumpScreenMultiViewport({
    required WidgetTester tester,
    required Widget screen,
    ThemeData? theme,
    Locale? locale,
    List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
    List<Locale>? supportedLocales,
  }) async {
    final viewports = [
      const _ViewportConfig(width: 320, height: 568, scale: 1.25),
      const _ViewportConfig(width: 360, height: 640, scale: 1.35),
      const _ViewportConfig(width: 412, height: 915, scale: 1.5),
    ];

    for (final config in viewports) {
      await pumpScreenWithOverflowCheck(
        tester: tester,
        screen: screen,
        width: config.width,
        height: config.height,
        textScale: config.scale,
        theme: theme,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
      );
    }
  }
}

class _ViewportConfig {
  final double width;
  final double height;
  final double scale;

  const _ViewportConfig({
    required this.width,
    required this.height,
    required this.scale,
  });
}

/// Mock platform interface for ImagePicker to test hardware camera & gallery behaviors.
class MockImagePickerPlatform extends ImagePickerPlatform {
  static ImagePickerPlatform? _originalPlatform;
  static late MockImagePickerPlatform activeMock;

  XFile? mockResult;
  ImageSource? lastSource;
  CameraDevice? lastCameraDevice;
  int? lastImageQuality;
  bool shouldThrow = false;
  int callCount = 0;

  static MockImagePickerPlatform setup() {
    _originalPlatform = ImagePickerPlatform.instance;
    activeMock = MockImagePickerPlatform();
    ImagePickerPlatform.instance = activeMock;
    return activeMock;
  }

  static void tearDown() {
    if (_originalPlatform != null) {
      ImagePickerPlatform.instance = _originalPlatform!;
      _originalPlatform = null;
    }
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    callCount++;
    lastSource = source;
    lastCameraDevice = options.preferredCameraDevice;
    lastImageQuality = options.imageQuality;

    if (shouldThrow) {
      throw PlatformException(
        code: 'camera_access_denied',
        message: 'The user has denied camera access permissions.',
      );
    }

    return mockResult;
  }
}
