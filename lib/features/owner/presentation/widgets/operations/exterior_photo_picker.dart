import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/media_picker_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../services/handover_photo_upload_service.dart';
import '../../../../../core/theme/card_decoration.dart';
import 'handover_photo_tile.dart';

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

  /// Item 9 (O29): the wizard adds Interior + Dashboard slots, so
  /// the picker covers six sides instead of four. Off by default —
  /// the return flow keeps its four exterior slots.
  final bool includeInterior;

  /// Side → ISO-8601 timestamp of when the photo was taken (O29).
  final Map<String, String> takenAt;
  final ValueChanged<Map<String, String>>? onTakenAtChanged;

  const ExteriorPhotoPicker({
    super.key,
    required this.bookingId,
    required this.shopId,
    required this.photos,
    required this.onChanged,
    this.targetCollection = 'handovers',
    this.includeInterior = false,
    this.takenAt = const {},
    this.onTakenAtChanged,
  });

  static const List<String> sides = ['front', 'back', 'left', 'right'];

  /// All slots this picker shows: the four exterior sides, plus
  /// Interior + Dashboard when the wizard asks for them.
  List<String> get allSides => includeInterior
      ? [...sides, 'interior', 'dashboard']
      : sides;

  static String fieldFor(String side) {
    if (side == 'interior') return 'photoInteriorUrl';
    if (side == 'dashboard') return 'photoDashboardUrl';
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
        // O29: the timestamp is when the photo was taken, not when
        // the upload finished — record it at pick time.
        final takenAt = DateTime.now().toIso8601String();
        widget.onTakenAtChanged?.call(
            {...widget.takenAt, side: takenAt});
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
                  fontWeight: FontWeight.w600,
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
            itemCount: widget.allSides.length,
            itemBuilder: (context, index) {
              final side = widget.allSides[index];
              return _photoTile(context, l10n, side);
            },
          ),
        ],
      ),
    );
  }

  Widget _photoTile(BuildContext context, AppLocalizations l10n, String side) {
    final takenAt = widget.takenAt[side];
    return HandoverPhotoTile(
      label: _sideLabel(l10n, side),
      uploadingLabel: l10n.handoverPhotoUploading,
      url: widget.photos[side],
      localPath: _localPaths[side],
      uploading: _uploading.contains(side),
      takenAtLabel: takenAt == null
          ? null
          : l10n.handoverWizardPhotoTakenAt(_shortTime(takenAt)),
      onTap: () => _pick(side),
    );
  }

  String _shortTime(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _sideLabel(AppLocalizations l10n, String side) {
    switch (side) {
      case 'front':
        return l10n.handoverPhotoFront;
      case 'back':
        return l10n.handoverPhotoBack;
      case 'left':
        return l10n.handoverPhotoLeft;
      case 'interior':
        return l10n.handoverPhotoInterior;
      case 'dashboard':
        return l10n.handoverPhotoDashboard;
      default:
        return l10n.handoverPhotoRight;
    }
  }
}
