import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../owner/presentation/services/whatsapp_credits_models.dart';
import '../../data/datasources/admin_packages_data_source.dart';
import 'admin_mini_kpi_strip.dart';
import 'admin_status_chip.dart';

/// Displays WhatsApp credit pack purchase requests with Approve / Reject
/// actions for Super Admin & Operations.
class AdminWhatsappPackagesTab extends StatelessWidget {
  const AdminWhatsappPackagesTab({
    super.key,
    required this.requests,
    required this.canManage,
    required this.onDecide,
  });

  final List<AdminCreditRequest> requests;
  final bool canManage;
  final void Function(AdminCreditRequest req, bool approve) onDecide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final packStrip = AdminMiniKpiStrip(
      items: [
        for (final pack in whatsappCreditPacks)
          AdminMiniKpi(
            label: '${pack.name} (${pack.credits})',
            value:
                'Rs. ${formatRs(pack.price)} · ${l10n?.packagesComingSoonBadge ?? 'Coming Soon'}',
            icon: Icons.chat_rounded,
            muted: true,
          ),
      ],
    );
    if (requests.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          packStrip,
          Expanded(
            child: AppEmptyState(
              title: l10n?.adminPackagesNoCreditRequests ??
                  'No WhatsApp credit requests yet.',
              icon: Icons.chat_rounded,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        packStrip,
        Expanded(
          child: ListView.separated(
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
                        '${req.shopName} • +${req.packCredits} credits',
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
                  '${req.packName} • Rs. ${formatRs(req.amount.toDouble())}${req.trxId.isEmpty ? '' : ' • TRX: ${req.trxId}'}',
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
          ),
        ),
      ],
    );
  }
}
