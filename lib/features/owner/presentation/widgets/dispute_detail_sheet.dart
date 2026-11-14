import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import 'dispute_list_tile.dart';

/// The dispute detail sheet the showroom opens from the inbox: the
/// full description, who filed it and when, and the two actions that
/// move a dispute forward — mark it in review, then resolved. The
/// sheet reports the new status back so the list can refresh.
class DisputeDetailSheet extends StatefulWidget {
  const DisputeDetailSheet({
    super.key,
    required this.dispute,
    required this.onStatusChanged,
  });

  final DisputeRecord dispute;

  /// Reports whether the status change reached the store, so the
  /// sheet can stay open (with an error) when it did not.
  final Future<bool> Function(String status) onStatusChanged;

  @override
  State<DisputeDetailSheet> createState() => _DisputeDetailSheetState();
}

class _DisputeDetailSheetState extends State<DisputeDetailSheet> {
  bool _isWorking = false;

  Future<void> _change(String status) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isWorking = true);
    try {
      // Audit §30: a failed update used to strand the sheet with
      // the button permanently disabled and no error. The sheet
      // now stays open and reports the failure.
      // NOTE: no resolution-note field was added — `updateDisputeStatus`
      // takes no note, and adding one means editing the shared
      // dispute data source (customer feature, outside this batch)
      // plus a Firestore field; the admin panel shares that source.
      final ok = await widget.onStatusChanged(status);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        setState(() => _isWorking = false);
        AppFeedback.showError(context, l10n.disputesUpdateError);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isWorking = false);
        AppFeedback.showError(context, l10n.disputesUpdateError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final d = widget.dispute;
    final container = DisputeListTile.statusContainer(context, d.status);
    final color = DisputeListTile.statusColor(context, d.status);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.category.isEmpty ? l10n.disputesFallbackTitle : d.category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: container,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DisputeListTile.statusLabel(l10n, d.status),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.disputesBookingLine(d.bookingId, d.customerName ?? d.customerId ?? l10n.requestsCustomerFallback) +
              (d.createdAt == null ? '' : ' • ${DisputeListTile.formatDate(l10n, d.createdAt)}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              d.description.isEmpty ? l10n.disputesNoDescription : d.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (d.status == 'open')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isWorking ? null : () => _change('in_review'),
                  child: Text(_isWorking ? l10n.disputesSaving : l10n.disputesMarkInReview),
                ),
              ),
            if (d.status != 'resolved') ...[
              if (d.status == 'open') const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isWorking ? null : () => _change('resolved'),
                  child: Text(_isWorking ? l10n.disputesSaving : l10n.disputesMarkResolved),
                ),
              ),
            ],
            if (d.status == 'resolved')
              Text(
                l10n.disputesResolvedNote,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
