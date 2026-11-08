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
              ? AppColors.accentSuccess.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? AppColors.accentSuccess : Theme.of(context).dividerColor,
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
                    ? AppColors.accentSuccess
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isUploaded
                    ? Icons.check_circle_rounded
                    : Icons.camera_alt_rounded,
                color: isUploaded ? Colors.white : Theme.of(context).colorScheme.onSurface,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isUploaded
                    ? AppColors.accentSuccess.withValues(alpha: 0.15)
                    : AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUploaded ? 'Encrypted' : 'Upload',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: isUploaded
                      ? AppColors.successTextFor(Theme.of(context).brightness)
                      : AppColors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

