import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/booking_entity.dart';

/// The advance-amount copy row on the proof-upload screen: the
/// payer never types the amount. (Deep link to JazzCash/Easypaisa:
/// NOT added — neither app publishes a documented payment
/// deep-link scheme, so an invented `jazzcash://` URI could silently
/// fail or open the wrong screen; copy + paste is the reliable path.)
class ProofAdvanceCopyRow extends StatelessWidget {
  const ProofAdvanceCopyRow({super.key, required this.booking});

  final BookingEntity booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: Text('${l10n.summaryAdvancePayable}: ${l10n.amountRs(formatRs(booking.advanceRequired))}', style: Theme.of(context).textTheme.bodyMedium)),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20),
          tooltip: l10n.proofCopyAdvance,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: '${booking.advanceRequired}'));
            if (context.mounted) AppFeedback.showSuccess(context, l10n.proofAdvanceCopied);
          },
        ),
      ],
    );
  }
}
