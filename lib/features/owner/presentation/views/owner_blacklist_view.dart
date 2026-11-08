import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
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
  bool _submitting = false;

  String get _shopId => widget.shopId ?? currentShopId();

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
    final reports =
        await sl<BlacklistRemoteDataSource>().getShopReports(_shopId);
    if (!mounted) return;
    setState(() {
      _reports = reports;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final cnic = _cnicController.text.trim();
    final phone = _phoneController.text.trim();
    final description = _descriptionController.text.trim();
    if (cnic.replaceAll('-', '').trim().length != 13) {
      AppFeedback.showError(
          context, 'Enter the full 13-digit CNIC of the customer.');
      return;
    }
    if (description.isEmpty) {
      AppFeedback.showError(
          context, 'Describe what happened — the tribunal reads this.');
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
      AppFeedback.showSuccess(context,
          'Reported. The CNIC is now flagged for every shop.');
      _cnicController.clear();
      _phoneController.clear();
      _descriptionController.clear();
      await _load();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Report failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: widget.onBack ?? () => context.pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Blacklist Reports',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('Shared with every shop • Tribunal reviewed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Report a customer',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        _field(_cnicController, 'Customer CNIC',
                            keyboard: TextInputType.number),
                        _field(_phoneController, 'Customer phone',
                            keyboard: TextInputType.phone),
                        DropdownButtonFormField<String>(
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          initialValue: _reason,
                          decoration: InputDecoration(
                            labelText: 'Reason',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          items: _reasons
                              .map((r) => DropdownMenuItem(
                                  value: r, child: Text(r)))
                              .toList(),
                          onChanged: (r) =>
                              setState(() => _reason = r ?? _reason),
                        ),
                        const SizedBox(height: 12),
                        _field(_descriptionController,
                            'What happened? (dates, car, amount)',
                            maxLines: 3),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: const Icon(Icons.flag_rounded),
                            label: const Text('Report to Blacklist'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('My reports (${_reports.length})',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        if (_reports.isEmpty)
                          const Text(
                              'No reports from this shop yet. Reports cannot be undone by the shop — only the tribunal admin can revert one.'),
                        ..._reports.map((r) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Icon(
                                  Icons.flag_rounded,
                                  color: r.isActive
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                title: Text(r.cnicNumber,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                subtitle: Text(
                                    '${r.reasonCategory}\n${r.description}'),
                                isThreeLine: true,
                                trailing: Chip(
                                  label: Text(
                                      r.isActive ? 'Active' : 'Reverted',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                                  backgroundColor: r.isActive
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                            )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
