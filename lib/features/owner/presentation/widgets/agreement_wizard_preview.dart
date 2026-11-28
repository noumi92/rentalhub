import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/theme/card_decoration.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import 'contract_fare_table.dart';
import 'contract_paper_sheet.dart';

/// Item 10 (O46): the agreement preview step of the wizard — the
/// Generated badge + booking/shop/date/QR header, the paper sheet
/// (with license + true photo count), the fare table, and the
/// guarantor detail block (name/CNIC/relation, or an honest "no
/// guarantor" row). The trust score is deliberately NOT shown: it
/// is a live admin computation, not a field on any record this
/// wizard can read.
class AgreementWizardPreview extends StatelessWidget {
  final BookingEntity booking;
  final Uint8List? pdfBytes;
  final String? verificationUrl;
  final int? odometer;
  final String? fuelLevel;
  final int? securityDeposit;
  final Uint8List? customerSignaturePng;
  final Uint8List? ownerSignaturePng;
  final String? guarantorSignatureUrl;
  final Uint8List? guarantorSignaturePng;
  final String? guarantorName;
  final String? licenseNumber;
  final int? handoverPhotoCount;
  final VoidCallback onNext;

  const AgreementWizardPreview({
    super.key,
    required this.booking,
    required this.pdfBytes,
    this.verificationUrl,
    required this.odometer,
    required this.fuelLevel,
    this.securityDeposit,
    this.customerSignaturePng,
    this.ownerSignaturePng,
    this.guarantorSignatureUrl,
    this.guarantorSignaturePng,
    this.guarantorName,
    this.licenseNumber,
    this.handoverPhotoCount,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasGuarantor = booking.guarantorName != null &&
            booking.guarantorName!.isNotEmpty ||
        booking.guarantorCnic != null && booking.guarantorCnic!.isNotEmpty ||
        booking.guarantorRelation != null &&
            booking.guarantorRelation!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking #${booking.bookingId}',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(booking.shopName ?? 'RentalHub',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(formatDateEn(booking.pickupTime),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                    const SizedBox(height: 6),
                    if (pdfBytes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer),
                            const SizedBox(width: 4),
                            Text(l10n.agreementWizardGenerated,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              QrImageView(data: booking.bookingId, size: 72),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ContractPaperSheet(
          booking: booking,
          odometer: odometer,
          fuelLevel: fuelLevel,
          securityDeposit: securityDeposit,
          customerSignaturePng: customerSignaturePng,
          ownerSignaturePng: ownerSignaturePng,
          guarantorSignatureUrl: guarantorSignatureUrl,
          guarantorSignaturePng: guarantorSignaturePng,
          guarantorName: guarantorName,
          licenseNumber: licenseNumber,
          handoverPhotoCount: handoverPhotoCount,
        ),
        const SizedBox(height: 16),
        ContractFareTable(booking: booking),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppCardDecoration.shadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.agreementWizardGuarantor,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (hasGuarantor) ...[
                if (booking.guarantorName != null &&
                    booking.guarantorName!.isNotEmpty)
                  _row(context, l10n.agreementWizardGuarantor,
                      booking.guarantorName!),
                if (booking.guarantorCnic != null &&
                    booking.guarantorCnic!.isNotEmpty)
                  _row(context, l10n.contractFieldCnic,
                      booking.guarantorCnic!),
                if (booking.guarantorRelation != null &&
                    booking.guarantorRelation!.isNotEmpty)
                  _row(context, l10n.agreementWizardRelation,
                      booking.guarantorRelation!),
              ] else
                Text(l10n.agreementWizardNoGuarantor,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DebouncedButton(
          text: l10n.agreementWizardTermsSignatures,
          icon: Icons.arrow_forward_rounded,
          onPressed: onNext,
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
