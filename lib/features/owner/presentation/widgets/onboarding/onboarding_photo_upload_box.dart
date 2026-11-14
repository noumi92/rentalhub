import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/card_decoration.dart';

class OnboardingPhotoUploadBox extends StatelessWidget {
  final String label;
  final XFile? file;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final double height;
  final bool isRequired;

  const OnboardingPhotoUploadBox({
    super.key,
    required this.label,
    required this.file,
    required this.onTap,
    this.onRemove,
    this.height = 100,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: hasFile ? AppColors.successContainerFor(Theme.of(context).brightness) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: hasFile
              ? Border.all(
                  color: AppColors.successBorderFor(
                      Theme.of(context).brightness),
                  width: 1.5,
                )
              : null,
          boxShadow: AppCardDecoration.shadow(context),
        ),
        child: hasFile
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(file!.path), fit: BoxFit.cover),
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      padding: const EdgeInsets.all(6),
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onRemove != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accentDanger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: AppColors.secondary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    isRequired ? l10n.onboardingTapToUpload : l10n.onboardingOptional,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isRequired ? Theme.of(context).colorScheme.onSurfaceVariant : AppColors.primaryContainer),
                  ),
                ],
              ),
      ),
    );
  }
}
