import '../../features/admin/domain/admin_permissions.dart';

/// Phase A (A3) — the admin gate, actually called by the router
/// (AuthRouteGuard) on every /admin navigation.
///
/// The old version hardcoded one email (`superadmin@rentalhub.pk`) and
/// was never called from `lib/` — any visitor could open the panel.
/// The real check is the role: the users doc `admin_role` (or the
/// custom claim), resolved by AdminSession. No email is special.
abstract final class AdminGuard {
  static bool isAdminRole(String? adminRole) =>
      AdminPermissions.allRoles.contains(adminRole);

  static bool isSuperAdmin(String? adminRole) =>
      adminRole == AdminPermissions.superAdmin;

  static bool can(String? adminRole, AdminPermission permission) =>
      AdminPermissions.can(adminRole, permission);
}
