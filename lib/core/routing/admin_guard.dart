class AdminGuard {
  static const String masterSuperAdminEmail = 'superadmin@rentalhub.pk';

  static bool verifySuperAdmin({
    required String? email,
    required String? role,
  }) {
    if (email == null || role == null) return false;
    return email.trim().toLowerCase() == masterSuperAdminEmail &&
        role == 'super_admin';
  }
}

