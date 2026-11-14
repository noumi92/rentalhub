import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../../domain/admin_permissions.dart';
import 'admin_permission_check.dart';

/// The C2 appeal decision for one blacklist record, extracted from the
/// tribunal view so the view stays under the 250-line cap.
///
/// A customer appeals a blacklist flag (the customer appeal sheet
/// files it in-app; it can also arrive by phone or WhatsApp); the
/// tribunal decides:
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
          context, AppLocalizations.of(context)!.admin2_appealReasonRequired);
      return;
    }
    String adminUid = '';
    try {
      adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {}
    // F-C1: super admin + operations only (manageBlacklist). See
    // the shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.manageBlacklist);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminPeopleDataSource>().decideAppeal(
      blacklistId: widget.record.entity.blacklistId,
      decision: decision,
      reason: reason,
      adminUid: adminUid,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      final l10n = AppLocalizations.of(context)!;
      AppFeedback.showSuccess(context,
          decision == 'keep' ? l10n.admin2_appealKept : l10n.admin2_appealRemoved);
      widget.onDecided();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(context, AppLocalizations.of(context)!.admin2_serverUnreachable);
      setState(() => _isWorking = false);
    }
  }

  /// AD-m15: the evidence viewer — the count line opens this
  /// dialog (a scrollable list of the evidence photos, each
  /// tappable to the fleet-photo zoom pattern), instead of the
  /// count being the only thing the tribunal ever sees.
  void _showEvidence() {
    final l10n = AppLocalizations.of(context)!;
    final urls = widget.record.entity.evidenceUrls;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.admin2_evidenceTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: urls
                        .map((url) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Semantics(
                                button: true,
                                label: l10n.admin2_fleetPhotoTooltip,
                                // E3: the evidence photo is a labelled
                                // button for screen readers; the tap
                                // behaviour is unchanged.
                                child: GestureDetector(
                                  onTap: () => _zoom(ctx, url),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(
                                                height: 120,
                                                child: Icon(Icons
                                                    .broken_image_rounded))),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The fleet-photo zoom pattern (InteractiveViewer + BoxFit.contain
  /// + insetPadding), reused for one evidence photo.
  void _zoom(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Photo could not be loaded.')),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: AppLocalizations.of(context)?.close ?? 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.record.entity;
    return AlertDialog(
      // scrollable: at 1.35x/2.0x text scale the content column is
      // taller than a 360px phone viewport — without this the dialog
      // overflows vertically instead of scrolling.
      scrollable: true,
      title: Text(l10n.admin2_appealDialogTitle,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.admin2_tribunalCaseLine(item.blacklistId, item.cnicNumber),
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          const SizedBox(height: 6),
          Text('${item.reasonCategory} — ${item.description}',
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (item.evidenceUrls.isNotEmpty) ...[
            const SizedBox(height: 6),
            // AD-m15: the count is a button — it opens the
            // evidence viewer (photos), not just a number.
            TextButton.icon(
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft),
              onPressed: _showEvidence,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(l10n.admin2_appealEvidence(item.evidenceUrls.length),
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
          if (widget.record.appealStatus != 'none') ...[
            const SizedBox(height: 6),
            Text(
                l10n.admin2_tribunalAppealLine(widget.record.appealStatus, widget.record.appealReason),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 12),
          Text(l10n.admin2_appealDecisionLabel,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.admin2_appealDecisionHint,
              // Rulebook radius 16 (was the bare 4dp default).
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isWorking ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        // AD-m15: the red is on the consequential action. Keeping
        // the flag denies the appeal — that is the FilledButton;
        // removing it is the neutral OutlinedButton now.
        OutlinedButton(
          onPressed: _isWorking ? null : () => _decide('remove'),
          child: Text(l10n.admin2_appealRemove),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: _isWorking ? null : () => _decide('keep'),
          child: Text(l10n.admin2_appealKeep),
        ),
      ],
    );
  }
}
