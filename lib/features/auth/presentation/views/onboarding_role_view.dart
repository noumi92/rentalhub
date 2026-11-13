import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
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
    final l10n = AppLocalizations.of(context);
    final isCustomer = _selectedRole == 'customer';
    final roleTitle =
        isCustomer ? l10n?.roleCustomerTitle ?? 'Customer (Rent a Vehicle)' : l10n?.roleOwner ?? 'Fleet Owner (Showroom)';

    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: l10n?.roleConfirm ?? 'Confirm Permanent Role',
      message:
          l10n?.roleSelectingNote(roleTitle) ?? 'You are selecting "$roleTitle". In accordance with National NADRA KYC policies, this role is locked permanently and cannot be changed later.',
      confirmLabel: l10n?.roleLockProceed ?? 'Lock My Role & Proceed',
      cancelLabel: l10n?.roleReview ?? 'Review Selection',
      icon: Icons.verified_user_rounded,
    );

    if (!confirmed || !mounted) return;

    // Audit SH-C1: the role lock IS the write — without a registered
    // data source there is nothing to lock. Fail here, before the
    // "confirmed" toast and the navigation, instead of proceeding
    // with no role saved.
    if (!sl.isRegistered<AuthRemoteDataSource>()) {
      AppFeedback.showError(context,
          l10n?.authUnavailable ?? 'Authentication unavailable. Please try again later.');
      return;
    }

    AppFeedback.showSuccess(context, l10n?.roleConfirmed(roleTitle) ?? 'Account role "$roleTitle" confirmed.');

    final auth = sl<AuthRemoteDataSource>();
    await auth.assignPermanentRole(
      role: _selectedRole,
      fullName: auth.fullName,
      phone: auth.phoneNumber,
    );
    if (isCustomer) {
      await auth.setOnboardingCompleted(true);
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
    final l10n = AppLocalizations.of(context);
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
                    MinimalAppBar(
                      title: l10n?.onboardingStep2 ?? 'Step 2: Account Role',
                      subtitle: l10n?.roleSelectSubtitle ?? 'Choose how you want to use RentalHub',
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.onboardingProfile);
                        }
                      },
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
                                l10n?.roleSecurityPolicy ?? 'Security Policy: Role selection is strictly one-way and immutable once confirmed.',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n?.roleSelectTitle ?? 'Select Permanent Account Role',
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
                            title: l10n?.roleCustomer ?? 'Rent a Vehicle (Customer)',
                            urduSubtitle: l10n?.roleCustomerUrdu ?? 'Rent a vehicle',
                            description:
                                l10n?.roleCustomerDesc ?? 'Discover verified rental shops within 1–5 km, book Self-Drive or With-Driver packages.',
                            icon: Icons.person_pin_circle_rounded,
                            isSelected: _selectedRole == 'customer',
                            onTap: () =>
                                setState(() => _selectedRole = 'customer'),
                          ),
                          const SizedBox(height: 12),
                          RoleSelectorCard(
                            roleKey: 'owner',
                            title: l10n?.roleOwnerTitle ?? 'List My Fleet (Shop Owner)',
                            urduSubtitle: l10n?.roleOwnerUrdu ?? 'Register a showroom',
                            description:
                                l10n?.roleOwnerDesc ?? 'Register your showroom, manage fleet rates, digital handovers, and RentalHub\'s shared blacklist.',
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
                    ? l10n?.roleContinueCustomer ?? 'Continue as Customer'
                    : l10n?.roleContinueOwner ?? 'Continue as Fleet Owner',
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
