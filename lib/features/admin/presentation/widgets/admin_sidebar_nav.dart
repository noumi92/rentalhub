import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/services/admin_queue_counts_service.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';

/// Phase A (A6) — the admin panel's sidebar, now wired to the real
/// routes. The mock-era items (accreditation, settings) are replaced by
/// the real sections; the footer shows the signed-in admin's email
/// instead of the hardcoded superadmin@rentalhub.pk.
///
/// Phase 2 (2.1) — grouped, with live count badges on the review
/// queues: Overview (Dashboard, Reports), Review queues (KYC Review,
/// Cars, Disputes, Reviews, Support), Marketplace (Shops, Customers,
/// Bookings), Platform (Announcements, Settings, APK Download),
/// Governance (Blacklist, Admin Team, Activity Log). Phase 3 (3.1):
/// Approvals is no longer its own nav item — it is the Shops list
/// with the Pending filter, so the Shops item carries the pending
/// count badge instead. 16 items with both role-gated items visible
/// (14 without them); Subscriptions stays hidden (Phase 1, 1.2 —
/// the route exists but the screen is still Coming Soon).
///
/// Stateful only so the role-gated items can resolve the signed-in
/// admin's role once: the super-admin-only "APK Download" item and
/// the super-admin + operations "KYC Review" item stay hidden for
/// roles that may not use them. The role is read from the session
/// cache synchronously in initState when the router guard already
/// resolved it, so the gated items are correct on the first paint;
/// while the role is still resolving, a 48dp placeholder reserves
/// their space instead of shifting the list when they appear.
/// Every other section is visible to all admin roles.
///
/// The queue badges come from [AdminQueueCountsService] (60 s cache),
/// so the sidebar re-rendering on every navigation does not re-read
/// the collections; a failed count load simply hides the badges.
class AdminSidebarNav extends StatefulWidget {
  final String activeRoute;
  final ValueChanged<String> onNavigate;

  /// Sidebar width: 260 on desktop; the mobile drawer passes 280 so
  /// the panel fills the drawer exactly.
  final double width;

  /// Test seam: when non-null, forces the APK Download item visible
  /// (true) or hidden (false) without resolving the signed-in role.
  final bool? showApkDownload;

  /// Test seam: when non-null, forces the KYC Review item visible
  /// (true) or hidden (false) without resolving the signed-in role.
  final bool? showKycReview;

  /// Test seam: when non-null, supplies the queue counts instead of
  /// reading them from [AdminQueueCountsService].
  final Future<AdminQueueCounts> Function()? loadCounts;

  const AdminSidebarNav({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
    this.width = 260,
    this.showApkDownload,
    this.showKycReview,
    this.loadCounts,
  });

  @override
  State<AdminSidebarNav> createState() => _AdminSidebarNavState();
}

class _AdminSidebarNavState extends State<AdminSidebarNav> {
  bool _showApkDownload = false;
  bool _canReviewKyc = false;
  bool _roleResolved = false;
  AdminQueueCounts? _counts;

  @override
  void initState() {
    super.initState();
    if (widget.showApkDownload != null) {
      _showApkDownload = widget.showApkDownload!;
    }
    if (widget.showKycReview != null) {
      _canReviewKyc = widget.showKycReview!;
    }
    if (widget.showApkDownload != null && widget.showKycReview != null) {
      _roleResolved = true;
    } else {
      _resolveRoleSync();
      if (!_roleResolved) _resolveRole();
    }
    _loadCounts();
  }

  @override
  void didUpdateWidget(covariant AdminSidebarNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The test seams force visibility: a rebuild with a changed seam
    // applies it (initState only runs once per element).
    if (widget.showApkDownload != null) {
      _showApkDownload = widget.showApkDownload!;
    }
    if (widget.showKycReview != null) {
      _canReviewKyc = widget.showKycReview!;
    }
    if (widget.showApkDownload != null && widget.showKycReview != null) {
      _roleResolved = true;
    }
  }

  /// Phase 2 (2.1): the router guard already resolved the role
  /// before any admin screen opens, so the session cache usually
  /// holds it — read it synchronously so the gated items are right
  /// on the first paint instead of appearing a frame later.
  void _resolveRoleSync() {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    if (user == null) return;
    final role = AdminSession.cachedRoleFor(user);
    if (role == null) return;
    _applyRole(role);
    _roleResolved = true;
  }

