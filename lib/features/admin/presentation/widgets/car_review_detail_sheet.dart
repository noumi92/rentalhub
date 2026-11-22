import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../../domain/admin_permissions.dart';
import 'admin_permission_check.dart';
import 'admin_status_chip.dart';

/// The B3 review sheet for one car listing: the real rates (in-city
/// and out-of-city), the documents the vehicle record actually holds
/// (tracker, insurance policy, chassis/engine numbers, mileage), the
/// photo, and the decision — Approve, Hide, or Reject with a reason.
///
/// What is NOT here: a docs x/4 count and an ownership-name mismatch
/// check — the vehicle schema holds no registration documents or
/// registration-owner name, so those checks have no data to read. They
/// wait for a vehicle-documents field, and are not faked in the meantime.
class CarReviewDetailSheet extends StatefulWidget {
  const CarReviewDetailSheet({
    super.key,
    required this.vehicle,
    required this.review,
    required this.onDecided,
  });

  final VehicleEntity vehicle;
  final CarReview? review;
  final VoidCallback onDecided;

  @override
  State<CarReviewDetailSheet> createState() => _CarReviewDetailSheetState();
}

class _CarReviewDetailSheetState extends State<CarReviewDetailSheet> {
  final _reasonController = TextEditingController();
  bool _isWorking = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _decide(String status) async {
    final reason = _reasonController.text.trim();
    if (status != 'approved' && reason.isEmpty) {
      AppFeedback.showError(context,
          AppLocalizations.of(context)!.admin2_carReviewReasonRequired);
      return;
    }
    // F-C1: super admin + operations only (decideVendor) — see the
    // shop application sheet for the check's contract.
    final check = await AdminPermissionCheck.check(
        context, AdminPermission.decideVendor);
    if (!check.proceed) return;
    setState(() => _isWorking = true);
    final synced = await sl<AdminShopsDataSource>().setCarReview(
      vehicleId: widget.vehicle.vehicleId,
      status: status,
      reason: reason,
      adminRole: check.role,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(
          context, AppLocalizations.of(context)!.admin2_decisionSaved);
      widget.onDecided();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(
          context, AppLocalizations.of(context)!.admin2_serverUnreachable);
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${v.make} ${v.model} (${v.year})',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 4),
            Text(
                '${l10n.admin2_carReviewMetaLine1(v.plateNumber, v.category, v.transmission, v.fuelType, v.seats)}\n${l10n.admin2_carReviewMetaLine2(humanizeStatus(v.status, l10n), widget.review?.status == null ? l10n.admin2_carReviewNotReviewed : humanizeStatus(widget.review!.status, l10n))}',
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if ((widget.review?.reason ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.admin2_carReviewLastDecision(widget.review!.reason),
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            if (v.imageUrl != null && v.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(v.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                        height: 120,
                        child: Center(
                            child: Icon(Icons.broken_image_rounded)))),
              ),
            const SizedBox(height: 16),
            _row(l10n.admin2_carReviewDaily,
                l10n.addVehicleReviewDailyRate(formatRs(v.rates.daily24))),
            _row(l10n.admin2_carReviewOutCityDaily,
                v.rates.outOfCityDaily == null
                    ? l10n.admin2_carReviewNotSet
                    : l10n.amountRs(formatRs(v.rates.outOfCityDaily!))),
            _row(l10n.admin2_carReviewHourly,
                '${v.rates.hourly1 == null ? '—' : l10n.amountRs(formatRs(v.rates.hourly1!))} / ${v.rates.hourly3 == null ? '—' : l10n.amountRs(formatRs(v.rates.hourly3!))} / ${v.rates.hourly6 == null ? '—' : l10n.amountRs(formatRs(v.rates.hourly6!))}'),
            _row(l10n.admin2_carReviewWeekly,
                v.weeklyRate == null
                    ? l10n.admin2_carReviewNotSet
                    : l10n.amountRs(formatRs(v.weeklyRate!))),
            _row(l10n.admin2_carReviewDeposit,
                v.securityDepositPkr == null
                    ? l10n.admin2_carReviewNotSet
                    : l10n.amountRs(formatRs(v.securityDepositPkr!))),
            _row(l10n.admin2_selfDrive,
                v.isSelfDriveAvailable ? l10n.admin2_yes : l10n.admin2_no),
            _row(l10n.admin2_withDriver,
                v.isWithDriverAvailable ? l10n.admin2_yes : l10n.admin2_no),
            _row(l10n.admin2_carReviewTracker,
                v.trackerProvider ?? l10n.admin2_carReviewNotListed),
            _row(l10n.admin2_carReviewInsurance,
                v.insurancePolicy ?? l10n.admin2_carReviewNotListed),
            _row(l10n.admin2_carReviewChassis,
                v.chassisNumber ?? l10n.admin2_carReviewNotListed),
            _row(l10n.admin2_carReviewEngine,
                v.engineNumber ?? l10n.admin2_carReviewNotListed),
            _row(l10n.admin2_carReviewMileage,
                v.mileageKm == null
                    ? l10n.admin2_carReviewNotListed
                    : l10n.admin2_carReviewMileageKm(v.mileageKm!)),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.admin2_carReviewReasonLabel,
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            // AD-m8: the trio stacks full-width (like the shop
            // application sheet) with 48dp minimum targets — the old
            // 3-in-a-row Row squeezed them below 48dp at 360px.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed:
                      _isWorking ? null : () => _decide('approved'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.admin2_approve),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed:
                      _isWorking ? null : () => _decide('hidden'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.admin2_reviewHide),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed:
                      _isWorking ? null : () => _decide('rejected'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerTextFor(
                          Theme.of(context).brightness),
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.admin2_reject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
