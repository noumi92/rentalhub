import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// The admin login's credentials form, extracted from AdminLoginView
/// so the view stays under the 250-line cap: email + password fields,
/// the error line, and the sign-in button.
class AdminLoginForm extends StatefulWidget {
  const AdminLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isWorking,
    required this.error,
    required this.onSignIn,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isWorking;
  final String? error;
  final VoidCallback onSignIn;

  @override
  State<AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends State<AdminLoginForm> {
  // AD-m5: the password field has the standard visibility toggle.
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n?.admin2_loginFormTitle ?? 'RentalHub Admin',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 8),
        Text(l10n?.admin2_loginFormSubtitle ?? 'Sign in with your admin account.',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        TextField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration(context, l10n?.admin2_loginFormEmail ?? 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          decoration: _decoration(context, l10n?.admin2_loginFormPassword ?? 'Password').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              tooltip: _obscurePassword
                  ? l10n?.admin2_showPassword ?? 'Show password'
                  : l10n?.admin2_hidePassword ?? 'Hide password',
              onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 12),
          Text(widget.error!,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.red)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.isWorking ? null : widget.onSignIn,
          style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48)),
          child: Text(widget.isWorking ? l10n?.admin2_loginFormSigningIn ?? 'Signing in…' : l10n?.admin2_loginFormSignIn ?? 'Sign in'),
        ),
      ],
    );
  }

  InputDecoration _decoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

/// Shown when the signed-in account holds no admin role: it explains
/// the situation and offers to sign out and try another account.
class AdminNotAdminCard extends StatelessWidget {
  const AdminNotAdminCard({
    super.key,
    required this.onUseDifferentAccount,
  });

  final VoidCallback onUseDifferentAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n?.admin2_loginNotAdmin ?? 'Not an admin account',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 8),
        Text(
          l10n?.admin2_loginNoRole ?? 'This account has no admin role. Sign out and sign in with an admin account, or ask a super admin to grant you one.',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: onUseDifferentAccount,
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48)),
          child: Text(l10n?.admin2_loginUseDifferent ?? 'Use a different account'),
        ),
      ],
    );
  }
}
