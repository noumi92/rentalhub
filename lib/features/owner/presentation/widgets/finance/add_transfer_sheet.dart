import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../finance/data/datasources/finance_category_data_source.dart';
import '../../../../finance/data/datasources/finance_transfer_data_source.dart';
import '../../../../finance/domain/entities/finance_account_entity.dart';
import '../../../../finance/domain/entities/finance_category_entity.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Phase B (H2): the form for one ledger entry. Salaries are
/// recorded here too — as an expense with the 'salary' category
/// and the person's name in the note. A vehicle can be tagged so
/// the entry shows up in that car's P&L.
/// Audit impl (O35/O36): a Date field (defaults to today), a
/// Payment Method (Cash / Bank Transfer / JazzCash / EasyPaisa),
/// an "Advance" income source, a Booking # link, and a "Wash"
/// expense category. Categories are read from the
/// `finance_categories` collection, with the old hardcoded lists
/// as fallback defaults seeded on first use — the single "Add
/// entry" dialog is kept, not split into two screens.
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
  final _categoryDs = FinanceCategoryDataSource();
  String _kind = 'income';
  String _category = 'rent';
  String? _accountId;
  String? _vehicleId;
  String _paymentMethod = 'cash';
  DateTime _date = DateTime.now();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _bookingIdController = TextEditingController();
  List<FinanceCategoryEntity> _incomeCategories = [];
  List<FinanceCategoryEntity> _expenseCategories = [];
  bool _isSaving = false;

  static const _incomeFallback = ['rent', 'advance', 'deposit', 'other'];
  static const _expenseFallback = [
    'fuel',
    'maintenance',
    'wash',
    'salary',
    'partner_share',
    'deposit_refund',
    'other',
  ];

  List<String> get _categories {
    final loaded =
        _kind == 'income' ? _incomeCategories : _expenseCategories;
    if (loaded.isEmpty) {
      return _kind == 'income' ? _incomeFallback : _expenseFallback;
    }
    return loaded.map((c) => c.code).toList();
  }

  @override
  void initState() {
    super.initState();
    _accountId =
        widget.accounts.where((a) => a.isDefault).firstOrNull?.accountId ??
            widget.accounts.firstOrNull?.accountId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final income = await _categoryDs.getShopCategories(widget.shopId,
          kind: 'income');
      final expense = await _categoryDs.getShopCategories(widget.shopId,
          kind: 'expense');
      if (mounted) {
        setState(() {
          _incomeCategories = income;
          _expenseCategories = expense;
        });
      }
    } catch (_) {
      // Offline / no Firestore: the hardcoded fallback lists above
      // keep the sheet working.
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _bookingIdController.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n, String category) {
    final custom = [..._incomeCategories, ..._expenseCategories]
        .where((c) => c.code == category)
        .firstOrNull;
    if (custom != null) return custom.name;
    return {
      'rent': l10n.financeCategoryRent,
      'advance': l10n.financeCategoryAdvance,
      'deposit': l10n.addVehicleReviewDeposit,
      'other': l10n.blacklistReasonOther,
      'fuel': l10n.financeCategoryFuel,
      'maintenance': l10n.fleetFilterMaintenance,
      'wash': l10n.financeCategoryWash,
      'salary': l10n.financeCategorySalary,
      'partner_share': l10n.financeCategoryPartnerShare,
      'deposit_refund': l10n.financeCategoryDepositRefund,
    }[category] ?? category;
  }

  String _paymentMethodLabel(AppLocalizations l10n, String method) {
    return {
      'cash': l10n.financePaymentCash,
      'bank': l10n.financePaymentBank,
      'jazzcash': l10n.financePaymentJazzCash,
      'easypaisa': l10n.financePaymentEasyPaisa,
    }[method] ?? method;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    if (_accountId == null) return;
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final at = DateTime(
          _date.year, _date.month, _date.day, now.hour, now.minute);
      final bookingId = _bookingIdController.text.trim();
      await sl<FinanceTransferDataSource>().addTransfer(
        shopId: widget.shopId,
        accountId: _accountId!,
        kind: _kind,
        category: _category,
        amountPkr: amount,
        bookingId: bookingId.isEmpty ? null : bookingId,
        vehicleId: _vehicleId,
        paymentMethod: _paymentMethod,
        createdAt: at,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _categories.contains(_category)
                  ? _category
                  : _categories.first,
              decoration: InputDecoration(
                  labelText: l10n.financeCategoryLabel,
                  border: const OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        _categoryLabel(l10n, c),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? _categories.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: l10n.financeAmountRs,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.financeDateLabel),
              trailing: TextButton(
                onPressed: _pickDate,
                // Audit 2026-11-15 DS-5: localized date, never raw d/m/y (MaterialLocalizations needs no new import, so this 348-line widget stays at its cap).
              child: Text(MaterialLocalizations.of(context).formatMediumDate(_date)),
              ),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _paymentMethod,
              decoration: InputDecoration(
                  labelText: l10n.financePaymentMethodLabel,
                  border: const OutlineInputBorder()),
              items: ['cash', 'bank', 'jazzcash', 'easypaisa']
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        _paymentMethodLabel(l10n, m),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )))
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bookingIdController,
              decoration: InputDecoration(
                  labelText: l10n.financeBookingNumberLabel,
                  hintText: l10n.financeBookingNumberHint,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _accountId,
              decoration: InputDecoration(
                  labelText: l10n.financeAccountFallback,
                  border: const OutlineInputBorder()),
              items: widget.accounts
                  .map((a) => DropdownMenuItem(
                      value: a.accountId,
                      child: Text(
                        a.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _vehicleId,
              decoration: InputDecoration(
                  labelText: l10n.financeVehicleOptional,
                  border: const OutlineInputBorder()),
              items: [
                DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      l10n.financeNoVehicle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )),
                ...widget.vehicles.map((v) => DropdownMenuItem<String?>(
                    value: v.vehicleId,
                    child: Text(
                      v.displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ))),
              ],
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                  labelText: l10n.financeNoteOptional,
                  hintText: l10n.financeNoteHint,
                  border: const OutlineInputBorder()),
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
