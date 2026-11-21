import 'package:flutter/material.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../customer/domain/repositories/customer_repository.dart';
import '../services/kyc_slot_replace_service.dart';
import 'customer_kyc_slots.dart';

/// Walk-in CRM: the KYC-replace flow for one docs-grid tile,
/// shared by the detail view (and its tests). CNIC slots offer
/// Camera / Gallery (the gallery pick is OCR-guarded inside the
/// service); every other slot goes straight to the rear camera.
/// On success the one URL field is merge-set via [upsertCustomer]
/// and [onChanged] fires so the caller reloads — the tile then
/// shows the new photo immediately. A cancelled pick is silent;
/// a rejected or failed replace shows honest feedback.
Future<void> handleKycSlotReplace({
  required BuildContext context,
  required CustomerEntity customer,
  required String field,
  required String shopId,
  required CustomerRepository repository,
  required KycSlotReplaceService replacer,
  required VoidCallback onChanged,
}) async {
  final l10n = AppLocalizations.of(context)!;
  var fromGallery = false;
  if (KycSlotReplaceService.isCnicSlot(field)) {
    final choice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.customerDetailKycReplaceTitle),
        content: Text(l10n.customerDetailKycReplacePrompt),
        actions: [
          TextButton(
            key: const ValueKey('kyc_replace_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('kyc_replace_gallery'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.kycFromGallery),
          ),
          TextButton(
            key: const ValueKey('kyc_replace_camera'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.kycTakePhoto),
          ),
        ],
      ),
    );
    if (choice == null) return;
    fromGallery = choice;
  }
  try {
    final url = await replacer.replaceSlot(
      customer: customer,
      field: field,
      shopId: shopId,
      fromGallery: fromGallery,
    );
    if (url == null) return; // Cancelled pick — stay silent.
    await repository.upsertCustomer(
      customerWithSlotUrl(customer, field, url),
    );
    onChanged();
    if (context.mounted) {
      AppFeedback.showSuccess(context, l10n.customerDetailKycReplaced);
    }
  } on KycSlotReplaceException catch (e) {
    if (!context.mounted) return;
    AppFeedback.showError(
      context,
      e.unreadable
          ? l10n.kycWizardImageNotClear
          : l10n.customerDetailKycReplaceFailed,
    );
  } catch (_) {
    if (!context.mounted) return;
    AppFeedback.showError(context, l10n.customerDetailKycReplaceFailed);
  }
}
