import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';

/// Phase A (A6) — the admin panel's sidebar, now wired to the real
/// routes. The mock-era items (accreditation, settings) are replaced by
/// the real sections; the footer shows the signed-in admin's email
/// instead of the hardcoded superadmin@rentalhub.pk.
///
/// Stateful only so the super-admin-only "APK Download" item can
/// resolve the signed-in admin's role once: no other role may even see
/// the download, so the item stays hidden for them (and while the role
/// is resolving). Every other section is visible to all admin roles.
class AdminSidebarNav extends StatefulWidget {
  final String activeRoute;
  final ValueChanged<String> onNavigate;

  /// Sidebar width: 260 on desktop; the mobile drawer passes 280 so
  /// the panel fills the drawer exactly.
  final double width;

  /// Test seam: when non-null, forces the APK Download item visible
  /// (true) or hidden (false) without resolving the signed-in role.
  final bool? showApkDownload;

  const AdminSidebarNav({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    this.width = 260,
    this.showApkDownload,
  });

  @override
  State<AdminSidebarNav> createState() => _AdminSidebarNavState();
}

class _AdminSidebarNavState extends State<AdminSidebarNav> {
  bool _showApkDownload = false;

  @override
  void initState() {
    super.initState();
    if (widget.showApkDownload != null) {
      _showApkDownload = widget.showApkDownload!;
    } else {
      _resolveRole();
    }
  }

  Future<void> _resolveRole() async {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    if (user == null) return;
    final role = await AdminSession.resolveAdminRole(user);
    if (!mounted) return;
    setState(
      () => _showApkDownload =
          AdminPermissions.can(role, AdminPermission.downloadApk),
    );
  }

  String get _adminEmail {
    try {
      return FirebaseAuth.instance.currentUser?.email ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RENTALHUB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0)),
                      Text('ADMIN PANEL', style: TextStyle(color: AppColors.secondary, fontSize: 9.5, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          // 16 items now (17 for a super admin, with APK Download) —
          // the list scrolls on short windows instead of overflowing
          // the sidebar.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _navItem(RouteNames.adminDashboard, 'Dashboard', Icons.dashboard_rounded),
                  _navItem(RouteNames.adminShops, 'Shops', Icons.store_rounded),
                  _navItem(RouteNames.adminApprovals, 'Approvals', Icons.verified_user_rounded),
                  _navItem(RouteNames.adminCars, 'Cars', Icons.directions_car_rounded),
                  _navItem(RouteNames.adminCustomers, 'Customers', Icons.people_rounded),
                  _navItem(RouteNames.adminBookings, 'Bookings', Icons.receipt_long_rounded),
                  _navItem(RouteNames.adminDisputes, 'Disputes', Icons.gavel_rounded),
                  _navItem(RouteNames.adminReviews, 'Reviews', Icons.star_rounded),
                  _navItem(RouteNames.adminTickets, 'Support', Icons.support_agent_rounded),
                  _navItem(RouteNames.adminAnnouncements, 'Announcements', Icons.campaign_rounded),
                  _navItem(RouteNames.adminReports, 'Reports', Icons.bar_chart_rounded),
                  _navItem(RouteNames.adminSettings, 'Settings', Icons.settings_rounded),
                  if (_showApkDownload)
                    _navItem(RouteNames.adminApkDownload, 'APK Download', Icons.android_rounded),
                  _navItem(RouteNames.adminBlacklist, 'Blacklist', Icons.gavel_rounded),
                  _navItem(RouteNames.adminTeam, 'Admin Team', Icons.group_rounded),
                  _navItem(RouteNames.adminActivity, 'Activity Log', Icons.history_rounded),
                  _navItem(RouteNames.adminSubscriptions, 'Subscriptions', Icons.monetization_on_rounded),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SIGNED IN AS ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.secondary)),
                const SizedBox(height: 4),
                Text(
                  _adminEmail.isEmpty ? 'Admin' : _adminEmail,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String route, String label, IconData icon) {
    final isSelected = widget.activeRoute == route;
    return InkWell(
      onTap: () => widget.onNavigate(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withAlpha(40) : Colors.transparent,
          border: isSelected ? const Border(left: BorderSide(color: AppColors.secondary, width: 3.5)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.secondary : Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
