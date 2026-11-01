import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
              height: 170,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RentalHub Pakistan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Enterprise Car Rental & Fleet Ecosystem • خوش آمدید',
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign In to Your Account',
                          style: TextStyle(
                            fontSize: 17,
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
                            widget.onSignedIn?.call();
                          },
                        ),
                        const SizedBox(height: 12),
                        GoogleSignInButton(
                          onPressed: () {
                            widget.onSignedIn?.call();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

