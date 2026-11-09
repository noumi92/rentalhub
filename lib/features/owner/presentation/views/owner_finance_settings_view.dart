import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
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
    setState(() => _isSaving = true);
    try {
      await _settingsDs.saveSettings(current.copyWith(
        taxPercent: tax ?? 0,
        serviceChargePercent: service ?? 0,
      ));
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.financeSettingsSaved);
      }
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.shopSaveError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    return Scaffold(
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
                                              fontWeight: FontWeight.w900),
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
                                        border: const OutlineInputBorder()),
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
                                        border: const OutlineInputBorder()),
                                  ),
                                  const SizedBox(height: 20),
                                  _sectionTitle(l10n.financeSettingsPaymentMethods),
                                  SwitchListTile(
                                    title: Text(l10n.financePaymentCash),
                                    value: settings.paymentCash,
                                    onChanged: (v) => setState(() =>
                                        _settings = settings.copyWith(
                                            paymentCash: v)),
                                  ),
                                  SwitchListTile(
                                    title:
                                        Text(l10n.financePaymentBank),
                                    value: settings.paymentBankTransfer,
                                    onChanged: (v) => setState(() =>
                                        _settings = settings.copyWith(
                                            paymentBankTransfer: v)),
                                  ),
                                  SwitchListTile(
                                    title:
                                        Text(l10n.financePaymentJazzCash),
                                    value: settings.paymentJazzCash,
                                    onChanged: (v) => setState(() =>
                                        _settings = settings.copyWith(
                                            paymentJazzCash: v)),
                                  ),
                                  SwitchListTile(
                                    title:
                                        Text(l10n.financePaymentEasyPaisa),
                                    value: settings.paymentEasyPaisa,
                                    onChanged: (v) => setState(() =>
                                        _settings = settings.copyWith(
                                            paymentEasyPaisa: v)),
                                  ),
                                  const SizedBox(height: 20),
                                  _sectionTitle(l10n.financeSettingsReceipts),
                                  SwitchListTile(
                                    title: Text(
                                        l10n.financeSettingsAutoReceipt),
                                    subtitle: Text(
                                        l10n.financeSettingsAutoReceiptNote),
                                    value: settings.autoSendReceipt,
                                    onChanged: (v) => setState(() =>
                                        _settings = settings.copyWith(
                                            autoSendReceipt: v)),
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
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ));
  }
}
