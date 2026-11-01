import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AdminDesktopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;

  const AdminDesktopHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.emeraldGreen.withAlpha(50)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: AppColors.emeraldGreen),
                    SizedBox(width: 6),
                    Text('Production Mainnet Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.emeraldGreen)),
                  ],
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.midnightNavy, size: 20),
                  tooltip: 'Sync Live Stream',
                  onPressed: onRefresh,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
