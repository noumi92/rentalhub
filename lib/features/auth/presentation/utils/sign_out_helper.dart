import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/repositories/auth_repository.dart';

/// Phone-test #9: the single sign-out path for every settings/profile
/// screen. The old router callbacks called `FirebaseAuth.signOut()`
/// directly with no try/catch and no feedback, so a throw left the
/// user exactly where they were with no message, and the
/// `await` + `context.mounted` check silently skipped navigation when
/// the widget unmounted mid-sign-out.
///
/// This helper routes through the repository `signOut()` (which
/// already catches Firebase errors), shows visible feedback on
/// failure, and navigates on success — through the calling context
/// when it is still mounted, otherwise through the root router, so
/// the user always lands on the login screen.
Future<void> signOutToAuth(BuildContext context) async {
  try {
    await sl<AuthRepository>().signOut();
  } catch (e) {
    if (context.mounted) {
      AppFeedback.showError(
        context,
        'Could not sign out. Please try again.',
      );
    }
    return;
  }
  if (context.mounted) {
    context.go(RouteNames.auth);
  } else {
    AppRouter.router.go(RouteNames.auth);
  }
}
