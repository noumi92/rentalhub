import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';

class ProofScreenshotPicker extends StatelessWidget {
  final File? selectedFile;
  final ValueChanged<File?> onFileSelected;

  const ProofScreenshotPicker({
    super.key,
    required this.selectedFile,
    required this.onFileSelected,
  });

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      onFileSelected(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedFile != null) {
      return Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          image: DecorationImage(
            image: FileImage(selectedFile!),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => onFileSelected(null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Screenshot Ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lavenderMist,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                color: AppColors.royalNavy, size: 30),
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload Transfer Screenshot',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.midnightNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Support JPG, PNG receipt from banking app',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.royalNavy,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.photo_library_rounded, size: 16),
                label: const Text('From Gallery'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.royalNavy,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Capture Camera'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
