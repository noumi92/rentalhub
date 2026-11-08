import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/usecases/save_customer_usecase.dart';

/// Phase B (C3): who guarantees this booking — picked from the
/// shop's saved customers, found by CNIC, or added on the spot. A
/// blacklisted CNIC cannot be a guarantor.
class GuarantorSelection {
  final String name;
  final String cnic;
  final String phone;
  final String relationship;

  const GuarantorSelection({
    required this.name,
    required this.cnic,
    required this.phone,
    required this.relationship,
  });
}

class GuarantorPicker extends StatefulWidget {
  final String? shopId;
  final GuarantorSelection? initial;
  final ValueChanged<GuarantorSelection?> onChanged;

  const GuarantorPicker({
    super.key,
    this.shopId,
    this.initial,
    required this.onChanged,
  });

  @override
  State<GuarantorPicker> createState() => _GuarantorPickerState();
}

class _GuarantorPickerState extends State<GuarantorPicker> {
  GuarantorSelection? _selected;
  List<CustomerEntity> _saved = [];
  bool _loadingSaved = true;
  bool _loadSavedFailed = false;
  bool _addingNew = false;
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _relationshipController =
      TextEditingController(text: 'Guarantor');

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _loadSaved();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    // Audit C4: a failed saved-list load is a visible error with a retry,
    // never a spinner that spins forever.
    setState(() {
      _loadingSaved = true;
      _loadSavedFailed = false;
    });
    try {
      final saved =
          await sl<CustomerRemoteDataSource>().getShopCustomers(_shopId);
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _loadingSaved = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSaved = false;
        _loadSavedFailed = true;
      });
    }
  }

  void _select(CustomerEntity c, String relationship) {
    final selection = GuarantorSelection(
      name: c.name,
      cnic: c.cnic ?? '',
      phone: c.phone,
      relationship: relationship,
    );
    setState(() => _selected = selection);
    widget.onChanged(selection);
  }

  Future<void> _searchByCnic() async {
  final l10n = AppLocalizations.of(context)!;
    final cnic = _searchController.text.trim();
    if (cnic.isEmpty) return;
    final found = await sl<CustomerRemoteDataSource>()
        .getCustomerByCnic(_shopId, cnic);
    if (!mounted) return;
    if (found == null) {
      AppFeedback.showInfo(context,
          l10n.manualBookingGuarantorNotFound);
      setState(() {
        _cnicController.text = cnic;
        _addingNew = true;
      });
      return;
    }
    if (await sl<BlacklistRemoteDataSource>()
        .isCnicBlacklisted(found.cnic ?? cnic)) {
      if (!mounted) return;
      AppFeedback.showError(context,
          l10n.manualBookingGuarantorBlacklisted);
      return;
    }
    _select(found, _relationshipController.text.trim());
  }

  Future<void> _addNew() async {
  final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    if (name.isEmpty || phone.isEmpty || cnic.isEmpty) {
      AppFeedback.showError(
          context, l10n.manualBookingGuarantorRequired);
      return;
    }
    if (await sl<BlacklistRemoteDataSource>().isCnicBlacklisted(cnic)) {
      if (!mounted) return;
      AppFeedback.showError(context,
          l10n.manualBookingGuarantorBlacklisted);
      return;
    }
    final digits = cnic.replaceAll(RegExp(r'\D'), '');
    final customer = CustomerEntity(
      customerId: 'cust-$digits',
      shopId: _shopId,
      name: name,
      phone: phone,
      cnic: cnic,
      source: 'guarantor',
      createdAt: DateTime.now(),
    );
    await sl<SaveCustomerUseCase>()(customer);
    await _loadSaved();
    if (!mounted) return;
    _select(customer, _relationshipController.text.trim());
    setState(() => _addingNew = false);
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    if (_selected != null) {
      final s = _selected!;
      return Card(
        child: ListTile(
          leading: Icon(Icons.verified_user_rounded,
              color: AppColors.successTextFor(Theme.of(context).brightness)),
          title: Text(s.name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${s.cnic} • ${s.phone}\n${s.relationship}'),
          trailing: IconButton(
            tooltip: l10n.manualBookingGuarantorRemove,
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              setState(() => _selected = null);
              widget.onChanged(null);
            },
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.manualBookingGuarantorSearch,
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _searchByCnic,
                child: Text(l10n.manualBookingGuarantorFind),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadSavedFailed) ...[
          Text(l10n.customersLoadError,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.dangerTextFor(
                      Theme.of(context).brightness))),
          TextButton.icon(
            onPressed: _loadSaved,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.commonRetry),
          ),
        ],
        if (_loadingSaved)
          const Center(child: CircularProgressIndicator())
        else if (_saved.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: _saved.length,
              itemBuilder: (context, i) {
                final c = _saved[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_rounded),
                  title: Text(c.name),
                  subtitle: Text(
                      [c.cnic, c.phone].where((e) => e != null && e.isNotEmpty).join(' • ')),
                  trailing: const Icon(Icons.add_circle_outline_rounded),
                  onTap: () =>
                      _select(c, _relationshipController.text.trim()),
                );
              },
            ),
          )
        else if (!_loadSavedFailed)
          Text(l10n.manualBookingGuarantorEmpty,
              style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _addingNew = !_addingNew),
          icon: Icon(_addingNew
              ? Icons.expand_less_rounded
              : Icons.person_add_rounded),
          label: Text(_addingNew ? l10n.manualBookingGuarantorHide : l10n.manualBookingGuarantorAdd),
        ),
        if (_addingNew) ...[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.manualBookingGuarantorName,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.manualBookingGuarantorPhone,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cnicController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.manualBookingGuarantorCnic,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _relationshipController,
            decoration: InputDecoration(
              labelText: l10n.manualBookingGuarantorRelationship,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _addNew,
              child: Text(l10n.manualBookingGuarantorSave),
            ),
          ),
        ],
      ],
    );
  }
}
