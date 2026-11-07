import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_shell.dart';

/// Phase E (E2) — cities & settings: the single
/// `platform_settings/global` document — live cities, car categories,
/// and the global defaults (advance %, default deposit, late grace,
/// support hours, default agreement terms). This replaces the old
/// mock settings view.
class AdminPlatformSettingsView extends StatefulWidget {
  const AdminPlatformSettingsView({super.key});

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
  bool _isLoading = true;
  bool _isSaving = false;

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
    final settings =
        await sl<AdminSupportDataSource>().getPlatformSettings();
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
    final synced = await sl<AdminSupportDataSource>().savePlatformSettings(
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
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
