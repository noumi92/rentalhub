import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';

class OnboardingDocumentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final XFile? file;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const OnboardingDocumentTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? AppColors.accentSuccess : AppColors.borderSubtle,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (hasFile)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(file!.path),
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: AppColors.secondary,
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (hasFile && onRemove != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentDanger, size: 20),
                tooltip: 'Remove',
                onPressed: onRemove,
              )
            else
              Text(
                hasFile ? 'Ready ✓' : 'Upload',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: hasFile ? AppColors.accentSuccess : AppColors.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
