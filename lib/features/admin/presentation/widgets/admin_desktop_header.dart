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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
                Text(subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.midnightNavy, size: 20),
              tooltip: 'Refresh',
              onPressed: onRefresh,
            ),
        ],
      ),
    );
  }
}

