import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../widgets/finance_settings_switch.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/data/datasources/finance_settings_data_source.dart';
import '../../../finance/domain/entities/finance_settings_entity.dart';

/// Audit impl (O48): finance settings — default currency (PKR,
/// display-only), tax / service charges (percentages, persisted
/// per shop), payment-method toggles, and receipt settings. The
/// auto-send WhatsApp receipt toggle only records the preference:
/// actual sending needs the WhatsApp Business setup (gate D2), and
/// the screen says so honestly.
class OwnerFinanceSettingsView extends StatefulWidget {
  final String shopId;

  const OwnerFinanceSettingsView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerFinanceSettingsView> createState() =>
      _OwnerFinanceSettingsViewState();
}

class _OwnerFinanceSettingsViewState extends State<OwnerFinanceSettingsView> {
  final _settingsDs = FinanceSettingsDataSource();
  final _taxController = TextEditingController();
  final _serviceController = TextEditingController();
  FinanceSettingsEntity? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;
  // OW-m9: dirty guard — the toggles + fields snapshot taken at load
  // (and refreshed on save); back with edits asks first.
  String _initialSnapshot = '';
  bool _discardConfirmed = false;

  String _snapshot() {
    final s = _settings;
    return '${_taxController.text}|${_serviceController.text}|${s?.paymentCash}|${s?.paymentBankTransfer}|${s?.paymentJazzCash}|${s?.paymentEasyPaisa}|${s?.autoSendReceipt}';
  }

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
          _taxController.text =
              settings.taxPercent == 0 ? '' : '${settings.taxPercent}';
          _serviceController.text = settings.serviceChargePercent == 0
              ? ''
              : '${settings.serviceChargePercent}';
          _initialSnapshot = _snapshot();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final current = _settings;
    if (current == null) return;
    final tax = double.tryParse(_taxController.text.trim());
    final service = double.tryParse(_serviceController.text.trim());
    if ((_taxController.text.trim().isNotEmpty && tax == null) ||
        (_serviceController.text.trim().isNotEmpty && service == null)) {
      AppFeedback.showError(context, l10n.financeSettingsInvalidPercent);
      return;
    }
    // OW-m9: −5% or 250% used to save happily — percentages are
    // clamped to 0–100 with a localized error.
    if ((tax != null && (tax < 0 || tax > 100)) ||
        (service != null && (service < 0 || service > 100))) {
      AppFeedback.showError(context, l10n.financeSettingsPercentRange);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _settingsDs.saveSettings(current.copyWith(
        taxPercent: tax ?? 0,
        serviceChargePercent: service ?? 0,
      ));
      if (mounted) {
        _initialSnapshot = _snapshot();
        AppFeedback.showSuccess(context, l10n.financeSettingsSaved);
      }
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// OW-m9: back with unsaved edits asks first (same dialog shape
  /// as the rate matrix, generic wording).
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
    _taxController.dispose();
    _serviceController.dispose();
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
              title: l10n.financeSettingsTitle,
              subtitle: l10n.financeSettingsSubtitle,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.dashboardLoadError, onRetry: _load)
                      : settings == null
                          ? AppEmptyState(
                              title: l10n.financeSettingsEmpty,
                              icon: Icons.settings_rounded)
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(l10n.financeSettingsCurrency),
                                    subtitle: Text(
                                        l10n.financeSettingsCurrencyNote),
                                    trailing: Text(
                                      settings.currency,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _taxController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                        labelText:
                                            l10n.financeSettingsTax,
                                        suffixText: '%',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _serviceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: InputDecoration(
                                        labelText:
                                            l10n.financeSettingsServiceCharge,
                                        suffixText: '%',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                                  ),
                                  const SizedBox(height: 20),
                                  _sectionTitle(l10n.financeSettingsPaymentMethods),
                                  FinanceSettingsSwitch(title: l10n.financePaymentCash, value: settings.paymentCash, onChanged: (v) => setState(() => _settings = settings.copyWith(paymentCash: v))),
                                  FinanceSettingsSwitch(title: l10n.financePaymentBank, value: settings.paymentBankTransfer, onChanged: (v) => setState(() => _settings = settings.copyWith(paymentBankTransfer: v))),
                                  FinanceSettingsSwitch(title: l10n.financePaymentJazzCash, value: settings.paymentJazzCash, onChanged: (v) => setState(() => _settings = settings.copyWith(paymentJazzCash: v))),
                                  FinanceSettingsSwitch(title: l10n.financePaymentEasyPaisa, value: settings.paymentEasyPaisa, onChanged: (v) => setState(() => _settings = settings.copyWith(paymentEasyPaisa: v))),
                                  const SizedBox(height: 20),
                                  _sectionTitle(l10n.financeSettingsReceipts),
                                  FinanceSettingsSwitch(title: l10n.financeSettingsAutoReceipt, subtitle: l10n.financeSettingsAutoReceiptNote, value: settings.autoSendReceipt, onChanged: (v) => setState(() => _settings = settings.copyWith(autoSendReceipt: v))),
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

  Widget _sectionTitle(String title) {
    return Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ));
  }
}
