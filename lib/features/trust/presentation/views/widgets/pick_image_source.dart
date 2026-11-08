import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../l10n/app_localizations.dart';

/// G3: lets the user pick a photo from the camera or the gallery.
/// Returns the picked file, or null when they cancel.
Future<File?> pickImageFile(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title:  Text(l10n.kycTakePhoto),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title:  Text(l10n.kycFromGallery),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return File(picked.path);
}
