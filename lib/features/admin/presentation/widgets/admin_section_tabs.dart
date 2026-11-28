import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import 'admin_sub_tab_bar.dart';

/// Centralized horizontal sub-tab presets for the 7 primary admin sections.
/// Keeps every screen small and ensures sibling tabs never drift out of sync.
abstract final class AdminSectionTabs {
  /// Maps any admin route (including detail or sub-tab routes) to its
  /// parent primary section route in the 7-item sidebar.
  static String primaryRouteFor(String route) {
    final clean = route.split('?').first;
    if (clean == RouteNames.adminDashboard ||
        clean == RouteNames.adminReports ||
        clean == RouteNames.adminQueues) {
      return RouteNames.adminDashboard;
    }
    if (clean == RouteNames.adminShops ||
        clean.startsWith('${RouteNames.adminShops}/') ||
        clean == RouteNames.adminCars) {
      return RouteNames.adminShops;
    }
    if (clean == RouteNames.adminCustomers ||
        clean.startsWith('${RouteNames.adminCustomers}/') ||
        clean == RouteNames.adminKycReview ||
        clean.startsWith('${RouteNames.adminKycReview}/') ||
        clean == RouteNames.adminBlacklist) {
      return RouteNames.adminCustomers;
    }
    if (clean == RouteNames.adminSubscriptions) {
      return RouteNames.adminSubscriptions;
    }
    if (clean == RouteNames.adminBookings ||
        clean.startsWith('${RouteNames.adminBookings}/') ||
        clean == RouteNames.adminDisputes ||
        clean.startsWith('${RouteNames.adminDisputes}/') ||
        clean == RouteNames.adminReviews) {
      return RouteNames.adminDisputes;
    }
    if (clean == RouteNames.adminTickets ||
        clean.startsWith('${RouteNames.adminTickets}/') ||
        clean == RouteNames.adminAnnouncements ||
        clean.startsWith('${RouteNames.adminAnnouncements}/')) {
      return RouteNames.adminTickets;
    }
    if (clean == RouteNames.adminSettings ||
        clean == RouteNames.adminTeam ||
        clean == RouteNames.adminActivity ||
        clean == RouteNames.adminApkDownload) {
      return RouteNames.adminSettings;
    }
    return clean;
  }

  static AppLocalizations _l10n(BuildContext context) =>
      AppLocalizations.of(context) ?? AppLocalizationsEn();

  static List<AdminSubTab> overview(
    BuildContext context, {
    required String activeRoute,
  }) {
    final l10n = _l10n(context);
    return [
      AdminSubTab(
        label: l10n.admin2_navDashboard,
        route: RouteNames.adminDashboard,
        icon: Icons.dashboard_rounded,
        isActive: activeRoute == RouteNames.adminDashboard,
      ),
      AdminSubTab(
        label: l10n.admin2_navReports,
        route: RouteNames.adminReports,
        icon: Icons.bar_chart_rounded,
        isActive: activeRoute == RouteNames.adminReports,
      ),
    ];
  }

  static List<AdminSubTab> shopsAndFleet(
    BuildContext context, {
    required String activeRoute,
    String? activeFilter,
    int approvalsBadge = 0,
    int carsBadge = 0,
  }) {
    final l10n = _l10n(context);
    final onShops = activeRoute == RouteNames.adminShops;
    return [
      AdminSubTab(
        label: l10n.adminTabAllShops,
        route: RouteNames.adminShops,
        icon: Icons.store_rounded,
        isActive: onShops && (activeFilter == null || activeFilter == 'all'),
      ),
      AdminSubTab(
        label: l10n.statusApproved,
        route: '${RouteNames.adminShops}?filter=approved',
        icon: Icons.verified_rounded,
        isActive: onShops && activeFilter == 'approved',
      ),
      AdminSubTab(
        label: l10n.adminTabPendingApprovals,
        route: '${RouteNames.adminShops}?filter=pending',
        icon: Icons.pending_actions_rounded,
        badgeCount: approvalsBadge,
        isActive: onShops && activeFilter == 'pending',
      ),
      AdminSubTab(
        label: l10n.adminTabSuspended,
        route: '${RouteNames.adminShops}?filter=suspended',
        icon: Icons.block_rounded,
        isActive: onShops && activeFilter == 'suspended',
      ),
      AdminSubTab(
        label: l10n.adminTabFleetCars,
        route: RouteNames.adminCars,
        icon: Icons.directions_car_rounded,
        badgeCount: carsBadge,
        isActive: activeRoute == RouteNames.adminCars,
      ),
    ];
  }

