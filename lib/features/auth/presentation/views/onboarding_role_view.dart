import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'widgets/auth_stepper_bar.dart';
import 'widgets/role_selector_card.dart';
import 'widgets/security_policy_banner.dart';

class OnboardingRoleView extends StatefulWidget {
  final ValueChanged<String>? onRoleLocked;

  const OnboardingRoleView({super.key, this.onRoleLocked});

  @override
  State<OnboardingRoleView> createState() => _OnboardingRoleViewState();
}

class _OnboardingRoleViewState extends State<OnboardingRoleView> {
  String _selectedRole = 'customer';

  void _handleContinue() async {
    final isCustomer = _selectedRole == 'customer';
    final roleTitle = isCustomer ? 'Customer (Rent a Vehicle)' : 'Fleet Owner (Showroom)';

    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Confirm Permanent Role',
      message: 'You are selecting "$roleTitle". In accordance with National NADRA KYC policies, this role is locked permanently and cannot be changed later.',
      confirmLabel: 'Lock My Role & Proceed',
      cancelLabel: 'Review Selection',
      icon: Icons.verified_user_rounded,
    );

    if (!confirmed || !mounted) return;

    AppFeedback.showSuccess(context, 'Account role "$roleTitle" confirmed.');

    if (sl.isRegistered<AuthRemoteDataSource>()) {
      final auth = sl<AuthRemoteDataSource>();
      await auth.assignPermanentRole(
        role: _selectedRole,
        fullName: auth.fullName,
        phone: auth.phoneNumber,
      );
      if (isCustomer) {
        await auth.setOnboardingCompleted(true);
      }
    }

    if (!mounted) return;

    if (widget.onRoleLocked != null) {
      widget.onRoleLocked!(_selectedRole);
    } else {
      if (isCustomer) {
        context.go(RouteNames.customerLocationPrompt);
      } else {
        context.go(RouteNames.ownerOnboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header rolls up with scroll
                    CustomCurvedHeader(
                      height: 105,
                      leadingWidget: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(RouteNames.onboardingProfile);
                          }
                        },
                      ),
                      titleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step 2: Account Role',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Choose how you want to use RentalHub',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2-Step Progress Stepper
                    const AuthStepperBar(currentStep: 2),

                    // Role Cards Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SecurityPolicyBanner(
                            message: 'Security Policy: Role selection is strictly one-way and immutable once confirmed.',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select Permanent Account Role',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          RoleSelectorCard(
                            roleKey: 'customer',
                            title: 'Rent a Vehicle (Customer)',
                            urduSubtitle: 'گاڑی کرایہ پر لیں',
                            description: 'Discover verified rental shops within 1–5 km, book Self-Drive or With-Driver packages.',
                            icon: Icons.person_pin_circle_rounded,
                            isSelected: _selectedRole == 'customer',
                            onTap: () => setState(() => _selectedRole = 'customer'),
                          ),
                          const SizedBox(height: 12),
                          RoleSelectorCard(
                            roleKey: 'owner',
                            title: 'List My Fleet (Shop Owner)',
                            urduSubtitle: 'شوروم رجسٹر کریں',
                            description: 'Register your showroom, manage fleet rates, digital handovers, and National Blacklist.',
                            icon: Icons.storefront_rounded,
                            isSelected: _selectedRole == 'owner',
                            onTap: () => setState(() => _selectedRole = 'owner'),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Sticky CTA (Clean label, single icon)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                boxShadow: [
                  BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, -3)),
                ],
              ),
              child: DebouncedButton(
                text: _selectedRole == 'customer' ? 'Continue as Customer' : 'Continue as Fleet Owner',
                icon: Icons.verified_user_rounded,
                onPressed: () async => _handleContinue(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