  void _applyRole(String? role) {
    if (widget.showApkDownload == null) {
      _showApkDownload =
          AdminPermissions.can(role, AdminPermission.downloadApk);
    }
    if (widget.showKycReview == null) {
      _canReviewKyc =
          AdminPermissions.can(role, AdminPermission.decideKyc);
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
    setState(() {
      _applyRole(role);
      _roleResolved = true;
    });
  }

  Future<void> _loadCounts() async {
    try {
      final counts = widget.loadCounts != null
          ? await widget.loadCounts!()
          : await sl<AdminQueueCountsService>().getCounts();
      if (!mounted) return;
      setState(() => _counts = counts);
    } catch (_) {
      // A failed count load hides the badges — the queue screens
      // themselves always load live, so the sidebar never errors.
    }
  }

  String get _adminEmail {
    try {
      return FirebaseAuth.instance.currentUser?.email ?? '';
    } catch (_) {
      return '';
    }
  }

  /// AD-M3: sign out of the panel — clears the in-memory TOTP flag
  /// and role cache, then routes to the admin login.
  Future<void> _signOut() async {
    AdminSession.clear();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (mounted) context.go(RouteNames.adminLogin);
  }

  /// A role-gated item: the real item once its visibility is
  /// resolved (its test seam, or the async role resolution), a 48dp
  /// placeholder while it resolves (so the list below never shifts),
  /// nothing when the role says the admin may not use it.
  Widget _gatedItem({
    required bool resolved,
    required bool visible,
    required Widget item,
  }) {
    if (!resolved) return const SizedBox(height: 48);
    if (!visible) return const SizedBox.shrink();
    return item;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final counts = _counts;
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
                      Text('RENTALHUB', style: TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 1.0)),
                      Text('ADMIN PANEL', style: TextStyle(color: AppColors.secondary, fontSize: 9.5, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(l10n.admin2_sidebarGroupOverview),
                  _navItem(RouteNames.adminDashboard, l10n.admin2_navDashboard, Icons.dashboard_rounded),
                  _navItem(RouteNames.adminReports, l10n.admin2_navReports, Icons.bar_chart_rounded),
                  _sectionHeader(l10n.admin2_sidebarGroupQueues),
                  _gatedItem(
                    resolved: widget.showKycReview != null || _roleResolved,
                    visible: _canReviewKyc,
                    item: _navItem(RouteNames.adminKycReview, l10n.adminKycReviewTitle, Icons.badge_rounded, badge: counts?.kyc),
                  ),
                  _navItem(RouteNames.adminCars, l10n.admin2_navCars, Icons.directions_car_rounded, badge: counts?.cars),
                  _navItem(RouteNames.adminDisputes, l10n.admin2_navDisputes, Icons.gavel_rounded, badge: counts?.disputes),
                  _navItem(RouteNames.adminReviews, l10n.admin2_navReviews, Icons.star_rounded, badge: counts?.reviews),
                  _navItem(RouteNames.adminTickets, l10n.admin2_navSupport, Icons.support_agent_rounded, badge: counts?.tickets),
                  _sectionHeader(l10n.admin2_sidebarGroupMarketplace),
                  // Phase 3 (3.1): the pending-shop count lives on
                  // Shops — Approvals is the Shops list with the
                  // Pending filter, not its own screen any more.
                  _navItem(RouteNames.adminShops, l10n.admin2_navShops, Icons.store_rounded, badge: counts?.approvals),
                  _navItem(RouteNames.adminCustomers, l10n.admin2_navCustomers, Icons.people_rounded),
                  _navItem(RouteNames.adminBookings, l10n.admin2_navBookings, Icons.receipt_long_rounded),
                  _sectionHeader(l10n.admin2_sidebarGroupPlatform),
                  _navItem(RouteNames.adminAnnouncements, l10n.admin2_navAnnouncements, Icons.campaign_rounded),
                  _navItem(RouteNames.adminSettings, l10n.admin2_navSettings, Icons.settings_rounded),
                  _gatedItem(
                    resolved: widget.showApkDownload != null || _roleResolved,
                    visible: _showApkDownload,
                    item: _navItem(RouteNames.adminApkDownload, l10n.admin2_navApkDownload, Icons.android_rounded),
                  ),
                  _sectionHeader(l10n.admin2_sidebarGroupGovernance),
                  // AD-m1: Blacklist gets its own icon — it shared
                  // the gavel with Disputes.
                  _navItem(RouteNames.adminBlacklist, l10n.admin2_navBlacklist, Icons.block_rounded),
                  _navItem(RouteNames.adminTeam, l10n.admin2_navAdminTeam, Icons.group_rounded),
                  _navItem(RouteNames.adminActivity, l10n.admin2_navActivityLog, Icons.history_rounded),
                  const SizedBox(height: 12),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.admin2_sidebarSignedInAs, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.secondary)),
                      const SizedBox(height: 4),
                      Text(
                        _adminEmail.isEmpty ? l10n.admin2_roleAdmin : _adminEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                // AD-M3: the panel had no sign-out control anywhere.
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.white70),
                  tooltip: AppLocalizations.of(context)?.signOut ?? 'Sign out',
                  onPressed: _signOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _navItem(String route, String label, IconData icon, {int? badge}) {
    final isSelected = widget.activeRoute == route;
    final showBadge = badge != null && badge > 0;
    return Semantics(
      button: true,
      selected: isSelected,
      label: showBadge ? '$label, $badge waiting' : label,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? AppColors.secondary.withAlpha(40) : Colors.transparent,
        child: InkWell(
          onTap: () => widget.onNavigate(route),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isSelected
                  ? const BorderDirectional(
                      start: BorderSide(color: AppColors.secondary, width: 3.5),
                    )
                  : null,
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
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
                if (showBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
