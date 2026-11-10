import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/media_picker_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../services/handover_photo_upload_service.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Audit item 4/5 (O19, O25): the exterior-photo picker shared by
/// the handover and return flows — Front / Back / Left / Right, each
/// with "+ Add Photo". Picking goes through [MediaPickerHelper];
/// upload goes through [HandoverPhotoUploadService] (the vehicle
/// flow's cPanel path, folder `handovers`). While an upload is still
/// queued the tile shows the local photo as a preview only — the
/// reported URL stays null until the real signed URL exists, so no
/// local path is ever stored as if it were uploaded.
class ExteriorPhotoPicker extends StatefulWidget {
  final String bookingId;
  final String shopId;

  /// Side → signed URL (null = no photo yet for that side).
  final Map<String, String?> photos;
  final ValueChanged<Map<String, String?>> onChanged;

  /// Target Firestore field prefix, e.g. 'photo' → 'photoFrontUrl'.
  /// Return flow stores its photos on the settlement doc instead.
  final String targetCollection;

  const ExteriorPhotoPicker({
    super.key,
    required this.bookingId,
    required this.shopId,
    required this.photos,
    required this.onChanged,
    this.targetCollection = 'handovers',
  });

  static const List<String> sides = ['front', 'back', 'left', 'right'];

  static String fieldFor(String side) {
    final cap = side[0].toUpperCase() + side.substring(1);
    return 'photo${cap}Url';
  }

  @override
  State<ExteriorPhotoPicker> createState() => _ExteriorPhotoPickerState();
}

class _ExteriorPhotoPickerState extends State<ExteriorPhotoPicker> {
  final Map<String, String> _localPaths = {};
  final Set<String> _uploading = {};

  Future<void> _pick(String side) async {
    await MediaPickerHelper.showMediaSourceSheet(
      context: context,
      onImageSelected: (XFile? file) async {
        if (file == null) return;
        setState(() {
          _localPaths[side] = file.path;
          _uploading.add(side);
        });
        final url = await HandoverPhotoUploadService.uploadHandoverPhoto(
          shopId: widget.shopId,
          bookingId: widget.bookingId,
          photo: file,
          targetField: ExteriorPhotoPicker.fieldFor(side),
          targetCollection: widget.targetCollection,
        );
        if (!mounted) return;
        setState(() => _uploading.remove(side));
        if (url != null) {
          final next = Map<String, String?>.from(widget.photos);
          next[side] = url;
          widget.onChanged(next);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.handoverPhotosTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemCount: ExteriorPhotoPicker.sides.length,
            itemBuilder: (context, index) {
              final side = ExteriorPhotoPicker.sides[index];
              return _photoTile(context, l10n, side);
            },
          ),
        ],
      ),
    );
  }

  Widget _photoTile(BuildContext context, AppLocalizations l10n, String side) {
    final url = widget.photos[side];
    final localPath = _localPaths[side];
    final uploading = _uploading.contains(side);
    final label = _sideLabel(l10n, side);
    return InkWell(
      onTap: uploading ? null : () => _pick(side),
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
              Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(context))
            else if (localPath != null)
              Image.file(File(localPath), fit: BoxFit.cover,
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
                  uploading ? l10n.handoverPhotoUploading : label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

  String _sideLabel(AppLocalizations l10n, String side) {
    switch (side) {
      case 'front':
        return l10n.handoverPhotoFront;
      case 'back':
        return l10n.handoverPhotoBack;
      case 'left':
        return l10n.handoverPhotoLeft;
      default:
        return l10n.handoverPhotoRight;
    }
  }
}
