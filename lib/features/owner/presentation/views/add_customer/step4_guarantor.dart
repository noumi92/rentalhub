import 'package:flutter/material.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/masked_value.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../../customer/domain/entities/customer_entity.dart';
import '../../widgets/guarantor_manual_form.dart';
import 'kyc_draft.dart';
import 'kyc_info_box.dart';
import 'kyc_step.dart';

/// Wizard final step — guarantor (optional). Supports BOTH entering
/// inline guarantor details and picking an existing shop customer.
class Step4Guarantor extends StatefulWidget {
  final KycDraft draft;
  final VoidCallback onChanged;
  final String shopId;

  const Step4Guarantor({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.shopId,
  });

  @override
  State<Step4Guarantor> createState() => _Step4GuarantorState();
}

class _Step4GuarantorState extends KycStepState<Step4Guarantor> {
  final _searchController = TextEditingController();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cnicController;
  late final TextEditingController _addressController;

  List<CustomerEntity> _all = [];
  bool _loading = true;
  bool _loadFailed = false;
  String _query = '';
  late bool _manualMode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft.guarantorName);
    _phoneController = TextEditingController(text: widget.draft.guarantorPhone);
    _cnicController = TextEditingController(text: widget.draft.guarantorCnic);
    _addressController =
        TextEditingController(text: widget.draft.guarantorAddress);
    _manualMode = widget.draft.guarantorCustomerId == null;
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final customers = await sl<CustomerRemoteDataSource>()
          .getShopCustomers(widget.shopId);
      if (!mounted) return;
      setState(() {
        _all = customers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  CustomerEntity? get _selected {
    final id = widget.draft.guarantorCustomerId;
    if (id == null) return null;
    for (final c in _all) {
      if (c.customerId == id) return c;
    }
    return null;
  }

  List<CustomerEntity> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return _all.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if (c.phone.toLowerCase().contains(q)) return true;
      final cnic = c.cnic ?? '';
      if (cnic.toLowerCase().contains(q)) return true;
      return digits.isNotEmpty &&
          cnic.replaceAll(RegExp(r'\D'), '').contains(digits);
    }).toList();
  }

  @override
  Future<bool> validate() async => true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selected;
    final filtered = _filtered;
    const relations = ['Friend', 'Family', 'Colleague', 'Other'];
    final relationLabels = {
      'Friend': l10n.kycWizardRelationFriend,
      'Family': l10n.kycWizardRelationFamily,
      'Colleague': l10n.kycWizardRelationColleague,
      'Other': l10n.kycWizardRelationOther,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          key: const ValueKey('guarantor_mode_toggle'),
          segments: [
            ButtonSegment<bool>(
              value: true,
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: Text(l10n.guarantorModeManual),
            ),
            ButtonSegment<bool>(
              value: false,
              icon: const Icon(Icons.people_outline_rounded, size: 18),
              label: Text(l10n.guarantorModeExisting),
            ),
          ],
          selected: {_manualMode},
          onSelectionChanged: (s) {
            setState(() {
              _manualMode = s.first;
              if (_manualMode) widget.draft.guarantorCustomerId = null;
            });
            widget.onChanged();
          },
        ),
        const SizedBox(height: 14),
        if (_manualMode)
          GuarantorManualForm(
            draft: widget.draft,
            nameController: _nameController,
            phoneController: _phoneController,
            cnicController: _cnicController,
            addressController: _addressController,
            relations: relations,
            relationLabels: relationLabels,
            onChanged: () {
              setState(() {});
              widget.onChanged();
            },
          )
        else ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: l10n.kycWizardSearchGuarantor,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          if (_loading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(l10n.customersLoadingMessage),
              ],
            )
          else if (_loadFailed) ...[
            Text(l10n.customersLoadError, style: Theme.of(context).textTheme.bodySmall),
            TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 18), label: Text(l10n.commonRetry)),
          ] else if (filtered.isEmpty)
            Text(l10n.manualBookingGuarantorEmpty, style: Theme.of(context).textTheme.bodySmall)
          else
            RadioGroup<String?>(
              groupValue: widget.draft.guarantorCustomerId,
              onChanged: (val) {
                setState(() {
                  widget.draft.guarantorCustomerId = val;
                  final picked = val == null ? null : _all.where((c) => c.customerId == val).firstOrNull;
                  if (picked != null) {
                    widget.draft.guarantorName = picked.name;
                    widget.draft.guarantorPhone = picked.phone;
                    widget.draft.guarantorCnic = picked.cnic ?? '';
                    widget.draft.guarantorAddress = picked.address ?? '';
                    _nameController.text = picked.name;
                    _phoneController.text = picked.phone;
                    _cnicController.text = picked.cnic ?? '';
                    _addressController.text = picked.address ?? '';
                  }
                });
                widget.onChanged();
              },
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  final parts = [c.phone, if (c.cnic != null && c.cnic!.isNotEmpty) MaskedValue.maskCnic(c.cnic!)];
                  return RadioListTile<String?>(value: c.customerId, toggleable: true, title: Text(c.name), subtitle: Text(parts.join(' • ')));
                },
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(widget.draft.guarantorCustomerId),
            decoration: InputDecoration(labelText: l10n.kycWizardRelation, filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest),
            initialValue: selected == null ? null : widget.draft.guarantorRelation,
            items: relations.map((r) => DropdownMenuItem(value: r, child: Text(relationLabels[r]!))).toList(),
            onChanged: selected == null ? null : (v) { setState(() => widget.draft.guarantorRelation = v ?? 'Friend'); widget.onChanged(); },
          ),
          if (selected == null) ...[
            const SizedBox(height: 6),
            Text(l10n.kycWizardRelationPickFirst, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
        const SizedBox(height: 12),
        if (widget.draft.isKycComplete) ...[
          KycInfoBox(tone: KycInfoTone.info, icon: Icons.verified_rounded, text: l10n.kycWizardKycComplete),
          const SizedBox(height: 8),
        ],
        Text(l10n.kycWizardGuarantorOptional, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
