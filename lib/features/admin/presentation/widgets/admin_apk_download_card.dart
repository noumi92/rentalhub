import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/admin_apk_release_service.dart';
import '../../data/services/admin_session.dart';
import '../../domain/admin_permissions.dart';

/// Super-admin-only APK download card for the Settings screen.
///
/// The card resolves the signed-in admin's role exactly the way
/// [AdminTeamView] does and stays hidden entirely for any other role.
/// For a super admin it reads the latest build from `apk/version.json`
/// (published by CI to cPanel on every master push) and offers the APK
/// for download. A missing file means no build has been published yet —
/// the card says so instead of showing a version that does not exist.
class AdminApkDownloadCard extends StatefulWidget {
  const AdminApkDownloadCard({
    super.key,
    this.adminRole,
    this.resolveAdminRole,
    this.service,
  });

  /// The signed-in admin's role. Tests pass it directly; the router
  /// leaves it null and the card resolves it from the signed-in user.
  final String? adminRole;

  /// Role resolver override for tests. Defaults to
  /// [AdminSession.resolveAdminRole] on the signed-in user.
  final Future<String?> Function()? resolveAdminRole;

  /// Release service override for tests. Defaults to a service that
  /// reads `apk/version.json` relative to the panel's own URL.
  final AdminApkReleaseService? service;

  @override
  State<AdminApkDownloadCard> createState() => _AdminApkDownloadCardState();
}

class _AdminApkDownloadCardState extends State<AdminApkDownloadCard> {
  bool _visible = false;
  bool _loading = true;
  bool _failed = false;
  AppReleaseInfo? _info;
  late final AdminApkReleaseService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminApkReleaseService();
    _resolveAndLoad();
  }

  Future<void> _resolveAndLoad() async {
    // AD-M5: a throw in the role resolution used to leave the card
    // hidden with no feedback (and _loading stuck true). It is
    // caught here; the card simply stays hidden for a non-super-admin
    // or an unresolvable role.
    try {
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
      if (!AdminPermissions.can(role, AdminPermission.downloadApk)) {
        setState(() => _loading = false);
        return;
      }
      setState(() => _visible = true);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final info = await _service.fetchLatest();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _info = null;
        _loading = false;
        _failed = true;
      });
    } catch (_) {
      // AD-M5: any other failure (network, timeout, …) used to
      // escape uncaught and spin the loader forever. It now lands
      // on the failed state, where the retry button already exists.
      if (!mounted) return;
      setState(() {
        _info = null;
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _download() async {
    final info = _info;
    if (info == null) return;
    final uri = _service.downloadUriFor(info);
    final l10n = AppLocalizations.of(context);
    try {
      final opened =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        AppFeedback.showError(
            context,
            l10n?.admin2_apkDownloadFailed ??
                'Could not open the download link.');
      }
    } catch (_) {
      if (!mounted) return;
      AppFeedback.showError(context,
          l10n?.admin2_apkDownloadFailed ?? 'Could not open the download link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    // The admin panel pumps without localizations delegates in
    // tests, so every string falls back to English.
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.android_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.admin2_apkDownloadTitle ??
                            'Android app (APK)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        l10n?.admin2_apkDownloadSubtitle ??
                            'Latest release build published by CI.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n?.admin2_apkLoading ??
                        'Checking for the latest build…'),
                  ),
                ],
              )
            else if (_failed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n?.admin2_apkLoadFailed ??
                      'Could not load the latest build.'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _load,
                    child: Text(
                        l10n?.commonRetry ?? 'Retry'),
                  ),
                ],
              )
            else if (_info == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n?.admin2_apkNoBuild ?? 'No build published yet'),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.admin2_apkNoBuildHint ??
                        'The APK appears here after CI publishes a release build.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_info!.versionName != null ||
                      _info!.versionCode != null)
                    _row(
                      l10n?.admin2_apkVersion ?? 'Version',
                      _versionLabel(_info!),
                    ),
                  if (_info!.build != null)
                    _row(
                      l10n?.admin2_apkBuild ?? 'Build',
                      _info!.build.toString(),
                    ),
                  if (_info!.updatedAt != null)
                    _row(
                      l10n?.admin2_apkUpdated ?? 'Updated',
                      _formatUpdated(_info!.updatedAt!),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _download,
                      icon: const Icon(Icons.download_rounded),
                      label: Text(l10n?.admin2_apkDownloadButton ??
                          'Download APK'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.admin2_apkDownloadLink ?? 'Download link',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SelectableText(
                    _service.downloadUriFor(_info!).toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _versionLabel(AppReleaseInfo info) {
    final name = info.versionName;
    final code = info.versionCode;
    if (name != null && code != null) return '$name (code $code)';
    if (name != null) return name;
    return code.toString();
  }

  String _formatUpdated(DateTime updatedAt) {
    final utc = updatedAt.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
        '${two(utc.hour)}:${two(utc.minute)} UTC';
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
