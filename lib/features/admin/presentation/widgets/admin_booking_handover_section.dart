import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../finance/domain/entities/security_deposit_entity.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import 'admin_detail_section.dart';
import 'admin_status_chip.dart';

/// F-M16: the handover (pickup) and return checklists on the admin
/// booking detail — the handover photos, documents, accessories and
/// keys that the detail used to omit, plus the return checklist from
/// `return_settlements/{bookingId}`. Photos are thumbnails with
/// tap-to-open; the return odometer is the pickup odometer plus the
/// deposit record's driven kilometres.
class AdminBookingHandoverSection extends StatelessWidget {
  const AdminBookingHandoverSection({
    super.key,
    required this.handover,
    required this.returnSettlement,
    required this.deposit,
  });

  final HandoverSummary? handover;
  final ReturnSettlementSummary? returnSettlement;
  final SecurityDepositEntity? deposit;

  Future<void> _openPhoto(BuildContext context, String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        AppFeedback.showError(context,
            AppLocalizations.of(context)!.admin2_bookingPhotoOpenFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final h = handover;
    final photos = <({String label, String url})>[
      if (h?.photoFrontUrl != null)
        (label: l10n.handoverPhotoFront, url: h!.photoFrontUrl!),
      if (h?.photoBackUrl != null)
        (label: l10n.handoverPhotoBack, url: h!.photoBackUrl!),
      if (h?.photoLeftUrl != null)
        (label: l10n.handoverPhotoLeft, url: h!.photoLeftUrl!),
      if (h?.photoRightUrl != null)
        (label: l10n.handoverPhotoRight, url: h!.photoRightUrl!),
    ];
    final returnPhotos = returnSettlement?.returnPhotoUrls.entries
            .map((e) => (label: humanizeStatus(e.key, l10n), url: e.value))
            .toList() ??
        [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminDetailSection(title: l10n.admin2_bookingDetailHandover, lines: [
          if (h == null) l10n.admin2_bookingDetailNoHandover,
          if (h != null) ...[
            l10n.admin2_bookingDetailOdometer(h.initialOdometer),
            l10n.admin2_bookingDetailFuel(h.fuelLevel),
            l10n.admin2_bookingDetailDamage(h.damageNotes.isEmpty ? l10n.admin2_none : h.damageNotes.join('; ')),
            '${l10n.handoverDocumentsGiven}: ${h.documentsGiven.isEmpty ? l10n.admin2_none : h.documentsGiven.join(', ')}',
            '${l10n.handoverAccessories}: ${h.accessories.isEmpty ? l10n.admin2_none : h.accessories.join(', ')}',
            h.keysHandedOver
                ? l10n.handoverKeysHandedOver
                : l10n.handoverKeysNotHandedOver,
          ],
        ]),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: photos
                  .map((p) => _PhotoThumb(
                        label: p.label,
                        url: p.url,
                        onTap: () => _openPhoto(context, p.url),
                      ))
                  .toList(),
            ),
          ),
        AdminDetailSection(
          title: l10n.returnChecklistTitle,
          lines: _returnLines(l10n),
        ),
        if (returnPhotos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: returnPhotos
                  .map((p) => _PhotoThumb(
                        label: p.label,
                        url: p.url,
                        onTap: () => _openPhoto(context, p.url),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  List<String> _returnLines(AppLocalizations l10n) {
    final r = returnSettlement;
    if (r == null) return [l10n.returnChecklistEmpty];
    final lines = <String>[
      '${l10n.returnCondition}: ${humanizeStatus(r.condition, l10n)}',
      '${l10n.returnRemainingCollected}: ${l10n.amountRs(formatRs(r.remainingRentCollected))}',
      '${l10n.returnNetRefund}: ${l10n.amountRs(formatRs(r.netRefund))}',
      if (r.paymentMethod != null)
        '${l10n.returnPaymentMethod}: ${humanizeStatus(r.paymentMethod!, l10n)}',
    ];
    final driven = deposit?.totalKmDriven;
    if (handover != null && driven != null) {
      lines.insert(
          1, '${l10n.returnOdometer}: ${handover!.initialOdometer + driven} km');
    }
    final notes = deposit?.returnDamageNotes ?? const [];
    if (notes.isNotEmpty) {
      lines.add('${l10n.returnDamageNotes}: ${notes.join('; ')}');
    }
    return lines;
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.label,
    required this.url,
    required this.onTap,
  });

  final String label;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : const SizedBox(
                            width: 96,
                            height: 96,
                            child: Center(
                                child: CircularProgressIndicator())),
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
