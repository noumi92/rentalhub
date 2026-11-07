import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Phase B (B3): a stable home for files waiting to upload.
///
/// A queue entry that references a picked photo or document must
/// still find the file after a restart — the picker's temp files
/// are not guaranteed to survive. [store] copies the file into the
/// app documents dir (`offline_uploads/`) and returns the new path;
/// the queue entry stores that path. Files are deleted once their
/// entry is confirmed synced (by the upload handler).
class QueuedUploads {
  static const String dirName = 'offline_uploads';

  static Future<String> store(File file, {Directory? baseDir}) async {
    final base = baseDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final name = file.uri.pathSegments.isEmpty
        ? 'upload'
        : file.uri.pathSegments.last;
    final dest =
        File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$name');
    await file.copy(dest.path);
    return dest.path;
  }

  static Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
