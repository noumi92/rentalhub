import 'package:flutter/material.dart';

import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/theme/card_decoration.dart';

/// Resolves a stored cPanel `kyc` key to a viewable URL. Keys already
/// holding a full URL (older uploads stored the `url` response) are
/// used as-is; bare keys go through the signed media endpoint, the
/// same way the owner KYC uploader and the payment-proof view do.
String kycReviewImageUrl(
    String key, CPanelStorageClient client, String userUid) {
  final trimmed = key.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return client.getSignedMediaUrl(trimmed, userUid);
}

/// One KYC document image on the admin review detail: a labelled
/// tile with the photo, an honest "Not provided" state when the
/// customer submitted nothing for it, and tap-to-zoom (the dialog
/// dismisses by tapping outside it — no close button to forget a
/// tooltip for).
class KycReviewDocumentTile extends StatelessWidget {
  const KycReviewDocumentTile({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.noDocumentLabel,
  });

  final String label;
  final String imageUrl;
  final String noDocumentLabel;

  void _zoom(BuildContext context) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, Object error, StackTrace? stack) =>
                Padding(
              padding: const EdgeInsets.all(24),
              child: Text(noDocumentLabel, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: AppCardDecoration.of(context, radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          SizedBox(
            height: 100,
            child: imageUrl.isEmpty
                ? Center(
                    child: Text(noDocumentLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall))
                : InkWell(
                    onTap: () => _zoom(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, Object error, StackTrace? stack) =>
                            Center(
                          child: Text(noDocumentLabel,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
