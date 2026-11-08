import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import 'operations/fuel_odometer_input_widget.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// Phase B (E3): the agreement rendered as a paper sheet, extracted
/// from [OwnerContractView] so the view stays under the 250-line
/// cap. Shows only real data — no fake shop name, no fake
/// "Verified Clean" claim, no hardcoded deposit.
class ContractPaperSheet extends StatelessWidget {
  final BookingEntity booking;

  /// Null renders as "—": an unknown odometer/fuel must never
  /// render as an invented value on the contract.
  final int? odometer;
  final String? fuelLevel;
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
                // §15: every text run on the deliberate white paper
                // carries an explicit dark-on-paper colour — bare theme
                // text is near-white in dark mode and vanishes here.
                Text(l10n.contractAgencyLine,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        )),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      // §15: the pill had no background, so white text
                      // on white paper was invisible in both modes.
                      color: AppColors.primary,
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
          _fieldRow(context, l10n.contractFieldAgreementNo, '#${booking.bookingId}'),
          _fieldRow(context, l10n.contractFieldHirer, booking.customerName ?? l10n.contractWalkInCustomer),
          _fieldRow(context, l10n.contractFieldContact, booking.customerPhone ?? '—'),
          _fieldRow(context, l10n.contractFieldCnic, booking.customerCnic ?? l10n.contractNotProvided),
          const Divider(height: 20),
          _fieldRow(context, l10n.contractFieldVehicle, booking.vehicleName ?? l10n.summaryVehicle),
          _fieldRow(context, l10n.contractFieldPackage,
              '${booking.packageType} (${booking.isWithDriver ? l10n.contractChauffeur : l10n.selfDriveHyphen})'),
          _fieldRow(context, l10n.contractFieldOdometer,
              odometer == null ? '—' : '$odometer KM'),
          _fieldRow(context, l10n.contractFieldFuel,
              fuelLevel == null ? '—' : fuelLevelLabel(l10n, fuelLevel!)),
          _fieldRow(context, l10n.contractFieldTotalPaid, l10n.amountRs(formatRs(booking.totalAmount))),
          _fieldRow(context, l10n.contractFieldDeposit,
              securityDeposit != null ? l10n.contractDepositRefundable(formatRs(securityDeposit!)) : '—'),
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
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _signatureColumn(context,
                  l10n.contractHirerSignature, customerSignaturePng, l10n.contractSignedOnPad),
              _signatureColumn(context, l10n.contractHostSignature, ownerSignaturePng,
                  l10n.contractAuthorizedManager),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureColumn(
      BuildContext context, String label, Uint8List? png, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (png != null)
          Image.memory(png, width: 110, height: 44, fit: BoxFit.contain)
        else
          const Icon(Icons.verified_rounded,
              color: AppColors.accentSuccess, size: 24),
        const SizedBox(height: 2),
        // C8: theme font slots with explicit dark-on-paper colours
        // (was hardcoded 11 / 9.5sp with no colour).
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                )),
        Text(caption,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                )),
      ],
    );
  }

  Widget _fieldRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // C8: theme font slots with explicit dark-on-paper colours
          // (was hardcoded 11.5 / 12sp).
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  )),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
          ),
        ],
      ),
    );
  }
}
