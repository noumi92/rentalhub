/// Phase A (A2) — admin permission matrix, ported from the old repo
/// (noumi92/renthub Batch 14) and adapted to this repo.
///
/// Roles (stored on the users doc as `admin_role`, written only by the
/// setAdminRole Cloud Function — see the plan's D1/D2):
/// - super_admin: everything, including team management and role grants.
/// - operations: day-to-day platform decisions (KYC, shops, blacklist,
///   subscriptions) but no team management.
/// - support: disputes and read-only views; no approvals, no team.
///
/// Enforcement lives in three places: this matrix gates the UI and the
/// admin decision methods; setAdminRole enforces team management
/// server-side; Firestore rules enforce the privileged user-doc fields.
/// A support admin must never be able to approve a shop or grant a role
/// — if a check is missing somewhere, the function/rules layer is the
/// backstop for team changes.
enum AdminPermission {
  manageTeam,
  decideKyc,
  decideVendor,
  manageBlacklist,
  manageDisputes,
  manageSubscriptions,
  toggleFlagship,
  viewActivityLog,
  // Dispute decisions are super admin + operations only; support may
  // view and triage the queue but not decide a dispute.
  decideDispute,
  // Support tickets: anyone with an admin role may reply and triage
  // (move to in_progress / escalate priority); only super admin +
  // operations may resolve (close) a ticket.
  triageTicket,
  resolveTicket,
  // Platform settings: cities list and announcements.
  managePlatform,
  // APK download: the latest release APK published by CI. Super admin
  // only — no other role may even see the download card.
  downloadApk,
}

abstract final class AdminPermissions {
  static const String superAdmin = 'super_admin';
  static const String operations = 'operations';
  static const String support = 'support';

  static const List<String> allRoles = [superAdmin, operations, support];

  static const Map<AdminPermission, List<String>> _matrix = {
    AdminPermission.manageTeam: [superAdmin],
    AdminPermission.decideKyc: [superAdmin, operations],
    AdminPermission.decideVendor: [superAdmin, operations],
    AdminPermission.manageBlacklist: [superAdmin, operations],
    AdminPermission.manageDisputes: [superAdmin, operations, support],
    AdminPermission.manageSubscriptions: [superAdmin, operations],
    AdminPermission.toggleFlagship: [superAdmin, operations],
    AdminPermission.viewActivityLog: [superAdmin, operations, support],
    AdminPermission.decideDispute: [superAdmin, operations],
    AdminPermission.triageTicket: [superAdmin, operations, support],
    AdminPermission.resolveTicket: [superAdmin, operations],
    AdminPermission.managePlatform: [superAdmin, operations],
    AdminPermission.downloadApk: [superAdmin],
  };

  static bool can(String? adminRole, AdminPermission permission) {
    if (adminRole == null) return false;
    return _matrix[permission]?.contains(adminRole) ?? false;
  }

  static String label(String? adminRole) {
    return switch (adminRole) {
      superAdmin => 'Super Admin',
      operations => 'Operations',
      support => 'Support',
      _ => 'Admin',
    };
  }
}
