import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// Phase B (F1): the damage noted when the car left, shown at return
/// so the owner only charges for damage that is new.
class HandoverNotesBanner extends StatelessWidget {
  final List<String> notes;

  const HandoverNotesBanner({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Noted at handover: ${notes.join('; ')}',
        style:
            const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}
