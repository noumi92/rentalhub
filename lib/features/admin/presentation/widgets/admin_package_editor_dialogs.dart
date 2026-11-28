import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_package_catalog_data_source.dart';

/// Dialog to create or modify a Shop Subscription Package.
Future<AdminShopPackage?> showAdminShopPackageEditorDialog(
  BuildContext context, {
  AdminShopPackage? existing,
}) {
  return showDialog<AdminShopPackage>(
    context: context,
    builder: (_) => _ShopPackageEditorDialog(existing: existing),
  );
}

/// Dialog to create or modify a WhatsApp Credit Package.
Future<AdminWhatsappPackage?> showAdminWhatsappPackageEditorDialog(
  BuildContext context, {
  AdminWhatsappPackage? existing,
}) {
  return showDialog<AdminWhatsappPackage>(
    context: context,
    builder: (_) => _WhatsappPackageEditorDialog(existing: existing),
  );
}

String _slugify(String raw) {
  final slug = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return slug.isEmpty
      ? 'pkg_${DateTime.now().millisecondsSinceEpoch}'
      : slug;
}

class _ShopPackageEditorDialog extends StatefulWidget {
  const _ShopPackageEditorDialog({this.existing});

  final AdminShopPackage? existing;

  @override
  State<_ShopPackageEditorDialog> createState() =>
      _ShopPackageEditorDialogState();
}

class _ShopPackageEditorDialogState extends State<_ShopPackageEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _monthlyCtrl;
  late final TextEditingController _yearlyCtrl;
  late final TextEditingController _carLimitCtrl;
  late final TextEditingController _staffCtrl;
  late final TextEditingController _creditsCtrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _monthlyCtrl = TextEditingController(text: '${e?.monthlyPrice ?? 0}');
    _yearlyCtrl = TextEditingController(text: '${e?.yearlyPrice ?? 0}');
    _carLimitCtrl =
        TextEditingController(text: e?.carLimit != null ? '${e!.carLimit}' : '');
    _staffCtrl = TextEditingController(text: '${e?.staffLimit ?? 1}');
    _creditsCtrl =
        TextEditingController(text: '${e?.freeMonthlyCredits ?? 0}');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _monthlyCtrl.dispose();
    _yearlyCtrl.dispose();
    _carLimitCtrl.dispose();
    _staffCtrl.dispose();
    _creditsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.existing == null
          ? (l10n?.adminCreateShopPackage ?? 'Create Shop Package')
          : (l10n?.adminEditShopPackage ?? 'Edit Shop Package')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('shop_pkg_name'),
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n?.adminPackageNameLabel ?? 'Package Name',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('shop_pkg_monthly'),
                controller: _monthlyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText:
                      l10n?.adminPackageMonthlyPrice ?? 'Monthly Price (Rs.)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('shop_pkg_yearly'),
                controller: _yearlyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText:
                      l10n?.adminPackageYearlyPrice ?? 'Yearly Price (Rs.)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('shop_pkg_car_limit'),
                controller: _carLimitCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n?.adminPackageCarLimit ??
                      'Car Limit (blank = Unlimited)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('shop_pkg_staff_limit'),
                controller: _staffCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n?.adminPackageStaffLimit ?? 'Staff Limit',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('shop_pkg_free_credits'),
                controller: _creditsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n?.adminPackageFreeCredits ??
                      'Monthly Free WhatsApp Credits',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n?.active ?? 'Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          key: const ValueKey('shop_pkg_save'),
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final carText = _carLimitCtrl.text.trim();
            Navigator.of(context).pop(AdminShopPackage(
              id: widget.existing?.id ?? _slugify(_nameCtrl.text),
              name: _nameCtrl.text.trim(),
              monthlyPrice: int.tryParse(_monthlyCtrl.text.trim()) ?? 0,
              yearlyPrice: int.tryParse(_yearlyCtrl.text.trim()) ?? 0,
              carLimit: carText.isEmpty ? null : int.tryParse(carText),
              staffLimit:
                  (int.tryParse(_staffCtrl.text.trim()) ?? 1).clamp(1, 999),
              freeMonthlyCredits: int.tryParse(_creditsCtrl.text.trim()) ?? 0,
              isActive: _isActive,
            ));
          },
          child: Text(l10n?.admin2_save ?? 'Save'),
        ),
      ],
    );
  }
}

class _WhatsappPackageEditorDialog extends StatefulWidget {
  const _WhatsappPackageEditorDialog({this.existing});

  final AdminWhatsappPackage? existing;

  @override
  State<_WhatsappPackageEditorDialog> createState() =>
      _WhatsappPackageEditorDialogState();
}

class _WhatsappPackageEditorDialogState
    extends State<_WhatsappPackageEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _creditsCtrl;
  late final TextEditingController _priceCtrl;
  late bool _bestValue;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _creditsCtrl = TextEditingController(text: '${e?.credits ?? 100}');
    _priceCtrl = TextEditingController(text: '${e?.price ?? 500}');
    _bestValue = e?.bestValue ?? false;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _creditsCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.existing == null
          ? (l10n?.adminCreateWhatsappPackage ?? 'Create WhatsApp Package')
          : (l10n?.adminEditWhatsappPackage ?? 'Edit WhatsApp Package')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('wa_pkg_name'),
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n?.adminPackageNameLabel ?? 'Package Name',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('wa_pkg_credits'),
                controller: _creditsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n?.adminPackageCreditsCount ?? 'Credits Count',
                ),
                validator: (v) =>
                    (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('wa_pkg_price'),
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n?.adminPackagePricePkr ?? 'Price (Rs.)',
                ),
                validator: (v) =>
                    (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n?.adminPackageBestValue ?? 'Best Value'),
                value: _bestValue,
                onChanged: (v) => setState(() => _bestValue = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n?.active ?? 'Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          key: const ValueKey('wa_pkg_save'),
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(AdminWhatsappPackage(
              id: widget.existing?.id ?? _slugify(_nameCtrl.text),
              name: _nameCtrl.text.trim(),
              credits: int.tryParse(_creditsCtrl.text.trim()) ?? 0,
              price: int.tryParse(_priceCtrl.text.trim()) ?? 0,
              bestValue: _bestValue,
              isActive: _isActive,
            ));
          },
          child: Text(l10n?.admin2_save ?? 'Save'),
        ),
      ],
    );
  }
}
