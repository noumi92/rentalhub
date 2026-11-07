import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';

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
    final hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile ? AppColors.accentSuccess : AppColors.borderSubtle,
            width: hasFile ? 1.5 : 1,
          ),
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
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    isRequired ? 'Tap to Upload' : 'Optional',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isRequired ? AppColors.textMuted : AppColors.primaryContainer),
                  ),
                ],
              ),
      ),
    );
  }
}
