import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../finance/data/datasources/finance_transfer_data_source.dart';
import '../../../../finance/domain/entities/finance_account_entity.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Phase B (H2): the form for one ledger entry. Salaries are
/// recorded here too — as an expense with the 'salary' category
/// and the person's name in the note. A vehicle can be tagged so
/// the entry shows up in that car's P&L.
class AddTransferSheet extends StatefulWidget {
  final String shopId;
  final List<FinanceAccountEntity> accounts;
  final List<VehicleEntity> vehicles;
  final VoidCallback onSaved;

  const AddTransferSheet({
    super.key,
    required this.shopId,
    required this.accounts,
    required this.vehicles,
    required this.onSaved,
  });

  @override
  State<AddTransferSheet> createState() => _AddTransferSheetState();
}

class _AddTransferSheetState extends State<AddTransferSheet> {
  String _kind = 'income';
  String _category = 'rent';
  String? _accountId;
  String? _vehicleId;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  static const _incomeCategories = ['rent', 'deposit', 'other'];
  static const _expenseCategories = [
    'fuel',
    'maintenance',
    'salary',
    'partner_share',
    'deposit_refund',
    'other',
  ];

  List<String> get _categories =>
      _kind == 'income' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _accountId =
        widget.accounts.where((a) => a.isDefault).firstOrNull?.accountId ??
            widget.accounts.firstOrNull?.accountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    if (_accountId == null) return;
    setState(() => _isSaving = true);
    try {
      await sl<FinanceTransferDataSource>().addTransfer(
        shopId: widget.shopId,
        accountId: _accountId!,
        kind: _kind,
        category: _category,
        amountPkr: amount,
        vehicleId: _vehicleId,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.financeAddTransfer),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text(l10n.financeIncome),
                  selected: _kind == 'income',
                  onSelected: (_) => setState(() {
                    _kind = 'income';
                    _category = 'rent';
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text(l10n.financeExpense),
                  selected: _kind == 'expense',
                  onSelected: (_) => setState(() {
                    _kind = 'expense';
                    _category = 'fuel';
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _category,
              decoration: InputDecoration(
                  labelText: l10n.financeCategoryLabel, border: OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(_categoryLabel(l10n, c))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? _categories.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: l10n.financeAmountRs, border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _accountId,
              decoration: InputDecoration(
                  labelText: l10n.financeAccountFallback, border: OutlineInputBorder()),
              items: widget.accounts
                  .map((a) =>
                      DropdownMenuItem(value: a.accountId, child: Text(a.name)))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _vehicleId,
              decoration: InputDecoration(
                  labelText: l10n.financeVehicleOptional,
                  border: OutlineInputBorder()),
              items: [
                DropdownMenuItem<String?>(
                    value: null, child: Text(l10n.financeNoVehicle)),
                ...widget.vehicles.map((v) => DropdownMenuItem<String?>(
                    value: v.vehicleId, child: Text(v.displayName))),
              ],
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                  labelText: l10n.financeNoteOptional,
                  hintText: l10n.financeNoteHint,
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        DebouncedButton(
          text: _isSaving ? l10n.editSaving : l10n.financeSaveEntry,
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// Stored ledger category codes mapped to localized labels — the
/// stored value itself is never changed.
String _categoryLabel(AppLocalizations l10n, String category) => {'rent': l10n.financeCategoryRent, 'deposit': l10n.addVehicleReviewDeposit, 'other': l10n.blacklistReasonOther, 'fuel': l10n.financeCategoryFuel, 'maintenance': l10n.fleetFilterMaintenance, 'salary': l10n.financeCategorySalary, 'partner_share': l10n.financeCategoryPartnerShare, 'deposit_refund': l10n.financeCategoryDepositRefund}[category] ?? category;
