import 'package:flutter/material.dart';
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
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'read':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all_rounded;
        break;
      case 'delivered':
        statusColor = AppColors.emeraldGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                    Text(recipientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
                    const SizedBox(width: 6),
                    Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$messageType • $timestamp', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                  Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                ],
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: onResend,
                child: const Text('Resend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sunsetOrange)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

