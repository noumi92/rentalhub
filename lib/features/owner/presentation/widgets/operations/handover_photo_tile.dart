import 'dart:io';

import 'package:flutter/material.dart';

/// Item 9 (O29): one photo slot tile for [ExteriorPhotoPicker] —
/// the uploaded photo (or the local preview while it uploads, or
/// the add-photo placeholder), the side label, the uploading
/// spinner, and the per-photo timestamp once the photo exists.
/// Extracted so the picker stays under the 250-line cap.
class HandoverPhotoTile extends StatelessWidget {
  final String label;
  final String uploadingLabel;
  final String? url;
  final String? localPath;
  final bool uploading;
  final String? takenAtLabel;
  final VoidCallback? onTap;

  const HandoverPhotoTile({
    super.key,
    required this.label,
    required this.uploadingLabel,
    required this.url,
    required this.localPath,
    required this.uploading,
    required this.takenAtLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              Image.network(url!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(context))
            else if (localPath != null)
              Image.file(File(localPath!), fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(context))
            else
              _placeholder(context),
            if (uploading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  uploading ? uploadingLabel : label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
            if (url != null && takenAtLabel != null)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    takenAtLabel!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // The side label is shown once, in the overlay chip below — the
  // placeholder itself is icon-only, otherwise "Front" renders twice.
  Widget _placeholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }
}
