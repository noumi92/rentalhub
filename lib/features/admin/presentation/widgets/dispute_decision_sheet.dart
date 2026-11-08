import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../../data/datasources/admin_platform_data_source.dart';

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
  });

  final DisputeRecord dispute;
  final VoidCallback onDecided;

  @override
  State<DisputeDecisionSheet> createState() => _DisputeDecisionSheetState();
}

class _DisputeDecisionSheetState extends State<DisputeDecisionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _decision = 'partial';
  bool _isWorking = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _slaText {
    final created = widget.dispute.createdAt;
    if (created == null) return 'SLA: filed date unknown';
    final deadline = created.add(const Duration(hours: 72));
    final left = deadline.difference(DateTime.now());
    if (left.isNegative) {
      return 'SLA breached by ${-left.inHours}h — decide now';
    }
    return 'SLA: ${left.inHours}h left of 72h';
  }

  Future<void> _decide() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? -1;
    final note = _noteController.text.trim();
    if (amount < 0) {
      AppFeedback.showError(
          context, 'Enter the decision amount in rupees (0 is allowed).');
      return;
    }
    if (note.isEmpty) {
      AppFeedback.showError(
          context, 'An admin note is required with the decision.');
      return;
    }
    setState(() => _isWorking = true);
    final synced = await sl<AdminPlatformDataSource>().decideDispute(
      disputeId: widget.dispute.id,
      decision: _decision,
      decisionAmount: amount,
      adminNote: note,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context, 'Dispute decided.');
      widget.onDecided();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Dispute ${d.id}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    )),
            const SizedBox(height: 4),
            Text(
                'Booking ${d.bookingId} • ${d.status} • $_slaText',
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            _side('Customer statement', [
              'Category: ${d.category}',
              d.description,
              if (d.customerName != null) 'Customer: ${d.customerName}',
            ]),
            _side('Shop side — the booking record', [
              'Booking: ${d.bookingId}',
              if (d.shopId != null) 'Shop: ${d.shopId}',
              'The shop has no written statement on file — the decision uses the booking, handover and deposit records.',
            ]),
            const SizedBox(height: 8),
            const Text('Decision',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              initialValue: _decision,
              items: const [
                DropdownMenuItem(
                    value: 'full_to_customer',
                    child: Text('Full refund to customer')),
                DropdownMenuItem(
                    value: 'partial', child: Text('Partial — split')),
                DropdownMenuItem(
                    value: 'full_to_owner',
                    child: Text('Full to owner (claim upheld)')),
              ],
              onChanged: (v) =>
                  setState(() => _decision = v ?? 'partial'),
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Decision amount (Rs.)',
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Admin note — why this decision (both sides see it)',
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isWorking ? null : _decide,
                child: Text(_isWorking ? 'Saving…' : 'Save decision'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _side(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l,
                    style: TextStyle(
                        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )),
        ],
      ),
    );
  }
}