  static List<AdminSubTab> onlineCustomers(
    BuildContext context, {
    required String activeRoute,
    bool canDecideKyc = true,
    int kycBadge = 0,
  }) {
    final l10n = _l10n(context);
    return [
      AdminSubTab(
        label: l10n.adminTabDirectory,
        route: RouteNames.adminCustomers,
        icon: Icons.people_rounded,
        isActive: activeRoute == RouteNames.adminCustomers,
      ),
      if (canDecideKyc)
        AdminSubTab(
          label: l10n.adminTabKycQueue,
          route: RouteNames.adminKycReview,
          icon: Icons.badge_rounded,
          badgeCount: kycBadge,
          isActive: activeRoute == RouteNames.adminKycReview,
        ),
      AdminSubTab(
        label: l10n.admin2_navBlacklist,
        route: RouteNames.adminBlacklist,
        icon: Icons.gpp_bad_rounded,
        isActive: activeRoute == RouteNames.adminBlacklist,
      ),
    ];
  }

  static List<AdminSubTab> packagesAndCredits(
    BuildContext context, {
    required String activeTab,
    int subscriptionsBadge = 0,
    int creditsBadge = 0,
  }) {
    final l10n = _l10n(context);
    return [
      AdminSubTab(
        label: l10n.adminTabPackageCatalog,
        route: '${RouteNames.adminSubscriptions}?tab=catalog',
        icon: Icons.inventory_2_rounded,
        isActive: activeTab == 'catalog',
      ),
      AdminSubTab(
        label: l10n.adminTabShopPlans,
        route: '${RouteNames.adminSubscriptions}?tab=plans',
        icon: Icons.card_membership_rounded,
        isActive: activeTab == 'plans',
      ),
      AdminSubTab(
        label: l10n.adminTabUpgradeRequests,
        route: '${RouteNames.adminSubscriptions}?tab=requests',
        icon: Icons.upgrade_rounded,
        badgeCount: subscriptionsBadge,
        isActive: activeTab == 'requests',
      ),
      AdminSubTab(
        label: l10n.adminTabWhatsappPackages,
        route: '${RouteNames.adminSubscriptions}?tab=whatsapp',
        icon: Icons.chat_rounded,
        badgeCount: creditsBadge,
        isActive: activeTab == 'whatsapp',
      ),
    ];
  }

  static List<AdminSubTab> bookings(
    BuildContext context, {
    required String activeRoute,
    int disputesBadge = 0,
    int reviewsBadge = 0,
  }) {
    final l10n = _l10n(context);
    return [
      AdminSubTab(
        label: l10n.admin2_navDisputes,
        route: RouteNames.adminDisputes,
        icon: Icons.gavel_rounded,
        badgeCount: disputesBadge,
        isActive: activeRoute == RouteNames.adminDisputes,
      ),
      AdminSubTab(
        label: l10n.admin2_navReviews,
        route: RouteNames.adminReviews,
        icon: Icons.star_rounded,
        badgeCount: reviewsBadge,
        isActive: activeRoute == RouteNames.adminReviews,
      ),
    ];
  }

  static List<AdminSubTab> trustAndSupport(
    BuildContext context, {
    required String activeRoute,
    int ticketsBadge = 0,
  }) {
    final l10n = _l10n(context);
    return [
      AdminSubTab(
        label: l10n.admin2_navSupport,
        route: RouteNames.adminTickets,
        icon: Icons.support_agent_rounded,
        badgeCount: ticketsBadge,
        isActive: activeRoute == RouteNames.adminTickets,
      ),
      AdminSubTab(
        label: l10n.admin2_navAnnouncements,
        route: RouteNames.adminAnnouncements,
        icon: Icons.campaign_rounded,
        isActive: activeRoute == RouteNames.adminAnnouncements,
      ),
    ];
  }

  static List<AdminSubTab> platformAndSystem(
    BuildContext context, {
    required String activeRoute,
    bool? canDownloadApk,
  }) {
    final l10n = _l10n(context);
    var showApk = canDownloadApk ?? false;
    if (canDownloadApk == null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final role = AdminSession.cachedRoleFor(user);
          showApk = AdminPermissions.can(role, AdminPermission.downloadApk);
        }
      } catch (_) {}
    }
    return [
      AdminSubTab(
        label: l10n.admin2_navSettings,
        route: RouteNames.adminSettings,
        icon: Icons.settings_rounded,
        isActive: activeRoute == RouteNames.adminSettings,
      ),
      AdminSubTab(
        label: l10n.admin2_navAdminTeam,
        route: RouteNames.adminTeam,
        icon: Icons.group_rounded,
        isActive: activeRoute == RouteNames.adminTeam,
      ),
      AdminSubTab(
        label: l10n.admin2_navActivityLog,
        route: RouteNames.adminActivity,
        icon: Icons.history_rounded,
        isActive: activeRoute == RouteNames.adminActivity,
      ),
      if (showApk)
        AdminSubTab(
          label: l10n.adminTabApkRelease,
          route: RouteNames.adminApkDownload,
          icon: Icons.android_rounded,
          isActive: activeRoute == RouteNames.adminApkDownload,
        ),
    ];
  }
}
