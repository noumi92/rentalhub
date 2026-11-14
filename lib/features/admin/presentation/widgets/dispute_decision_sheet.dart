import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../../domain/admin_permissions.dart';
import 'admin_permission_check.dart';
import 'admin_status_chip.dart';

/// The stored decision value as the admin reads it. Shared by the
/// disputes centre rows and the booking detail's dispute section so
/// the label never drifts between screens.
/// Localised decision label; without `l10n` the English form is
/// returned (code-only uses and tests).
String disputeDecisionLabel(String decision, [AppLocalizations? l10n]) {
  if (l10n != null) {
    return switch (decision) {
      'full_to_customer' => l10n.admin2_disputeFullCustomer,
      'full_to_owner' => l10n.admin2_disputeFullOwner,
      'partial' => l10n.admin2_disputePartial,
      _ => decision,
    };
  }
  return switch (decision) {
    'full_to_customer' => 'Full refund to customer',
    'full_to_owner' => 'Full to owner (claim upheld)',
    'partial' => 'Partial — split',
    _ => decision,
  };
}

/// The D2 decision sheet for one dispute: the customer's statement
/// and the booking's facts side by side, the 72 h SLA state, and the
/// decision — Full to customer / Partial / Full to owner — with the
/// amount and an admin note. The decision is stored on the dispute
/// document; the shop is notified in-app; the C3 trust score counts
/// a decision against the customer automatically.
class DisputeDecisionSheet extends StatefulWidget {
  const DisputeDecisionSheet({
    super.key,
    required this.dispute,
    required this.onDecided,
    this.readOnly = false,
  });

  final DisputeRecord dispute;
  final VoidCallback onDecided;

  /// AD-M10: a resolved dispute opens read-only — the decision,
  /// amount and note are shown, nothing can be changed.
  final bool readOnly;

  @override
  State<DisputeDecisionSheet> createState() => _DisputeDecisionSheetState();
}

class _DisputeDecisionSheetState extends State<DisputeDecisionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  // AD-M11: no pre-selected decision — the admin must choose one.
  String? _decision;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    if (widget.readOnly) {
      _decision = widget.dispute.decision;
      final amount = widget.dispute.decisionAmount;
      if (amount != null) _amountController.text = '$amount';
      final note = widget.dispute.adminNote;
      if (note != null) _noteController.text = note;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _slaText {
    final l10n = AppLocalizations.of(context)!;
    final created = widget.dispute.createdAt;
    if (created == null) return l10n.admin2_slaUnknownDate;
    final deadline = created.add(const Duration(hours: 72));
    final left = deadline.difference(DateTime.now());
    if (left.isNegative) return l10n.admin2_disputeSlaBreached(-left.inHours);
    return l10n.admin2_disputeSlaLeft(left.inHours);
  }

  Future<void> _decide() async {
    final decision = _decision;
    if (decision == null) {
      AppFeedback.showError(context, AppLocalizations.of(context)?.disputeDecisionRequired ?? 'Choose a decision before saving.');
      return;
    }
    final amount = int.tryParse(_amountController.text.trim()) ?? -1;
    final note = _noteController.text.trim();
    if (amount < 0) {
      AppFeedback.showError(context, AppLocalizations.of(context)!.admin2_disputeAmountHint);
      return;
    }
    if (note.isEmpty) {
      AppFeedback.showError(context, AppLocalizations.of(context)!.admin2_disputeNoteRequired);
      return;
    }
    // F-C1: deciding needs decideDispute (super admin +
    // operations) — support may view and triage but never decide.
    // See the shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(context, AdminPermission.decideDispute);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminPlatformDataSource>().decideDispute(
      disputeId: widget.dispute.id,
      decision: decision,
      decisionAmount: amount,
      adminNote: note,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context, AppLocalizations.of(context)!.admin2_disputeDecided);
      widget.onDecided();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(context, AppLocalizations.of(context)!.admin2_serverUnreachable);
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = widget.dispute;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.admin2_disputeTitle(d.id), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(l10n.admin2_disputeBookingLine(d.bookingId, humanizeStatus(d.status, l10n), _slaText),
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            _side(l10n.admin2_disputeCustomerStatement, [
              l10n.admin2_disputeCategory(d.category),
              d.description,
              if (d.customerName != null) l10n.admin2_disputeCustomer(d.customerName!),
            ]),
            _side(l10n.admin2_disputeShopSide, [
              l10n.admin2_disputeBookingLabel(d.bookingId),
              if (d.shopId != null) l10n.admin2_disputeShopLabel(d.shopId!),
              l10n.admin2_disputeNoShopStatement,
            ]),
            const SizedBox(height: 8),
            Text(l10n.admin2_disputeDecisionHeading, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // isExpanded: the button must fill the field width —
              // at 2.0x text scale the intrinsic-width row of the
              // selected item + arrow overflows the field.
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _decision,
              hint: Text(AppLocalizations.of(context)?.disputeDecisionChoose ?? 'Choose a decision'),
              items: [
                DropdownMenuItem(value: 'full_to_customer', child: Text(disputeDecisionLabel('full_to_customer', l10n))),
                DropdownMenuItem(value: 'partial', child: Text(disputeDecisionLabel('partial', l10n))),
                DropdownMenuItem(value: 'full_to_owner', child: Text(disputeDecisionLabel('full_to_owner', l10n))),
              ],
              onChanged: widget.readOnly ? null : (v) => setState(() => _decision = v),
              decoration: _fieldDecoration(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              readOnly: widget.readOnly,
              decoration: _fieldDecoration(l10n.admin2_disputeAmountLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              readOnly: widget.readOnly,
              decoration: _fieldDecoration(l10n.admin2_disputeNoteLabel),
            ),
            const SizedBox(height: 16),
            if (!widget.readOnly)
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _isWorking ? null : _decide, child: Text(_isWorking ? l10n.admin2_saving : l10n.admin2_disputeSave)),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration([String? hintText]) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _side(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )),
        ],
      ),
    );
  }
}
