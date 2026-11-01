import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import 'widgets/role_selector_card.dart';

class OnboardingRoleView extends StatefulWidget {
  final ValueChanged<String>? onRoleLocked;

  const OnboardingRoleView({super.key, this.onRoleLocked});

  @override
  State<OnboardingRoleView> createState() => _OnboardingRoleViewState();
}

class _OnboardingRoleViewState extends State<OnboardingRoleView> {
  String _selectedRole = 'customer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const CustomCurvedHeader(
              height: 165,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permanent Role Selection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Choose your permanent account role (Cannot be changed later)',
                    style: TextStyle(
                      color: AppColors.textLavender,
                      fontSize: 12,
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
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.amberGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.amberGold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.lock_clock_rounded,
                                color: AppColors.amberGold,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'DOC-2 Security Policy: Accounts are permanently locked to either Customer or Rental Shop Owner.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.midnightNavy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RoleSelectorCard(
                          roleKey: 'customer',
                          title: 'Rent a Vehicle (Customer)',
                          urduSubtitle: 'گاڑی کرایہ پر لیں',
                          description:
                              'Discover verified rental shops within 1–5 km, book Self-Drive or With-Driver packages.',
                          icon: Icons.person_pin_circle_rounded,
                          isSelected: _selectedRole == 'customer',
                          onTap: () =>
                              setState(() => _selectedRole = 'customer'),
                        ),
                        const SizedBox(height: 12),
                        RoleSelectorCard(
                          roleKey: 'owner',
                          title: 'List My Fleet (Shop Owner)',
                          urduSubtitle: 'شوروم رجسٹر کریں',
                          description:
                              'Register your showroom, manage fleet rates, digital handovers, and National Blacklist.',
                          icon: Icons.storefront_rounded,
                          isSelected: _selectedRole == 'owner',
                          onTap: () => setState(() => _selectedRole = 'owner'),
                        ),
                        const SizedBox(height: 20),
                        DebouncedButton(
                          text:
                              'Lock Permanent Role (${_selectedRole.toUpperCase()})',
                          icon: Icons.verified_user_rounded,
                          onPressed: () async {
                            if (widget.onRoleLocked != null) {
                              widget.onRoleLocked!(_selectedRole);
                            } else {
                              if (_selectedRole == 'customer') {
                                context.go(RouteNames.customerHome);
                              } else {
                                context.go(RouteNames.ownerDashboard);
                              }
                            }
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

