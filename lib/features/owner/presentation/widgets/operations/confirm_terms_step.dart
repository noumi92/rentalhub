import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';

/// Audit §5 item 16 (O16 p.6): the Confirm Terms step of the
/// request-accept flow — Car Condition / Fuel Level / Mileage /
/// Documents, then Confirm Booking. The confirm action fires only
/// once all four items are ticked; until then it explains what is
/// still missing instead of silently doing nothing.
class ConfirmTermsStep extends StatefulWidget {
  const ConfirmTermsStep({super.key, required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  State<ConfirmTermsStep> createState() => _ConfirmTermsStepState();
}

class _ConfirmTermsStepState extends State<ConfirmTermsStep> {
  bool _condition = false;
  bool _fuel = false;
  bool _mileage = false;
  bool _documents = false;

  bool get _allChecked => _condition && _fuel && _mileage && _documents;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingConfirmTermsTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.bookingTermCondition),
              value: _condition,
              onChanged: (v) => setState(() => _condition = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.bookingTermFuel),
              value: _fuel,
              onChanged: (v) => setState(() => _fuel = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.bookingTermMileage),
              value: _mileage,
              onChanged: (v) => setState(() => _mileage = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.bookingTermDocuments),
              value: _documents,
              onChanged: (v) => setState(() => _documents = v ?? false),
            ),
            const SizedBox(height: 8),
            DebouncedButton(
              text: l10n.manualBookingConfirmBooking,
              icon: Icons.check_circle_rounded,
              onPressed: () {
                if (_allChecked) {
                  widget.onConfirm();
                } else {
                  AppFeedback.showError(
                      context, l10n.bookingTermsIncomplete);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
