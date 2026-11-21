import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_settings_data_source.dart';
import '../../../bookings/domain/entities/booking_settings_entity.dart';

/// Worker A (2026-11-21): booking general settings — the shop's
/// driver rate (Rs/day). SHOP-SCOPED: one rate for the whole shop,
/// charged on top of the package price whenever a trip has a driver.
/// It replaces the per-vehicle `withDriverSurchargePkr` for pricing.
/// Empty means unset: trips with a driver add no extra charge. A
/// change here never rewrites already-booked trips — pricing reads
/// the setting only at booking time; settlements read the booked
/// amounts.
class OwnerBookingSettingsView extends StatefulWidget {
  final String shopId;

  const OwnerBookingSettingsView({super.key, required this.shopId});

  @override
  State<OwnerBookingSettingsView> createState() =>
      _OwnerBookingSettingsViewState();
}

class _OwnerBookingSettingsViewState extends State<OwnerBookingSettingsView> {
  final _settingsDs = BookingSettingsDataSource();
  final _rateController = TextEditingController();
  BookingSettingsEntity? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;
  String _initialSnapshot = '';
  bool _discardConfirmed = false;

  String _snapshot() => _rateController.text;

  bool get _isDirty => _settings != null && _snapshot() != _initialSnapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final settings = await _settingsDs.getSettings(widget.shopId);
      if (mounted) {
        setState(() {
          _settings = settings;
          _rateController.text =
              settings.driverRatePerDayPkr?.toString() ?? '';
          _initialSnapshot = _snapshot();
        });
      }
    } catch (e) {
      debugPrint('OwnerBookingSettingsView load failed: $e');
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final current = _settings;
    if (current == null) return;
    final text = _rateController.text.trim();
    final rate = text.isEmpty ? null : int.tryParse(text);
    if (text.isNotEmpty && (rate == null || rate < 0)) {
      AppFeedback.showError(context, l10n.bookingSettingsInvalidRate);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _settingsDs.saveSettings(current.copyWith(
        driverRatePerDayPkr: rate,
        clearDriverRate: rate == null,
      ));
      if (mounted) {
        _initialSnapshot = _snapshot();
        AppFeedback.showSuccess(context, l10n.bookingSettingsSaved);
      }
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleBack() async {
    if (!_isDirty) {
      if (mounted) context.pop();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesBody),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)), FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.syncDiscard))],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _discardConfirmed = true);
      context.pop();
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = _settings;
    return PopScope(
      canPop: !_isDirty || _discardConfirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              MinimalAppBar(
                title: l10n.bookingSettingsTitle,
                subtitle: l10n.bookingSettingsSubtitle,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: _isLoading
                    ? const AppLoadingState()
                    : _hasError
                        ? AppErrorState(
                            message: l10n.bookingSettingsLoadError,
                            onRetry: _load)
                        : settings == null
                            ? AppEmptyState(
                                title: l10n.bookingSettingsEmpty,
                                icon: Icons.settings_rounded)
                            : SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _rateController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText:
                                            l10n.bookingSettingsDriverRate,
                                        prefixText: l10n.currencyPrefix,
                                        suffixText:
                                            l10n.addVehiclePerDaySuffix,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      settings.driverRatePerDayPkr == null
                                          ? l10n
                                              .bookingSettingsDriverRateUnset
                                          : l10n
                                              .bookingSettingsDriverRateNote,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    const SizedBox(height: 20),
                                    DebouncedButton(
                                      text: l10n.financeSettingsSave,
                                      isLoading: _isSaving,
                                      onPressed: _save,
                                    ),
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
