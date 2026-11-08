import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import 'operations/fuel_odometer_input_widget.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// Phase B (E3): the agreement rendered as a paper sheet, extracted
/// from [OwnerContractView] so the view stays under the 250-line
/// cap. Shows only real data — no fake shop name, no fake
/// "Verified Clean" claim, no hardcoded deposit.
class ContractPaperSheet extends StatelessWidget {
  final BookingEntity booking;
  final int odometer;
  final String fuelLevel;
  final int? securityDeposit;
  final Uint8List? customerSignaturePng;
  final Uint8List? ownerSignaturePng;

  const ContractPaperSheet({
    super.key,
    required this.booking,
    required this.odometer,
    required this.fuelLevel,
    this.securityDeposit,
    this.customerSignaturePng,
    this.ownerSignaturePng,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  (booking.shopName ?? 'RentalHub').toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(l10n.contractAgencyLine,
                    style:
                        Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(l10n.contractCertifiedTitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1.5),
          _fieldRow(l10n.contractFieldAgreementNo, '#${booking.bookingId}'),
          _fieldRow(l10n.contractFieldHirer, booking.customerName ?? l10n.contractWalkInCustomer),
          _fieldRow(l10n.contractFieldContact, booking.customerPhone ?? '—'),
          _fieldRow(l10n.contractFieldCnic, booking.customerCnic ?? l10n.contractNotProvided),
          const Divider(height: 20),
          _fieldRow(l10n.contractFieldVehicle, booking.vehicleName ?? l10n.summaryVehicle),
          _fieldRow(l10n.contractFieldPackage,
              '${booking.packageType} (${booking.isWithDriver ? l10n.contractChauffeur : l10n.selfDriveHyphen})'),
          _fieldRow(l10n.contractFieldOdometer, '$odometer KM'),
          _fieldRow(l10n.contractFieldFuel, fuelLevelLabel(l10n, fuelLevel)),
          _fieldRow(l10n.contractFieldTotalPaid, l10n.amountRs(booking.totalAmount)),
          _fieldRow(l10n.contractFieldDeposit,
              securityDeposit != null ? l10n.contractDepositRefundable(securityDeposit!) : '—'),
          const Divider(height: 20),
          Text(
            l10n.contractTermsTitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.contractTerm1}\n${l10n.contractTerm2}\n${l10n.contractTerm3}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              height: 1.4,
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _signatureColumn(
                  l10n.contractHirerSignature, customerSignaturePng, l10n.contractSignedOnPad),
              _signatureColumn(l10n.contractHostSignature, ownerSignaturePng,
                  l10n.contractAuthorizedManager),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureColumn(String label, Uint8List? png, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (png != null)
          Image.memory(png, width: 110, height: 44, fit: BoxFit.contain)
        else
          const Icon(Icons.verified_rounded,
              color: AppColors.accentSuccess, size: 24),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        Text(caption,
            style:
                const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
