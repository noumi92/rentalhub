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
import '../../../../l10n/app_localizations.dart';

class OnboardingRoleView extends StatefulWidget {
  final ValueChanged<String>? onRoleLocked;

  const OnboardingRoleView({super.key, this.onRoleLocked});

  @override
  State<OnboardingRoleView> createState() => _OnboardingRoleViewState();
}

class _OnboardingRoleViewState extends State<OnboardingRoleView> {
  String _selectedRole = 'customer';

  void _handleContinue() async {
    final l10n = AppLocalizations.of(context)!;
    final isCustomer = _selectedRole == 'customer';
    final roleTitle =
        isCustomer ? l10n.roleCustomerTitle : l10n.roleOwner;

    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: l10n.roleConfirm,
      message:
          l10n.roleSelectingNote(roleTitle),
      confirmLabel: l10n.roleLockProceed,
      cancelLabel: l10n.roleReview,
      icon: Icons.verified_user_rounded,
    );

    if (!confirmed || !mounted) return;

    AppFeedback.showSuccess(context, l10n.roleConfirmed(roleTitle));

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
    final l10n = AppLocalizations.of(context)!;
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
                      variant: CustomCurvedHeaderVariant.compact,
                      leadingWidget: IconButton(
                        tooltip: l10n.back,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
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
                            l10n.onboardingStep2,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            l10n.roleSelectSubtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                           SecurityPolicyBanner(
                            message:
                                l10n.roleSecurityPolicy,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.roleSelectTitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 10),
                          RoleSelectorCard(
                            roleKey: 'customer',
                            title: l10n.roleCustomer,
                            urduSubtitle: l10n.roleCustomerUrdu,
                            description:
                                l10n.roleCustomerDesc,
                            icon: Icons.person_pin_circle_rounded,
                            isSelected: _selectedRole == 'customer',
                            onTap: () =>
                                setState(() => _selectedRole = 'customer'),
                          ),
                          const SizedBox(height: 12),
                          RoleSelectorCard(
                            roleKey: 'owner',
                            title: l10n.roleOwnerTitle,
                            urduSubtitle: l10n.roleOwnerUrdu,
                            description:
                                l10n.roleOwnerDesc,
                            icon: Icons.storefront_rounded,
                            isSelected: _selectedRole == 'owner',
                            onTap: () =>
                                setState(() => _selectedRole = 'owner'),
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor)),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 8,
                      offset: Offset(0, -3)),
                ],
              ),
              child: DebouncedButton(
                text: _selectedRole == 'customer'
                    ? l10n.roleContinueCustomer
                    : l10n.roleContinueOwner,
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
