import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/card_decoration.dart';

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
  final l10n = AppLocalizations.of(context)!;
    final hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.successContainerFor(Theme.of(context).brightness) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: hasFile
              ? Border.all(
                  color: AppColors.successBorderFor(
                      Theme.of(context).brightness),
                  width: 1.5,
                )
              : null,
          boxShadow: AppCardDecoration.shadow(context),
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
                      fontWeight: FontWeight.w500,
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
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.errorOnContainerFor(Theme.of(context).brightness), size: 20),
                tooltip: l10n.onboardingDocRemove,
                onPressed: onRemove,
              )
            else
              Text(
                hasFile ? l10n.onboardingDocReady : l10n.onboardingDocUpload,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  // Item 4: the "Upload" state was AppColors.secondary
                  // as text (3.29:1) — the orange text token is 5.18:1
                  // in light, 7.92:1 in dark.
                  color: hasFile ? AppColors.successOnContainerFor(Theme.of(context).brightness) : AppColors.orangeTextFor(Theme.of(context).brightness),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
