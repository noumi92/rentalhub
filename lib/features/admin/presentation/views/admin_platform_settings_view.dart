import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
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

  const AdminPlatformSettingsView({super.key, this.dataSource});

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
    // The admin panel pumps without localizations delegates in
    // tests, so every toggle label falls back to English.
    final l10n = AppLocalizations.of(context);
    return AdminShell(
      activeRoute: RouteNames.adminSettings,
      title: 'Cities & settings',
      subtitle: 'The platform defaults, in one document',
      onRefresh: _load,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('Live cities (comma-separated)',
                      _citiesController),
                  _field('Car categories (comma-separated)',
                      _categoriesController),
                  _field('Advance %', _advanceController,
                      keyboardType: TextInputType.number),
                  _field('Default deposit (Rs.)', _depositController,
                      keyboardType: TextInputType.number),
                  _field('Late grace (minutes)', _graceController,
                      keyboardType: TextInputType.number),
                  _field('Support hours', _hoursController),
                  _field('Default agreement terms', _termsController,
                      maxLines: 3),
                  SwitchListTile(
                    title: const Text('Maintenance mode'),
                    subtitle: const Text(
                        'When on, the app shows a maintenance notice.'),
                    value: _maintenanceMode,
                    onChanged: (v) =>
                        setState(() => _maintenanceMode = v),
                  ),
                  SwitchListTile(
                    title: Text(l10n?.admin2_displayUnverifiedShops ??
                        'Display unverified shops'),
                    subtitle: Text(
                        l10n?.admin2_displayUnverifiedShopsHint ??
                            'When off, unverified shops are hidden from the Shops tab.'),
                    value: _displayUnverifiedShops,
                    onChanged: (v) =>
                        setState(() => _displayUnverifiedShops = v),
                  ),
                  SwitchListTile(
                    title: Text(
                        l10n?.admin2_allowBookingsFromUnverifiedShops ??
                            'Allow bookings from unverified shops'),
                    subtitle: Text(
                        l10n?.admin2_allowBookingsFromUnverifiedShopsHint ??
                            'When off, customers cannot book from unverified shops.'),
                    value: _allowBookingsFromUnverifiedShops,
                    onChanged: (v) => setState(
                        () => _allowBookingsFromUnverifiedShops = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: Text(
                          _isSaving ? 'Saving…' : 'Save settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
