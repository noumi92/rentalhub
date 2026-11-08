import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';

class WhatsAppLogTile extends StatelessWidget {
  final String recipientName;
  final String phone;
  final String messageType;
  final String timestamp;
  final String status; // 'delivered', 'read', 'failed'
  final VoidCallback onResend;

  const WhatsAppLogTile({
    super.key,
    required this.recipientName,
    required this.phone,
    required this.messageType,
    required this.timestamp,
    required this.status,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'read':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all_rounded;
        break;
      case 'delivered':
        statusColor = AppColors.accentSuccess;
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF25D366).withAlpha(30),
            child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(recipientName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Text(phone, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$messageType • $timestamp', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(_statusLabel(l10n, status).toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: statusColor)),
                ],
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: onResend,
                child: Text(l10n.whatsappLogsResend, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.secondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Stored log-status codes mapped to localized labels — the stored
/// value itself is never changed.
String _statusLabel(AppLocalizations l10n, String status) => {'delivered': l10n.whatsappLogsDelivered, 'read': l10n.whatsappLogsRead, 'failed': l10n.whatsappLogsFailed}[status.toLowerCase()] ?? status;
