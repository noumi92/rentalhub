import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/datasources/admin_people_data_source.dart';

/// The C2 appeal decision for one blacklist record, extracted from the
/// tribunal view so the view stays under the 250-line cap.
///
/// A customer appeals a blacklist flag (by phone or WhatsApp — there
/// is no in-app appeal form yet); the tribunal decides:
/// - Keep: the flag stays, the appeal is denied, the reason is stored.
/// - Remove: the flag is lifted through the tribunal revert (reason
///   mandatory, audit-logged) and the appeal is marked removed.
class BlacklistAppealDialog extends StatefulWidget {
  const BlacklistAppealDialog({
    super.key,
    required this.record,
    required this.onDecided,
  });

  final AdminBlacklistRecord record;
  final VoidCallback onDecided;

  @override
  State<BlacklistAppealDialog> createState() => _BlacklistAppealDialogState();
}

class _BlacklistAppealDialogState extends State<BlacklistAppealDialog> {
  final _reasonController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _decide(String decision) async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      AppFeedback.showError(
          context, 'A reason is required — it is stored with the decision.');
      return;
    }
    String adminUid = '';
    try {
      adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {}
    setState(() => _isWorking = true);
    final synced = await sl<AdminPeopleDataSource>().decideAppeal(
      blacklistId: widget.record.entity.blacklistId,
      decision: decision,
      reason: reason,
      adminUid: adminUid,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context,
          decision == 'keep' ? 'Flag kept — appeal denied.' : 'Flag removed.');
      widget.onDecided();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.record.entity;
    return AlertDialog(
      // scrollable: at 1.35x/2.0x text scale the content column is
      // taller than a 360px phone viewport — without this the dialog
      // overflows vertically instead of scrolling.
      scrollable: true,
      title: const Text('Tribunal Blacklist Appeal',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Case: ${item.blacklistId} • CNIC: ${item.cnicNumber}',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 6),
          Text('${item.reasonCategory} — ${item.description}',
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (item.evidenceUrls.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Evidence: ${item.evidenceUrls.length} file(s) on record',
                style:
                    TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
          if (widget.record.appealStatus != 'none') ...[
            const SizedBox(height: 6),
            Text(
                'Appeal: ${widget.record.appealStatus} — ${widget.record.appealReason}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 12),
          const Text('Decision reason (mandatory):',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Why is the flag kept or removed?',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isWorking ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: _isWorking ? null : () => _decide('keep'),
          child: const Text('Keep flag'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: _isWorking ? null : () => _decide('remove'),
          child: const Text('Remove flag'),
        ),
      ],
    );
  }
}
