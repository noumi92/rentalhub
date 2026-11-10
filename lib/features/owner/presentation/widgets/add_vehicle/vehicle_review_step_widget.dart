import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/widgets/pakistani_plate_widget.dart';

class VehicleReviewStepWidget extends StatelessWidget {
  final XFile? photoFrontFile;
  final String selectedMake;
  final String selectedModel;
  final String category;
  final int selectedYear;
  final String color;
  final String plateNumber;
  final bool isAutomatic;
  final String fuelType;
  final int seats;

  /// Audit §5: AC is rendered honestly from the step-1 switch —
  /// never a hardcoded "Full AC".
  final bool hasAc;

  /// Audit §5: names of the picked documents (reg book / token tax /
  /// insurance) and extra photos, so the owner sees what was picked
  /// before publishing. Entries are "Label: filename".
  final List<String> documentNames;
  final int dailyRate;
  final int driverAllowance;

  /// Audit §5 (O08): the Monthly package rate, when the owner set
  /// one — the "Your Earning" row below is computed from it and only
  /// renders when it is greater than zero.
  final int monthlyRate;

  /// Audit §5 (O08): Delivery & Collection, Discounts and Insurance
  /// rows render ONLY when the caller supplies the underlying data.
  /// The add-vehicle flow has no delivery setting, discount or
  /// insurance date, so those rows are omitted there — never invented.
  final String? deliveryNote;
  final String? discountNote;
  final String? insuranceNote;

  final bool supportSelfDrive;
  final bool supportWithDriver;
  final int deposit;
  final int advance;
  final int extraHour;
  final String fuelPolicy;

  const VehicleReviewStepWidget({
    super.key,
    required this.photoFrontFile,
    required this.selectedMake,
    required this.selectedModel,
    required this.category,
    required this.selectedYear,
    required this.color,
    required this.plateNumber,
    required this.isAutomatic,
    required this.fuelType,
    required this.seats,
    required this.dailyRate,
    required this.driverAllowance,
    this.monthlyRate = 0,
    this.deliveryNote,
    this.discountNote,
    this.insuranceNote,
    required this.supportSelfDrive,
    required this.supportWithDriver,
    required this.deposit,
    required this.advance,
    required this.extraHour,
    required this.fuelPolicy,
    required this.hasAc,
    this.documentNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (photoFrontFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(photoFrontFile!.path), width: 56, height: 56, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.directions_car_rounded, size: 28),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$selectedMake $selectedModel',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text('$category • $selectedYear • $color', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    // Audit §5: no sample plate as a fallback — an
                    // empty plate shows a dash until one is entered.
                    if (plateNumber.isEmpty)
                      Text('—', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))
                    else
                      PakistaniPlateWidget(
                        plateNumber: plateNumber,
                        isCompact: true,
                      ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    _reviewSpec(context, l10n.addVehicleReviewGear, isAutomatic ? l10n.addVehicleReviewAuto : l10n.addVehicleManual),
                    _reviewSpec(context, l10n.addVehicleReviewFuel, fuelType),
                    _reviewSpec(context, l10n.addVehicleReviewSeats, '$seats'),
                    _reviewSpec(context, l10n.addVehicleReviewAc, hasAc ? l10n.addVehicleReviewFullAc : l10n.addVehicleReviewNotOffered),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.addVehicleReviewSelfDriveRate, style: Theme.of(context).textTheme.labelSmall),
                        Text(
                          supportSelfDrive ? l10n.addVehicleReviewDailyRate(formatRs(dailyRate)) : l10n.addVehicleReviewNotOffered,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: supportSelfDrive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l10n.addVehicleReviewWithDriverRate, style: Theme.of(context).textTheme.labelSmall),
                        Text(
                          supportWithDriver ? l10n.addVehicleReviewDailyRate(formatRs(dailyRate + driverAllowance)) : l10n.addVehicleReviewNotOffered,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: supportWithDriver ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    _reviewMiniDetail(context, l10n.addVehicleReviewDeposit, l10n.amountRs(formatRs(deposit))),
                    _reviewMiniDetail(context, l10n.addVehicleReviewAdvance, l10n.amountRs(formatRs(advance))),
                    _reviewMiniDetail(context, l10n.addVehicleReviewOverstay, l10n.addVehicleReviewOverstayRate(formatRs(extraHour))),
                    _reviewMiniDetail(context, l10n.addVehicleReviewFuel, fuelPolicy),
                  ],
                ),
                // Audit §5 (O08): only rows with real underlying data.
                if (deliveryNote != null) ...[
                  const Divider(height: 20),
                  _reviewLine(context, l10n.vehicleReviewDelivery, deliveryNote!),
                ],
                if (discountNote != null) ...[
                  const Divider(height: 20),
                  _reviewLine(context, l10n.vehicleReviewDiscounts, discountNote!),
                ],
                if (insuranceNote != null) ...[
                  const Divider(height: 20),
                  _reviewLine(context, l10n.vehicleReviewInsurance, insuranceNote!),
                ],
                if (monthlyRate > 0) ...[
                  const Divider(height: 20),
                  _reviewLine(context, l10n.vehicleReviewYourEarning, l10n.amountRs(formatRs(monthlyRate))),
                ],
                // Audit §5: the picked photos/documents are listed,
                // so the review shows what will actually be uploaded.
                if (documentNames.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text(l10n.addVehicleLegalDocs, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  ...documentNames.map((name) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.attach_file_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.successContainerFor(Theme.of(context).brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.successBorderFor(Theme.of(context).brightness)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.successOnContainerFor(Theme.of(context).brightness), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.addVehicleReviewBanner,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Audit §5 (C8): theme font slots, one Expanded column each, with
  // ellipsis — the old hardcoded 13/10/11.5sp rows in a bare Row
  // overflowed at 360px / 1.35× / Urdu.
  Widget _reviewSpec(BuildContext context, String title, String val) {
    return Expanded(
      child: Column(
        children: [
          Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _reviewLine(BuildContext context, String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        const SizedBox(width: 8),
        Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _reviewMiniDetail(BuildContext context, String title, String val) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

