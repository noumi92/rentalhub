import 'package:flutter/material.dart';

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
    final saved =
        await sl<CustomerRemoteDataSource>().getShopCustomers(_shopId);
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _loadingSaved = false;
    });
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
    final cnic = _searchController.text.trim();
    if (cnic.isEmpty) return;
    final found = await sl<CustomerRemoteDataSource>()
        .getCustomerByCnic(_shopId, cnic);
    if (!mounted) return;
    if (found == null) {
      AppFeedback.showInfo(context,
          'No saved customer with that CNIC — add them below.');
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
          'This CNIC is blacklisted and cannot be a guarantor.');
      return;
    }
    _select(found, _relationshipController.text.trim());
  }

  Future<void> _addNew() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final cnic = _cnicController.text.trim();
    if (name.isEmpty || phone.isEmpty || cnic.isEmpty) {
      AppFeedback.showError(
          context, 'Name, phone and CNIC are required for a guarantor.');
      return;
    }
    if (await sl<BlacklistRemoteDataSource>().isCnicBlacklisted(cnic)) {
      if (!mounted) return;
      AppFeedback.showError(context,
          'This CNIC is blacklisted and cannot be a guarantor.');
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
            tooltip: 'Remove guarantor',
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
                  hintText: 'Search guarantor by CNIC',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _searchByCnic,
              child: const Text('Find'),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        else
          Text('No saved customers yet.',
              style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _addingNew = !_addingNew),
          icon: Icon(_addingNew
              ? Icons.expand_less_rounded
              : Icons.person_add_rounded),
          label: Text(_addingNew ? 'Hide new guarantor' : 'Add new guarantor'),
        ),
        if (_addingNew) ...[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Guarantor full name',
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
              labelText: 'Phone number',
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
              labelText: 'CNIC number',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _relationshipController,
            decoration: InputDecoration(
              labelText: 'Relationship (e.g. Father, Brother, Friend)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addNew,
              child: const Text('Save & Select Guarantor'),
            ),
          ),
        ],
      ],
    );
  }
}
