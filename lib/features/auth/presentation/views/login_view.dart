import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';

class LoginView extends StatefulWidget {
  final VoidCallback? onSignedIn;

  const LoginView({super.key, this.onSignedIn});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController =
      TextEditingController(text: 'ahmed.raza@rentalhub.pk');
  final _passwordController = TextEditingController(text: 'password123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const CustomCurvedHeader(
              height: 180,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RentalHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pakistan Premier Car Rental & Fleet Ecosystem • خوش آمدید',
                    style: TextStyle(
                      color: AppColors.textLavender,
                      fontSize: 12.5,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sign In to Your Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.midnightNavy,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                              onPressed: () async {
                                if (widget.onSignedIn != null) {
                                  widget.onSignedIn!();
                                } else {
                                  context.go(RouteNames.onboardingRole);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            GoogleSignInButton(
                              onPressed: () {
                                if (widget.onSignedIn != null) {
                                  widget.onSignedIn!();
                                } else {
                                  context.go(RouteNames.onboardingRole);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  context.go(RouteNames.onboardingRole);
                                },
                                child: const Text(
                                  'New to RentalHub? Choose Role & Register',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Production Quick Navigation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.explore_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Explore Platform Portals',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.midnightNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.go(RouteNames.customerHome),
                                  icon: const Icon(Icons.directions_car,
                                      size: 16),
                                  label: const Text('Customer App'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.go(RouteNames.ownerDashboard),
                                  icon: const Icon(Icons.storefront, size: 16),
                                  label: const Text('Owner Portal'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.emeraldGreen,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.go(RouteNames.adminDashboard),
                                  icon: const Icon(Icons.shield, size: 16),
                                  label: const Text('Web Admin'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.midnightNavy,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
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
