import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class DocumentSlotTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isUploaded;
  final VoidCallback onTap;

  const DocumentSlotTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isUploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUploaded
              ? AppColors.emeraldGreen.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? AppColors.emeraldGreen : AppColors.border,
            width: isUploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUploaded
                    ? AppColors.emeraldGreen
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isUploaded
                    ? Icons.check_circle_rounded
                    : Icons.camera_alt_rounded,
                color: isUploaded ? Colors.white : AppColors.midnightNavy,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isUploaded
                    ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                    : AppColors.sunsetOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUploaded ? 'Encrypted' : 'Upload',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isUploaded
                      ? AppColors.emeraldGreen
                      : AppColors.sunsetOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

