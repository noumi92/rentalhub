import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/admin_apk_release_service.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_apk_download_card.dart';
import '../widgets/admin_shell.dart';

/// The "APK Download" sidebar section: the mobile APK download as its
/// own section instead of only a card inside Settings.
///
/// The view resolves the signed-in admin's role once and passes it to
/// the card, so the card does not resolve it again. Any other role gets
/// an honest "super admins only" state instead of the download — the
/// APK and its version are never shown to them.
class AdminApkDownloadView extends StatefulWidget {
  const AdminApkDownloadView({
    super.key,
    this.adminRole,
    this.resolveAdminRole,
    this.service,
  });

  /// The signed-in admin's role. Tests pass it directly; the router
  /// leaves it null and the view resolves it from the signed-in user.
  final String? adminRole;

  /// Role resolver override for tests. Defaults to
  /// [AdminSession.resolveAdminRole] on the signed-in user.
  final Future<String?> Function()? resolveAdminRole;

  /// Release service override for tests. Defaults to a service that
  /// reads `apk/version.json` relative to the panel's own URL.
  final AdminApkReleaseService? service;

  @override
  State<AdminApkDownloadView> createState() => _AdminApkDownloadViewState();
}

class _AdminApkDownloadViewState extends State<AdminApkDownloadView> {
  String? _role;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    var role = widget.adminRole;
    if (role == null) {
      if (widget.resolveAdminRole != null) {
        role = await widget.resolveAdminRole!();
      } else {
        User? user;
        try {
          user = FirebaseAuth.instance.currentUser;
        } catch (_) {}
        if (user != null) {
          role = await AdminSession.resolveAdminRole(user);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _role = role;
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The admin panel pumps without localizations delegates in tests,
    // so every string falls back to English.
    final l10n = AppLocalizations.of(context);
    return AdminShell(
      activeRoute: RouteNames.adminApkDownload,
      title: 'APK Download',
      subtitle: l10n?.admin2_apkDownloadSubtitle ??
          'Latest release build published by CI.',
      child: _resolving
          ? const AppLoadingState()
          : !AdminPermissions.can(_role, AdminPermission.downloadApk)
              ? AppEmptyState(
                  title: l10n?.admin2_apkSuperAdminOnly ??
                      'Only super admins can download the APK',
                  message: l10n?.admin2_apkSuperAdminOnlyHint ??
                      'Ask a super admin for the latest build.',
                  icon: Icons.lock_rounded,
                )
              : AdminApkDownloadCard(
                  adminRole: _role,
                  service: widget.service,
                ),
    );
  }
}
