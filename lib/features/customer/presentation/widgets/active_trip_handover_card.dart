import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// E3: the handover card on the active-trip screen — the odometer and
/// fuel the owner recorded at pickup, from `handovers/{bookingId}`.
/// When the record does not exist yet (handover not done), it says so
/// instead of inventing values.
class ActiveTripHandoverCard extends StatelessWidget {
  const ActiveTripHandoverCard({
    super.key,
    required this.handover,
    required this.loaded,
  });

  final Map<String, dynamic>? handover;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Handover at Pickup',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          if (!loaded)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ))
          else if (handover == null)
            Text(
              'The shop records the odometer and fuel level at handover — they will appear here once the car is handed over.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
            )
          else ...[
            _fact('Odometer at pickup', '${handover!['initialOdometer'] ?? '—'} km'),
            const SizedBox(height: 8),
            _fact('Fuel at pickup', '${handover!['fuelLevel'] ?? '—'}'),
            if ((handover!['damageNotes'] as List?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _fact('Damage noted',
                  (handover!['damageNotes'] as List).join(', ')),
            ],
          ],
        ],
      ),
    );
  }

  Widget _fact(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ),
      ],
    );
  }
}
