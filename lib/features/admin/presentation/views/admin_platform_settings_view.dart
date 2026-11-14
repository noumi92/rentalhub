import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../../data/services/admin_apk_release_service.dart';
import '../widgets/admin_apk_download_card.dart';
import '../widgets/admin_platform_settings_form.dart';
import '../widgets/admin_shell.dart';

/// Phase E (E2) — cities & settings: the single
/// `platform_settings/global` document — live cities, car categories,
/// and the global defaults (advance %, default deposit, late grace,
/// support hours, default agreement terms). This replaces the old
/// mock settings view.
///
/// Customer rework (Worker E): the two unverified-shop toggles live
/// here too — "Display unverified shops" and "Allow bookings from
/// unverified shops". Both default ON; the customer side reads them
/// through [PlatformSettingsRepository] and treats a missing
/// document/field as ON.
class AdminPlatformSettingsView extends StatefulWidget {
  final AdminSupportDataSource? dataSource;

  /// The signed-in admin's role, forwarded to the APK download card.
  /// The router leaves it null and the card resolves it from the
  /// signed-in user; tests pass it directly.
  final String? adminRole;

  /// Role resolver override for tests.
  final Future<String?> Function()? resolveAdminRole;

  /// APK release service override for tests.
  final AdminApkReleaseService? apkReleaseService;

  const AdminPlatformSettingsView({super.key, this.dataSource, this.adminRole, this.resolveAdminRole, this.apkReleaseService});

  @override
  State<AdminPlatformSettingsView> createState() =>
      _AdminPlatformSettingsViewState();
}

class _AdminPlatformSettingsViewState
    extends State<AdminPlatformSettingsView> {
  final _citiesController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _advanceController = TextEditingController();
  final _depositController = TextEditingController();
  final _graceController = TextEditingController();
  final _hoursController = TextEditingController();
  final _termsController = TextEditingController();
  bool _maintenanceMode = false;
  bool _displayUnverifiedShops = true;
  bool _allowBookingsFromUnverifiedShops = true;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;

  AdminSupportDataSource get _dataSource =>
      widget.dataSource ?? sl<AdminSupportDataSource>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _citiesController.dispose();
    _categoriesController.dispose();
    _advanceController.dispose();
    _depositController.dispose();
    _graceController.dispose();
    _hoursController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final settings = await _dataSource.getPlatformSettings();
      if (!mounted) return;
      _citiesController.text = settings.liveCities.join(', ');
      _categoriesController.text = settings.carCategories.join(', ');
      _advanceController.text = settings.advancePercent.toString();
      _depositController.text = settings.defaultDepositPkr.toString();
      _graceController.text = settings.lateGraceMinutes.toString();
      _hoursController.text = settings.supportHours;
      _termsController.text = settings.defaultAgreementTerms;
      setState(() {
        _maintenanceMode = settings.maintenanceMode;
        _displayUnverifiedShops = settings.displayUnverifiedShops;
        _allowBookingsFromUnverifiedShops =
            settings.allowBookingsFromUnverifiedShops;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final advance = int.tryParse(_advanceController.text.trim());
    final deposit = int.tryParse(_depositController.text.trim());
    final grace = int.tryParse(_graceController.text.trim());
    if (advance == null || deposit == null || grace == null) {
      AppFeedback.showError(
          context, 'Advance %, deposit and late grace must be numbers.');
      return;
    }
    setState(() => _isSaving = true);
    final synced = await _dataSource.savePlatformSettings(
      PlatformSettings(
        liveCities: _citiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        carCategories: _categoriesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        advancePercent: advance,
        defaultDepositPkr: deposit,
        lateGraceMinutes: grace,
        supportHours: _hoursController.text.trim(),
        defaultAgreementTerms: _termsController.text.trim(),
        maintenanceMode: _maintenanceMode,
        displayUnverifiedShops: _displayUnverifiedShops,
        allowBookingsFromUnverifiedShops:
            _allowBookingsFromUnverifiedShops,
      ),
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context, 'Platform settings saved.');
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminSettings,
      title: 'Cities & settings',
      subtitle: 'The platform defaults, in one document',
      onRefresh: _load,
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: 'Could not load the platform settings.',
                  onRetry: _load,
                )
              : SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPlatformSettingsForm(
                    citiesController: _citiesController,
                    categoriesController: _categoriesController,
                    advanceController: _advanceController,
                    depositController: _depositController,
                    graceController: _graceController,
                    hoursController: _hoursController,
                    termsController: _termsController,
                    maintenanceMode: _maintenanceMode,
                    displayUnverifiedShops: _displayUnverifiedShops,
                    allowBookingsFromUnverifiedShops:
                        _allowBookingsFromUnverifiedShops,
                    isSaving: _isSaving,
                    onMaintenanceChanged: (v) =>
                        setState(() => _maintenanceMode = v),
                    onDisplayChanged: (v) =>
                        setState(() => _displayUnverifiedShops = v),
                    onAllowChanged: (v) => setState(
                        () => _allowBookingsFromUnverifiedShops = v),
                    onSave: _save,
                  ),
                  // Super admin only: the card hides itself for any
                  // other role (and while the role is resolving).
                  AdminApkDownloadCard(
                    adminRole: widget.adminRole,
                    resolveAdminRole: widget.resolveAdminRole,
                    service: widget.apkReleaseService,
                  ),
                ],
              ),
            ),
    );
  }

}
