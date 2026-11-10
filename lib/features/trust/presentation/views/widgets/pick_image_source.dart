import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// KYC document capture — rear camera ONLY.
///
/// The CNIC + driving license uploads never accept a gallery photo:
/// this opens the back camera directly and offers no source choice.
/// (The old version showed a camera/gallery bottom sheet; the gallery
/// row is removed by the KYC camera rule, 2026-11-10.)
/// Returns the picked file, or null when they cancel.
Future<File?> pickImageFile(BuildContext context) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.rear,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return File(picked.path);
}
