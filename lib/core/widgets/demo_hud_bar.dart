import 'package:flutter/material.dart';
import '../routing/app_router.dart';
import '../routing/route_names.dart';
import '../theme/app_theme.dart';

enum DemoRole {
  customer,
  owner,
  admin,
}

class DemoHudController extends ChangeNotifier {
  static final DemoHudController instance = DemoHudController._();
  DemoHudController._();

  DemoRole currentRole = DemoRole.customer;
  String currentAnchor = 'ANC-01';

  void setRole(DemoRole role) {
    currentRole = role;
    if (role == DemoRole.customer) {
      jumpToAnchor('ANC-01');
    } else if (role == DemoRole.owner) {
      jumpToAnchor('ANC-10');
    } else {
      jumpToAnchor('ANC-17');
    }
  }

  void jumpToAnchor(String anchor) {
    currentAnchor = anchor;
    if (anchor.startsWith('ANC-0') || anchor == 'ANC-08') {
      currentRole = DemoRole.customer;
    } else if (int.tryParse(anchor.replaceAll('ANC-', '')) != null &&
        int.parse(anchor.replaceAll('ANC-', '')) >= 9 &&
        int.parse(anchor.replaceAll('ANC-', '')) <= 16) {
      currentRole = DemoRole.owner;
    } else {
      currentRole = DemoRole.admin;
    }
    notifyListeners();
    final route = _routeForAnchor(anchor);
    if (route != null) {
      try {
        AppRouter.router.go(route);
      } catch (_) {}
    }
  }

  String? _routeForAnchor(String anchor) {
    switch (anchor) {
      case 'ANC-01':
        return RouteNames.customerHome;
      case 'ANC-02':
        return RouteNames.customerVehicleDetail;
      case 'ANC-03':
        return RouteNames.customerPaymentProof;
      case 'ANC-04':
        return RouteNames.customerReviewBooking;
      case 'ANC-05':
        return RouteNames.customerPickupPass;
      case 'ANC-06':
        return RouteNames.customerActiveTrip;
      case 'ANC-07':
        return RouteNames.customerKyc;
      case 'ANC-08':
        return RouteNames.customerRateTrip;
      case 'ANC-09':
        return RouteNames.ownerOnboarding;
      case 'ANC-10':
        return RouteNames.ownerDashboard;
      case 'ANC-11':
        return RouteNames.ownerFleet;
      case 'ANC-12':
        return RouteNames.ownerRates;
      case 'ANC-13':
        return RouteNames.ownerRequests;
      case 'ANC-14':
        return RouteNames.ownerHandover;
      case 'ANC-15':
        return RouteNames.ownerReturn;
      case 'ANC-16':
        return RouteNames.ownerBlacklist;
      case 'ANC-17':
        return RouteNames.adminDashboard;
      case 'ANC-18':
        return RouteNames.adminShops;
      case 'ANC-19':
        return RouteNames.adminBlacklist;
      case 'ANC-20':
        return RouteNames.adminSubscriptions;
      default:
        return null;
    }
  }
}

class DemoHudBar extends StatelessWidget {
  const DemoHudBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DemoHudController.instance,
      builder: (context, _) {
        final ctrl = DemoHudController.instance;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoleChip(
                label: 'Customer',
                icon: Icons.person_rounded,
                isActive: ctrl.currentRole == DemoRole.customer,
                onTap: () => ctrl.setRole(DemoRole.customer),
              ),
              const SizedBox(width: 6),
              _buildRoleChip(
                label: 'Host / Owner',
                icon: Icons.directions_car_rounded,
                isActive: ctrl.currentRole == DemoRole.owner,
                onTap: () => ctrl.setRole(DemoRole.owner),
              ),
              const SizedBox(width: 6),
              _buildRoleChip(
                label: 'Super Admin',
                icon: Icons.admin_panel_settings_rounded,
                isActive: ctrl.currentRole == DemoRole.admin,
                onTap: () => ctrl.setRole(DemoRole.admin),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.list_alt_rounded,
                    color: AppColors.secondary, size: 20),
                tooltip: 'Jump to Any Anchor Screen',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () => _showAnchorMenu(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? Colors.white
                  : AppColors.primaryContainer.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : AppColors.primaryContainer.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnchorMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jump to 20 Core Anchor Screens',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      _buildMenuSection(
                          'Customer App Anchors (ANC-01 to 08)',
                          [
                            'ANC-01: Customer Discovery & Nav',
                            'ANC-02: Vehicle Detail & Packages',
                            'ANC-03: Upload Payment Proof',
                            'ANC-04: Review & Send Reservation',
                            'ANC-05: Pickup Pass & Countdown',
                            'ANC-06: Active Trip Dashboard & SOS',
                            'ANC-07: KYC Document Upload',
                            'ANC-08: Rate Trip & Condition',
                          ],
                          context),
                      _buildMenuSection(
                          'Owner App Anchors (ANC-09 to 16)',
                          [
                            'ANC-09: Shop Onboarding Step 1',
                            'ANC-10: Fleet Dashboard & KPIs',
                            'ANC-11: Fleet Inventory',
                            'ANC-12: Add Vehicle Rate Matrix',
                            'ANC-13: Booking Requests Triage',
                            'ANC-14: Vehicle Handover & Signatures',
                            'ANC-15: Return & Settle Voucher',
                            'ANC-16: Fraud Blacklist Report',
                          ],
                          context),
                      _buildMenuSection(
                          'Admin Web Anchors (ANC-17 to 20)',
                          [
                            'ANC-17: Super Admin Operations Dashboard',
                            'ANC-18: Shop Accreditation Queue',
                            'ANC-19: National Blacklist Registry',
                            'ANC-20: Subscription Tiers & Quota',
                          ],
                          context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(
      String title, List<String> items, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.orangeTextFor(
                      Theme.of(context).brightness),
                ),
          ),
        ),
        ...items.map((item) {
          final anchorId = item.split(':').first.trim();
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.arrow_forward_ios, size: 12),
            title: Text(item,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
            onTap: () {
              Navigator.pop(context);
              DemoHudController.instance.jumpToAnchor(anchorId);
            },
          );
        }),
        const Divider(),
      ],
    );
  }
}
