import 'package:flutter/foundation.dart';

/// Testable seam for platform checks.
///
/// Production reads [kIsWeb]: the web build is the admin panel, while
/// the mobile app is customer + owner. Tests override [isWebOverride]
/// to simulate the web build — kIsWeb is false under flutter test, so
/// a web routing decision based on it directly would be untestable.
abstract final class AppPlatform {
  static bool? _isWebOverride;

  static bool get isWeb => _isWebOverride ?? kIsWeb;

  @visibleForTesting
  static set isWebOverride(bool? value) => _isWebOverride = value;

  @visibleForTesting
  static void resetOverrides() => _isWebOverride = null;
}
