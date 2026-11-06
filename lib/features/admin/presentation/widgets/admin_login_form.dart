import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// The admin login's credentials form, extracted from AdminLoginView
/// so the view stays under the 250-line cap: email + password fields,
/// the error line, and the sign-in button.
class AdminLoginForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('RentalHub Admin',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.midnightNavy)),
        const SizedBox(height: 8),
        const Text('Sign in with your admin account.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration(context, 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: _decoration(context, 'Password'),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.red)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: isWorking ? null : onSignIn,
          child: Text(isWorking ? 'Signing in…' : 'Sign in'),
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
        borderSide: const BorderSide(color: AppColors.border),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Not an admin account',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.midnightNavy)),
        const SizedBox(height: 8),
        const Text(
          'This account has no admin role. Sign out and sign in with an admin account, or ask a super admin to grant you one.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: onUseDifferentAccount,
          child: const Text('Use a different account'),
        ),
      ],
    );
  }
}
