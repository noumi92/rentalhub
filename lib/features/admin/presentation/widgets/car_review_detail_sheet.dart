import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../data/datasources/admin_shops_data_source.dart';

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
      AppFeedback.showError(
          context, 'A reason is required to hide or reject a listing.');
      return;
    }
    setState(() => _isWorking = true);
    final synced = await sl<AdminShopsDataSource>().setCarReview(
      vehicleId: widget.vehicle.vehicleId,
      status: status,
      reason: reason,
    );
    if (!mounted) return;
    if (synced) {
      AppFeedback.showSuccess(context, 'Decision saved.');
      widget.onDecided();
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(context, 'Could not reach the server.');
      setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
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
                    fontWeight: FontWeight.w900,
                    )),
            const SizedBox(height: 4),
            Text(
                'Plate ${v.plateNumber} • ${v.category} • ${v.transmission} • ${v.fuelType} • ${v.seats} seats\nStatus: ${v.status} • Current review: ${widget.review?.status ?? 'not reviewed yet'}',
                style:
                    TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            if ((widget.review?.reason ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Last decision: ${widget.review!.reason}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
            _row('Daily (24 h)', 'Rs. ${v.rates.daily24}'),
            _row('Out-of-city daily',
                v.rates.outOfCityDaily == null
                    ? 'Not set'
                    : 'Rs. ${v.rates.outOfCityDaily}'),
            _row('1 h / 3 h / 6 h',
                '${v.rates.hourly1 ?? '—'} / ${v.rates.hourly3 ?? '—'} / ${v.rates.hourly6 ?? '—'}'),
            _row('Weekly rate',
                v.weeklyRate == null ? 'Not set' : 'Rs. ${v.weeklyRate}'),
            _row('Security deposit',
                v.securityDepositPkr == null
                    ? 'Not set'
                    : 'Rs. ${v.securityDepositPkr}'),
            _row('Self drive',
                v.isSelfDriveAvailable ? 'Yes' : 'No'),
            _row('With driver',
                v.isWithDriverAvailable ? 'Yes' : 'No'),
            _row('Tracker', v.trackerProvider ?? 'Not listed'),
            _row('Insurance policy', v.insurancePolicy ?? 'Not listed'),
            _row('Chassis', v.chassisNumber ?? 'Not listed'),
            _row('Engine', v.engineNumber ?? 'Not listed'),
            _row('Mileage',
                v.mileageKm == null ? 'Not listed' : '${v.mileageKm} km'),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    'Reason (required to hide or reject — stored with the decision)',
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
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _isWorking ? null : () => _decide('approved'),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isWorking ? null : () => _decide('hidden'),
                    child: const Text('Hide'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isWorking ? null : () => _decide('rejected'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700),
                    child: const Text('Reject'),
                  ),
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
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  )),
        ],
      ),
    );
  }
}
