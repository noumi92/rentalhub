import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/hero_car_slider.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';
import '../../../../l10n/app_localizations.dart';

class LoginView extends StatefulWidget {
  final VoidCallback? onSignedIn;

  const LoginView({super.key, this.onSignedIn});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleEmailSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      AppFeedback.showError(context, l10n.authValidEmail);
      return;
    }
    if (password.isEmpty || password.length < 6) {
      AppFeedback.showError(context, l10n.authPasswordLength);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (sl.isRegistered<AuthRemoteDataSource>()) {
        await sl<AuthRemoteDataSource>().signInWithEmail(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.authSignedIn);
      if (widget.onSignedIn != null) {
        widget.onSignedIn!();
      } else {
        context.go(AuthRouteGuard.resolveAuthDestination());
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e is ServerException ? e.message : e.toString();
      AppFeedback.showError(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      if (sl.isRegistered<AuthRemoteDataSource>()) {
        await sl<AuthRemoteDataSource>().signInWithGoogle();
      }

      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.authSignedInGoogle);
      if (widget.onSignedIn != null) {
        widget.onSignedIn!();
      } else {
        context.go(AuthRouteGuard.resolveAuthDestination());
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e is ServerException ? e.message : e.toString();
      AppFeedback.showError(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.hero,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RentalHub',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    l10n.authTagline,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
              // #1: the car slider fills the hero between the greeting
              // row and the overlapping sign-in card.
              bottomWidget: const HeroCarSlider(height: 104),
            ),
            HeaderOverlapContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // #1: the static sedan is gone — it
                            // duplicated the hero slider above.
                            Center(
                              child: Text(
                                l10n.authWelcome,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                l10n.authSignInSubtitle,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              controller: _emailController,
                              label: l10n.authEmail,
                              hint: 'you@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            AuthTextField(
                              controller: _passwordController,
                              label: l10n.authPassword,
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                            ),
                            const SizedBox(height: 20),
                            DebouncedButton(
                              text: l10n.authSignInEmail,
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
                              onPressed: () async => _handleEmailSignIn(),
                            ),
                            const SizedBox(height: 12),
                            GoogleSignInButton(
                              isLoading: _isLoading,
                              onPressed: _handleGoogleSignIn,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Audit §5 finish (P2-1): Terms / Privacy footer.
                    // Real documents, top-level routes, no dead links.
                    // (The old authNewUser bypass button stays removed.)
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.authLegalIntro,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push(RouteNames.legalTermsOfService),
                          child: Text(l10n.authTermsOfService),
                        ),
                        Text(
                          l10n.authLegalAnd,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push(RouteNames.legalPrivacyPolicy),
                          child: Text(l10n.authPrivacyPolicy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
