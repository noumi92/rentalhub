import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';

/// Audit impl (O49): the signed-out state — "You have been signed
/// out" with a "Sign In Again" button back to the login screen.
/// Reached after the sign-out confirmation (see
/// [showSignOutConfirmDialog]); it is a plain state screen, not
/// the sign-in form itself.
class OwnerSignedOutView extends StatelessWidget {
  const OwnerSignedOutView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.signOutSignedOutTitle,
              onBack: () => context.go(RouteNames.auth),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.signOutSignedOutTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.signOutSignedOutBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    DebouncedButton(
                      text: l10n.signOutSignInAgain,
                      onPressed: () => context.go(RouteNames.auth),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
