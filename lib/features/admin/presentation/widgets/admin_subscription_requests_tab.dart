import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_packages_data_source.dart';
import 'admin_status_chip.dart';

/// Displays pending & historical shop subscription upgrade requests with
/// Approve / Reject controls for Super Admin & Operations.
class AdminSubscriptionRequestsTab extends StatelessWidget {
  const AdminSubscriptionRequestsTab({
    super.key,
    required this.requests,
    required this.canManage,
    required this.onDecide,
  });

  final List<AdminSubscriptionRequest> requests;
  final bool canManage;
  final void Function(AdminSubscriptionRequest req, bool approve) onDecide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (requests.isEmpty) {
      return AppEmptyState(
        title: l10n?.adminPackagesNoPendingRequests ??
            'No subscription upgrade requests yet.',
        icon: Icons.upgrade_rounded,
      );
    }
    return ListView.separated(
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final req = requests[i];
        final isPending = req.status == 'pending';
        final tone = switch (req.status) {
          'approved' => AdminStatusTone.success,
          'rejected' => AdminStatusTone.danger,
          _ => AdminStatusTone.warning,
        };
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${req.shopName} → ${req.tier.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AdminStatusChip(
                      label: req.status.toUpperCase(),
                      tone: tone,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs. ${formatRs(req.amount.toDouble())} (${req.billingPeriod})${req.trxId.isEmpty ? '' : ' • TRX: ${req.trxId}'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (req.reason != null && req.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    req.reason!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (isPending && canManage) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => onDecide(req, true),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text(
                          l10n?.adminPackagesApproveRequest ?? 'Approve',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onDecide(req, false),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text(
                          l10n?.adminPackagesRejectRequest ?? 'Reject',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
