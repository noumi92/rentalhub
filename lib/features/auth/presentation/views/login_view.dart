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
import '../../data/datasources/auth_remote_data_source.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';

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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      AppFeedback.showError(context, 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      AppFeedback.showError(context, 'Password must be at least 6 characters.');
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
      AppFeedback.showSuccess(context, 'Signed in successfully!');
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
    setState(() => _isLoading = true);

    try {
      if (sl.isRegistered<AuthRemoteDataSource>()) {
        await sl<AuthRemoteDataSource>().signInWithGoogle();
      }

      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Signed in with Google!');
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
                    'Pakistan Premier Car Rental & Fleet Ecosystem • خوش آمدید',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
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
                            // Real Matching Car Showcase
                            Center(
                              child: Container(
                                height: 84,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Image.asset(
                                  'assets/images/white_sedan_hero.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                'Welcome to RentalHub',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'Sign in to rent a car near you',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'you@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            AuthTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: true,
                            ),
                            const SizedBox(height: 20),
                            DebouncedButton(
                              text: 'Sign In with Email',
                              icon: Icons.login_rounded,
                              isLoading: _isLoading,
                              onPressed: () async => _handleEmailSignIn(),
                            ),
                            const SizedBox(height: 12),
                            GoogleSignInButton(
                              isLoading: _isLoading,
                              onPressed: _handleGoogleSignIn,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () async {
                                  if (sl.isRegistered<AuthRemoteDataSource>()) {
                                    final auth = sl<AuthRemoteDataSource>();
                                    if (!auth.isLoggedIn) {
                                      await auth.setLoggedIn(true);
                                    }
                                  }
                                  if (context.mounted) {
                                    context.go(RouteNames.onboardingProfile);
                                  }
                                },
                                child: Text(
                                  'New to RentalHub? Choose Role & Register',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
