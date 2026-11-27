import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../widgets/admin_confirm_dialog.dart';
import '../widgets/admin_permission_check.dart';
import '../widgets/admin_platform_settings_form.dart';
import '../widgets/admin_settings_draft.dart';
import '../widgets/admin_shell.dart';

/// Phase E (E2) — cities & settings: the single
/// `platform_settings/global` document — live cities, car categories,
/// and the global defaults (advance %, default deposit, late grace,
/// support hours, default agreement terms).
///
/// Customer rework (Worker E): the two unverified-shop toggles live
/// here too — "Display unverified shops" and "Allow bookings from
/// unverified shops". Both default ON; the customer side reads them
/// through [PlatformSettingsRepository] and treats a missing
/// document/field as ON.
///
/// The editable state lives in [AdminSettingsDraft] (controllers,
/// validation, dirty guard); this view only loads, guards the save,
/// and renders.
class AdminPlatformSettingsView extends StatefulWidget {
  final AdminSupportDataSource? dataSource;

  const AdminPlatformSettingsView({super.key, this.dataSource});

  @override
  State<AdminPlatformSettingsView> createState() =>
      _AdminPlatformSettingsViewState();
}

class _AdminPlatformSettingsViewState
    extends State<AdminPlatformSettingsView> {
  final _draft = AdminSettingsDraft();
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;
  // F-M12 / AD-M12: `_loadSucceeded` guards the save (never save
  // from a failed load); `_noDocument` marks "no settings saved
  // yet"; `_allowPop` lets a confirmed discard through the guard.
  bool _noDocument = false;
  bool _loadSucceeded = false;
  bool _allowPop = false;
  Map<String, String> _fieldErrors = {};

  AdminSupportDataSource get _dataSource =>
      widget.dataSource ?? sl<AdminSupportDataSource>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      // F-M12: null means no settings document exists yet — the
      // form shows the factory defaults with an explicit banner and
      // Save creates the document. A throw means the read failed:
      // the error state shows and Save is unreachable.
      final loaded = await _dataSource.getPlatformSettings();
      if (!mounted) return;
      _draft.apply(loaded ?? const PlatformSettings());
      setState(() {
        _noDocument = loaded == null;
        _loadSucceeded = true;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop || !_draft.isDirty) return;
    final leave = await showAdminConfirmDialog(
      context,
      title: AppLocalizations.of(context)?.admin2_settingsUnsavedTitle ??
          'Leave without saving?',
      body: AppLocalizations.of(context)?.admin2_settingsUnsavedBody ??
          'You have unsaved changes. They will be lost if you leave.',
    );
    if (leave && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    if (!_loadSucceeded) {
      AppFeedback.showError(
          context,
          AppLocalizations.of(context)?.admin2_settingsNotLoaded ??
              'Settings have not loaded yet — try again.');
      return;
    }
    // AD-M12: range validation with localised inline errors.
    final errors = _draft.validate(AppLocalizations.of(context));
    setState(() => _fieldErrors = errors);
    if (errors.isNotEmpty) return;
    final advance = int.parse(_draft.advanceController.text.trim());
    final deposit = int.parse(_draft.depositController.text.trim());
    final grace = int.parse(_draft.graceController.text.trim());
    // F-C1: super admin + operations only (managePlatform). See
    // the shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.managePlatform);
    if (!check.proceed) return;
    setState(() => _isSaving = true);
    final synced = await _dataSource.savePlatformSettings(
      _draft.toSettings(advance: advance, deposit: deposit, grace: grace),
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(
          context,
          AppLocalizations.of(context)?.admin2_settingsSaved ??
              'Platform settings saved.');
      // The saved values are the new clean state; the document
      // exists now even when this save created it.
      setState(() {
        _draft.loaded = _draft.toSettings(
            advance: advance, deposit: deposit, grace: grace);
        _noDocument = false;
      });
    } else {
      AppFeedback.showError(
          context,
          AppLocalizations.of(context)?.admin2_serverUnreachable ??
              'Could not reach the server.');
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return PopScope(
      // AD-M12 dirty guard: leaving (system back / browser back)
      // with unsaved edits asks first. Sidebar section switches
      // use `go` rather than a pop, so they are not covered.
      canPop: !_draft.isDirty || _allowPop,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: AdminShell(
        activeRoute: RouteNames.adminSettings,
        title: AppLocalizations.of(context)?.admin2_settingsTitle ??
            'Cities & settings',
        subtitle: AppLocalizations.of(context)?.admin2_settingsSubtitle ??
            'The platform defaults, in one document',
        onRefresh: _load,
        child: _isLoading
            ? const AppLoadingState()
            : _hasError
                ? AppErrorState(
                    message: AppLocalizations.of(context)
                            ?.admin2_settingsLoadFailed ??
                        'Could not load the platform settings.',
                    onRetry: _load,
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(compact ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdminPlatformSettingsForm(
                          draft: _draft,
                          isSaving: _isSaving,
                          noDocument: _noDocument,
                          fieldErrors: _fieldErrors,
                          onChanged: () => setState(() {}),
                          onSave: _save,
                        ),
                        // Phase 1 (1.3): the APK download card lived
                        // here too — the standalone /admin/apk-download
                        // route is now the only path to it.
                      ],
                    ),
                  ),
      ),
    );
  }
}
