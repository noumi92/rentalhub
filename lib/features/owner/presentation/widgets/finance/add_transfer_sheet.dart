import 'package:flutter/material.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/debounced_button.dart';
import  '../../../../finance/data/datasources/finance_transfer_data_source.dart';
import  '../../../../finance/domain/entities/finance_account_entity.dart';
import  '../../../../fleet/domain/entities/vehicle_entity.dart';

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
    _accountId = widget.accounts
            .where((a) => a.isDefault)
            .firstOrNull
            ?.accountId ??
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
    return AlertDialog(
      title: const Text('Add ledger entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Income'),
                  selected: _kind == 'income',
                  onSelected: (_) => setState(() {
                    _kind = 'income';
                    _category = 'rent';
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Expense'),
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
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? _categories.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _accountId,
              decoration: const InputDecoration(
                  labelText: 'Account', border: OutlineInputBorder()),
              items: widget.accounts
                  .map((a) => DropdownMenuItem(
                      value: a.accountId, child: Text(a.name)))
                  .toList(),
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _vehicleId,
              decoration: const InputDecoration(
                  labelText: 'Vehicle (optional — for car P&L)',
                  border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('No vehicle')),
                ...widget.vehicles.map((v) => DropdownMenuItem<String?>(
                    value: v.vehicleId, child: Text(v.displayName))),
              ],
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. driver salary — Ahmed',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        DebouncedButton(
          text: _isSaving ? 'Saving...' : 'Save entry',
          isLoading: _isSaving,
          onPressed: _save,
        ),
      ],
    );
  }
}
