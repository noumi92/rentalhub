import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
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
  final Future<void> Function(String status) onStatusChanged;

  @override
  State<DisputeDetailSheet> createState() => _DisputeDetailSheetState();
}

class _DisputeDetailSheetState extends State<DisputeDetailSheet> {
  bool _isWorking = false;

  Future<void> _change(String status) async {
    setState(() => _isWorking = true);
    await widget.onStatusChanged(status);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dispute;
    final color = DisputeListTile.statusColor(d.status);
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
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.category.isEmpty ? 'Dispute' : d.category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DisputeListTile.statusLabel(d.status),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Booking ${d.bookingId} • ${d.customerName ?? d.customerId ?? 'Customer'}'
              '${d.createdAt == null ? '' : ' • ${DisputeListTile.formatDate(d.createdAt)}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              d.description.isEmpty ? 'No description given.' : d.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (d.status == 'open')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isWorking ? null : () => _change('in_review'),
                  child: Text(_isWorking ? 'Saving…' : 'Mark in review'),
                ),
              ),
            if (d.status != 'resolved') ...[
              if (d.status == 'open') const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isWorking ? null : () => _change('resolved'),
                  child: Text(_isWorking ? 'Saving…' : 'Mark resolved'),
                ),
              ),
            ],
            if (d.status == 'resolved')
              Text(
                'Resolved — no further action needed.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
