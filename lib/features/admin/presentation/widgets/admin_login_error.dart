import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';

/// AD-m4: login errors surface a localised friendly string, never the
/// raw exception text. The raw error is logged for debugging and
/// otherwise discarded. Extracted from AdminLoginView so the view
/// stays under the 250-line cap.
String adminLoginFriendlyError(Object e, AppLocalizations? l10n) {
  debugPrint('Admin sign-in error: $e');
  final generic =
      l10n?.admin2_signInFailedGeneric ?? 'Sign-in failed. Try again.';
  final code = e is FirebaseException ? e.code : '';
  final text = e.toString();
  bool matches(List<String> needles) =>
      needles.any((n) => code.contains(n) || text.contains(n));
  if (matches([
    'invalid-credential',
    'INVALID_LOGIN_CREDENTIALS',
    'wrong-password',
    'user-not-found',
  ])) {
    return l10n?.admin2_signInWrongCredentials ??
        'The email or password is incorrect.';
  }
  if (matches(['user-disabled'])) {
    return l10n?.admin2_signInAccountDisabled ??
        'This account is disabled. Ask a super admin for help.';
  }
  if (matches(['too-many-requests'])) {
    return l10n?.admin2_signInTooManyAttempts ??
        'Too many sign-in attempts. Try again later.';
  }
  if (matches(['invalid-email'])) {
    return l10n?.admin2_signInInvalidEmail ??
        'Enter a valid email address.';
  }
  if (matches([
    'network-request-failed',
    'unavailable',
    'deadline-exceeded',
  ])) {
    return l10n?.admin2_signInNoConnection ??
        'Could not reach the server. Check your connection and try again.';
  }
  return generic;
}
