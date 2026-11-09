import 'package:flutter/material.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/widgets/masked_value.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../../customer/domain/entities/customer_entity.dart';
import 'kyc_draft.dart';
import 'kyc_step.dart';

/// Wizard step 4 — guarantor (O15). The guarantor is OPTIONAL:
/// [validate] always passes; the shell's Save button performs the
/// actual save through [KycCustomerSaver]. This step only records
/// the pick (and the relation) on the draft.
///
/// The booking flow's [GuarantorPicker] was NOT reused: it is built
/// around CNIC search + adding a new guarantor on the spot, while
/// this step needs a plain name/phone/CNIC filter, a radio list, a
/// fixed relation dropdown, and the on-file/completeness boxes.
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
  List<CustomerEntity> _all = [];
  bool _loading = true;
  bool _loadFailed = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      if (digits.isNotEmpty &&
          cnic.replaceAll(RegExp(r'\D'), '').contains(digits)) {
        return true;
      }
      return false;
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
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: l10n.kycWizardSearchGuarantor,
            prefixIcon: const Icon(Icons.search_rounded),
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_loadFailed) ...[
          Text(l10n.customersLoadError,
              style: Theme.of(context).textTheme.bodySmall),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.commonRetry),
          ),
        ] else if (filtered.isEmpty)
          Text(l10n.manualBookingGuarantorEmpty,
              style: Theme.of(context).textTheme.bodySmall)
        else
          RadioGroup<String?>(
            // toggleable tiles: tapping the selected guarantor again
            // clears the pick (val == null) — it is optional.
            groupValue: widget.draft.guarantorCustomerId,
            onChanged: (val) {
              setState(() => widget.draft.guarantorCustomerId = val);
              widget.onChanged();
            },
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final c = filtered[i];
                final parts = [c.phone];
                if (c.cnic != null && c.cnic!.isNotEmpty) {
                  parts.add(MaskedValue.maskCnic(c.cnic!));
                }
                return RadioListTile<String?>(
                  value: c.customerId,
                  toggleable: true,
                  title: Text(c.name),
                  subtitle: Text(parts.join(' • ')),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // Rebuilt per pick so the (initial-only) value follows the
          // selection; the field's own state tracks relation changes.
          key: ValueKey(widget.draft.guarantorCustomerId),
          decoration: InputDecoration(
            labelText: l10n.kycWizardRelation,
            border: const OutlineInputBorder(),
          ),
          initialValue:
              selected == null ? null : widget.draft.guarantorRelation,
          items: relations
              .map((r) => DropdownMenuItem(
                  value: r, child: Text(relationLabels[r]!)))
              .toList(),
          onChanged: selected == null
              ? null
              : (v) {
                  setState(() {
                    widget.draft.guarantorRelation = v ?? 'Friend';
                  });
                  widget.onChanged();
                },
        ),
        const SizedBox(height: 12),
        if (selected != null &&
            (selected.signatureUrl != null ||
                selected.thumbprintUrl != null))
          _InfoBox(
            color: Colors.green,
            icon: Icons.check_circle_rounded,
            text: l10n.kycWizardGuarantorOnFile,
          ),
        if (widget.draft.isKycComplete) ...[
          const SizedBox(height: 8),
          _InfoBox(
            color: Colors.blue,
            icon: Icons.verified_rounded,
            text: l10n.kycWizardKycComplete,
          ),
        ],
        const SizedBox(height: 12),
        Text(l10n.kycWizardGuarantorOptional,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _InfoBox({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
