import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../blacklist/domain/entities/blacklist_entity.dart';

/// Phase B (C4): report a customer to the shared blacklist and see
/// the reports this shop filed. Reports are stored in Firestore, so
/// other shops see them too. Only an admin can revert a report —
/// the tribunal reviews it — so the list here is read-only.
class OwnerBlacklistView extends StatefulWidget {
  final String? shopId;
  final VoidCallback? onBack;

  const OwnerBlacklistView({super.key, this.shopId, this.onBack});

  @override
  State<OwnerBlacklistView> createState() => _OwnerBlacklistViewState();
}

class _OwnerBlacklistViewState extends State<OwnerBlacklistView> {
  static const _reasons = [
    'Non-payment',
    'Car damage',
    'Late return',
    'Fraud / fake documents',
    'Default & Car Impoundment',
    'Other',
  ];

  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _reason = _reasons.first;
  List<BlacklistEntity> _reports = [];
  bool _loading = true;
  // Audit §22/C4: a load failure used to spin forever — now an error
  // state with retry. Audit §22: All/Active/Reverted filter.
  bool _hasError = false;
  String _filter = 'all';

  String get _shopId => widget.shopId ?? currentShopId();

  List<BlacklistEntity> get _filtered => _filter == 'active' ? _reports.where((r) => r.isActive).toList() : _filter == 'reverted' ? _reports.where((r) => !r.isActive).toList() : _reports;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cnicController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _hasError = false; });
    try {
      final reports = await sl<BlacklistRemoteDataSource>().getShopReports(_shopId);
      if (!mounted) return;
      setState(() { _reports = reports; _loading = false; });
    } catch (e) {
      // OW-m37: the raw exception goes to the log only — the owner
      // sees a localized message, never "Exception: ...".
      debugPrint('Blacklist load failed: $e');
      if (mounted) setState(() { _hasError = true; _loading = false; });
    }
  }

  Future<void> _submit() async {
  final l10n = AppLocalizations.of(context)!;
    final cnic = _cnicController.text.trim();
    final phone = _phoneController.text.trim();
    final description = _descriptionController.text.trim();
    if (cnic.replaceAll('-', '').trim().length != 13) {
      AppFeedback.showError(context, l10n.blacklistEnterCnic);
      return;
    }
    if (description.isEmpty) {
      AppFeedback.showError(context, l10n.blacklistDescribe);
      return;
    }
    setState(() => _submitting = true);
    try {
      await sl<BlacklistRemoteDataSource>().reportCustomerToBlacklist(
        reportedByShopId: _shopId,
        cnicNumber: cnic,
        phoneNumber: phone,
        reasonCategory: _reason,
        description: description,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.blacklistReported);
      _cnicController.clear();
      _phoneController.clear();
      _descriptionController.clear();
      await _load();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.blacklistReportFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _submitting = false;

  Widget _field(TextEditingController controller, String label,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final reports = _filtered;
    return Scaffold(
      // C1: MinimalAppBar owns the top inset — no double status bar.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.blacklist,
              subtitle: l10n.blacklistSubtitle,
              onBack: widget.onBack ?? () => context.pop(),
            ),
            Expanded(
              child: _loading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(message: l10n.blacklistLoadError, onRetry: _load)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Audit §22: the report form is its own
                              // card, separated from the history below.
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.blacklistReportTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 10),
                                      _field(_cnicController, l10n.blacklistCustomerCnic, keyboard: TextInputType.number),
                                      _field(_phoneController, l10n.blacklistCustomerPhone, keyboard: TextInputType.phone),
                                      DropdownButtonFormField<String>(
                                        dropdownColor: Theme.of(context).colorScheme.surface,
                                        initialValue: _reason,
                                        decoration: InputDecoration(labelText: l10n.blacklistReasonLabel, border: const OutlineInputBorder(), filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest),
                                        items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(_reasonLabel(l10n, r)))).toList(),
                                        onChanged: (r) => setState(() => _reason = r ?? _reason),
                                      ),
                                      const SizedBox(height: 12),
                                      _field(_descriptionController, l10n.blacklistWhatHappened, maxLines: 3),
                                      // Audit §22/C7: 54dp DebouncedButton.
                                      DebouncedButton(text: l10n.blacklistReportButton, icon: Icons.flag_rounded, isLoading: _submitting, onPressed: _submit),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(l10n.blacklistMyReports(_reports.length), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              // Audit §22: All/Active/Reverted filter.
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(label: Text(l10n.filterAll), selected: _filter == 'all', onSelected: (_) => setState(() => _filter = 'all')),
                                  ChoiceChip(label: Text(l10n.active), selected: _filter == 'active', onSelected: (_) => setState(() => _filter = 'active')),
                                  ChoiceChip(label: Text(l10n.blacklistReverted), selected: _filter == 'reverted', onSelected: (_) => setState(() => _filter = 'reverted')),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (reports.isEmpty)
                                AppEmptyState(title: l10n.blacklistNoReports, icon: Icons.flag_outlined)
                              else
                                ...reports.map((r) => Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        leading: Icon(Icons.flag_rounded, color: r.isActive ? AppColors.errorDark : Theme.of(context).colorScheme.onSurfaceVariant),
                                        title: Text(r.cnicNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text('${_reasonLabel(l10n, r.reasonCategory)}\n${r.description}'),
                                        isThreeLine: true,
                                        trailing: Chip(
                                          label: Text(r.isActive ? l10n.active : l10n.blacklistReverted, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                                          // Audit §22: white on
                                          // Colors.red is 3.68:1 —
                                          // errorDark #DC2626 is ~4.9:1.
                                          // (Reverted keeps textMuted,
                                          // 4.76:1 — already passing.)
                                          backgroundColor: r.isActive ? AppColors.errorDark : AppColors.textMuted,
                                        ),
                                      ),
                                    )),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stored blacklist reason categories mapped to localized labels —
/// the stored value itself is never changed.
String _reasonLabel(AppLocalizations l10n, String reason) => {'Non-payment': l10n.blacklistReasonNonPayment, 'Car damage': l10n.blacklistReasonCarDamage, 'Late return': l10n.blacklistReasonLateReturn, 'Fraud / fake documents': l10n.blacklistReasonFraud, 'Default & Car Impoundment': l10n.blacklistReasonImpoundment, 'Other': l10n.blacklistReasonOther}[reason] ?? reason;
